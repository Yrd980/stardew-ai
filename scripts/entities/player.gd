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
	if hud != null and hud.has_method("is_modal_open") and hud.is_modal_open():
		hud.handle_modal_input()
		velocity = Vector2.ZERO
		return
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
		ActionCoordinator.save_game(SceneRouter.current_map_id, global_position)
	if Input.is_action_just_pressed("use_tool"):
		_use_selected_slot()
	if Input.is_action_just_pressed("interact"):
		_interact()


func _use_selected_slot() -> void:
	if current_map == null:
		return
	var target_cell := get_target_cell()
	ActionCoordinator.use_selected_slot(current_map.map_id, target_cell, current_map.can_farm_cell(target_cell))


func _interact() -> void:
	if current_map == null:
		return
	var target_cell := get_target_cell()
	var target_world := global_position + facing * TilePalette.TILE_SIZE
	var interactable = current_map.find_interactable(target_world, global_position)
	ActionCoordinator.interact_at_target(current_map.map_id, target_cell, interactable)
