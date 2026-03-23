extends Node

signal crop_harvested(event: Dictionary)

const FARM_BLOCKED_PLACEABLE_CELLS := [
	Vector2i(4, 7),
	Vector2i(7, 8),
	Vector2i(13, 8),
	Vector2i(15, 8),
	Vector2i(22, 9)
]


func till_cell(map_id: String, cell: Vector2i) -> Dictionary:
	if not WorldState.till_cell(map_id, cell):
		return _result(false, "That soil is already prepared.")
	var result := _result(true, "Soil tilled.", 5, [{"type": "soil_tilled", "map_id": map_id, "cell": cell}])
	return result


func water_cell(map_id: String, cell: Vector2i) -> Dictionary:
	if not WorldState.water_cell(map_id, cell):
		return _result(false, "There is nothing new to water there.")
	var result := _result(true, "Soil watered for the day.", 5, [{"type": "soil_watered", "map_id": map_id, "cell": cell}])
	return result


func plant_seed(map_id: String, cell: Vector2i, item_id: String) -> Dictionary:
	var item = GameState.get_item_data(item_id)
	if item == null:
		return _result(false, "Those seeds are missing data.")
	if InventoryService.get_total_item_count(item_id) <= 0:
		return _result(false, "You do not have those seeds right now.")
	if not WorldState.plant_crop(map_id, cell, item.crop_id):
		return _result(false, "You need empty tilled soil for that.")
	InventoryService.consume_item(item_id, 1)
	var result := _result(true, "Planted %s." % item.display_name, 5, [{
		"type": "crop_planted",
		"map_id": map_id,
		"cell": cell,
		"item_id": item_id,
		"crop_id": item.crop_id
	}])
	return result


func apply_fertilizer(map_id: String, cell: Vector2i, item_id: String) -> Dictionary:
	var item = GameState.get_item_data(item_id)
	if item == null or int(item.fertilizer_tier) <= 0:
		return _result(false, "That is not fertilizer.")
	if InventoryService.get_total_item_count(item_id) <= 0:
		return _result(false, "You do not have that fertilizer right now.")
	if not WorldState.apply_fertilizer(map_id, cell, int(item.fertilizer_tier)):
		return _result(false, "Fertilizer only works on empty tilled soil.")
	InventoryService.consume_item(item_id, 1)
	return _result(true, "Worked %s into the soil." % item.display_name, 5, [{
		"type": "fertilizer_applied",
		"map_id": map_id,
		"cell": cell,
		"item_id": item_id,
		"tier": int(item.fertilizer_tier)
	}])


func place_selected_object(map_id: String, cell: Vector2i, item_id: String) -> Dictionary:
	var item = GameState.get_item_data(item_id)
	if item == null or String(item.placeable_id).is_empty():
		return _result(false, "That item cannot be placed.")
	if InventoryService.get_total_item_count(item_id) <= 0:
		return _result(false, "You do not have that placeable right now.")
	if map_id != "farm":
		return _result(false, "Farm equipment can only be placed on the farm.")
	if FARM_BLOCKED_PLACEABLE_CELLS.has(cell):
		return _result(false, "Keep that tile clear for farm access.")
	if WorldState.has_placeable(map_id, cell):
		return _result(false, "That tile is already occupied.")
	if not WorldState.get_crop(map_id, cell).is_empty():
		return _result(false, "Clear the crop before placing anything there.")
	var placed: Dictionary = WorldState.place_object(map_id, cell, String(item.placeable_id))
	if placed.is_empty():
		return _result(false, "That tile cannot accept a placeable right now.")
	InventoryService.consume_item(item_id, 1)
	var placeable = GameState.get_placeable_data(String(item.placeable_id))
	return _result(true, "Placed %s." % (placeable.display_name if placeable else item.display_name), 5, [{
		"type": "placeable_placed",
		"map_id": map_id,
		"cell": cell,
		"placeable_id": String(item.placeable_id),
		"object_id": String(placed.get("object_id", ""))
	}])


func harvest_crop(map_id: String, cell: Vector2i) -> Dictionary:
	if not WorldState.can_harvest(map_id, cell):
		return _result(false, "Nothing is ready to harvest there.")
	var harvest_preview := _peek_harvest_item(map_id, cell)
	var harvest_item_id := String(harvest_preview.get("item_id", ""))
	var harvest_quality := String(harvest_preview.get("quality", "normal"))
	if harvest_item_id.is_empty():
		return _result(false, "That crop is missing harvest data.")
	if not InventoryService.can_add_item_with_quality(harvest_item_id, 1, harvest_quality):
		return _result(false, "Inventory full. Make room before harvesting.")
	var harvested_payload: Dictionary = WorldState.harvest_crop(map_id, cell)
	var harvested_item_id := String(harvested_payload.get("item_id", ""))
	var harvested_quality := String(harvested_payload.get("quality", "normal"))
	if harvested_item_id.is_empty():
		return _result(false, "Harvest failed.")
	InventoryService.add_item(harvested_item_id, 1, harvested_quality)
	var item = GameState.get_item_data(harvested_item_id)
	var event := {
		"type": "crop_harvested",
		"map_id": map_id,
		"cell": cell,
		"item_id": harvested_item_id,
		"quality": harvested_quality
	}
	crop_harvested.emit(event)
	var quality_label := "" if harvested_quality == "normal" else "%s " % harvested_quality.capitalize()
	var result := _result(true, "Harvested %s%s." % [quality_label, item.display_name if item else harvested_item_id], 5, [event])
	return result


func _peek_harvest_item(map_id: String, cell: Vector2i) -> Dictionary:
	var crop_state: Dictionary = WorldState.get_crop(map_id, cell)
	if crop_state.is_empty():
		return {}
	var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
	if crop_def == null:
		return {}
	return {
		"item_id": String(crop_def.harvest_item_id),
		"quality": WorldState.get_crop_quality(crop_state)
	}


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
