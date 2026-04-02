extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }

@export var enemy_name: String    = "Void Grunt"
@export var max_hp:     int       = 60
@export var damage:     int       = 8
@export var speed:      float     = 80.0
@export var aggro_range: float    = 200.0
@export var attack_range: float   = 55.0
@export var attack_cd:  float     = 1.5
@export var loot_count: int       = 1
@export var power_lvl:  int       = 1

var hp:           int   = 0
var state:        State = State.IDLE
var target:       Node  = null
var taunt_target: Node  = null
var taunt_timer:  float = 0.0
var attack_timer: float = 0.0
var patrol_timer: float = 0.0
var patrol_dir:   Vector2 = Vector2.ZERO
var status_effects: Array = []
var origin_pos: Vector2 = Vector2.ZERO

signal died(enemy: Node)

var _visual:  ColorRect   = null
var _hp_bar:  ProgressBar = null
var _name_lbl: Label      = null

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	origin_pos = global_position
	_build_visuals()
	patrol_dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	patrol_timer = randf_range(1.0, 3.0)

func _build_visuals() -> void:
	_visual = ColorRect.new()
	_visual.size     = Vector2(26, 26)
	_visual.position = Vector2(-13, -26)
	_visual.color    = Color(0.8, 0.2, 0.2)
	add_child(_visual)

	_hp_bar = ProgressBar.new()
	_hp_bar.size     = Vector2(36, 4)
	_hp_bar.position = Vector2(-18, -30)
	_hp_bar.max_value = max_hp
	_hp_bar.value     = max_hp
	_hp_bar.show_percentage = false
	add_child(_hp_bar)

	_name_lbl = Label.new()
	_name_lbl.text     = enemy_name
	_name_lbl.position = Vector2(-24, -42)
	_name_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_name_lbl)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 22)
	col.shape  = rect
	col.position = Vector2(0, -10)
	add_child(col)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
		_tick_status_effects(delta)
		_tick_timers(delta)
		match state:
			State.IDLE:    _do_idle(delta)
			State.PATROL:  _do_patrol(delta)
			State.CHASE:   _do_chase(delta)
			State.ATTACK:  _do_attack(delta)
			_check_aggro()
			move_and_slide()

func _tick_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		if taunt_timer > 0:
			taunt_timer -= delta
			if taunt_timer <= 0:
				taunt_target = null
				if patrol_timer > 0:
					patrol_timer -= delta

func _do_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if patrol_timer <= 0:
		patrol_dir   = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		patrol_timer = randf_range(2.0, 4.0)
		state        = State.PATROL

func _do_patrol(delta: float) -> void:
	if patrol_timer <= 0:
		state = State.IDLE
		velocity = Vector2.ZERO
		return
		velocity = patrol_dir * speed * 0.4
		if global_position.distance_to(origin_pos) > 150.0:
			patrol_dir = (origin_pos - global_position).normalized()

func _do_chase(delta: float) -> void:
	var t: Node = _get_target()
	if t == null:
		state = State.PATROL
		return
		var dist: float = global_position.distance_to(t.global_position)
		if dist <= attack_range:
			velocity = Vector2.ZERO
			state    = State.ATTACK
		elif dist > aggro_range * 1.5:
			target = null
			state  = State.PATROL
		else:
			var spd: float = speed
			if _has_status("slow"): spd *= 0.5
			velocity = (t.global_position - global_position).normalized() * spd

func _do_attack(delta: float) -> void:
	var t: Node = _get_target()
	if t == null:
		state = State.PATROL
		return
		var dist: float = global_position.distance_to(t.global_position)
		if dist > attack_range:
			state = State.CHASE
			return
			velocity = Vector2.ZERO
			if attack_timer <= 0:
				attack_timer = attack_cd
				_perform_attack(t)

func _check_aggro() -> void:
	if state in [State.CHASE, State.ATTACK]:
		return
		for p in get_tree().get_nodes_in_group("player"):
			if global_position.distance_to(p.global_position) <= aggro_range:
				target = p
				state  = State.CHASE
				break

func _get_target() -> Node:
	if taunt_target and is_instance_valid(taunt_target):
		return taunt_target
		if target and is_instance_valid(target):
			return target
			for p in get_tree().get_nodes_in_group("player"):
				return p
				return null

func _perform_attack(t: Node) -> void:
	var dmg: int = damage
	if _has_status("weaken"):
		dmg = int(dmg * 0.7)
		if t.has_method("take_damage"):
			t.take_damage(dmg, self)

func take_damage(amount: int, from_node: Node = null) -> void:
	if state == State.DEAD:
		return
		if from_node and state == State.IDLE:
			target = from_node
			state  = State.CHASE
			var mitigated: int = max(1, amount)
			hp = max(0, hp - mitigated)
			if _hp_bar:
				_hp_bar.value = hp
				if hp <= 0:
					_die()

func apply_status(type: String, duration: float, value: int = 0) -> void:
	for se in status_effects:
		if se["type"] == type:
			se["timer"] = max(se["timer"], duration)
			return
			status_effects.append({"type": type, "timer": duration, "value": value, "tick_acc": 0.0})

func _has_status(type: String) -> bool:
	for se in status_effects:
		if se["type"] == type:
			return true
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
					if _visual:
						if _has_status("burn"):  _visual.color = Color(1.0, 0.5, 0.1)
					elif _has_status("slow"): _visual.color = Color(0.4, 0.4, 0.9)
				else:                     _visual.color = Color(0.8, 0.2, 0.2)

func set_taunt_target(t: Node, duration: float) -> void:
	taunt_target = t
	taunt_timer  = duration
	target       = t
	state        = State.CHASE

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	# Drop loot
	_spawn_loot()
	# Notify player perk procs
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("on_enemy_killed"):
			p.on_enemy_killed()
			died.emit(self)
			queue_free()

func _spawn_loot() -> void:
	var loot_scene: PackedScene = load("res://scenes/entities/LootDrop.tscn")
	if loot_scene == null:
		return
		var count: int = loot_count
		for i in count:
			var loot: Node = loot_scene.instantiate()
			loot.global_position = global_position + Vector2(randf_range(-20,20), randf_range(-20,20))
			loot.item = LootSystem.generate_item(power_lvl)
			get_parent().add_child(loot)
