extends Node2D

func _ready() -> void:
_build_ui()

func _build_ui() -> void:
var bg := ColorRect.new()
bg.color    = Color(0.05, 0.05, 0.12)
bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
add_child(bg)

var title := Label.new()
title.text     = "RUNES OF THE VOID"
title.position = Vector2(400, 60)
title.add_theme_font_size_override("font_size", 38)
title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
add_child(title)

var sub := Label.new()
sub.text     = "Choose your class"
sub.position = Vector2(530, 116)
sub.add_theme_font_size_override("font_size", 16)
add_child(sub)

var classes_info: Dictionary = {
"Tank": {
"color": Color(0.2, 0.4, 1.0),
"desc": "The stalwart guardian.\n\nAbilities:\n• Shield Wall – Boost defense 60% for 6s\n• Taunt – Force enemies to attack you\n• Cleave – AoE melee strike\n• Juggernaut – Massive barrier + reflect\n\nHigh HP | Low Damage",
},
"Healer": {
"color": Color(0.2, 0.9, 0.4),
"desc": "The sacred mender.\n\nAbilities:\n• Mend – Instant heal 50 HP\n• Regenerate – HoT 15 HP/s for 8s\n• Holy Shield – Absorb 80 damage\n• Resurrection Field – Heal 120 + cleanse\n\nMedium HP | Support",
},
"DPS": {
"color": Color(1.0, 0.2, 0.2),
"desc": "The ruthless striker.\n\nAbilities:\n• Power Strike – 2× damage burst\n• Void Burst – AoE explosion 150 px\n• Shadow Step – Teleport + Slow nearby\n• Death Mark – Double damage for 8s\n\nLow HP | High Damage",
},
}

var x_positions: Array = [100, 440, 780]
var i: int = 0
for cls in ["Tank", "Healer", "DPS"]:
var info: Dictionary = classes_info[cls]
var panel := Panel.new()
panel.size     = Vector2(300, 420)
panel.position = Vector2(x_positions[i], 160)
add_child(panel)

var icon := ColorRect.new()
icon.size     = Vector2(60, 60)
icon.position = Vector2(120, 20)
icon.color    = info["color"]
panel.add_child(icon)

var name_lbl := Label.new()
name_lbl.text     = cls.to_upper()
name_lbl.position = Vector2(90, 88)
name_lbl.add_theme_font_size_override("font_size", 22)
panel.add_child(name_lbl)

var desc_lbl := Label.new()
desc_lbl.text     = info["desc"]
desc_lbl.position = Vector2(10, 120)
desc_lbl.size     = Vector2(280, 240)
desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
desc_lbl.add_theme_font_size_override("font_size", 11)
panel.add_child(desc_lbl)

var btn := Button.new()
btn.text     = "Play as " + cls
btn.size     = Vector2(200, 44)
btn.position = Vector2(50, 368)
var cls_copy: String = cls
btn.pressed.connect(_on_class_selected.bind(cls_copy))
panel.add_child(btn)

i += 1

var ctrl_lbl := Label.new()
ctrl_lbl.text     = "Controls: Left-click to move/attack  •  1-4 Abilities  •  I Inventory  •  Right-click pick up loot  •  F5 Save"
ctrl_lbl.position = Vector2(80, 618)
ctrl_lbl.add_theme_font_size_override("font_size", 11)
add_child(ctrl_lbl)

func _on_class_selected(cls: String) -> void:
GameState.initialize_player(cls)
get_tree().change_scene_to_file("res://scenes/Overworld.tscn")
