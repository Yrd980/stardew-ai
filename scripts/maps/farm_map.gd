extends "res://scripts/world/map_scene.gd"

const DoorInteractable = preload("res://scripts/world/door_interactable.gd")
const ShippingBinInteractable = preload("res://scripts/world/shipping_bin_interactable.gd")
const ActionRequestInteractable = preload("res://scripts/world/action_request_interactable.gd")

const FARMABLE_RECT := Rect2i(5, 10, 11, 6)


func get_enter_message() -> String:
	return "Back on the farm."


func can_farm_cell(cell: Vector2i) -> bool:
	return FARMABLE_RECT.has_point(cell)


func _build_static_map() -> void:
	ground_layer.clear()
	collision_layer.clear()
	decoration_layer.clear()
	_paint_rect(ground_layer, Rect2i(Vector2i.ZERO, map_size), TilePalette.GRASS)
	_paint_rect(ground_layer, Rect2i(8, 0, 4, map_size.y), TilePalette.PATH)
	_paint_rect(ground_layer, Rect2i(9, 7, 3, 7), TilePalette.PATH)
	_paint_rect(ground_layer, Rect2i(4, 6, 6, 3), TilePalette.PATH)
	_paint_rect(ground_layer, FARMABLE_RECT, TilePalette.PATH)
	_paint_rect(decoration_layer, Rect2i(2, 2, 6, 4), TilePalette.ROOF)
	_paint_rect(collision_layer, Rect2i(2, 6, 6, 2), TilePalette.WALL)
	_paint_rect(decoration_layer, Rect2i(19, 2, 7, 4), TilePalette.ROOF)
	_paint_rect(collision_layer, Rect2i(19, 6, 7, 4), TilePalette.WALL)
	collision_layer.set_cell(Vector2i(4, 7), TilePalette.SOURCE_ID, TilePalette.DOOR)
	collision_layer.set_cell(Vector2i(22, 9), TilePalette.SOURCE_ID, TilePalette.DOOR)
	decoration_layer.set_cell(Vector2i(7, 8), TilePalette.SOURCE_ID, TilePalette.BIN)
	decoration_layer.set_cell(Vector2i(13, 8), TilePalette.SOURCE_ID, TilePalette.HOUSE_ACCENT)
	decoration_layer.set_cell(Vector2i(15, 8), TilePalette.SOURCE_ID, TilePalette.BIN)
	ground_layer.update_internals()
	collision_layer.update_internals()
	decoration_layer.update_internals()


func _build_solids() -> void:
	_spawn_static_rect("TopBoundary", Rect2i(0, -1, map_size.x, 1))
	_spawn_static_rect("BottomBoundary", Rect2i(0, map_size.y, map_size.x, 1))
	_spawn_static_rect("LeftBoundary", Rect2i(-1, 0, 1, map_size.y))
	_spawn_static_rect("RightBoundary", Rect2i(map_size.x, 0, 1, map_size.y))
	_spawn_static_rect("ShopBody", Rect2i(2, 2, 6, 6))
	_spawn_static_rect("HouseBody", Rect2i(19, 2, 7, 8))


func _build_interactables() -> void:
	var to_house := DoorInteractable.new()
	to_house.name = "ToHouse"
	to_house.position = cell_to_world(Vector2i(22, 9))
	to_house.destination_map_id = "house"
	to_house.destination_spawn_id = "from_farm"
	to_house.prompt = "Go inside"
	interactables_root.add_child(to_house)

	var shipping_bin := ShippingBinInteractable.new()
	shipping_bin.name = "ShippingBin"
	shipping_bin.position = cell_to_world(Vector2i(7, 8))
	shipping_bin.prompt = "Ship selected stack"
	interactables_root.add_child(shipping_bin)

	var to_shop := DoorInteractable.new()
	to_shop.name = "ToShop"
	to_shop.position = cell_to_world(Vector2i(4, 7))
	to_shop.destination_map_id = "shop"
	to_shop.destination_spawn_id = "from_farm"
	to_shop.prompt = "Visit the seed shop"
	interactables_root.add_child(to_shop)

	var workbench := ActionRequestInteractable.new()
	workbench.name = "Workbench"
	workbench.position = cell_to_world(Vector2i(13, 8))
	workbench.prompt = "Use the workbench"
	workbench.request = {
		"type": "open_crafting",
		"message": "Workbench ready."
	}
	interactables_root.add_child(workbench)

	var delivery_box := ActionRequestInteractable.new()
	delivery_box.name = "DeliveryBox"
	delivery_box.position = cell_to_world(Vector2i(15, 8))
	delivery_box.prompt = "Check deliveries"
	delivery_box.request = {
		"type": "open_delivery",
		"message": "Delivery box opened."
	}
	interactables_root.add_child(delivery_box)
