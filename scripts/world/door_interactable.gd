class_name DoorInteractable
extends "res://scripts/world/interactable.gd"

@export var destination_map_id := ""
@export var destination_spawn_id := "default"

func build_action_request() -> Dictionary:
	return {
		"type": "map_change",
		"destination_map_id": destination_map_id,
		"destination_spawn_id": destination_spawn_id,
		"message": "Entering %s." % destination_map_id.capitalize()
	}
