extends Node2D

const ROOM_W: int = 1200
const ROOM_H: int = 680

var _player:       Node = null
var _hud:          Node = null
var _boss:         Node = null
var _enemies_left: int  = 0
var _boss_room_open: bool = false
var _aoe_nodes:    Array = []
var _boss_warning_label: Label = null

func _ready() -> void:
	GameState.current_zone = "dungeon"
	_build_map()
	_spawn_player()
	_spawn_enemies()
	_spawn_hud()

func _build_map() -> void:
	# Dark dungeon background
	var bg := ColorRect.new()
	bg.size  = Vector2(ROOM_W, ROOM_H)
	bg.color = Color(0.08, 0.07, 0.12)
	add_child(bg)

	# Floor tiles
	var tiles := Node2D.new()
	add_child(tiles)
	for row in 22:
		for col in 36:
			var t := ColorRect.new()
			t.size     = Vector2(33, 31)
			t.position = Vector2(col * 33, row * 31)
			if (row + col) % 2 == 0:
				t.color = Color(0.16, 0.14, 0.22)
			else:
				t.color = Color(0.13, 0.11, 0.18)
				tiles.add_child(t)

				# Corridor walls (border)
				for side in [
				[Vector2(0,0),      Vector2(ROOM_W, 20)],
				[Vector2(0,ROOM_H-20), Vector2(ROOM_W, 20)],
				[Vector2(0,0),      Vector2(20, ROOM_H)],
				[Vector2(ROOM_W-20,0), Vector2(20, ROOM_H)],
				]:
					var wall := ColorRect.new()
					wall.position = side[0]
					wall.size     = side[1]
					wall.color    = Color(0.3, 0.25, 0.4)
					add_child(wall)

					# Room dividers
					var div1 := ColorRect.new()
					div1.size     = Vector2(20, 300)
					div1.position = Vector2(380, 0)
					div1.color    = Color(0.3, 0.25, 0.4)
					add_child(div1)

					var div2 := ColorRect.new()
					div2.size     = Vector2(20, 300)
					div2.position = Vector2(760, ROOM_H - 300)
					div2.color    = Color(0.3, 0.25, 0.4)
					add_child(div2)

					# Boss room marker (locked at start)
					var boss_door := ColorRect.new()
					boss_door.name     = "BossDoor"
					boss_door.size     = Vector2(60, 60)
					boss_door.position = Vector2(960, 310)
					boss_door.color    = Color(0.5, 0.0, 0.7)
					add_child(boss_door)

					var boss_lbl := Label.new()
					boss_lbl.text     = "BOSS"
					boss_lbl.position = Vector2(965, 318)
					boss_lbl.add_theme_font_size_override("font_size", 11)
					add_child(boss_lbl)

					# Back to overworld portal
					var portal := ColorRect.new()
					portal.name     = "ExitPortal"
					portal.size     = Vector2(50, 50)
					portal.position = Vector2(30, 310)
					portal.color    = Color(0.1, 0.7, 0.9)
					add_child(portal)

					var exit_lbl := Label.new()
					exit_lbl.text     = "Exit"
					exit_lbl.position = Vector2(34, 362)
					exit_lbl.add_theme_font_size_override("font_size", 10)
					add_child(exit_lbl)

					var exit_area := Area2D.new()
					exit_area.position = Vector2(55, 335)
					var ec   := CollisionShape2D.new()
					var ecirc := CircleShape2D.new()
					ecirc.radius = 30.0
					ec.shape     = ecirc
					exit_area.add_child(ec)
					exit_area.body_entered.connect(_on_exit_entered)
					add_child(exit_area)

					# Rune sigils (decorative)
					for i in 4:
						var rune := ColorRect.new()
						rune.size     = Vector2(18, 18)
						rune.position = Vector2(200 + i * 200, 200 + i % 2 * 280)
						rune.color    = Color(0.6, 0.2, 1.0, 0.6)
						add_child(rune)

						# Boss AoE warning label
						_boss_warning_label = Label.new()
						_boss_warning_label.text    = ""
						_boss_warning_label.position = Vector2(440, 140)
						_boss_warning_label.add_theme_font_size_override("font_size", 20)
						_boss_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.0))
						_boss_warning_label.visible = false
						add_child(_boss_warning_label)

func _spawn_player() -> void:
	var ps: PackedScene = load("res://scenes/entities/Player.tscn")
	_player = ps.instantiate()
	_player.global_position = Vector2(100, 340)
	add_child(_player)
	_player.died.connect(_on_player_died)

func _spawn_enemies() -> void:
	var es: PackedScene = load("res://scenes/entities/Enemy.tscn")
	var positions: Array = [
	Vector2(450, 150), Vector2(520, 220), Vector2(600, 180),
	Vector2(470, 420), Vector2(560, 480), Vector2(630, 440),
	Vector2(800, 200), Vector2(870, 160), Vector2(820, 300),
	]
	_enemies_left = positions.size()
	for pos in positions:
		var e: Node = es.instantiate()
		e.global_position = pos
		e.power_lvl = GameState.power_level
		e.max_hp    = 60 + GameState.power_level * 10
		e.damage    = 8  + GameState.power_level * 2
		e.died.connect(_on_enemy_died)
		add_child(e)

