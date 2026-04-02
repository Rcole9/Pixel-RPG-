extends CharacterBody2D

const ATTACK_RANGE:    float = 60.0
const AUTO_ATTACK_CD:  float = 1.2
const INTERACT_RANGE:  float = 80.0
const MOVE_THRESHOLD:  float = 6.0

var target_pos:      Vector2 = Vector2.ZERO
var is_moving:       bool    = false
var attack_target:   Node    = null
var last_mouse_pos:  Vector2 = Vector2.ZERO
var abilities:       Array   = []
var cooldowns:       Array   = [0.0, 0.0, 0.0, 0.0]
var auto_attack_timer: float = 0.0
var status_effects:  Array   = []

var shield_active:   bool  = false
var shield_amount:   int   = 0
var defense_bonus:   int   = 0
var defense_timer:   float = 0.0
var regen_amount:    int   = 0
var death_mark_target: Node  = null
var death_mark_timer:  float = 0.0
var juggernaut_active: bool  = false
var juggernaut_timer:  float = 0.0

signal died
signal auto_attacked(target: Node, dmg: int)
signal ability_used(index: int)

var _visual:      ColorRect   = null
var _class_label: Label       = null
var _hp_bar:      ProgressBar = null

func _ready() -> void:
	add_to_group("player")
	_build_visuals()
	_load_class()
	GameState.stats_changed.connect(_on_stats_changed)

func _build_visuals() -> void:
	_visual = ColorRect.new()
	_visual.size        = Vector2(28, 28)
	_visual.position    = Vector2(-14, -28)
	_visual.color       = Color(0.2, 0.5, 1.0)
	add_child(_visual)

	_class_label = Label.new()
	_class_label.position = Vector2(-20, -50)
	_class_label.add_theme_font_size_override("font_size", 10)
	add_child(_class_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.size     = Vector2(40, 5)
	_hp_bar.position = Vector2(-20, -33)
	_hp_bar.show_percentage = false
	add_child(_hp_bar)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 22)
	col.shape  = rect
	col.position = Vector2(0, -10)
	add_child(col)

func _load_class() -> void:
	match GameState.player_class:
		"Tank":
			abilities = TankClass.ABILITIES.duplicate(true)
			if _visual: _visual.color = Color(0.2, 0.4, 0.9)
			if _class_label: _class_label.text = "T"
			"Healer":
				abilities = HealerClass.ABILITIES.duplicate(true)
				if _visual: _visual.color = Color(0.2, 0.8, 0.3)
				if _class_label: _class_label.text = "H"
				"DPS":
					abilities = DPSClass.ABILITIES.duplicate(true)
					if _visual: _visual.color = Color(0.9, 0.2, 0.2)
					if _class_label: _class_label.text = "D"
					_on_stats_changed()

func _on_stats_changed() -> void:
	if _hp_bar and GameState.player_stats.size() > 0:
		_hp_bar.max_value = GameState.player_stats.get("max_hp", 100)
		_hp_bar.value     = GameState.player_stats.get("hp", 100)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mpos: Vector2 = get_global_mouse_position()
		last_mouse_pos = mpos
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mpos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(mpos)
			for i in 4:
				if Input.is_action_just_pressed("ability_%d" % (i + 1)):
					use_ability(i)
					if Input.is_action_just_pressed("open_inventory"):
						var hud := get_tree().get_first_node_in_group("hud")
						if hud and hud.has_method("toggle_inventory"):
							hud.toggle_inventory()

func _handle_left_click(mpos: Vector2) -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		if mpos.distance_to(npc.global_position) < INTERACT_RANGE:
			if npc.has_method("interact"):
				npc.interact()
				return
				var found_enemy: Node = null
				for enemy in get_tree().get_nodes_in_group("enemy"):
					if mpos.distance_to(enemy.global_position) < 28.0:
						found_enemy = enemy
						break
						if found_enemy:
							attack_target = found_enemy
							target_pos    = found_enemy.global_position
							is_moving     = true
						else:
							attack_target = null
							target_pos    = mpos
							is_moving     = true

func _handle_right_click(mpos: Vector2) -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		if mpos.distance_to(loot.global_position) < 40.0:
			if loot.has_method("collect"):
				loot.collect()
				return

