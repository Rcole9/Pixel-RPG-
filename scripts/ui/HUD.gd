extends CanvasLayer

var hp_bar:        ProgressBar = null
var resource_bar:  ProgressBar = null
var hp_label:      Label       = null
var resource_label: Label      = null
var quest_label:   Label       = null
var loot_label:    Label       = null
var loot_timer:    float       = 0.0
var ability_btns:  Array       = []
var cd_overlays:   Array       = []
var save_btn:      Button      = null
var inventory_panel: Node      = null
var player_ref:    Node        = null
var status_label:  Label       = null
var _pl_label:     Label       = null
var _item_grid:    GridContainer = null
var _equip_slots:  GridContainer = null

func _ready() -> void:
add_to_group("hud")
_build_hud()
GameState.stats_changed.connect(_refresh_stats)
GameState.quest_accepted.connect(_refresh_quests)
GameState.quest_completed.connect(_refresh_quests)
GameState.loot_notification.connect(_show_loot_notif)
# Find player
await get_tree().process_frame
player_ref = get_tree().get_first_node_in_group("player")

func _build_hud() -> void:
var root := Control.new()
root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
add_child(root)

# ─── HP / Resource bars (top-left) ────────────────────────────────
var bars_panel := Panel.new()
bars_panel.size     = Vector2(220, 80)
bars_panel.position = Vector2(10, 10)
root.add_child(bars_panel)

hp_bar = ProgressBar.new()
hp_bar.size     = Vector2(200, 22)
hp_bar.position = Vector2(10, 8)
hp_bar.max_value = 200
hp_bar.value     = 200
hp_bar.show_percentage = false
hp_bar.add_theme_color_override("fill_color_under", Color(0.5, 0, 0))
bars_panel.add_child(hp_bar)

hp_label = Label.new()
hp_label.size     = Vector2(200, 22)
hp_label.position = Vector2(10, 8)
hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
hp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
hp_label.add_theme_font_size_override("font_size", 12)
hp_label.text = "HP: 200/200"
bars_panel.add_child(hp_label)

resource_bar = ProgressBar.new()
resource_bar.size     = Vector2(200, 18)
resource_bar.position = Vector2(10, 38)
resource_bar.max_value = 100
resource_bar.value     = 100
resource_bar.show_percentage = false
resource_bar.add_theme_color_override("fill_color_under", Color(0.0, 0.2, 0.7))
bars_panel.add_child(resource_bar)

resource_label = Label.new()
resource_label.size     = Vector2(200, 18)
resource_label.position = Vector2(10, 38)
resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
resource_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
resource_label.add_theme_font_size_override("font_size", 11)
resource_label.text = "100/100"
bars_panel.add_child(resource_label)

# Power level
_pl_label = Label.new()
_pl_label.name     = "PLLabel"
_pl_label.text     = "PL 1"
_pl_label.position = Vector2(10, 58)
_pl_label.add_theme_font_size_override("font_size", 11)
bars_panel.add_child(_pl_label)

# ─── Quest tracker (top-right) ─────────────────────────────────────
quest_label = Label.new()
quest_label.text     = "No active quests"
quest_label.position = Vector2(900, 10)
quest_label.size     = Vector2(360, 80)
quest_label.add_theme_font_size_override("font_size", 11)
quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
root.add_child(quest_label)

# ─── Loot notification ─────────────────────────────────────────────
loot_label = Label.new()
loot_label.text     = ""
loot_label.position = Vector2(440, 80)
loot_label.size     = Vector2(400, 30)
loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
loot_label.add_theme_font_size_override("font_size", 14)
loot_label.visible  = false
root.add_child(loot_label)

# ─── Status effects label ──────────────────────────────────────────
status_label = Label.new()
status_label.text     = ""
status_label.position = Vector2(10, 95)
status_label.size     = Vector2(300, 20)
status_label.add_theme_font_size_override("font_size", 10)
root.add_child(status_label)

# ─── Ability hotbar (bottom-center) ───────────────────────────────
var hotbar := HBoxContainer.new()
hotbar.position = Vector2(440, 636)
hotbar.size     = Vector2(400, 72)
root.add_child(hotbar)

for i in 4:
var slot := Panel.new()
slot.custom_minimum_size = Vector2(70, 70)

var btn := Button.new()
btn.size     = Vector2(60, 60)
btn.position = Vector2(5, 5)
btn.text     = str(i + 1)
btn.pressed.connect(_on_ability_pressed.bind(i))
slot.add_child(btn)

