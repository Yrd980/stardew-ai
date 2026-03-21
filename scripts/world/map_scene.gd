extends Node2D

const TilePalette = preload("res://scripts/world/tile_palette.gd")
const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")

@export var map_id := ""
@export var map_size := Vector2i(16, 12)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var collision_layer: TileMapLayer = $CollisionLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer
@onready var interaction_layer: TileMapLayer = $InteractionLayer
@onready var crop_layer: TileMapLayer = $CropLayer
@onready var solids_root: Node2D = $Solids
@onready var interactables_root: Node2D = $Interactables
@onready var spawn_points: Node2D = $SpawnPoints

var hud: Node
var crop_logic = CropLogicScript.new()


func _ready() -> void:
	var tile_set := TilePalette.get_tile_set()
	for layer in [ground_layer, collision_layer, decoration_layer, interaction_layer, crop_layer]:
		layer.tile_set = tile_set
	_build_static_map()
	_build_solids()
	_build_interactables()
	refresh_dynamic_layers()
	WorldState.world_changed.connect(_on_world_changed)


func _exit_tree() -> void:
	if WorldState.world_changed.is_connected(_on_world_changed):
		WorldState.world_changed.disconnect(_on_world_changed)


func bind_hud(target: Node) -> void:
	hud = target


func get_spawn_position(spawn_id: String) -> Vector2:
	if spawn_points.has_node(spawn_id):
		return spawn_points.get_node(spawn_id).global_position
	if spawn_points.get_child_count() > 0:
		return spawn_points.get_child(0).global_position
	return global_position


func get_enter_message() -> String:
	return "Entered %s." % map_id.capitalize()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(world_position))


func cell_to_world(cell: Vector2i) -> Vector2:
	return ground_layer.to_global(ground_layer.map_to_local(cell) + Vector2(TilePalette.TILE_SIZE / 2, TilePalette.TILE_SIZE / 2))


func can_farm_cell(_cell: Vector2i) -> bool:
	return false


func find_interactable(target_world: Vector2, actor_world: Vector2):
	var best = null
	var best_distance := INF
	for child in interactables_root.get_children():
		if child.has_method("can_be_interacted_with") and child.can_be_interacted_with(target_world, actor_world):
			var distance: float = child.global_position.distance_to(target_world)
			if distance < best_distance:
				best_distance = distance
				best = child
	return best


func refresh_dynamic_layers() -> void:
	interaction_layer.clear()
	crop_layer.clear()
	var soils: Dictionary = WorldState.get_soils(map_id)
	for key in soils.keys():
		var cell := WorldState.key_to_cell(String(key))
		var soil: Dictionary = soils[key]
		if soil.get("tilled", false):
			var tile := TilePalette.SOIL_WATERED if soil.get("watered", false) else TilePalette.SOIL_DRY
			interaction_layer.set_cell(cell, TilePalette.SOURCE_ID, tile)
	var crops: Dictionary = WorldState.get_crops(map_id)
	for key in crops.keys():
		var cell := WorldState.key_to_cell(String(key))
		var crop_state: Dictionary = crops[key]
		var crop_def = GameState.get_crop_data(String(crop_state.get("crop_id", "")))
		if crop_def == null:
			continue
		var stage: int = crop_logic.get_stage(int(crop_state.get("days_watered", 0)), crop_def)
		crop_layer.set_cell(cell, TilePalette.SOURCE_ID, TilePalette.get_crop_stage_coords(stage))
	interaction_layer.update_internals()
	crop_layer.update_internals()


func _on_world_changed(changed_map_id: String) -> void:
	if changed_map_id == map_id:
		refresh_dynamic_layers()


func _paint_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			layer.set_cell(Vector2i(x, y), TilePalette.SOURCE_ID, atlas_coords)


func _spawn_static_rect(name: String, rect: Rect2i) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.position = Vector2(rect.position) * TilePalette.TILE_SIZE + Vector2(rect.size) * TilePalette.TILE_SIZE / 2.0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(rect.size) * TilePalette.TILE_SIZE
	shape.shape = rectangle
	body.add_child(shape)
	solids_root.add_child(body)


func _build_static_map() -> void:
	pass


func _build_solids() -> void:
	pass


func _build_interactables() -> void:
	pass
