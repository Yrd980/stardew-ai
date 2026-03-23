extends Node


func build_snapshot() -> Dictionary:
	var map_scene = SceneRouter.get_loaded_map()
	var map_id := ActorService.get_player_map_id()
	var player_cell := ActorService.get_player_cell()
	return {
		"runtime": {
			"day": ClockService.day,
			"time_minutes": ClockService.time_minutes,
			"money": EconomyService.money,
			"current_map_id": map_id
		},
		"actor": {
			"actor_id": "player",
			"map_id": map_id,
			"cell": _cell_to_dict(player_cell),
			"world_position": _vector2_to_dict(ActorService.get_player_world_position()),
			"facing": ActorService.get_player_facing(),
			"adjacent_walkability": _build_adjacent_walkability(map_scene, player_cell)
		},
		"inventory": InventoryService.build_save_data(),
		"quests": QuestService.build_save_data(),
		"mail": MailService.build_save_data(),
		"crafting": CraftingService.build_save_data(),
		"economy": {
			"money": EconomyService.money,
			"pending_shipments": EconomyService.pending_shipments.duplicate(true),
			"last_settlement_summary": EconomyService.last_settlement_summary.duplicate(true),
			"lifetime_earnings": EconomyService.lifetime_earnings
		},
		"world": {
			"current_map": _build_current_map_snapshot(map_scene, map_id)
		}
	}


func build_room_directory() -> Dictionary:
	var maps: Array = []
	for map_id_variant in GameState.MAP_SCENES.keys():
		var map_id := String(map_id_variant)
		var scene = load(GameState.MAP_SCENES[map_id]).instantiate()
		maps.append(scene.get_room_directory())
		scene.free()
	return {
		"maps": maps
	}


func _build_current_map_snapshot(map_scene, map_id: String) -> Dictionary:
	var placeables: Array = []
	for key in WorldState.get_placeables(map_id).keys():
		var state: Dictionary = WorldState.get_placeables(map_id)[key]
		placeables.append(state.duplicate(true))
	var containers: Array = []
	for placeable in placeables:
		var object_id := String(placeable.get("object_id", ""))
		if object_id.is_empty():
			continue
		containers.append({
			"object_id": object_id,
			"slots": WorldState.get_container_slots(object_id)
		})
	return {
		"map_id": map_id,
		"soils": WorldState.get_soils(map_id).duplicate(true),
		"crops": WorldState.get_crops(map_id).duplicate(true),
		"placeables": placeables,
		"containers": containers,
		"npc_projections": NpcService.get_npcs_for_map(map_id),
		"static_interactables": map_scene.get_room_directory().get("static_interactables", []) if map_scene != null else []
	}


func _build_adjacent_walkability(map_scene, cell: Vector2i) -> Dictionary:
	var result := {}
	var offsets := {
		"up": Vector2i.UP,
		"down": Vector2i.DOWN,
		"left": Vector2i.LEFT,
		"right": Vector2i.RIGHT
	}
	for direction in offsets.keys():
		var next_cell: Vector2i = cell + offsets[direction]
		result[direction] = map_scene.can_walk_cell(next_cell) if map_scene != null else false
	return result


func _cell_to_dict(cell: Vector2i) -> Dictionary:
	return {"x": cell.x, "y": cell.y}


func _vector2_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
