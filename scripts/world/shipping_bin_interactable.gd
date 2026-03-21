class_name ShippingBinInteractable
extends "res://scripts/world/interactable.gd"


func interact(_player: Node, hud: Node) -> void:
	var result := InventoryService.sell_selected_stack()
	if not result.get("success", false):
		if hud != null:
			hud.push_message("Select a sellable item first.")
		return
	GameState.add_money(int(result.get("value", 0)))
	if hud != null:
		hud.push_message("Shipped %s x%s for %sg." % [
			String(result.get("item_name", "")),
			int(result.get("count", 0)),
			int(result.get("value", 0))
		])
