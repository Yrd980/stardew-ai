extends CharacterBody2D

const TilePalette = preload("res://scripts/world/tile_palette.gd")

const MOVE_SPEED := 90.0

var facing := Vector2.DOWN
var current_map = null
var hud: Node

@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	_handle_selection_input()
	_handle_action_input()
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	velocity = direction * MOVE_SPEED
	move_and_slide()


func set_hud(target: Node) -> void:
	hud = target


func get_target_cell() -> Vector2i:
	if current_map == null:
		return Vector2i.ZERO
	var target_world := global_position + facing * TilePalette.TILE_SIZE
	return current_map.world_to_cell(target_world)


func _handle_selection_input() -> void:
	if Input.is_action_just_pressed("hotbar_prev"):
		InventoryService.cycle_selected(-1)
	if Input.is_action_just_pressed("hotbar_next"):
		InventoryService.cycle_selected(1)
	for index in range(GameState.HOTBAR_SLOTS):
		if Input.is_action_just_pressed("slot_%s" % (index + 1)):
			InventoryService.select_slot(index)


func _handle_action_input() -> void:
	if Input.is_action_just_pressed("toggle_inventory") and hud != null:
		hud.toggle_inventory()
	if Input.is_action_just_pressed("save_game"):
		WorldState.set_player_position(SceneRouter.current_map_id, global_position)
		if SaveManager.save_game() and hud != null:
			hud.push_message("Game saved to user://savegame.json")
	if Input.is_action_just_pressed("use_tool"):
		_use_selected_slot()
	if Input.is_action_just_pressed("interact"):
		_interact()


func _use_selected_slot() -> void:
	if current_map == null:
		return
	var slot := InventoryService.get_selected_slot()
	var item_id := String(slot.get("item_id", ""))
	if item_id.is_empty():
		if hud != null:
			hud.push_message("Select a tool or seeds from the hotbar.")
		return
	var item = GameState.get_item_data(item_id)
	if item == null:
		return
	var target_cell := get_target_cell()
	match item.kind:
		"tool":
			_use_tool(item_id, target_cell)
		"seed":
			_plant_seed(item, target_cell)
		_:
			if hud != null:
				hud.push_message("That item is for inventory or shipping.")


func _use_tool(tool_id: String, cell: Vector2i) -> void:
	if current_map == null:
		return
	if not current_map.can_farm_cell(cell):
		if hud != null:
			hud.push_message("That tile is not part of your field.")
		return
	var tool = GameState.get_tool_data(tool_id)
	if tool == null:
		return
	match tool.action_kind:
		"till":
			if WorldState.till_cell(current_map.map_id, cell):
				ClockService.advance_time(5)
				if hud != null:
					hud.push_message("Soil tilled.")
			elif hud != null:
				hud.push_message("That soil is already prepared.")
		"water":
			if WorldState.water_cell(current_map.map_id, cell):
				ClockService.advance_time(5)
				if hud != null:
					hud.push_message("Soil watered for the day.")
			elif hud != null:
				hud.push_message("There is nothing new to water there.")


func _plant_seed(item, cell: Vector2i) -> void:
	if current_map == null:
		return
	if not current_map.can_farm_cell(cell):
		if hud != null:
			hud.push_message("Seeds only grow in the farm plot.")
		return
	if WorldState.plant_crop(current_map.map_id, cell, item.crop_id):
		InventoryService.consume_selected_item(1)
		ClockService.advance_time(5)
		if hud != null:
			hud.push_message("Planted %s." % item.display_name)
	elif hud != null:
		hud.push_message("You need empty tilled soil for that.")


func _interact() -> void:
	if current_map == null:
		return
	var target_cell := get_target_cell()
	if WorldState.can_harvest(current_map.map_id, target_cell):
		var harvest_item := WorldState.harvest_crop(current_map.map_id, target_cell)
		if not harvest_item.is_empty():
			InventoryService.add_item(harvest_item, 1)
			ClockService.advance_time(5)
			if hud != null:
				hud.push_message("Harvested %s." % GameState.get_item_data(harvest_item).display_name)
			return
	var target_world := global_position + facing * TilePalette.TILE_SIZE
	var interactable = current_map.find_interactable(target_world, global_position)
	if interactable != null:
		interactable.interact(self, hud)
	elif hud != null:
		hud.push_message("Nothing to interact with here.")
