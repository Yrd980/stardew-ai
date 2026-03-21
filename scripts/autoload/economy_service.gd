extends Node

signal pending_shipments_changed
signal shipment_settled(summary: Dictionary)
signal purchase_completed(result: Dictionary)

var pending_shipments: Array = []
var shop_purchase_counts := {}
var last_settlement_summary := {}


func reset_state() -> void:
	pending_shipments = []
	shop_purchase_counts = {}
	last_settlement_summary = {}
	pending_shipments_changed.emit()


func load_state(payload: Dictionary) -> void:
	pending_shipments = payload.get("pending_shipments", []).duplicate(true)
	shop_purchase_counts = payload.get("shop_purchase_counts", {}).duplicate(true)
	last_settlement_summary = payload.get("last_settlement_summary", {}).duplicate(true)
	pending_shipments_changed.emit()


func build_save_data() -> Dictionary:
	return {
		"pending_shipments": pending_shipments.duplicate(true),
		"shop_purchase_counts": shop_purchase_counts.duplicate(true),
		"last_settlement_summary": last_settlement_summary.duplicate(true)
	}


func queue_selected_stack_for_shipping() -> Dictionary:
	var slot := InventoryService.get_selected_slot()
	var item_id := String(slot.get("item_id", ""))
	if item_id.is_empty():
		return _result(false, "Select a sellable item first.")
	var item = GameState.get_item_data(item_id)
	if item == null or int(item.sell_price) <= 0:
		return _result(false, "Select a sellable item first.")
	var count := int(slot.get("count", 0))
	var shipment := {
		"item_id": item_id,
		"count": count,
		"unit_price": int(item.sell_price),
		"total_price": int(item.sell_price) * count
	}
	InventoryService.remove_amount(InventoryService.selected_index, count)
	pending_shipments.append(shipment)
	pending_shipments_changed.emit()
	return _result(true, "Queued %s x%s for tomorrow's shipment." % [item.display_name, count], 5, [{
		"type": "shipment_queued",
		"item_id": item_id,
		"count": count,
		"total_price": int(shipment["total_price"])
	}])


func settle_pending_shipments() -> Dictionary:
	var total_earned := 0
	var lines: Array = []
	for shipment in pending_shipments:
		total_earned += int(shipment.get("total_price", 0))
		lines.append("%s x%s" % [String(shipment.get("item_id", "")), int(shipment.get("count", 0))])
	if total_earned > 0:
		GameState.add_money(total_earned)
	var summary := {
		"total_earned": total_earned,
		"shipments": pending_shipments.duplicate(true),
		"line_count": pending_shipments.size()
	}
	last_settlement_summary = summary
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
	var unit_price := int(stock_entry.get("price", 0))
	var daily_limit := int(stock_entry.get("daily_limit", 0))
	var purchased_today := _get_daily_purchase_count(shop_id, item_id)
	if daily_limit > 0 and purchased_today + quantity > daily_limit:
		return _result(false, "That item is sold out for today.")
	var total_price := unit_price * quantity
	if GameState.money < total_price:
		return _result(false, "Not enough money.")
	if not InventoryService.can_add_item(item_id, quantity):
		return _result(false, "Inventory full. Make room before buying.")
	GameState.add_money(-total_price)
	InventoryService.add_item(item_id, quantity)
	_set_daily_purchase_count(shop_id, item_id, purchased_today + quantity)
	var item = GameState.get_item_data(item_id)
	var result := _result(true, "Bought %s x%s for %sg." % [item.display_name if item else item_id, quantity, total_price], 10, [{
		"type": "shop_purchase_completed",
		"shop_id": shop_id,
		"item_id": item_id,
		"count": quantity,
		"total_price": total_price
	}])
	purchase_completed.emit(result)
	return result


func get_purchase_count(shop_id: String, item_id: String) -> int:
	return _get_daily_purchase_count(shop_id, item_id)


func _find_stock_entry(shop, item_id: String) -> Dictionary:
	for entry in shop.stock:
		if String(entry.get("item_id", "")) == item_id:
			return entry
	return {}


func _get_daily_purchase_count(shop_id: String, item_id: String) -> int:
	if not shop_purchase_counts.has(shop_id):
		return 0
	return int(shop_purchase_counts[shop_id].get(item_id, 0))


func _set_daily_purchase_count(shop_id: String, item_id: String, value: int) -> void:
	if not shop_purchase_counts.has(shop_id):
		shop_purchase_counts[shop_id] = {}
	shop_purchase_counts[shop_id][item_id] = value


func _result(success: bool, message: String, time_cost: int = 0, events: Array = []) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events
	}
