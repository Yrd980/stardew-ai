extends Node

signal map_change_requested(map_id: String, spawn_id: String)
signal current_map_changed(map_id: String)

var current_map_id := "farm"
var current_map_scene = null


func set_current_map(map_id: String) -> void:
	current_map_id = map_id
	current_map_changed.emit(map_id)


func set_loaded_map(map_scene) -> void:
	current_map_scene = map_scene


func get_loaded_map():
	return current_map_scene


func request_map_change(map_id: String, spawn_id: String = "default") -> void:
	map_change_requested.emit(map_id, spawn_id)
