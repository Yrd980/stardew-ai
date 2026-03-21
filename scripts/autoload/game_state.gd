extends Node

signal money_changed(amount: int)

const INVENTORY_SLOTS := 12
const HOTBAR_SLOTS := 8
const STARTING_MONEY := 250
const ITEM_DIR := "res://resources/items"
const TOOL_DIR := "res://resources/tools"
const CROP_DIR := "res://resources/crops"

var item_defs := {}
var tool_defs := {}
var crop_defs := {}
var money := STARTING_MONEY


func _ready() -> void:
	ensure_input_map()
	load_databases()


func ensure_input_map() -> void:
	_ensure_keys("move_up", [KEY_W, KEY_UP])
	_ensure_keys("move_down", [KEY_S, KEY_DOWN])
	_ensure_keys("move_left", [KEY_A, KEY_LEFT])
	_ensure_keys("move_right", [KEY_D, KEY_RIGHT])
	_ensure_keys("interact", [KEY_E, KEY_SPACE])
	_ensure_keys("use_tool", [KEY_F, KEY_ENTER])
	_ensure_keys("toggle_inventory", [KEY_TAB, KEY_I])
	_ensure_keys("hotbar_prev", [KEY_Q])
	_ensure_keys("hotbar_next", [KEY_R])
	_ensure_keys("save_game", [KEY_F5])
	_ensure_keys("slot_1", [KEY_1])
	_ensure_keys("slot_2", [KEY_2])
	_ensure_keys("slot_3", [KEY_3])
	_ensure_keys("slot_4", [KEY_4])
	_ensure_keys("slot_5", [KEY_5])
	_ensure_keys("slot_6", [KEY_6])
	_ensure_keys("slot_7", [KEY_7])
	_ensure_keys("slot_8", [KEY_8])


func _ensure_keys(action_name: String, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = int(keycode)
		InputMap.action_add_event(action_name, event)


func load_databases() -> void:
	item_defs = _load_resources(ITEM_DIR)
	tool_defs = _load_resources(TOOL_DIR)
	crop_defs = _load_resources(CROP_DIR)


func _load_resources(dir_path: String) -> Dictionary:
	var results := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource := load("%s/%s" % [dir_path, file_name])
			if resource != null and not String(resource.get("id")).is_empty():
				results[String(resource.get("id"))] = resource
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func start_new_game() -> void:
	money = STARTING_MONEY
	money_changed.emit(money)
	ClockService.reset_clock()
	InventoryService.reset_inventory(INVENTORY_SLOTS)
	InventoryService.add_item("hoe", 1)
	InventoryService.add_item("watering_can", 1)
	InventoryService.add_item("parsnip_seeds", 15)
	WorldState.reset_world()
	WorldState.current_map_id = "farm"
	WorldState.set_player_position("farm", Vector2(160, 208))
	SceneRouter.set_current_map("farm")


func build_save_payload() -> Dictionary:
	return {
		"money": money,
		"clock": ClockService.build_save_data(),
		"inventory": InventoryService.build_save_data(),
		"world": WorldState.build_save_data(),
		"scene_router": {"current_map_id": SceneRouter.current_map_id}
	}


func apply_save_payload(payload: Dictionary) -> void:
	money = int(payload.get("money", STARTING_MONEY))
	money_changed.emit(money)
	ClockService.load_state(payload.get("clock", {}))
	InventoryService.load_state(payload.get("inventory", {}))
	WorldState.load_state(payload.get("world", {}))
	SceneRouter.set_current_map(String(payload.get("scene_router", {}).get("current_map_id", WorldState.current_map_id)))


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func get_item_data(item_id: String):
	return item_defs.get(item_id)


func get_tool_data(tool_id: String):
	return tool_defs.get(tool_id)


func get_crop_data(crop_id: String):
	return crop_defs.get(crop_id)


func format_time(minutes: int) -> String:
	var hours := int(minutes / 60)
	var mins := int(minutes % 60)
	return "%02d:%02d" % [hours, mins]
