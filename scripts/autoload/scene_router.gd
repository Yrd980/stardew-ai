extends Node

signal map_change_requested(map_id: String, spawn_id: String)
signal current_map_changed(map_id: String)

var current_map_id := "farm"


func set_current_map(map_id: String) -> void:
	current_map_id = map_id
	current_map_changed.emit(map_id)


func request_map_change(map_id: String, spawn_id: String = "default") -> void:
	map_change_requested.emit(map_id, spawn_id)
