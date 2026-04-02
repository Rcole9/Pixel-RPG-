extends Area2D

var item: Dictionary = {}
var collected: bool  = false

var _visual: ColorRect = null
var _label:  Label     = null

func _ready() -> void:
	add_to_group("loot")
	_build_visuals()
	# Auto-collect timer as fallback
	var t := get_tree().create_timer(30.0)
	t.timeout.connect(queue_free)

func _build_visuals() -> void:
	_visual = ColorRect.new()
	_visual.size     = Vector2(14, 14)
	_visual.position = Vector2(-7, -7)
	_visual.color    = LootSystem.item_color(item)
	add_child(_visual)

	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 10.0
	col.shape   = circ
	add_child(col)

	_label = Label.new()
	_label.text     = item.get("name", "Loot")
	_label.position = Vector2(-30, -24)
	_label.add_theme_font_size_override("font_size", 8)
	_label.visible  = false
	add_child(_label)

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func _on_hover() -> void:
	if _label: _label.visible = true

func _on_unhover() -> void:
	if _label: _label.visible = false

func collect() -> void:
	if collected: return
	collected = true
	if not item.is_empty():
		GameState.add_item(item)
		queue_free()