func _spawn_boss() -> void:
	var bs: PackedScene = load("res://scenes/entities/Boss.tscn")
	_boss = bs.instantiate()
	_boss.global_position = Vector2(1050, 340)
	_boss.power_lvl       = GameState.power_level
	_boss.aoe_telegraphed.connect(_on_boss_aoe)
	_boss.phase_changed.connect(_on_phase_changed)
	_boss.died.connect(_on_boss_died)
	add_child(_boss)

func _spawn_hud() -> void:
	var hs: PackedScene = load("res://scenes/ui/HUD.tscn")
	_hud = hs.instantiate()
	add_child(_hud)
	await get_tree().process_frame
	if _hud.has_method("_refresh_ability_labels"):
		_hud._refresh_ability_labels()

func _on_enemy_died(_enemy: Node = null) -> void:
	_enemies_left -= 1
	if _enemies_left <= 0 and not _boss_room_open:
		_open_boss_room()

func _open_boss_room() -> void:
	_boss_room_open = true
	var boss_door: Node = get_node_or_null("BossDoor")
	if boss_door:
		boss_door.color = Color(0.0, 0.8, 0.3)
		_show_message("All enemies defeated! The boss chamber opens...")
		await get_tree().create_timer(1.5).timeout
		_spawn_boss()

func _on_boss_aoe(pos: Vector2, radius: float) -> void:
	if _boss_warning_label:
		_boss_warning_label.text    = "⚠ INCOMING AOE – MOVE AWAY! ⚠"
		_boss_warning_label.visible = true
		# Draw a warning circle node
		var warning := _AoeWarning.new()
		warning.warn_pos    = pos
		warning.warn_radius = radius
		warning.duration    = 2.0
		warning.warning_done.connect(func(): warning.queue_free())
		add_child(warning)
		await get_tree().create_timer(2.2).timeout
		if _boss_warning_label:
			_boss_warning_label.visible = false

func _on_phase_changed(phase: int) -> void:
	_show_message("⚠ BOSS ENRAGED – Phase %d!" % phase)

func _on_boss_died() -> void:
	GameState.boss_defeated = true
	GameState.dungeon_cleared = true
	GameState.complete_quest("enter_the_void")
	SaveLoad.save_game(_player)
	_show_victory()

func _show_victory() -> void:
	var panel := Panel.new()
	panel.size     = Vector2(420, 180)
	panel.position = Vector2(430, 270)
	add_child(panel)

	var lbl := Label.new()
	lbl.text     = "Victory! The Void Overlord is defeated!\n\nCollect your loot, then exit the dungeon."
	lbl.position = Vector2(10, 10)
	lbl.size     = Vector2(400, 100)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(lbl)

	var exit_btn := Button.new()
	exit_btn.text     = "Return to Overworld"
	exit_btn.size     = Vector2(200, 40)
	exit_btn.position = Vector2(110, 126)
	exit_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Overworld.tscn"))
		panel.add_child(exit_btn)

func _show_message(text: String) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(360, 50)
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(lbl): lbl.queue_free()

func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/Overworld.tscn")

func _on_player_died() -> void:
	var panel := Panel.new()
	panel.size     = Vector2(320, 140)
	panel.position = Vector2(480, 290)
	add_child(panel)

	var lbl := Label.new()
	lbl.text     = "You have fallen in the dungeon."
	lbl.position = Vector2(20, 16)
	lbl.add_theme_font_size_override("font_size", 14)
	panel.add_child(lbl)

	var btn := Button.new()
	btn.text     = "Retreat to Overworld"
	btn.size     = Vector2(220, 40)
	btn.position = Vector2(50, 80)
	btn.pressed.connect(func():
		GameState.player_stats["hp"] = int(GameState.player_stats["max_hp"] * 0.3)
		GameState.stats_changed.emit()
		get_tree().change_scene_to_file("res://scenes/Overworld.tscn"))
		panel.add_child(btn)


		# Inner class for AoE warning drawing
		class _AoeWarning extends Node2D:
			var warn_pos:    Vector2 = Vector2.ZERO
			var warn_radius: float   = 100.0
			var duration:    float   = 2.0
			var elapsed:     float   = 0.0

signal warning_done

func _process(delta: float) -> void:
	elapsed += delta
	modulate.a = 1.0 - elapsed / duration
	queue_redraw()
	if elapsed >= duration:
		warning_done.emit()

func _draw() -> void:
	var local_pos: Vector2 = warn_pos - global_position
	draw_arc(local_pos, warn_radius, 0, TAU, 48, Color(1.0, 0.3, 0.0, 0.8), 3.0)
	draw_circle(local_pos, warn_radius, Color(1.0, 0.2, 0.0, 0.15))