var cd_overlay := ColorRect.new()
cd_overlay.size     = Vector2(60, 60)
cd_overlay.position = Vector2(5, 5)
cd_overlay.color    = Color(0, 0, 0, 0.5)
cd_overlay.visible  = false
cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
slot.add_child(cd_overlay)

var cd_lbl := Label.new()
cd_lbl.name     = "CDLabel"
cd_lbl.size     = Vector2(60, 60)
cd_lbl.position = Vector2(5, 5)
cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
cd_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
cd_lbl.add_theme_font_size_override("font_size", 16)
cd_lbl.visible = false
slot.add_child(cd_lbl)

hotbar.add_child(slot)
ability_btns.append(btn)
cd_overlays.append({"overlay": cd_overlay, "label": cd_lbl})

# ─── Save / Inventory buttons (bottom-left) ───────────────────────
save_btn = Button.new()
save_btn.text     = "Save (F5)"
save_btn.size     = Vector2(100, 36)
save_btn.position = Vector2(10, 670)
save_btn.pressed.connect(_on_save)
root.add_child(save_btn)

var inv_btn := Button.new()
inv_btn.text     = "Inv (I)"
inv_btn.size     = Vector2(80, 36)
inv_btn.position = Vector2(120, 670)
inv_btn.pressed.connect(toggle_inventory)
root.add_child(inv_btn)

# ─── Inventory panel ──────────────────────────────────────────────
inventory_panel = _build_inventory_panel(root)
inventory_panel.visible = false

_refresh_stats()
_refresh_quests("init")

func _build_inventory_panel(parent: Control) -> Panel:
var panel := Panel.new()
panel.size     = Vector2(500, 460)
panel.position = Vector2(390, 120)
parent.add_child(panel)

var title := Label.new()
title.text     = "INVENTORY & EQUIPMENT"
title.position = Vector2(10, 8)
title.add_theme_font_size_override("font_size", 14)
panel.add_child(title)

# Equipment slots
var equip_label := Label.new()
equip_label.text     = "Equipment:"
equip_label.position = Vector2(10, 34)
equip_label.add_theme_font_size_override("font_size", 11)
panel.add_child(equip_label)

var eq_container := GridContainer.new()
eq_container.columns  = 5
eq_container.position = Vector2(10, 54)
eq_container.size     = Vector2(480, 60)
panel.add_child(eq_container)
eq_container.name = "EquipSlots"
_equip_slots      = eq_container

for slot in GameState.EQUIPMENT_SLOTS:
var eq_btn := Button.new()
eq_btn.custom_minimum_size = Vector2(88, 50)
eq_btn.text  = slot.capitalize()
eq_btn.name  = "Equip_" + slot
eq_btn.pressed.connect(_on_slot_click.bind(slot))
eq_container.add_child(eq_btn)

# Divider
var div := HSeparator.new()
div.position = Vector2(0, 118)
div.size     = Vector2(500, 8)
panel.add_child(div)

# Inventory items
var inv_label := Label.new()
inv_label.text     = "Bag:"
inv_label.position = Vector2(10, 130)
inv_label.add_theme_font_size_override("font_size", 11)
panel.add_child(inv_label)

var scroll := ScrollContainer.new()
scroll.position = Vector2(10, 150)
scroll.size     = Vector2(480, 240)
panel.add_child(scroll)

var grid := GridContainer.new()
grid.columns = 4
grid.name    = "ItemGrid"
scroll.add_child(grid)
_item_grid = grid

var close_btn := Button.new()
close_btn.text     = "Close"
close_btn.size     = Vector2(80, 32)
close_btn.position = Vector2(410, 418)
close_btn.pressed.connect(toggle_inventory)
panel.add_child(close_btn)

return panel

func toggle_inventory() -> void:
inventory_panel.visible = not inventory_panel.visible
if inventory_panel.visible:
_refresh_inventory_panel()

func _refresh_inventory_panel() -> void:
# Refresh equipment slots
if _equip_slots:
for slot in GameState.EQUIPMENT_SLOTS:
var btn: Button = _equip_slots.get_node_or_null("Equip_" + slot)
if btn:
var item: Dictionary = GameState.equipped_items.get(slot, {})
if item.is_empty():
btn.text         = slot.capitalize()
btn.tooltip_text = ""
else:
btn.text         = slot.capitalize() + "\n" + item.get("name","?").substr(0, 10)
btn.tooltip_text = LootSystem.item_summary(item)
# Refresh item grid
if _item_grid == null:
return
for child in _item_grid.get_children():
child.queue_free()
for item in GameState.player_inventory:
var ibtn := Button.new()
ibtn.custom_minimum_size = Vector2(110, 54)
var rarity: String = item.get("rarity", "common")
ibtn.text         = "[%s]\n%s" % [rarity.substr(0,3).to_upper(), item.get("name","?").substr(0,14)]
ibtn.tooltip_text = LootSystem.item_summary(item)
ibtn.add_theme_color_override("font_color", LootSystem.item_color(item))
var item_copy: Dictionary = item.duplicate()
ibtn.pressed.connect(_on_equip_item.bind(item_copy))
_item_grid.add_child(ibtn)

