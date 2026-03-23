extends Node

const CARDINAL_DIRECTIONS := {
	"up": Vector2i.UP,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
	"right": Vector2i.RIGHT
}


func handle_command(payload: Dictionary) -> Dictionary:
	var actor_id := String(payload.get("actor_id", "player"))
	var command_type := String(payload.get("type", ""))
	var command_id := String(payload.get("command_id", ""))
	if actor_id != "player":
		return _with_metadata(command_id, actor_id, _result(false, "Unknown actor."))
	var args: Dictionary = payload.get("args", {})
	var result := {}
	match command_type:
		"hello":
			result = _result(true, "OpenClaw player runtime ready.", 0, [{"type": "hello"}], {"actor_id": "player"})
		"get_snapshot":
			result = _result(true, "Snapshot ready.", 0, [], {"snapshot": AgentSnapshotService.build_snapshot()})
		"get_room_directory":
			result = _result(true, "Room directory ready.", 0, [], {"room_directory": AgentSnapshotService.build_room_directory()})
		"move":
			result = _move_player(String(args.get("direction", "")), int(args.get("steps", 1)))
		"face":
			result = _face_player(String(args.get("direction", "")))
		"use_tool":
			result = _use_tool(args)
		"plant_seed":
			result = _plant_seed(args)
		"apply_fertilizer":
			result = _apply_fertilizer(args)
		"harvest":
			result = _harvest(args)
		"place_object":
			result = _place_object(args)
		"talk_to":
			result = _talk_to(String(args.get("npc_id", "")))
		"buy_item":
			result = _buy_item(args)
		"ship_inventory_slot":
			result = _ship_inventory_slot(args)
		"sleep":
			result = _sleep()
		"craft_recipe":
			result = _craft_recipe(String(args.get("recipe_id", "")))
		"claim_delivery":
			result = _claim_delivery()
		"container_store":
			result = _container_store(args)
		"container_take":
			result = _container_take(args)
		"save_game":
			result = ActionCoordinator.save_game(ActorService.get_player_map_id(), ActorService.get_player_world_position())
		_:
			result = _result(false, "Unknown command.")
	return _with_metadata(command_id, actor_id, result)


func _move_player(direction: String, steps: int) -> Dictionary:
	var offset: Vector2i = CARDINAL_DIRECTIONS.get(direction, Vector2i.ZERO)
	if offset == Vector2i.ZERO:
		return _result(false, "Unknown direction.")
	var map_scene = SceneRouter.get_loaded_map()
	if map_scene == null:
		return _result(false, "No map loaded.")
	steps = max(1, steps)
	var current_cell := ActorService.get_player_cell()
	var applied_steps := 0
	var transition := {}
	ActorService.set_player_facing(direction)
	for _index in range(steps):
		var next_cell := current_cell + offset
		var door_descriptor: Dictionary = map_scene.find_static_interactable_at_cell(next_cell)
		if String(door_descriptor.get("kind", "")) == "door":
			applied_steps += 1
			transition = door_descriptor
			ActionCoordinator.run_action_request({
				"type": "map_change",
				"destination_map_id": String(door_descriptor.get("destination_map_id", "")),
				"destination_spawn_id": String(door_descriptor.get("destination_spawn_id", "default")),
				"message": "Entering %s." % String(door_descriptor.get("destination_map_id", "")).capitalize()
			})
			break
		if not map_scene.can_walk_cell(next_cell):
			return _result(applied_steps > 0, "Movement blocked.", 0, [], {
				"applied_steps": applied_steps,
				"blocked": true,
				"block_reason": "collision",
				"cell": _cell_dict(current_cell)
			})
		current_cell = next_cell
		applied_steps += 1
		ActorService.set_player_transform(map_scene.map_id, current_cell, map_scene.cell_to_world(current_cell), direction)
	if not transition.is_empty():
		return _result(true, "Moved through %s." % String(transition.get("target_id", "door")), 0, [], {
			"applied_steps": applied_steps,
			"transitioned_to_map_id": String(transition.get("destination_map_id", "")),
			"cell": _cell_dict(ActorService.get_player_cell())
		})
	return _result(true, "Moved %s step(s)." % applied_steps, 0, [], {
		"applied_steps": applied_steps,
		"cell": _cell_dict(current_cell)
	})


