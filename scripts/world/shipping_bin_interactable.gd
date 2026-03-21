class_name ShippingBinInteractable
extends "res://scripts/world/interactable.gd"

func build_action_request() -> Dictionary:
	return {"type": "ship_selected"}
