extends Node2D

const MAP_SCENES := {
	"farm": "res://scenes/maps/farm_map.tscn",
	"house": "res://scenes/maps/house_map.tscn",
	"shop": "res://scenes/maps/shop_map.tscn"
}

@onready var map_root: Node2D = $MapRoot
@onready var player = $Player
@onready var hud = $HUDLayer/HUD

var current_map = null


func _ready() -> void:
	player.set_hud(hud)
	SceneRouter.map_change_requested.connect(_on_map_change_requested)
	if not SaveManager.load_game():
		GameState.start_new_game()
	var spawn_id := "save" if SaveManager.has_save() else "default"
	_load_map(SceneRouter.current_map_id, spawn_id)
	hud.push_message("Farm loop ready: till, water, plant, talk, shop, ship.")


func _exit_tree() -> void:
	if current_map != null:
		WorldState.set_player_position(current_map.map_id, player.global_position)


func _on_map_change_requested(map_id: String, spawn_id: String) -> void:
	_load_map(map_id, spawn_id)


func _load_map(map_id: String, spawn_id: String) -> void:
	if current_map != null:
		WorldState.set_player_position(current_map.map_id, player.global_position)
		current_map.queue_free()
	current_map = load(MAP_SCENES[map_id]).instantiate()
	map_root.add_child(current_map)
	player.current_map = current_map
	SceneRouter.set_current_map(map_id)
	var spawn_position: Vector2 = current_map.get_spawn_position(spawn_id)
	if spawn_id == "save" and WorldState.has_player_position(map_id):
		spawn_position = WorldState.get_player_position(map_id, spawn_position)
	player.global_position = spawn_position
	if hud != null:
		hud.push_message(current_map.get_enter_message())
