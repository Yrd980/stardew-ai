extends Node2D

@onready var map_root: Node2D = $MapRoot
@onready var player = $Player
@onready var hud = $HUDLayer/HUD

var current_map = null


func _ready() -> void:
	player.set_hud(hud)
	SceneRouter.map_change_requested.connect(_on_map_change_requested)
	var has_save := SaveManager.has_save()
	if not SaveManager.load_game():
		GameState.start_new_game()
	var spawn_id := "save" if has_save else "default"
	_load_map(ActorService.get_player_map_id(), spawn_id)
	hud.push_message("OpenClaw runtime ready.")


func _exit_tree() -> void:
	SceneRouter.set_loaded_map(null)


func _on_map_change_requested(map_id: String, spawn_id: String) -> void:
	_load_map(map_id, spawn_id)


func _load_map(map_id: String, spawn_id: String) -> void:
	if current_map != null:
		current_map.queue_free()
	current_map = load(GameState.MAP_SCENES[map_id]).instantiate()
	map_root.add_child(current_map)
	player.current_map = current_map
	SceneRouter.set_loaded_map(current_map)
	SceneRouter.set_current_map(map_id)
	var spawn_position := ActorService.get_player_world_position()
	if spawn_id != "save" or ActorService.get_player_map_id() != map_id:
		spawn_position = current_map.get_spawn_position(spawn_id)
	ActorService.sync_player_from_world_position(current_map, map_id, spawn_position, ActorService.get_player_facing())
	if hud != null:
		hud.push_message(current_map.get_enter_message())
