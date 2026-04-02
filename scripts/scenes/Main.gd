extends Node

func _ready() -> void:
if SaveLoad.has_save():
_show_main_menu()
else:
_go_class_select()

func _show_main_menu() -> void:
var bg := ColorRect.new()
bg.color    = Color(0.05, 0.05, 0.12)
bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
add_child(bg)

var title := Label.new()
title.text     = "RUNES OF THE VOID"
title.position = Vector2(440, 160)
title.add_theme_font_size_override("font_size", 36)
add_child(title)

var subtitle := Label.new()
subtitle.text     = "An isometric pixel RPG"
subtitle.position = Vector2(500, 210)
subtitle.add_theme_font_size_override("font_size", 14)
add_child(subtitle)

var continue_btn := Button.new()
continue_btn.text     = "Continue"
continue_btn.size     = Vector2(200, 50)
continue_btn.position = Vector2(540, 300)
continue_btn.pressed.connect(_on_continue)
add_child(continue_btn)

var new_btn := Button.new()
new_btn.text     = "New Game"
new_btn.size     = Vector2(200, 50)
new_btn.position = Vector2(540, 370)
new_btn.pressed.connect(_on_new_game)
add_child(new_btn)

func _on_continue() -> void:
if SaveLoad.load_game():
get_tree().change_scene_to_file("res://scenes/Overworld.tscn")
else:
_go_class_select()

func _on_new_game() -> void:
SaveLoad.delete_save()
_go_class_select()

func _go_class_select() -> void:
get_tree().change_scene_to_file("res://scenes/ClassSelect.tscn")
