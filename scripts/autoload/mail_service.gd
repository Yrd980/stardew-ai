extends Node

signal deliveries_changed

var pending_deliveries: Array = []


func reset_state() -> void:
	pending_deliveries = []
	deliveries_changed.emit()


func load_state(payload: Dictionary) -> void:
	pending_deliveries = payload.get("pending_deliveries", []).duplicate(true)
	deliveries_changed.emit()


func build_save_data() -> Dictionary:
	return {
		"pending_deliveries": pending_deliveries.duplicate(true)
	}


func queue_recipe_delivery(recipe_ids: Array, title: String, delay_days: int = 1) -> void:
	pending_deliveries.append({
		"type": "recipe_unlock",
		"title": title,
		"recipe_ids": recipe_ids.duplicate(),
		"claim_day": ClockService.day + max(delay_days, 0)
	})
	deliveries_changed.emit()


func get_claimable_deliveries() -> Array:
	var claimable: Array = []
	for delivery in pending_deliveries:
		if int(delivery.get("claim_day", 1)) <= ClockService.day:
			claimable.append(delivery)
	return claimable


func has_claimable_delivery() -> bool:
	return not get_claimable_deliveries().is_empty()


func claim_next_delivery() -> Dictionary:
	for index in range(pending_deliveries.size()):
		var delivery: Dictionary = pending_deliveries[index]
		if int(delivery.get("claim_day", 1)) > ClockService.day:
			continue
		pending_deliveries.remove_at(index)
		deliveries_changed.emit()
		var unlocked := []
		if String(delivery.get("type", "")) == "recipe_unlock":
			unlocked = CraftingService.unlock_recipes(delivery.get("recipe_ids", []))
		return {
			"success": true,
			"message": "%s claimed." % String(delivery.get("title", "Delivery")),
			"time_cost": 0,
			"events": [{
				"type": "delivery_claimed",
				"title": String(delivery.get("title", "")),
				"recipe_ids": unlocked
			}],
			"directives": {}
		}
	return {
		"success": false,
		"message": "Nothing is ready for pickup yet.",
		"time_cost": 0,
		"events": [],
		"directives": {}
	}