func _face_player(direction: String) -> Dictionary:
	if not CARDINAL_DIRECTIONS.has(direction):
		return _result(false, "Unknown direction.")
	ActorService.set_player_facing(direction)
	return _result(true, "Facing %s." % direction)


func _use_tool(args: Dictionary) -> Dictionary:
	var prep := _prepare_target_action(args)
	if not bool(prep.get("success", false)):
		return prep
	return ActionCoordinator.use_tool_at(prep["map_id"], prep["cell"], String(args.get("tool_id", "")), bool(prep.get("can_farm_cell", false)))


func _plant_seed(args: Dictionary) -> Dictionary:
	var prep := _prepare_target_action(args)
	if not bool(prep.get("success", false)):
		return prep
	return ActionCoordinator.plant_seed_at(prep["map_id"], prep["cell"], String(args.get("seed_item_id", "")), bool(prep.get("can_farm_cell", false)))


func _apply_fertilizer(args: Dictionary) -> Dictionary:
	var prep := _prepare_target_action(args)
	if not bool(prep.get("success", false)):
		return prep
	return ActionCoordinator.apply_fertilizer_at(prep["map_id"], prep["cell"], String(args.get("item_id", "")))


func _harvest(args: Dictionary) -> Dictionary:
	var prep := _prepare_target_action(args)
	if not bool(prep.get("success", false)):
		return prep
	return ActionCoordinator.harvest_at(prep["map_id"], prep["cell"])


func _place_object(args: Dictionary) -> Dictionary:
	var prep := _prepare_target_action(args)
	if not bool(prep.get("success", false)):
		return prep
	return ActionCoordinator.place_object_at(prep["map_id"], prep["cell"], String(args.get("item_id", "")))


func _talk_to(npc_id: String) -> Dictionary:
	var npc_state: Dictionary = NpcService.get_npc_state(npc_id)
	if npc_state.is_empty():
		return _result(false, "That NPC is not available.")
	if String(npc_state.get("map_id", "")) != ActorService.get_player_map_id():
		return _result(false, "That NPC is not on this map.")
	var npc_cell := Vector2i(int(npc_state.get("cell", {}).get("x", 0)), int(npc_state.get("cell", {}).get("y", 0)))
	if not _is_adjacent(ActorService.get_player_cell(), npc_cell):
		return _result(false, "Move next to that NPC first.")
	ActorService.set_player_facing(_direction_to(ActorService.get_player_cell(), npc_cell))
	return ActionCoordinator.talk_to_npc(npc_id)


func _buy_item(args: Dictionary) -> Dictionary:
	var shop_id := String(args.get("shop_id", ""))
	var npc_id := _find_shopkeeper_id(shop_id)
	if npc_id.is_empty():
		return _result(false, "That shop is not available.")
	var npc_state: Dictionary = NpcService.get_npc_state(npc_id)
	if npc_state.is_empty():
		return _result(false, "That shopkeeper is not available.")
	if String(npc_state.get("map_id", "")) != ActorService.get_player_map_id():
		return _result(false, "That shopkeeper is not on this map.")
	var npc_cell := Vector2i(int(npc_state.get("cell", {}).get("x", 0)), int(npc_state.get("cell", {}).get("y", 0)))
	if not _is_adjacent(ActorService.get_player_cell(), npc_cell):
		return _result(false, "Move next to the shopkeeper first.")
	ActorService.set_player_facing(_direction_to(ActorService.get_player_cell(), npc_cell))
	return ActionCoordinator.purchase_shop_item(shop_id, String(args.get("item_id", "")), max(1, int(args.get("quantity", 1))), npc_id)


func _ship_inventory_slot(args: Dictionary) -> Dictionary:
	if not _is_adjacent_to_static_target("farm.shipping_bin"):
		return _result(false, "Move next to the shipping bin first.")
	return ActionCoordinator.ship_inventory_slot(int(args.get("slot_index", -1)), int(args.get("amount", 0)))


