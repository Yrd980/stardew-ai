extends "res://scripts/world/map_scene.gd"

const DoorInteractable = preload("res://scripts/world/door_interactable.gd")
const BedInteractable = preload("res://scripts/world/bed_interactable.gd")


func get_enter_message() -> String:
	return "Safe and warm inside."


func describe_static_interactables() -> Array:
	return [
		{
			"target_id": "house.to_farm",
			"kind": "door",
			"prompt": "Step outside",
			"cell": {"x": 8, "y": 11},
			"destination_map_id": "farm",
			"destination_spawn_id": "from_house"
		},
		{
			"target_id": "house.bed",
			"kind": "bed",
			"prompt": "Sleep until morning",
			"cell": {"x": 4, "y": 3}
		}
	]


func _build_static_map() -> void:
	ground_layer.clear()
	collision_layer.clear()
	decoration_layer.clear()
	_paint_rect(ground_layer, Rect2i(Vector2i.ZERO, map_size), TilePalette.HOUSE_FLOOR)
	_paint_rect(collision_layer, Rect2i(0, 0, map_size.x, 1), TilePalette.WALL)
	_paint_rect(collision_layer, Rect2i(0, map_size.y - 1, map_size.x, 1), TilePalette.WALL)
	_paint_rect(collision_layer, Rect2i(0, 0, 1, map_size.y), TilePalette.WALL)
	_paint_rect(collision_layer, Rect2i(map_size.x - 1, 0, 1, map_size.y), TilePalette.WALL)
	decoration_layer.set_cell(Vector2i(4, 3), TilePalette.SOURCE_ID, TilePalette.BED)
	collision_layer.set_cell(Vector2i(8, 11), TilePalette.SOURCE_ID, TilePalette.DOOR)
	ground_layer.update_internals()
	collision_layer.update_internals()
	decoration_layer.update_internals()


func _build_solids() -> void:
	_spawn_static_rect("TopWall", Rect2i(0, 0, map_size.x, 1))
	_spawn_static_rect("LeftWall", Rect2i(0, 0, 1, map_size.y))
	_spawn_static_rect("RightWall", Rect2i(map_size.x - 1, 0, 1, map_size.y))
	_spawn_static_rect("BottomWallLeft", Rect2i(0, map_size.y - 1, 7, 1))
	_spawn_static_rect("BottomWallRight", Rect2i(9, map_size.y - 1, map_size.x - 9, 1))


func _build_interactables() -> void:
	var to_farm := DoorInteractable.new()
	to_farm.name = "ToFarm"
	to_farm.position = cell_to_world(Vector2i(8, 11))
	to_farm.destination_map_id = "farm"
	to_farm.destination_spawn_id = "from_house"
	to_farm.prompt = "Step outside"
	interactables_root.add_child(to_farm)

	var bed := BedInteractable.new()
	bed.name = "Bed"
	bed.position = cell_to_world(Vector2i(4, 3))
	bed.prompt = "Sleep until morning"
	interactables_root.add_child(bed)
