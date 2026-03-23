extends Node

signal actor_changed(actor_id: String)

const DEFAULT_PLAYER_STATE := {
	"map_id": "farm",
	"cell": {"x": 4, "y": 6},
	"world_position": {"x": 160.0, "y": 208.0},
	"facing": "down"
}

var actors := {}


func reset_state() -> void:
	actors = {"player": DEFAULT_PLAYER_STATE.duplicate(true)}
	_sync_player_to_world_state()
	actor_changed.emit("player")


func load_state(payload: Dictionary) -> void:
	actors = payload.duplicate(true)
	if not actors.has("player"):
		actors["player"] = DEFAULT_PLAYER_STATE.duplicate(true)
	_sync_player_to_world_state()
	actor_changed.emit("player")


func build_save_data() -> Dictionary:
	return actors.duplicate(true)


func get_actor(actor_id: String) -> Dictionary:
	return actors.get(actor_id, {}).duplicate(true)


func get_player_actor() -> Dictionary:
	return get_actor("player")


func get_player_map_id() -> String:
	return String(get_player_actor().get("map_id", "farm"))


func get_player_facing() -> String:
	return String(get_player_actor().get("facing", "down"))


func get_player_world_position() -> Vector2:
	return _dict_to_vector2(get_player_actor().get("world_position", DEFAULT_PLAYER_STATE["world_position"]))


func get_player_cell() -> Vector2i:
	return _dict_to_cell(get_player_actor().get("cell", DEFAULT_PLAYER_STATE["cell"]))


func set_player_facing(facing: String) -> void:
	var player_state: Dictionary = get_player_actor()
	player_state["facing"] = facing
	actors["player"] = player_state
	actor_changed.emit("player")


func set_player_transform(map_id: String, cell: Vector2i, world_position: Vector2, facing: String = "") -> void:
	var player_state: Dictionary = get_player_actor()
	player_state["map_id"] = map_id
	player_state["cell"] = {"x": cell.x, "y": cell.y}
	player_state["world_position"] = {"x": world_position.x, "y": world_position.y}
	if not facing.is_empty():
		player_state["facing"] = facing
	actors["player"] = player_state
	_sync_player_to_world_state()
	actor_changed.emit("player")


func sync_player_from_world_position(map_scene, map_id: String, world_position: Vector2, facing: String = "") -> void:
	if map_scene == null:
		set_player_transform(map_id, _dict_to_cell(DEFAULT_PLAYER_STATE["cell"]), world_position, facing)
		return
	set_player_transform(map_id, map_scene.world_to_cell(world_position), world_position, facing)


func _sync_player_to_world_state() -> void:
	WorldState.set_player_position(get_player_map_id(), get_player_world_position())


func _dict_to_vector2(value) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO


func _dict_to_cell(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
