extends Node

const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")

signal world_changed(map_id: String)

var crop_logic = CropLogicScript.new()
var player_positions := {}
var soils_by_map := {}
var crops_by_map := {}


func reset_world() -> void:
	player_positions = {}
	soils_by_map = {}
	crops_by_map = {}
	world_changed.emit("farm")


func load_state(payload: Dictionary) -> void:
	player_positions = payload.get("player_positions", {}).duplicate(true)
	soils_by_map = payload.get("soils_by_map", {}).duplicate(true)
	crops_by_map = payload.get("crops_by_map", {}).duplicate(true)
	for map_id in soils_by_map.keys():
		world_changed.emit(String(map_id))
	for map_id in crops_by_map.keys():
		world_changed.emit(String(map_id))


func build_save_data() -> Dictionary:
	return {
		"player_positions": player_positions.duplicate(true),
		"soils_by_map": soils_by_map.duplicate(true),
		"crops_by_map": crops_by_map.duplicate(true)
	}


func _cell_key(cell: Vector2i) -> String:
	return "%s,%s" % [cell.x, cell.y]


func key_to_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func has_player_position(map_id: String) -> bool:
	return player_positions.has(map_id)


func get_player_position(map_id: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if not player_positions.has(map_id):
		return fallback
	var payload: Dictionary = player_positions[map_id]
	return Vector2(float(payload.get("x", fallback.x)), float(payload.get("y", fallback.y)))


func set_player_position(map_id: String, position: Vector2) -> void:
	player_positions[map_id] = {"x": position.x, "y": position.y}


func get_soils(map_id: String) -> Dictionary:
	if not soils_by_map.has(map_id):
		soils_by_map[map_id] = {}
	return soils_by_map[map_id]


func get_crops(map_id: String) -> Dictionary:
	if not crops_by_map.has(map_id):
		crops_by_map[map_id] = {}
	return crops_by_map[map_id]


func get_soil(map_id: String, cell: Vector2i) -> Dictionary:
	return get_soils(map_id).get(_cell_key(cell), {})


func get_crop(map_id: String, cell: Vector2i) -> Dictionary:
	return get_crops(map_id).get(_cell_key(cell), {})


func till_cell(map_id: String, cell: Vector2i) -> bool:
	var soils := get_soils(map_id)
	var key := _cell_key(cell)
	var soil: Dictionary = soils.get(key, {})
	if soil.get("tilled", false):
		return false
	soil["tilled"] = true
	soil["watered"] = false
	soils[key] = soil
	world_changed.emit(map_id)
	return true


func water_cell(map_id: String, cell: Vector2i) -> bool:
	var soils := get_soils(map_id)
	var key := _cell_key(cell)
	if not soils.has(key):
		return false
	var soil: Dictionary = soils[key]
	if not soil.get("tilled", false) or soil.get("watered", false):
		return false
	soil["watered"] = true
	soils[key] = soil
	world_changed.emit(map_id)
	return true


func plant_crop(map_id: String, cell: Vector2i, crop_id: String) -> bool:
	var soils := get_soils(map_id)
	var crops := get_crops(map_id)
	var key := _cell_key(cell)
	if not soils.has(key):
		return false
	if not soils[key].get("tilled", false):
		return false
	if crops.has(key):
		return false
	crops[key] = {"crop_id": crop_id, "days_watered": 0}
	world_changed.emit(map_id)
	return true


func get_crop_stage(map_id: String, cell: Vector2i, crop_def) -> int:
	var crop_state := get_crop(map_id, cell)
	if crop_state.is_empty():
		return -1
	return crop_logic.get_stage(int(crop_state.get("days_watered", 0)), crop_def)


func can_harvest(map_id: String, cell: Vector2i) -> bool:
	var crop_state := get_crop(map_id, cell)
	if crop_state.is_empty():
		return false
	var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
	if crop_def == null:
		return false
	return crop_logic.is_mature(crop_state, crop_def)


func harvest_crop(map_id: String, cell: Vector2i) -> String:
	if not can_harvest(map_id, cell):
		return ""
	var key := _cell_key(cell)
	var crop_state: Dictionary = get_crops(map_id)[key]
	var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
	get_crops(map_id).erase(key)
	world_changed.emit(map_id)
	return crop_def.harvest_item_id


func process_new_day(crop_defs: Dictionary) -> void:
	var result: Dictionary = crop_logic.advance_world(soils_by_map, crops_by_map, crop_defs)
	soils_by_map = result["soils_by_map"]
	crops_by_map = result["crops_by_map"]
	for map_id in soils_by_map.keys():
		world_changed.emit(String(map_id))
	for map_id in crops_by_map.keys():
		world_changed.emit(String(map_id))
