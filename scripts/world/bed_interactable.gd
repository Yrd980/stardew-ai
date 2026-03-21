class_name BedInteractable
extends "res://scripts/world/interactable.gd"

func build_action_request() -> Dictionary:
	return {"type": "sleep"}
