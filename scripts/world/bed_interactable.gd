class_name BedInteractable
extends "res://scripts/world/interactable.gd"


func interact(_player: Node, hud: Node) -> void:
	ClockService.sleep_and_advance_day()
	SaveManager.save_game()
	if hud != null:
		hud.push_message("You slept well. Day %s begins." % ClockService.day)
