class_name DoorInteractable
extends "res://scripts/world/interactable.gd"

@export var destination_map_id := ""
@export var destination_spawn_id := "default"


func interact(_player: Node, hud: Node) -> void:
	SceneRouter.request_map_change(destination_map_id, destination_spawn_id)
	if hud != null:
		hud.push_message("Entering %s." % destination_map_id.capitalize())
