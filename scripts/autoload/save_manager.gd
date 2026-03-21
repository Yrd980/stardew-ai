extends Node

const SaveCodecScript = preload("res://scripts/logic/save_codec.gd")

var save_codec = SaveCodecScript.new()

const SAVE_PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload: Dictionary = build_save_snapshot()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	if parse_result != OK:
		return false
	var payload: Dictionary = save_codec.decode_state(json.data)
	apply_save_snapshot(payload)
	return true


func build_save_snapshot() -> Dictionary:
	return save_codec.encode_state({
		"save_version": GameState.CURRENT_SAVE_VERSION,
		"clock": ClockService.build_save_data(),
		"inventory": InventoryService.build_save_data(),
		"world": WorldState.build_save_data(),
		"economy": EconomyService.build_save_data(),
		"quests": QuestService.build_save_data(),
		"scene_router": {"current_map_id": SceneRouter.current_map_id}
	})


func apply_save_snapshot(payload: Dictionary) -> void:
	ClockService.load_state(payload.get("clock", {}))
	InventoryService.load_state(payload.get("inventory", {}))
	WorldState.load_state(payload.get("world", {}))
	EconomyService.load_state(payload.get("economy", {}))
	NpcService.load_state(payload.get("npcs", {}))
	QuestService.load_state(payload.get("quests", {}))
	SceneRouter.set_current_map(String(payload.get("scene_router", {}).get("current_map_id", "farm")))
