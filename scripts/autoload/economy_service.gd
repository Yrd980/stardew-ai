extends Node

signal money_changed(amount: int)
signal pending_shipments_changed
signal shipment_settled(summary: Dictionary)
signal purchase_completed(result: Dictionary)

var money := GameState.STARTING_MONEY
var pending_shipments: Array = []
var shop_purchase_counts := {}
var last_settlement_summary := {}
var lifetime_earnings := 0
var shipment_history: Array = []


func reset_state() -> void:
	money = GameState.STARTING_MONEY
	pending_shipments = []
	shop_purchase_counts = {}
	last_settlement_summary = {}
	lifetime_earnings = 0
	shipment_history = []
	money_changed.emit(money)
	pending_shipments_changed.emit()


func load_state(payload: Dictionary) -> void:
	money = int(payload.get("money", GameState.STARTING_MONEY))
	pending_shipments = payload.get("pending_shipments", []).duplicate(true)
	shop_purchase_counts = payload.get("shop_purchase_counts", {}).duplicate(true)
	last_settlement_summary = payload.get("last_settlement_summary", {}).duplicate(true)
	lifetime_earnings = int(payload.get("lifetime_earnings", 0))
	shipment_history = payload.get("shipment_history", []).duplicate(true)
	money_changed.emit(money)
	pending_shipments_changed.emit()


func build_save_data() -> Dictionary:
	return {
		"money": money,
		"pending_shipments": pending_shipments.duplicate(true),
		"shop_purchase_counts": shop_purchase_counts.duplicate(true),
		"last_settlement_summary": last_settlement_summary.duplicate(true),
		"lifetime_earnings": lifetime_earnings,
		"shipment_history": shipment_history.duplicate(true)
	}


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func queue_selected_stack_for_shipping() -> Dictionary:
	var slot := InventoryService.get_selected_slot()
	return queue_inventory_slot_for_shipping(InventoryService.selected_index, int(slot.get("count", 0)))


func queue_inventory_slot_for_shipping(slot_index: int, amount: int = 0) -> Dictionary:
	if slot_index < 0 or slot_index >= InventoryService.slots.size():
		return _result(false, "That inventory slot is not available.")
	var slot: Dictionary = InventoryService.get_slot(slot_index)
	var item_id := String(slot.get("item_id", ""))
	var quality := String(slot.get("quality", "normal"))
	if item_id.is_empty():
		return _result(false, "Select a sellable item first.")
	var item = GameState.get_item_data(item_id)
	if item == null or int(item.sell_price) <= 0:
		return _result(false, "Select a sellable item first.")
	var count := int(slot.get("count", 0))
	if amount > 0:
		count = min(count, amount)
	if count <= 0:
		return _result(false, "Choose at least one item to ship.")
	var unit_price := get_sell_price(item_id, quality)
	var shipment := {
		"item_id": item_id,
		"quality": quality,
		"count": count,
		"unit_price": unit_price,
		"total_price": unit_price * count
	}
	InventoryService.remove_amount(slot_index, count)
	pending_shipments.append(shipment)
	pending_shipments_changed.emit()
	var quality_label := "" if quality == "normal" else "%s " % quality.capitalize()
	return _result(true, "Queued %s%s x%s for tomorrow's shipment." % [quality_label, item.display_name, count], 5, [{
		"type": "shipment_queued",
		"item_id": item_id,
		"quality": quality,
		"count": count,
		"total_price": int(shipment["total_price"])
	}])


func settle_pending_shipments() -> Dictionary:
	var total_earned := 0
	for shipment in pending_shipments:
		total_earned += int(shipment.get("total_price", 0))
	if total_earned > 0:
		add_money(total_earned)
		lifetime_earnings += total_earned
	var summary := {
		"total_earned": total_earned,
		"shipments": pending_shipments.duplicate(true),
		"line_count": pending_shipments.size(),
		"day": ClockService.day
	}
	last_settlement_summary = summary
	if total_earned > 0:
		shipment_history.append(summary.duplicate(true))
		if shipment_history.size() > 10:
			shipment_history = shipment_history.slice(shipment_history.size() - 10, shipment_history.size())
	pending_shipments = []
	shop_purchase_counts = {}
	pending_shipments_changed.emit()
	shipment_settled.emit(summary)
	return summary


