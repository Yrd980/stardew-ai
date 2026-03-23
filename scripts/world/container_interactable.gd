class_name ContainerInteractable
extends "res://scripts/world/interactable.gd"

@export var container_id := ""


func build_action_request() -> Dictionary:
	return {
		"type": "open_container",
		"container_id": container_id,
		"message": "Opened the chest."
	}
