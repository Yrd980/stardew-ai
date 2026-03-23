class_name ActionRequestInteractable
extends "res://scripts/world/interactable.gd"

@export var request: Dictionary = {}


func build_action_request() -> Dictionary:
	return request.duplicate(true)
