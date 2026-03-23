extends Node2D

const TilePalette = preload("res://scripts/world/tile_palette.gd")
const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")
const NpcProjectionScene = preload("res://scenes/entities/npc_projection.tscn")
const ContainerInteractable = preload("res://scripts/world/container_interactable.gd")

@export var map_id := ""
@export var map_size := Vector2i(16, 12)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var collision_layer: TileMapLayer = $CollisionLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer
@onready var interaction_layer: TileMapLayer = $InteractionLayer
@onready var crop_layer: TileMapLayer = $CropLayer
@onready var object_layer: TileMapLayer = $ObjectLayer
@onready var solids_root: Node2D = $Solids
@onready var interactables_root: Node2D = $Interactables
@onready var spawn_points: Node2D = $SpawnPoints

var npcs_root: Node2D
var dynamic_interactables_root: Node2D

var crop_logic = CropLogicScript.new()


func _ready() -> void:
	var tile_set := TilePalette.get_tile_set()
	for layer in [ground_layer, collision_layer, decoration_layer, interaction_layer, crop_layer, object_layer]:
		layer.tile_set = tile_set
	_build_static_map()
	_build_solids()
	_build_interactables()
	_ensure_dynamic_interactables_root()
	refresh_dynamic_layers()
	_ensure_npcs_root()
	refresh_npc_projections()
	WorldState.world_changed.connect(_on_world_changed)
	NpcService.npc_states_changed.connect(_on_npc_states_changed)


func _exit_tree() -> void:
	if WorldState.world_changed.is_connected(_on_world_changed):
		WorldState.world_changed.disconnect(_on_world_changed)
	if NpcService.npc_states_changed.is_connected(_on_npc_states_changed):
		NpcService.npc_states_changed.disconnect(_on_npc_states_changed)

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
	var candidates: Array = []
	candidates.append_array(interactables_root.get_children())
	if dynamic_interactables_root != null:
		candidates.append_array(dynamic_interactables_root.get_children())
	if npcs_root != null:
		candidates.append_array(npcs_root.get_children())
	for child in candidates:
		if child.has_method("can_be_interacted_with") and child.can_be_interacted_with(target_world, actor_world):
			var distance: float = child.global_position.distance_to(target_world)
			if distance < best_distance:
				best_distance = distance
				best = child
	return best


func refresh_dynamic_layers() -> void:
	interaction_layer.clear()
	crop_layer.clear()
	object_layer.clear()
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
	var placeables: Dictionary = WorldState.get_placeables(map_id)
	for key in placeables.keys():
		var cell := WorldState.key_to_cell(String(key))
		var placeable_state: Dictionary = placeables[key]
		var placeable = GameState.get_placeable_data(String(placeable_state.get("placeable_id", "")))
		if placeable == null:
			continue
		object_layer.set_cell(cell, TilePalette.SOURCE_ID, placeable.atlas_coords)
	_refresh_dynamic_interactables(placeables)
	interaction_layer.update_internals()
	crop_layer.update_internals()
	object_layer.update_internals()


func _on_world_changed(changed_map_id: String) -> void:
	if changed_map_id == map_id:
		refresh_dynamic_layers()


func refresh_npc_projections() -> void:
	if npcs_root == null:
		return
	for child in npcs_root.get_children():
		child.queue_free()
	for projection in NpcService.get_npcs_for_map(map_id):
		var npc_node = NpcProjectionScene.instantiate()
		npc_node.setup_projection(projection, self)
		npcs_root.add_child(npc_node)


func _ensure_npcs_root() -> void:
	if has_node("NPCs"):
		npcs_root = $NPCs
		return
	npcs_root = Node2D.new()
	npcs_root.name = "NPCs"
	add_child(npcs_root)


func _ensure_dynamic_interactables_root() -> void:
	if has_node("DynamicInteractables"):
		dynamic_interactables_root = $DynamicInteractables
		return
	dynamic_interactables_root = Node2D.new()
	dynamic_interactables_root.name = "DynamicInteractables"
	add_child(dynamic_interactables_root)


func _refresh_dynamic_interactables(placeables: Dictionary) -> void:
	if dynamic_interactables_root == null:
		return
	for child in dynamic_interactables_root.get_children():
		child.queue_free()
	for key in placeables.keys():
		var placeable_state: Dictionary = placeables[key]
		var placeable = GameState.get_placeable_data(String(placeable_state.get("placeable_id", "")))
		if placeable == null or String(placeable.kind) != "storage":
			continue
		var cell := WorldState.key_to_cell(String(key))
		var chest := ContainerInteractable.new()
		chest.name = "Chest_%s" % String(placeable_state.get("object_id", ""))
		chest.position = cell_to_world(cell)
		chest.container_id = String(placeable_state.get("object_id", ""))
		chest.prompt = "Open chest"
		dynamic_interactables_root.add_child(chest)


func _on_npc_states_changed() -> void:
	refresh_npc_projections()


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