func _physics_process(delta: float) -> void:
	if not GameState.is_player_alive():
		velocity = Vector2.ZERO
		return
		_tick_cooldowns(delta)
		_tick_status_effects(delta)
		_tick_buffs(delta)
		_tick_auto_attack(delta)
		if is_moving:
			var dir: Vector2 = target_pos - global_position
			if dir.length() > MOVE_THRESHOLD:
				var spd: float = float(GameState.player_stats.get("speed", 120))
				if _has_status("slow"):
					spd *= 0.5
					velocity = dir.normalized() * spd
				else:
					velocity  = Vector2.ZERO
					is_moving = false
					if attack_target and is_instance_valid(attack_target):
						_try_auto_attack_now()
					else:
						velocity = Vector2.ZERO
						move_and_slide()
						if attack_target and is_instance_valid(attack_target):
							var dist: float = global_position.distance_to(attack_target.global_position)
							if dist > ATTACK_RANGE * 1.5:
								target_pos = attack_target.global_position
								is_moving  = true
								for loot in get_tree().get_nodes_in_group("loot"):
									if is_instance_valid(loot) and global_position.distance_to(loot.global_position) < 30.0:
										if loot.has_method("collect"):
											loot.collect()

func _tick_cooldowns(delta: float) -> void:
	for i in cooldowns.size():
		if cooldowns[i] > 0:
			cooldowns[i] = max(0.0, cooldowns[i] - delta)

func get_cooldown_fraction(index: int) -> float:
	if index >= abilities.size():
		return 0.0
		var total: float = abilities[index].get("cooldown", 1.0)
		if total <= 0:
			return 0.0
			return cooldowns[index] / total

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
					GameState.damage_player(se.get("value", 5))
				elif se["type"] == "regen":
					se["tick_acc"] = se.get("tick_acc", 0.0) + delta
					if se["tick_acc"] >= 1.0:
						se["tick_acc"] -= 1.0
						GameState.heal_player(se.get("value", 15))
						status_effects = remaining

func apply_status(type: String, duration: float, value: int = 0) -> void:
	for se in status_effects:
		if se["type"] == type:
			se["timer"] = max(se["timer"], duration)
			return
			status_effects.append({"type": type, "timer": duration, "value": value, "tick_acc": 0.0})

func remove_status(type: String) -> void:
	var kept: Array = []
	for se in status_effects:
		if se["type"] != type:
			kept.append(se)
			status_effects = kept

func _has_status(type: String) -> bool:
	for se in status_effects:
		if se["type"] == type:
			return true
			return false

func clear_all_debuffs() -> void:
	var kept: Array = []
	for se in status_effects:
		if se["type"] == "regen":
			kept.append(se)
			status_effects = kept

func _tick_buffs(delta: float) -> void:
	if defense_timer > 0:
		defense_timer -= delta
		if defense_timer <= 0:
			defense_bonus = 0
			if juggernaut_timer > 0:
				juggernaut_timer -= delta
				if juggernaut_timer <= 0:
					juggernaut_active = false
					if death_mark_timer > 0:
						death_mark_timer -= delta
						if death_mark_timer <= 0:
							death_mark_target = null

func _tick_auto_attack(delta: float) -> void:
	if auto_attack_timer > 0:
		auto_attack_timer -= delta

func _try_auto_attack_now() -> void:
	if auto_attack_timer > 0:
		return
		if not (attack_target and is_instance_valid(attack_target)):
			return
			var dist: float = global_position.distance_to(attack_target.global_position)
			if dist > ATTACK_RANGE:
				return
				auto_attack_timer = AUTO_ATTACK_CD
				var dmg: int = GameState.player_stats.get("damage", 10)
				if _has_status("weaken"):
					dmg = int(dmg * 0.7)
					if death_mark_target == attack_target:
						dmg *= 2
						if attack_target.has_method("take_damage"):
							attack_target.take_damage(dmg, self)
							auto_attacked.emit(attack_target, dmg)
							_proc_perks_on_attack()

func _proc_perks_on_attack() -> void:
	for slot in GameState.equipped_items:
		var item: Dictionary = GameState.equipped_items[slot]
		if item.is_empty(): continue
		for perk in item.get("perks", []):
			if perk["trigger"] == "on_attack" and randf() < 0.15:
				match perk["effect"]:
					"burn":
						if attack_target and is_instance_valid(attack_target) and attack_target.has_method("apply_status"):
							attack_target.apply_status("burn", 5.0, 5)
							"slow":
								if attack_target and is_instance_valid(attack_target) and attack_target.has_method("apply_status"):
									attack_target.apply_status("slow", 4.0)
									"weaken":
										if attack_target and is_instance_valid(attack_target) and attack_target.has_method("apply_status"):
											attack_target.apply_status("weaken", 6.0)

