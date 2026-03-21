extends Node

signal message_requested(message: String)
signal shop_requested(shop_id: String, npc_id: String)
signal shop_close_requested


func use_selected_slot(map_id: String, cell: Vector2i, can_farm_cell: bool) -> Dictionary:
	var slot := InventoryService.get_selected_slot()
	var item_id := String(slot.get("item_id", ""))
	if item_id.is_empty():
		return _publish(_result(false, "Select a tool or seeds from the hotbar."))
	var item = GameState.get_item_data(item_id)
	if item == null:
		return _publish(_result(false, "That item is missing data."))
	match String(item.kind):
		"tool":
			return _publish(_use_tool(map_id, cell, can_farm_cell, item_id))
		"seed":
			return _publish(_plant_seed(map_id, cell, can_farm_cell, item_id))
		_:
			return _publish(_result(false, "That item is for inventory or shipping."))


func interact_at_target(map_id: String, target_cell: Vector2i, interactable) -> Dictionary:
	if WorldState.can_harvest(map_id, target_cell):
		var harvest_result := _publish(FarmService.harvest_crop(map_id, target_cell))
		if harvest_result.get("success", false):
			return harvest_result
	if interactable == null:
		return _publish(_result(false, "Nothing to interact with here."))
	if not interactable.has_method("build_action_request"):
		return _publish(_result(false, "That interaction is not ready yet."))
	return run_action_request(interactable.build_action_request())


func run_action_request(request: Dictionary) -> Dictionary:
	var action_type := String(request.get("type", ""))
	var result := {}
	match action_type:
		"map_change":
			result = _result(true, String(request.get("message", "")), 0, [], {
				"map_change": {
					"map_id": String(request.get("destination_map_id", "")),
					"spawn_id": String(request.get("destination_spawn_id", "default"))
				}
			})
		"sleep":
			result = ClockService.sleep_and_advance_day()
		"ship_selected":
			result = EconomyService.queue_selected_stack_for_shipping()
		"npc_interaction":
			result = NpcService.interact_with_npc(String(request.get("npc_id", "")))
		"save_game":
			result = _save_game_result(String(request.get("map_id", "")), request.get("player_position", Vector2.ZERO))
		_:
			result = _result(false, "Unknown action request.")
	return _publish(result)


func purchase_shop_item(shop_id: String, item_id: String, quantity: int = 1, npc_id: String = "") -> Dictionary:
	if not npc_id.is_empty() and not NpcService.is_shop_open(shop_id, npc_id):
		return _publish(_result(false, "The shop is closed right now.", 0, [], {"close_shop": true}))
	return _publish(EconomyService.purchase_item(shop_id, item_id, quantity))


func save_game(map_id: String, player_position: Vector2) -> Dictionary:
	return _publish(_save_game_result(map_id, player_position))


func _save_game_result(map_id: String, player_position: Vector2) -> Dictionary:
	if not map_id.is_empty():
		WorldState.set_player_position(map_id, player_position)
	if SaveManager.save_game():
		return _result(true, "Game saved to user://savegame.json")
	return _result(false, "Could not save the game right now.")


func _use_tool(map_id: String, cell: Vector2i, can_farm_cell: bool, tool_id: String) -> Dictionary:
	if not can_farm_cell:
		return _result(false, "That tile is not part of your field.")
	var tool = GameState.get_tool_data(tool_id)
	if tool == null:
		return _result(false, "That tool is missing data.")
	match String(tool.action_kind):
		"till":
			return FarmService.till_cell(map_id, cell)
		"water":
			return FarmService.water_cell(map_id, cell)
		_:
			return _result(false, "That tool does not have an action yet.")


func _plant_seed(map_id: String, cell: Vector2i, can_farm_cell: bool, item_id: String) -> Dictionary:
	if not can_farm_cell:
		return _result(false, "Seeds only grow in the farm plot.")
	return FarmService.plant_seed(map_id, cell, item_id)


func _publish(result: Dictionary) -> Dictionary:
	var normalized := _normalize_result(result)
	if normalized.get("success", false) and int(normalized.get("time_cost", 0)) > 0:
		ClockService.advance_time(int(normalized.get("time_cost", 0)))
	var directives: Dictionary = normalized.get("directives", {})
	if directives.get("close_shop", false):
		shop_close_requested.emit()
	if directives.has("map_change"):
		var map_change: Dictionary = directives.get("map_change", {})
		SceneRouter.request_map_change(String(map_change.get("map_id", "")), String(map_change.get("spawn_id", "default")))
	if directives.has("open_shop"):
		var open_shop: Dictionary = directives.get("open_shop", {})
		shop_requested.emit(String(open_shop.get("shop_id", "")), String(open_shop.get("npc_id", "")))
	var message := String(normalized.get("message", ""))
	if not message.is_empty():
		message_requested.emit(message)
	return normalized


func _normalize_result(result: Dictionary) -> Dictionary:
	var normalized: Dictionary = result.duplicate(true)
	if not normalized.has("success"):
		normalized["success"] = false
	if not normalized.has("message"):
		normalized["message"] = ""
	if not normalized.has("time_cost"):
		normalized["time_cost"] = 0
	if not normalized.has("events"):
		normalized["events"] = []
	if not normalized.has("directives"):
		normalized["directives"] = {}
	return normalized


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
