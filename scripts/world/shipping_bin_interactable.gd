class_name ShippingBinInteractable
extends "res://scripts/world/interactable.gd"


func interact(_player: Node, hud: Node) -> void:
	var result := EconomyService.queue_selected_stack_for_shipping()
	if result.get("success", false):
		ClockService.advance_time(int(result.get("time_cost", 0)))
	if hud != null:
		hud.push_message(String(result.get("message", "")))
