extends Node

const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")
const InventoryLogicScript = preload("res://scripts/logic/inventory_logic.gd")

signal world_changed(map_id: String)

var crop_logic = CropLogicScript.new()
var player_positions := {}
var soils_by_map := {}
var crops_by_map := {}
var placeables_by_map := {}
var containers_by_id := {}
var _next_placeable_id := 1


func reset_world() -> void:
	player_positions = {}
	soils_by_map = {}
	crops_by_map = {}
	placeables_by_map = {}
	containers_by_id = {}
	_next_placeable_id = 1
	world_changed.emit("farm")


func load_state(payload: Dictionary) -> void:
	player_positions = payload.get("player_positions", {}).duplicate(true)
	soils_by_map = payload.get("soils_by_map", {}).duplicate(true)
	crops_by_map = payload.get("crops_by_map", {}).duplicate(true)
	placeables_by_map = payload.get("placeables_by_map", {}).duplicate(true)
	containers_by_id = payload.get("containers_by_id", {}).duplicate(true)
	_next_placeable_id = _derive_next_placeable_id()
	for map_id in soils_by_map.keys():
		world_changed.emit(String(map_id))
	for map_id in crops_by_map.keys():
		world_changed.emit(String(map_id))
	for map_id in placeables_by_map.keys():
		world_changed.emit(String(map_id))


func build_save_data() -> Dictionary:
	return {
		"player_positions": player_positions.duplicate(true),
		"soils_by_map": soils_by_map.duplicate(true),
		"crops_by_map": crops_by_map.duplicate(true),
		"placeables_by_map": placeables_by_map.duplicate(true),
		"containers_by_id": containers_by_id.duplicate(true)
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


func get_placeables(map_id: String) -> Dictionary:
	if not placeables_by_map.has(map_id):
		placeables_by_map[map_id] = {}
	return placeables_by_map[map_id]


func get_placeable(map_id: String, cell: Vector2i) -> Dictionary:
	return get_placeables(map_id).get(_cell_key(cell), {})


func has_placeable(map_id: String, cell: Vector2i) -> bool:
	return not get_placeable(map_id, cell).is_empty()


func find_placeable_by_object_id(object_id: String) -> Dictionary:
	for map_id_variant in placeables_by_map.keys():
		var map_id := String(map_id_variant)
		var placeables: Dictionary = placeables_by_map[map_id]
		for key in placeables.keys():
			var placeable_state: Dictionary = placeables[key]
			if String(placeable_state.get("object_id", "")) != object_id:
				continue
			return {
				"map_id": map_id,
				"cell": placeable_state.get("cell", {}).duplicate(true),
				"state": placeable_state.duplicate(true)
			}
	return {}


func place_object(map_id: String, cell: Vector2i, placeable_id: String) -> Dictionary:
	var placeable_def = GameState.get_placeable_data(placeable_id)
	if placeable_def == null:
		return {}
	var key := _cell_key(cell)
	if get_placeables(map_id).has(key):
		return {}
	var object_id := "placeable_%s" % _next_placeable_id
	_next_placeable_id += 1
	var payload := {
		"object_id": object_id,
		"placeable_id": placeable_id,
		"cell": {"x": cell.x, "y": cell.y}
	}
	get_placeables(map_id)[key] = payload
	if int(placeable_def.storage_slots) > 0:
		containers_by_id[object_id] = {
			"slots": InventoryLogicScript.new().empty_slots(int(placeable_def.storage_slots))
		}
	world_changed.emit(map_id)
	return payload


func get_container_slots(object_id: String) -> Array:
	if not containers_by_id.has(object_id):
		return []
	return containers_by_id[object_id].get("slots", []).duplicate(true)


func set_container_slots(object_id: String, slots: Array) -> void:
	if not containers_by_id.has(object_id):
		containers_by_id[object_id] = {}
	containers_by_id[object_id]["slots"] = slots.duplicate(true)


func apply_fertilizer(map_id: String, cell: Vector2i, tier: int) -> bool:
	var soils := get_soils(map_id)
	var key := _cell_key(cell)
	if not soils.has(key):
		return false
	if get_crops(map_id).has(key):
		return false
	var soil: Dictionary = soils[key]
	if not soil.get("tilled", false):
		return false
	if int(soil.get("fertilizer_tier", 0)) >= tier:
		return false
	soil["fertilizer_tier"] = tier
	soils[key] = soil
	world_changed.emit(map_id)
	return true


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
	var soil: Dictionary = soils[key]
	crops[key] = {
		"crop_id": crop_id,
		"days_watered": 0,
		"fertilizer_tier": int(soil.get("fertilizer_tier", 0))
	}
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


func harvest_crop(map_id: String, cell: Vector2i) -> Dictionary:
	if not can_harvest(map_id, cell):
		return {}
	var key := _cell_key(cell)
	var crop_state: Dictionary = get_crops(map_id)[key]
	var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
	if crop_def != null and int(crop_def.regrow_days) > 0:
		crop_state["days_watered"] = max(0, crop_logic.get_total_growth_days(crop_def) - int(crop_def.regrow_days))
		get_crops(map_id)[key] = crop_state
	else:
		get_crops(map_id).erase(key)
		if get_soils(map_id).has(key):
			var soil: Dictionary = get_soils(map_id)[key]
			soil["fertilizer_tier"] = 0
			get_soils(map_id)[key] = soil
	world_changed.emit(map_id)
	return {
		"item_id": crop_def.harvest_item_id,
		"quality": get_crop_quality(crop_state)
	}


func process_new_day(crop_defs: Dictionary) -> void:
	var result: Dictionary = crop_logic.advance_world(soils_by_map, crops_by_map, crop_defs)
	soils_by_map = result["soils_by_map"]
	crops_by_map = result["crops_by_map"]
	for map_id in soils_by_map.keys():
		world_changed.emit(String(map_id))
	for map_id in crops_by_map.keys():
		world_changed.emit(String(map_id))


func get_crop_quality(crop_state: Dictionary) -> String:
	var tier := int(crop_state.get("fertilizer_tier", 0))
	if tier >= 2:
		return "gold"
	if tier >= 1:
		return "silver"
	return "normal"


func _derive_next_placeable_id() -> int:
	var next_id := 1
	for map_id in placeables_by_map.keys():
		var placeables: Dictionary = placeables_by_map[map_id]
		for key in placeables.keys():
			var object_id := String(placeables[key].get("object_id", ""))
			var suffix := object_id.trim_prefix("placeable_")
			if suffix.is_valid_int():
				next_id = max(next_id, int(suffix) + 1)
	return next_id