func _sleep() -> Dictionary:
	if not _is_adjacent_to_static_target("house.bed"):
		return _result(false, "Move next to the bed first.")
	return ActionCoordinator.run_action_request({"type": "sleep"})


func _craft_recipe(recipe_id: String) -> Dictionary:
	if not _is_adjacent_to_static_target("farm.workbench"):
		return _result(false, "Move next to the workbench first.")
	return ActionCoordinator.craft_recipe_by_id(recipe_id)


func _claim_delivery() -> Dictionary:
	if not _is_adjacent_to_static_target("farm.delivery_box"):
		return _result(false, "Move next to the delivery box first.")
	return ActionCoordinator.claim_delivery()


func _container_store(args: Dictionary) -> Dictionary:
	var placeable := _require_container(String(args.get("object_id", "")))
	if not bool(placeable.get("success", false)):
		return placeable
	return ActionCoordinator.container_store(String(args.get("object_id", "")), int(args.get("inventory_slot_index", -1)), int(args.get("amount", 0)))


func _container_take(args: Dictionary) -> Dictionary:
	var placeable := _require_container(String(args.get("object_id", "")))
	if not bool(placeable.get("success", false)):
		return placeable
	return ActionCoordinator.container_take(String(args.get("object_id", "")), int(args.get("container_slot_index", -1)), int(args.get("amount", 0)))


func _prepare_target_action(args: Dictionary) -> Dictionary:
	var map_scene = SceneRouter.get_loaded_map()
	if map_scene == null:
		return _result(false, "No map loaded.")
	var target_cell := _cell_from_value(args.get("target_cell", {}))
	if not _is_adjacent(ActorService.get_player_cell(), target_cell):
		return _result(false, "Target cell must be adjacent to the player.")
	ActorService.set_player_facing(_direction_to(ActorService.get_player_cell(), target_cell))
	return {
		"success": true,
		"map_id": map_scene.map_id,
		"cell": target_cell,
		"can_farm_cell": map_scene.can_farm_cell(target_cell)
	}


func _require_container(object_id: String) -> Dictionary:
	var placeable: Dictionary = WorldState.find_placeable_by_object_id(object_id)
	if placeable.is_empty():
		return _result(false, "That container does not exist.")
	if String(placeable.get("map_id", "")) != ActorService.get_player_map_id():
		return _result(false, "That container is on another map.")
	var cell := _cell_from_value(placeable.get("cell", {}))
	if not _is_adjacent(ActorService.get_player_cell(), cell):
		return _result(false, "Move next to that container first.")
	return {"success": true}


func _is_adjacent_to_static_target(target_id: String) -> bool:
	var map_scene = SceneRouter.get_loaded_map()
	if map_scene == null:
		return false
	var descriptor: Dictionary = map_scene.find_static_interactable_descriptor(target_id)
	if descriptor.is_empty():
		return false
	return _is_adjacent(ActorService.get_player_cell(), _cell_from_value(descriptor.get("cell", {})))


func _find_shopkeeper_id(shop_id: String) -> String:
	for npc_id_variant in GameState.npc_defs.keys():
		var npc_id := String(npc_id_variant)
		var npc = GameState.get_npc_data(npc_id)
		if npc != null and String(npc.shop_id) == shop_id:
			return npc_id
	return ""


func _direction_to(origin: Vector2i, target: Vector2i) -> String:
	var delta := target - origin
	if delta == Vector2i.UP:
		return "up"
	if delta == Vector2i.DOWN:
		return "down"
	if delta == Vector2i.LEFT:
		return "left"
	return "right"


func _is_adjacent(origin: Vector2i, target: Vector2i) -> bool:
	return abs(origin.x - target.x) + abs(origin.y - target.y) == 1


func _cell_from_value(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO


func _cell_dict(cell: Vector2i) -> Dictionary:
	return {"x": cell.x, "y": cell.y}


func _with_metadata(command_id: String, actor_id: String, result: Dictionary) -> Dictionary:
	var enriched: Dictionary = result.duplicate(true)
	enriched["command_id"] = command_id
	enriched["actor_id"] = actor_id
	return enriched


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
