extends Node

# ── Rarity ────────────────────────────────────────────────────────────
const RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]
const RARITY_WEIGHTS: Dictionary = {
"common": 60, "rare": 25, "epic": 12, "legendary": 3
}
const RARITY_COLORS: Dictionary = {
"common": Color(0.8, 0.8, 0.8),
"rare":   Color(0.3, 0.5, 1.0),
"epic":   Color(0.6, 0.2, 1.0),
"legendary": Color(1.0, 0.6, 0.1),
}
const RARITY_AFFIX_COUNT: Dictionary = {
"common": 1, "rare": 2, "epic": 3, "legendary": 4
}

# ── Item base names per slot ───────────────────────────────────────────
const SLOT_BASES: Dictionary = {
"weapon":   ["Rune Blade", "Void Staff", "Shadow Dagger", "Iron Hammer"],
"helm":     ["Iron Helm", "Void Crown", "Shadow Hood", "Rune Circlet"],
"chest":    ["Chain Hauberk", "Mage Robe", "Shadow Tunic", "Rune Plate"],
"boots":    ["Iron Greaves", "Void Treads", "Shadow Boots", "Rune Striders"],
"artifact": ["Void Shard", "Rune Stone", "Shadow Orb", "Ancient Token"],
}

# ── Affix pool ─────────────────────────────────────────────────────────
const AFFIXES: Array = [
{"prefix": "Healthy",  "stat": "hp",      "min": 10, "max": 40},
{"prefix": "Mighty",   "stat": "damage",  "min":  5, "max": 20},
{"prefix": "Sturdy",   "stat": "defense", "min":  3, "max": 15},
{"prefix": "Vital",    "stat": "hp",      "min": 20, "max": 60},
{"prefix": "Vicious",  "stat": "damage",  "min": 10, "max": 30},
{"prefix": "Fortified","stat": "defense", "min":  6, "max": 25},
]

# ── Perk pool ──────────────────────────────────────────────────────────
const PERKS: Array = [
{"name": "Ignition",      "desc": "20% chance on attack to apply Burn",         "trigger": "on_attack",  "effect": "burn"},
{"name": "Glacial Touch", "desc": "15% chance on attack to apply Slow",          "trigger": "on_attack",  "effect": "slow"},
{"name": "Enfeeble",      "desc": "10% chance on attack to apply Weaken",        "trigger": "on_attack",  "effect": "weaken"},
{"name": "Vampiric",      "desc": "Heal 5% of damage dealt",                     "trigger": "on_damage",  "effect": "lifesteal"},
{"name": "Last Stand",    "desc": "Below 30% HP, gain temporary shield",         "trigger": "low_hp",     "effect": "emergency_shield"},
{"name": "Rune Echo",     "desc": "Abilities refund 10% cooldown on kill",       "trigger": "on_kill",    "effect": "cdr"},
{"name": "Void Hunger",   "desc": "Killing enemies restores 10 resource",        "trigger": "on_kill",    "effect": "resource_restore"},
]

# ── Main generation function ───────────────────────────────────────────
func generate_item(power: int = 1, forced_slot: String = "") -> Dictionary:
var rarity: String = _roll_rarity(power)
var slot: String   = forced_slot if forced_slot != "" else _random_slot()
var base_name: String = SLOT_BASES[slot].pick_random()
var affix_count: int  = RARITY_AFFIX_COUNT[rarity]
var affixes: Array    = _roll_affixes(affix_count, power)
var perks: Array      = []
if rarity in ["epic", "legendary"]:
perks.append(PERKS[randi() % PERKS.size()].duplicate())
if rarity == "legendary":
perks.append(PERKS[randi() % PERKS.size()].duplicate())
var prefix: String = affixes[0]["prefix"] if affixes.size() > 0 else ""
var item_name: String = (prefix + " " + base_name).strip_edges()
return {
"name":    item_name,
"slot":    slot,
"rarity":  rarity,
"affixes": affixes,
"perks":   perks,
"power":   power,
}

func generate_loot_table(power: int, count: int) -> Array:
var result: Array = []
for i in count:
result.append(generate_item(power))
return result

func _roll_rarity(power: int) -> String:
# Higher power increases rare+ chance slightly
var weights: Dictionary = RARITY_WEIGHTS.duplicate()
var boost: int = min(power - 1, 10) * 2
weights["common"] = max(10, weights["common"] - boost)
weights["rare"]   = weights["rare"]  + boost / 2
weights["epic"]   = weights["epic"]  + boost / 4
var total: int = 0
for r in RARITIES:
total += weights[r]
var roll: int = randi() % total
var cumulative: int = 0
for r in RARITIES:
cumulative += weights[r]
if roll < cumulative:
return r
return "common"

func _random_slot() -> String:
return GameState.EQUIPMENT_SLOTS[randi() % GameState.EQUIPMENT_SLOTS.size()]

func _roll_affixes(count: int, power: int) -> Array:
var result: Array = []
var pool: Array   = AFFIXES.duplicate()
pool.shuffle()
for i in min(count, pool.size()):
var template: Dictionary = pool[i]
var scale: float = 1.0 + (power - 1) * 0.15
var val: int = int(randf_range(template["min"], template["max"]) * scale)
result.append({"prefix": template["prefix"], "stat": template["stat"], "value": val})
return result

func item_color(item: Dictionary) -> Color:
return RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)

func item_summary(item: Dictionary) -> String:
var lines: Array[String] = []
lines.append("[" + item.get("rarity","common").to_upper() + "] " + item.get("name","?"))
for a in item.get("affixes", []):
lines.append("  +" + str(a["value"]) + " " + a["stat"])
for p in item.get("perks", []):
lines.append("  ★ " + p["name"] + ": " + p["desc"])
return "\n".join(lines)
