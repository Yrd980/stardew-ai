extends Node

signal crop_harvested(event: Dictionary)


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
	if not WorldState.plant_crop(map_id, cell, item.crop_id):
		return _result(false, "You need empty tilled soil for that.")
	InventoryService.consume_selected_item(1)
	var result := _result(true, "Planted %s." % item.display_name, 5, [{
		"type": "crop_planted",
		"map_id": map_id,
		"cell": cell,
		"item_id": item_id,
		"crop_id": item.crop_id
	}])
	return result


func harvest_crop(map_id: String, cell: Vector2i) -> Dictionary:
	if not WorldState.can_harvest(map_id, cell):
		return _result(false, "Nothing is ready to harvest there.")
	var harvest_item_id := _peek_harvest_item(map_id, cell)
	if harvest_item_id.is_empty():
		return _result(false, "That crop is missing harvest data.")
	if not InventoryService.can_add_item(harvest_item_id, 1):
		return _result(false, "Inventory full. Make room before harvesting.")
	var harvested_item_id := WorldState.harvest_crop(map_id, cell)
	if harvested_item_id.is_empty():
		return _result(false, "Harvest failed.")
	InventoryService.add_item(harvested_item_id, 1)
	var item = GameState.get_item_data(harvested_item_id)
	var event := {
		"type": "crop_harvested",
		"map_id": map_id,
		"cell": cell,
		"item_id": harvested_item_id
	}
	crop_harvested.emit(event)
	var result := _result(true, "Harvested %s." % (item.display_name if item else harvested_item_id), 5, [event])
	return result


func _peek_harvest_item(map_id: String, cell: Vector2i) -> String:
	var crop_state := WorldState.get_crop(map_id, cell)
	if crop_state.is_empty():
		return ""
	var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
	if crop_def == null:
		return ""
	return String(crop_def.harvest_item_id)


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