func _on_equip_item(item: Dictionary) -> void:
GameState.equip_item(item)
_refresh_inventory_panel()
_refresh_stats()

func _on_slot_click(slot: String) -> void:
var item: Dictionary = GameState.equipped_items.get(slot, {})
if not item.is_empty():
GameState.add_item(item)
GameState.equipped_items[slot] = {}
GameState.apply_equipment_stats()
_refresh_inventory_panel()
_refresh_stats()

func _on_ability_pressed(index: int) -> void:
var player: Node = get_tree().get_first_node_in_group("player")
if player and player.has_method("use_ability"):
player.use_ability(index)

func _on_save() -> void:
var player: Node = get_tree().get_first_node_in_group("player")
SaveLoad.save_game(player)
_show_loot_notif("Game Saved!")

func _refresh_stats() -> void:
var stats: Dictionary = GameState.player_stats
if stats.is_empty():
return
var hp_val:     int = stats.get("hp", 0)
var max_hp_val: int = stats.get("max_hp", 1)
var res_val:    int = stats.get("resource", 0)
var max_res:    int = stats.get("max_resource", 1)

if hp_bar:
hp_bar.max_value = max_hp_val
hp_bar.value     = hp_val
if hp_label:
hp_label.text = "HP %d/%d" % [hp_val, max_hp_val]

if resource_bar:
resource_bar.max_value = max_res
resource_bar.value     = res_val
if resource_label:
var rname: String = stats.get("resource_name", "Resource")
resource_label.text = "%s %d/%d" % [rname, res_val, max_res]

# Update power level label
if _pl_label:
_pl_label.text = "PL %d  |  %s" % [GameState.power_level, GameState.player_class]

# Update ability labels
_refresh_ability_labels()

func _refresh_ability_labels() -> void:
var player: Node = get_tree().get_first_node_in_group("player")
if player == null:
return
var abs: Array = player.abilities if "abilities" in player else []
for i in min(4, abs.size()):
if i < ability_btns.size():
var ab: Dictionary = abs[i]
ability_btns[i].text = "%d\n%s" % [i+1, ab.get("name","?")[:8]]

func _refresh_quests(_arg = null) -> void:
if not quest_label:
return
if GameState.active_quests.is_empty() and GameState.completed_quests.is_empty():
quest_label.text = "No active quests"
return
var lines: Array[String] = []
for q in GameState.active_quests:
lines.append("► " + q.replace("_", " ").capitalize())
for q in GameState.completed_quests:
lines.append("✓ " + q.replace("_", " ").capitalize())
quest_label.text = "\n".join(lines)

func _show_loot_notif(text: String) -> void:
if not loot_label:
return
loot_label.text    = text
loot_label.visible = true
loot_timer         = 3.0

func _process(delta: float) -> void:
# Hide loot notification
if loot_timer > 0:
loot_timer -= delta
if loot_timer <= 0:
if loot_label: loot_label.visible = false

# Ability cooldown overlays
var player: Node = get_tree().get_first_node_in_group("player")
if player and "cooldowns" in player and "abilities" in player:
for i in min(4, cd_overlays.size()):
var frac: float = player.get_cooldown_fraction(i) if player.has_method("get_cooldown_fraction") else 0.0
var data: Dictionary = cd_overlays[i]
data["overlay"].visible = frac > 0.0
data["label"].visible   = frac > 0.0
if frac > 0.0:
var total_cd: float = player.abilities[i].get("cooldown", 1.0) if i < player.abilities.size() else 1.0
data["label"].text  = "%.1f" % (player.cooldowns[i] if i < player.cooldowns.size() else 0.0)

# Status effects display
if player and "status_effects" in player and status_label:
var se_texts: Array[String] = []
for se in player.status_effects:
se_texts.append("%s %.1fs" % [se["type"].capitalize(), se["timer"]])
if player.get("shield_active"):
se_texts.append("Shield(%d)" % player.get("shield_amount", 0))
status_label.text = " | ".join(se_texts)
