extends Node

# ── Class definitions ──────────────────────────────────────────────────
const CLASSES: Array[String] = ["Tank", "Healer", "DPS"]

const CLASS_BASE_STATS: Dictionary = {
"Tank":   { "max_hp": 200, "max_resource": 100, "damage": 15, "defense": 20, "speed": 100, "resource_name": "Rage"   },
"Healer": { "max_hp": 130, "max_resource": 160, "damage": 10, "defense": 10, "speed": 120, "resource_name": "Mana"   },
"DPS":    { "max_hp": 110, "max_resource":  90, "damage": 28, "defense":  6, "speed": 140, "resource_name": "Energy" },
}

const EQUIPMENT_SLOTS: Array[String] = ["weapon", "helm", "chest", "boots", "artifact"]

# ── Runtime state ──────────────────────────────────────────────────────
var player_class: String = ""
var player_stats: Dictionary = {}
var player_inventory: Array = []
var equipped_items: Dictionary = {}
var active_quests: Array = []
var completed_quests: Array = []
var power_level: int = 1
var current_zone: String = "overworld"
var dungeon_cleared: bool = false
var boss_defeated: bool = false
var player_position: Vector2 = Vector2(400, 300)

# ── Signals ────────────────────────────────────────────────────────────
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal item_equipped(slot: String, item: Dictionary)
signal player_class_changed(new_class: String)
signal stats_changed
signal item_added(item: Dictionary)
signal loot_notification(text: String)

# ── Initialisation ─────────────────────────────────────────────────────
func initialize_player(cls: String) -> void:
player_class = cls
var base: Dictionary = CLASS_BASE_STATS[cls]
player_stats = {
"hp":           base["max_hp"],
"max_hp":       base["max_hp"],
"resource":     base["max_resource"],
"max_resource": base["max_resource"],
"damage":       base["damage"],
"defense":      base["defense"],
"speed":        base["speed"],
"resource_name": base["resource_name"],
"power_level":  1,
}
player_inventory  = []
equipped_items = {}
for slot in EQUIPMENT_SLOTS:
equipped_items[slot] = {}
active_quests     = []
completed_quests  = []
power_level       = 1
current_zone      = "overworld"
dungeon_cleared   = false
boss_defeated     = false
player_position   = Vector2(400, 300)
player_class_changed.emit(cls)
stats_changed.emit()

# ── Stat helpers ───────────────────────────────────────────────────────
func apply_equipment_stats() -> void:
if player_class == "":
return
var base: Dictionary = CLASS_BASE_STATS[player_class]
var bonus_hp: int = 0
var bonus_dmg: int = 0
var bonus_def: int = 0
for slot in equipped_items:
var item: Dictionary = equipped_items[slot]
if item.is_empty():
continue
for affix in item.get("affixes", []):
match affix["stat"]:
"hp":      bonus_hp  += affix["value"]
"damage":  bonus_dmg += affix["value"]
"defense": bonus_def += affix["value"]
player_stats["max_hp"]  = base["max_hp"]  + bonus_hp
player_stats["damage"]  = base["damage"]  + bonus_dmg
player_stats["defense"] = base["defense"] + bonus_def
player_stats["hp"]      = min(player_stats["hp"], player_stats["max_hp"])
power_level = max(1, 1 + int((bonus_hp / 10) + (bonus_dmg / 5) + (bonus_def / 4)))
player_stats["power_level"] = power_level
stats_changed.emit()

func heal_player(amount: int) -> void:
player_stats["hp"] = min(player_stats["hp"] + amount, player_stats["max_hp"])
stats_changed.emit()

func damage_player(raw_amount: int) -> void:
var def_val: int = player_stats.get("defense", 0)
var mitigated: int = max(1, raw_amount - def_val / 3)
player_stats["hp"] = max(0, player_stats["hp"] - mitigated)
stats_changed.emit()

func spend_resource(amount: int) -> bool:
if player_stats.get("resource", 0) < amount:
return false
player_stats["resource"] -= amount
stats_changed.emit()
return true

func restore_resource(amount: int) -> void:
player_stats["resource"] = min(
player_stats.get("resource", 0) + amount,
player_stats.get("max_resource", 100))
stats_changed.emit()

func is_player_alive() -> bool:
return player_stats.get("hp", 0) > 0

# ── Inventory helpers ──────────────────────────────────────────────────
func add_item(item: Dictionary) -> void:
player_inventory.append(item)
item_added.emit(item)
loot_notification.emit("+" + item.get("name", "Item") + " [" + item.get("rarity", "common").capitalize() + "]")

func equip_item(item: Dictionary) -> void:
var slot: String = item.get("slot", "weapon")
if not (slot in EQUIPMENT_SLOTS):
return
var old: Dictionary = equipped_items.get(slot, {})
if not old.is_empty():
player_inventory.append(old)
equipped_items[slot] = item
player_inventory.erase(item)
apply_equipment_stats()
item_equipped.emit(slot, item)

# ── Quest helpers ──────────────────────────────────────────────────────
func accept_quest(quest_id: String) -> void:
if quest_id not in active_quests and quest_id not in completed_quests:
active_quests.append(quest_id)
quest_accepted.emit(quest_id)

func complete_quest(quest_id: String) -> void:
active_quests.erase(quest_id)
if quest_id not in completed_quests:
completed_quests.append(quest_id)
quest_completed.emit(quest_id)

func has_quest(quest_id: String) -> bool:
return quest_id in active_quests or quest_id in completed_quests
