extends Node

const InventoryLogicScript = preload("res://scripts/logic/inventory_logic.gd")

signal inventory_changed
signal selection_changed(index: int)

var inventory_logic = InventoryLogicScript.new()
var slots: Array = []
var selected_index := 0


func reset_inventory(size: int = 12) -> void:
	slots = inventory_logic.empty_slots(size)
	selected_index = 0
	inventory_changed.emit()
	selection_changed.emit(selected_index)


func load_state(payload: Dictionary) -> void:
	slots = payload.get("slots", []).duplicate(true)
	if slots.is_empty():
		slots = inventory_logic.empty_slots(12)
	selected_index = clamp(int(payload.get("selected_index", 0)), 0, slots.size() - 1)
	inventory_changed.emit()
	selection_changed.emit(selected_index)


func build_save_data() -> Dictionary:
	return {"slots": slots.duplicate(true), "selected_index": selected_index}


func can_add_item(item_id: String, amount: int) -> bool:
	return can_add_item_with_quality(item_id, amount, "normal")


func can_add_item_with_quality(item_id: String, amount: int, quality: String = "normal") -> bool:
	var item = GameState.get_item_data(item_id)
	if item == null:
		return false
	var result: Dictionary = inventory_logic.add_item(slots, item_id, amount, item.max_stack, quality)
	return int(result["leftover"]) == 0


func get_selected_slot() -> Dictionary:
	return slots[selected_index]


func get_slot(index: int) -> Dictionary:
	return slots[index]


func select_slot(index: int) -> void:
	if index < 0 or index >= min(slots.size(), GameState.HOTBAR_SLOTS):
		return
	selected_index = index
	selection_changed.emit(selected_index)


func cycle_selected(delta: int) -> void:
	var hotbar_size: int = min(slots.size(), GameState.HOTBAR_SLOTS)
	if hotbar_size == 0:
		return
	selected_index = posmod(selected_index + delta, hotbar_size)
	selection_changed.emit(selected_index)


func add_item(item_id: String, amount: int, quality: String = "normal") -> bool:
	var item = GameState.get_item_data(item_id)
	if item == null:
		return false
	var result: Dictionary = inventory_logic.add_item(slots, item_id, amount, item.max_stack, quality)
	slots = result["slots"]
	inventory_changed.emit()
	return int(result["leftover"]) == 0


func remove_amount(index: int, amount: int) -> void:
	slots = inventory_logic.remove_amount(slots, index, amount)
	inventory_changed.emit()


func consume_selected_item(amount: int = 1) -> void:
	remove_amount(selected_index, amount)


func sell_selected_stack() -> Dictionary:
	var slot := get_selected_slot()
	var item_id := String(slot.get("item_id", ""))
	if item_id.is_empty():
		return {"success": false, "value": 0, "item_name": ""}
	var item = GameState.get_item_data(item_id)
	if item == null or item.sell_price <= 0:
		return {"success": false, "value": 0, "item_name": item.display_name if item else ""}
	var count := int(slot.get("count", 0))
	var value: int = int(item.sell_price) * count
	remove_amount(selected_index, count)
	return {"success": true, "value": value, "item_name": item.display_name, "count": count}
