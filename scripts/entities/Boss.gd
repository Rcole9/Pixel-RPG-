extends CharacterBody2D

enum State { IDLE, PHASE1, PHASE2, DEAD }

const PHASE2_THRESHOLD: float = 0.5

@export var boss_name:    String = "The Void Overlord"
@export var max_hp:       int    = 600
@export var damage_p1:    int    = 20
@export var damage_p2:    int    = 35
@export var speed_p1:     float  = 60.0
@export var speed_p2:     float  = 100.0
@export var attack_range: float  = 70.0
@export var attack_cd_p1: float  = 2.0
@export var attack_cd_p2: float  = 1.2
@export var loot_count:   int    = 4
@export var power_lvl:    int    = 5

var hp:           int   = 0
var state:        State = State.IDLE
var target:       Node  = null
var attack_timer: float = 0.0
var phase2_entered: bool = false
var aoe_warning_timer: float = 0.0
var aoe_warning_active: bool = false
var aoe_warning_pos:   Vector2 = Vector2.ZERO
var add_spawn_timer:   float   = 12.0
var status_effects: Array = []

signal died
signal phase_changed(phase: int)
signal aoe_telegraphed(pos: Vector2, radius: float)

var _visual:  ColorRect   = null
var _hp_bar:  ProgressBar = null
var _name_lbl: Label      = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	hp = max_hp
	_build_visuals()

func _build_visuals() -> void:
	_visual = ColorRect.new()
	_visual.size     = Vector2(48, 48)
	_visual.position = Vector2(-24, -48)
	_visual.color    = Color(0.4, 0.0, 0.6)
	add_child(_visual)

	_hp_bar = ProgressBar.new()
	_hp_bar.size        = Vector2(80, 8)
	_hp_bar.position    = Vector2(-40, -58)
	_hp_bar.max_value   = max_hp
	_hp_bar.value       = max_hp
	_hp_bar.show_percentage = false
	add_child(_hp_bar)

	_name_lbl = Label.new()
	_name_lbl.text     = boss_name
	_name_lbl.position = Vector2(-50, -72)
	_name_lbl.add_theme_font_size_override("font_size", 11)
	add_child(_name_lbl)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	col.shape  = rect
	col.position = Vector2(0, -20)
	add_child(col)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
		_tick_status_effects(delta)
		_tick_timers(delta)
		_find_target()
		match state:
			State.IDLE:
				if target: state = State.PHASE1
				State.PHASE1: _do_phase1(delta)
				State.PHASE2: _do_phase2(delta)
				move_and_slide()

func _tick_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		if aoe_warning_active:
			aoe_warning_timer -= delta
			if aoe_warning_timer <= 0:
				aoe_warning_active = false
				_execute_aoe(aoe_warning_pos)
				if state == State.PHASE2 and add_spawn_timer > 0:
					add_spawn_timer -= delta
					if add_spawn_timer <= 0:
						add_spawn_timer = 14.0
						_spawn_adds()

func _find_target() -> void:
	if target and is_instance_valid(target):
		return
		for p in get_tree().get_nodes_in_group("player"):
			target = p
			return

func _do_phase1(delta: float) -> void:
	if not (target and is_instance_valid(target)):
		return
		_check_phase2_transition()
		var dist: float = global_position.distance_to(target.global_position)
		var spd: float = speed_p1
		if _has_status("slow"): spd *= 0.5
		if dist > attack_range:
			velocity = (target.global_position - global_position).normalized() * spd
		else:
			velocity = Vector2.ZERO
			if attack_timer <= 0:
				attack_timer = attack_cd_p1
				_perform_attack()

func _do_phase2(delta: float) -> void:
	if not (target and is_instance_valid(target)):
		return
		var dist: float = global_position.distance_to(target.global_position)
		var spd: float = speed_p2
		if _has_status("slow"): spd *= 0.5
		if dist > attack_range:
			velocity = (target.global_position - global_position).normalized() * spd
		else:
			velocity = Vector2.ZERO
			if attack_timer <= 0:
				attack_timer = attack_cd_p2
				_perform_attack()
				# Occasionally telegraph AoE
				if not aoe_warning_active and randf() < 0.3:
					_telegraph_aoe()

func _check_phase2_transition() -> void:
	if not phase2_entered and float(hp) / float(max_hp) <= PHASE2_THRESHOLD:
		phase2_entered = true
		state          = State.PHASE2
		if _visual: _visual.color = Color(0.7, 0.0, 0.9)
		phase_changed.emit(2)
		_spawn_adds()

func _perform_attack() -> void:
	if not (target and is_instance_valid(target)):
		return
		var dmg: int = damage_p2 if state == State.PHASE2 else damage_p1
		if _has_status("weaken"): dmg = int(dmg * 0.7)
		if target.has_method("take_damage"):
			target.take_damage(dmg, self)

func _telegraph_aoe() -> void:
	if not (target and is_instance_valid(target)):
		return
		aoe_warning_pos    = target.global_position
		aoe_warning_active = true
		aoe_warning_timer  = 2.0
		aoe_telegraphed.emit(aoe_warning_pos, 100.0)

func _execute_aoe(pos: Vector2) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if pos.distance_to(p.global_position) <= 100.0:
			if p.has_method("take_damage"):
				p.take_damage(40, self)

func _spawn_adds() -> void:
	var enemy_scene: PackedScene = load("res://scenes/entities/Enemy.tscn")
	if enemy_scene == null:
		return
		for i in 3:
			var add: Node = enemy_scene.instantiate()
			add.global_position = global_position + Vector2(randf_range(-120,120), randf_range(-120,120))
			if add.has_method("set") :
				add.max_hp    = 40
				add.damage    = 10
				add.power_lvl = power_lvl
				get_parent().add_child(add)

func take_damage(amount: int, _from: Node = null) -> void:
	if state == State.DEAD:
		return
		hp = max(0, hp - max(1, amount))
		if _hp_bar: _hp_bar.value = hp
		if hp <= 0:
			_die()
		elif not phase2_entered:
			_check_phase2_transition()

func apply_status(type: String, duration: float, value: int = 0) -> void:
	for se in status_effects:
		if se["type"] == type:
			se["timer"] = max(se["timer"], duration)
			return
			status_effects.append({"type": type, "timer": duration, "value": value, "tick_acc": 0.0})

func _has_status(type: String) -> bool:
	for se in status_effects:
		if se["type"] == type: return true
		return false

func _tick_status_effects(delta: float) -> void:
	var remaining: Array = []
	for se in status_effects:
		se["timer"] -= delta
		if se["timer"] > 0:
			remaining.append(se)
			if se["type"] == "burn":
				se["tick_acc"] = se.get("tick_acc", 0.0) + delta
				if se["tick_acc"] >= 1.0:
					se["tick_acc"] -= 1.0
					take_damage(se.get("value", 5))
					status_effects = remaining

func set_taunt_target(t: Node, duration: float) -> void:
	target = t

func _die() -> void:
	state    = State.DEAD
	velocity = Vector2.ZERO
	_spawn_boss_loot()
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("on_enemy_killed"):
			p.on_enemy_killed()
			died.emit()
			queue_free()

func _spawn_boss_loot() -> void:
	var loot_scene: PackedScene = load("res://scenes/entities/LootDrop.tscn")
	if loot_scene == null:
		return
		for i in loot_count:
			var loot: Node = loot_scene.instantiate()
			loot.global_position = global_position + Vector2(randf_range(-40,40), randf_range(-40,40))
			loot.item = LootSystem.generate_item(power_lvl)
			get_parent().add_child(loot)
