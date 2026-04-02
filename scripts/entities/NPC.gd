extends StaticBody2D

@export var npc_name:   String = "Elder Aric"
@export var quest_id:   String = "enter_the_void"
@export var quest_text: String = "The dungeon stirs with Void energy.\nDefeat the Overlord and restore the Runes!\n\nEnter the dungeon to the south-east."

var dialogue_open: bool = false
var _visual:    ColorRect = null
var _name_lbl:  Label     = null
var _dialogue:  Panel     = null
var _dlg_label: Label     = null
var _btn:       Button    = null

func _ready() -> void:
add_to_group("npc")
_build_visuals()

func _build_visuals() -> void:
_visual       = ColorRect.new()
_visual.size  = Vector2(26, 26)
_visual.position = Vector2(-13, -26)
_visual.color = Color(1.0, 0.85, 0.2)
add_child(_visual)

_name_lbl          = Label.new()
_name_lbl.text     = npc_name
_name_lbl.position = Vector2(-24, -42)
_name_lbl.add_theme_font_size_override("font_size", 9)
add_child(_name_lbl)

var col  := CollisionShape2D.new()
var rect := RectangleShape2D.new()
rect.size = Vector2(22, 22)
col.shape  = rect
col.position = Vector2(0, -10)
add_child(col)

# Dialogue panel (hidden by default, in screen-space via CanvasLayer)
var cl: CanvasLayer = CanvasLayer.new()
cl.layer = 10
add_child(cl)

_dialogue = Panel.new()
_dialogue.size     = Vector2(340, 160)
_dialogue.position = Vector2(470, 250)
_dialogue.visible  = false
cl.add_child(_dialogue)

_dlg_label = Label.new()
_dlg_label.size     = Vector2(320, 100)
_dlg_label.position = Vector2(10, 10)
_dlg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
_dialogue.add_child(_dlg_label)

_btn = Button.new()
_btn.text     = "Accept Quest"
_btn.size     = Vector2(140, 36)
_btn.position = Vector2(100, 114)
_btn.pressed.connect(_on_accept)
_dialogue.add_child(_btn)

func interact() -> void:
dialogue_open = not dialogue_open
_dialogue.visible = dialogue_open
if dialogue_open:
if GameState.has_quest(quest_id):
_dlg_label.text = "Safe travels, champion.\nThe Void awaits."
_btn.visible    = false
else:
_dlg_label.text = quest_text
_btn.visible    = true
_btn.text       = "Accept Quest"

func _on_accept() -> void:
GameState.accept_quest(quest_id)
_dlg_label.text = "Good luck, champion.\nThe Runes of the Void depend on you!"
_btn.visible    = false
await get_tree().create_timer(2.0).timeout
_dialogue.visible = false
dialogue_open     = false
