extends Node2D

const DUNGEON_POS:  Vector2 = Vector2(1100, 580)
const NPC_POS:      Vector2 = Vector2(380, 310)
const PLAYER_START: Vector2 = Vector2(400, 400)

var _player: Node = null
var _hud:    Node = null
var _dungeon_entrance: Area2D = null
var _prompt_shown: bool = false

func _ready() -> void:
GameState.current_zone = "overworld"
_build_map()
_spawn_player()
_spawn_npc()
_spawn_dungeon_entrance()
_spawn_hud()

func _build_map() -> void:
# Sky / background
var bg := ColorRect.new()
bg.size  = Vector2(1280, 720)
bg.color = Color(0.35, 0.55, 0.25)
add_child(bg)

# Ground tiles (isometric-flavoured grid)
var tile_container := Node2D.new()
tile_container.name = "Tiles"
add_child(tile_container)

# Draw a checkerboard of grass tiles
var tile_w: int = 64
var tile_h: int = 32
for row in 20:
for col in 24:
var t := ColorRect.new()
t.size     = Vector2(tile_w - 1, tile_h - 1)
t.position = Vector2(col * tile_w, row * tile_h)
if (row + col) % 2 == 0:
t.color = Color(0.32, 0.52, 0.22)
else:
t.color = Color(0.29, 0.48, 0.20)
tile_container.add_child(t)

# Village outlines
_draw_building(tile_container, Vector2(260, 200), Vector2(120, 90), Color(0.55, 0.42, 0.30), "Inn")
_draw_building(tile_container, Vector2(420, 180), Vector2(100, 80), Color(0.52, 0.40, 0.28), "Forge")
_draw_building(tile_container, Vector2(180, 320), Vector2(90, 70),  Color(0.48, 0.38, 0.26), "Store")

# Trees
for i in 30:
var tx: float = randf_range(50, 1200)
var ty: float = randf_range(50, 680)
if Vector2(tx, ty).distance_to(NPC_POS) < 120:
continue
var tree := ColorRect.new()
tree.size     = Vector2(20, 30)
tree.position = Vector2(tx, ty)
tree.color    = Color(0.15, 0.40, 0.12)
tile_container.add_child(tree)

# Path to dungeon (dirt strip)
var path_rect := ColorRect.new()
path_rect.size     = Vector2(480, 24)
path_rect.position = Vector2(620, 562)
path_rect.color    = Color(0.62, 0.50, 0.34)
tile_container.add_child(path_rect)

# Dungeon entrance visual
var de_back := ColorRect.new()
de_back.size     = Vector2(70, 70)
de_back.position = DUNGEON_POS - Vector2(35, 35)
de_back.color    = Color(0.08, 0.05, 0.15)
tile_container.add_child(de_back)

var de_label := Label.new()
de_label.text     = "DUNGEON"
de_label.position = DUNGEON_POS + Vector2(-30, 36)
de_label.add_theme_font_size_override("font_size", 11)
add_child(de_label)

func _draw_building(parent: Node, pos: Vector2, sz: Vector2, color: Color, lbl_text: String) -> void:
var r := ColorRect.new()
r.size     = sz
r.position = pos
r.color    = color
parent.add_child(r)
var lbl := Label.new()
lbl.text     = lbl_text
lbl.position = pos + Vector2(4, 4)
lbl.add_theme_font_size_override("font_size", 9)
parent.add_child(lbl)

func _spawn_player() -> void:
var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")
_player = player_scene.instantiate()
_player.global_position = GameState.player_position
add_child(_player)
_player.died.connect(_on_player_died)

func _spawn_npc() -> void:
var npc_scene: PackedScene = load("res://scenes/entities/NPC.tscn")
var npc: Node = npc_scene.instantiate()
npc.global_position = NPC_POS
add_child(npc)

func _spawn_dungeon_entrance() -> void:
_dungeon_entrance = Area2D.new()
_dungeon_entrance.global_position = DUNGEON_POS
var col  := CollisionShape2D.new()
var circ := CircleShape2D.new()
circ.radius = 45.0
col.shape   = circ
_dungeon_entrance.add_child(col)
_dungeon_entrance.body_entered.connect(_on_entrance_entered)
add_child(_dungeon_entrance)

func _spawn_hud() -> void:
var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
_hud = hud_scene.instantiate()
add_child(_hud)
# Give time for player to load abilities before refreshing labels
await get_tree().process_frame
if _hud.has_method("_refresh_ability_labels"):
_hud._refresh_ability_labels()

func _on_entrance_entered(body: Node) -> void:
if not body.is_in_group("player"):
return
if _prompt_shown:
return
# Check quest accepted
if not GameState.has_quest("enter_the_void"):
_show_hint("Talk to Elder Aric for a quest first!")
return
_prompt_shown = true
_show_dungeon_prompt()

func _show_hint(text: String) -> void:
var lbl := Label.new()
lbl.text     = text
lbl.position = Vector2(400, 340)
lbl.add_theme_font_size_override("font_size", 14)
add_child(lbl)
await get_tree().create_timer(3.0).timeout
if is_instance_valid(lbl): lbl.queue_free()

func _show_dungeon_prompt() -> void:
var panel := Panel.new()
panel.size     = Vector2(300, 100)
panel.position = Vector2(490, 310)
add_child(panel)

var lbl := Label.new()
lbl.text     = "Enter the dungeon?"
lbl.position = Vector2(10, 10)
lbl.add_theme_font_size_override("font_size", 14)
panel.add_child(lbl)

var yes_btn := Button.new()
yes_btn.text     = "Enter"
yes_btn.size     = Vector2(100, 36)
yes_btn.position = Vector2(30, 54)
yes_btn.pressed.connect(_enter_dungeon)
panel.add_child(yes_btn)

var no_btn := Button.new()
no_btn.text     = "Not yet"
no_btn.size     = Vector2(100, 36)
no_btn.position = Vector2(160, 54)
no_btn.pressed.connect(func():
panel.queue_free()
_prompt_shown = false)
panel.add_child(no_btn)

func _enter_dungeon() -> void:
if _player:
GameState.player_position = _player.global_position
SaveLoad.save_game(_player)
get_tree().change_scene_to_file("res://scenes/Dungeon.tscn")

func _on_player_died() -> void:
_show_game_over()

func _show_game_over() -> void:
var panel := Panel.new()
panel.size     = Vector2(320, 140)
panel.position = Vector2(480, 290)
add_child(panel)

var lbl := Label.new()
lbl.text     = "You have fallen."
lbl.position = Vector2(60, 16)
lbl.add_theme_font_size_override("font_size", 18)
panel.add_child(lbl)

var respawn := Button.new()
respawn.text     = "Respawn (full HP)"
respawn.size     = Vector2(200, 40)
respawn.position = Vector2(60, 80)
respawn.pressed.connect(func():
GameState.player_stats["hp"] = GameState.player_stats["max_hp"]
GameState.stats_changed.emit()
panel.queue_free())
panel.add_child(respawn)