func purchase_item(shop_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	var shop = GameState.get_shop_data(shop_id)
	if shop == null:
		return _result(false, "That shop is not available.")
	if not NpcService.is_shop_open(shop_id):
		return _result(false, "The shop is closed right now.")
	var stock_entry := _find_stock_entry(shop, item_id)
	if stock_entry.is_empty():
		return _result(false, "That item is not sold here.")
	if not is_stock_entry_available(stock_entry):
		return _result(false, _get_stock_lock_message(stock_entry))
	var unit_price := int(stock_entry.get("price", 0))
	var daily_limit := int(stock_entry.get("daily_limit", 0))
	var purchased_today := _get_daily_purchase_count(shop_id, item_id)
	if daily_limit > 0 and purchased_today + quantity > daily_limit:
		return _result(false, "That item is sold out for today.")
	var total_price := unit_price * quantity
	if money < total_price:
		return _result(false, "Not enough money.")
	add_money(-total_price)
	var events := []
	var item = GameState.get_item_data(item_id)
	if stock_entry.has("delivery_recipe_unlocks"):
		MailService.queue_recipe_delivery(stock_entry.get("delivery_recipe_unlocks", []), String(item.display_name if item else item_id))
		events.append({
			"type": "delivery_queued",
			"shop_id": shop_id,
			"item_id": item_id
		})
	else:
		if not InventoryService.can_add_item(item_id, quantity):
			add_money(total_price)
			return _result(false, "Inventory full. Make room before buying.")
		InventoryService.add_item(item_id, quantity)
		events.append({
			"type": "shop_purchase_completed",
			"shop_id": shop_id,
			"item_id": item_id,
			"count": quantity,
			"total_price": total_price
		})
	_set_daily_purchase_count(shop_id, item_id, purchased_today + quantity)
	var message := "Bought %s x%s for %sg." % [item.display_name if item else item_id, quantity, total_price]
	if stock_entry.has("delivery_recipe_unlocks"):
		message = "Ordered %s for %sg. Check the delivery box tomorrow." % [item.display_name if item else item_id, total_price]
	var result := _result(true, message, 10, events)
	purchase_completed.emit(result)
	return result


func get_sell_price(item_id: String, quality: String = "normal") -> int:
	var item = GameState.get_item_data(item_id)
	if item == null:
		return 0
	var multiplier := 1.0
	match quality:
		"silver":
			multiplier = 1.25
		"gold":
			multiplier = 1.5
	return int(round(int(item.sell_price) * multiplier))


func get_purchase_count(shop_id: String, item_id: String) -> int:
	return _get_daily_purchase_count(shop_id, item_id)


func get_available_shop_stock(shop_id: String) -> Array:
	var shop = GameState.get_shop_data(shop_id)
	if shop == null:
		return []
	var visible: Array = []
	for entry in shop.stock:
		if is_stock_entry_available(entry):
			visible.append(entry)
	return visible


func is_stock_entry_available(stock_entry: Dictionary) -> bool:
	var min_day := int(stock_entry.get("min_day", 1))
	if ClockService.day < min_day:
		return false
	var required_quest := String(stock_entry.get("required_completed_quest", ""))
	if not required_quest.is_empty() and not QuestService.has_completed_quest(required_quest):
		return false
	return true


func describe_stock_requirement(stock_entry: Dictionary) -> String:
	var min_day := int(stock_entry.get("min_day", 1))
	if ClockService.day < min_day:
		return "Available on day %s." % min_day
	var required_quest := String(stock_entry.get("required_completed_quest", ""))
	if not required_quest.is_empty() and not QuestService.has_completed_quest(required_quest):
		var quest = GameState.get_quest_data(required_quest)
		return "Complete %s first." % (quest.title if quest else required_quest)
	return ""


func _find_stock_entry(shop, item_id: String) -> Dictionary:
	for entry in shop.stock:
		if String(entry.get("item_id", "")) == item_id:
			return entry
	return {}


func _get_stock_lock_message(stock_entry: Dictionary) -> String:
	var requirement := describe_stock_requirement(stock_entry)
	if requirement.is_empty():
		return "That item is not ready to sell yet."
	return requirement


func _get_daily_purchase_count(shop_id: String, item_id: String) -> int:
	if not shop_purchase_counts.has(shop_id):
		return 0
	return int(shop_purchase_counts[shop_id].get(item_id, 0))


func _set_daily_purchase_count(shop_id: String, item_id: String, value: int) -> void:
	if not shop_purchase_counts.has(shop_id):
		shop_purchase_counts[shop_id] = {}
	shop_purchase_counts[shop_id][item_id] = value


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
