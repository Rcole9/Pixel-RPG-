extends Node

const SAVE_PATH: String = "user://savegame.json"

func save_game(player_node: Node = null) -> void:
	var data: Dictionary = {
		"player_class":     GameState.player_class,
		"player_stats":     GameState.player_stats,
		"player_inventory": GameState.player_inventory,
		"equipped_items":   GameState.equipped_items,
		"active_quests":    GameState.active_quests,
		"completed_quests": GameState.completed_quests,
		"power_level":      GameState.power_level,
		"current_zone":     GameState.current_zone,
		"dungeon_cleared":  GameState.dungeon_cleared,
		"boss_defeated":    GameState.boss_defeated,
	}
	if player_node != null:
		data["player_pos_x"] = player_node.global_position.x
		data["player_pos_y"] = player_node.global_position.y
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	GameState.player_class     = data.get("player_class", "")
	GameState.player_stats     = data.get("player_stats", {})
	GameState.player_inventory = data.get("player_inventory", [])
	GameState.equipped_items   = data.get("equipped_items", {})
	GameState.active_quests    = data.get("active_quests", [])
	GameState.completed_quests = data.get("completed_quests", [])
	GameState.power_level      = data.get("power_level", 1)
	GameState.current_zone     = data.get("current_zone", "overworld")
	GameState.dungeon_cleared  = data.get("dungeon_cleared", false)
	GameState.boss_defeated    = data.get("boss_defeated", false)
	if data.has("player_pos_x"):
		GameState.player_position = Vector2(data["player_pos_x"], data["player_pos_y"])
	for slot in GameState.EQUIPMENT_SLOTS:
		if not (slot in GameState.equipped_items):
			GameState.equipped_items[slot] = {}
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