func use_ability(index: int) -> void:
	if index >= abilities.size():
		return
		if cooldowns[index] > 0:
			return
			var ability: Dictionary = abilities[index]
			if not GameState.spend_resource(ability.get("cost", 0)):
				return
				cooldowns[index] = ability.get("cooldown", 1.0)
				_execute_ability(ability)
				ability_used.emit(index)

func _execute_ability(ability: Dictionary) -> void:
	match ability["effect"]:
		"shield_wall":
			defense_bonus = int(GameState.player_stats.get("defense", 10) * 0.6)
			defense_timer = ability.get("duration", 6.0)
			"taunt":
				for enemy in get_tree().get_nodes_in_group("enemy"):
					if global_position.distance_to(enemy.global_position) <= ability.get("radius", 200.0):
						if enemy.has_method("set_taunt_target"):
							enemy.set_taunt_target(self, ability.get("duration", 8.0))
							"cleave":
								var dmg: int = int(GameState.player_stats.get("damage", 10) * ability.get("damage_mult", 1.2))
								for enemy in get_tree().get_nodes_in_group("enemy"):
									if global_position.distance_to(enemy.global_position) <= ability.get("radius", 100.0):
										if enemy.has_method("take_damage"):
											enemy.take_damage(dmg, self)
											"juggernaut":
												juggernaut_active = true
												juggernaut_timer  = ability.get("duration", 10.0)
												shield_active     = true
												shield_amount     = 150
												"direct_heal":
													GameState.heal_player(ability.get("amount", 50))
													"regen":
														apply_status("regen", ability.get("duration", 8.0), ability.get("tick_amount", 15))
														"absorb_shield":
															shield_active = true
															shield_amount = ability.get("amount", 80)
															"res_field":
																GameState.heal_player(ability.get("amount", 120))
																clear_all_debuffs()
																"power_strike":
																	if attack_target and is_instance_valid(attack_target):
																		var dmg: int = int(GameState.player_stats.get("damage", 10) * ability.get("damage_mult", 2.0))
																		if attack_target.has_method("take_damage"):
																			attack_target.take_damage(dmg, self)
																			"void_burst":
																				var dmg: int = int(GameState.player_stats.get("damage", 10) * ability.get("damage_mult", 0.8))
																				for enemy in get_tree().get_nodes_in_group("enemy"):
																					if global_position.distance_to(enemy.global_position) <= ability.get("radius", 150.0):
																						if enemy.has_method("take_damage"):
																							enemy.take_damage(dmg, self)
																							"shadow_step":
																								var dir: Vector2 = (last_mouse_pos - global_position).normalized()
																								global_position += dir * ability.get("distance", 200.0)
																								for enemy in get_tree().get_nodes_in_group("enemy"):
																									if global_position.distance_to(enemy.global_position) <= 80.0:
																										if enemy.has_method("apply_status"):
																											enemy.apply_status("slow", 4.0)
																											"death_mark":
																												if attack_target and is_instance_valid(attack_target):
																													death_mark_target = attack_target
																													death_mark_timer  = ability.get("duration", 8.0)

func take_damage(amount: int, _from: Node = null) -> void:
	if shield_active and shield_amount > 0:
		shield_amount -= amount
		if shield_amount <= 0:
			shield_active = false
			shield_amount = 0
			return
			var mitigated: int = max(1, amount - (GameState.player_stats.get("defense", 0) + defense_bonus) / 3)
			if juggernaut_active:
				if _from and is_instance_valid(_from) and _from.has_method("take_damage"):
					_from.take_damage(int(mitigated * 0.3))
					mitigated = int(mitigated * 0.5)
					GameState.damage_player(mitigated)
					_proc_low_hp_perks()
					if not GameState.is_player_alive():
						died.emit()

func _proc_low_hp_perks() -> void:
	var hp_pct: float = float(GameState.player_stats.get("hp", 1)) / float(GameState.player_stats.get("max_hp", 1))
	if hp_pct < 0.3:
		for slot in GameState.equipped_items:
			var item: Dictionary = GameState.equipped_items[slot]
			if item.is_empty(): continue
			for perk in item.get("perks", []):
				if perk["effect"] == "emergency_shield" and not shield_active:
					shield_active = true
					shield_amount = 60

func on_enemy_killed() -> void:
	for slot in GameState.equipped_items:
		var item: Dictionary = GameState.equipped_items[slot]
		if item.is_empty(): continue
		for perk in item.get("perks", []):
			match perk["effect"]:
				"cdr":
					for i in cooldowns.size():
						cooldowns[i] = max(0.0, cooldowns[i] * 0.9)
						"resource_restore":
							GameState.restore_resource(10)
