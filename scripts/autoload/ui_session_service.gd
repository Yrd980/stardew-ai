extends Node

signal session_changed

var inventory_open := false
var active_shop_id := ""
var active_shopkeeper_id := ""


func _ready() -> void:
	if not ActionCoordinator.shop_requested.is_connected(open_shop):
		ActionCoordinator.shop_requested.connect(open_shop)
	if not ActionCoordinator.shop_close_requested.is_connected(close_shop):
		ActionCoordinator.shop_close_requested.connect(close_shop)
	session_changed.emit()


func is_inventory_open() -> bool:
	return inventory_open


func is_modal_open() -> bool:
	return not active_shop_id.is_empty()


func get_active_shop_id() -> String:
	return active_shop_id


func get_active_shopkeeper_id() -> String:
	return active_shopkeeper_id


func toggle_inventory() -> void:
	if is_modal_open():
		close_shop()
		return
	inventory_open = not inventory_open
	session_changed.emit()


func open_shop(shop_id: String, npc_id: String = "") -> void:
	if shop_id.is_empty():
		return
	active_shop_id = shop_id
	active_shopkeeper_id = npc_id
	inventory_open = false
	session_changed.emit()


func close_shop() -> void:
	if active_shop_id.is_empty() and active_shopkeeper_id.is_empty() and not inventory_open:
		return
	active_shop_id = ""
	active_shopkeeper_id = ""
	session_changed.emit()
