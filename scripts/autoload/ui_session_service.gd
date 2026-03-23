extends Node

signal session_changed

var inventory_open := false
var active_shop_id := ""
var active_shopkeeper_id := ""
var active_container_id := ""
var crafting_open := false
var delivery_open := false


func _ready() -> void:
	if not ActionCoordinator.shop_requested.is_connected(open_shop):
		ActionCoordinator.shop_requested.connect(open_shop)
	if not ActionCoordinator.shop_close_requested.is_connected(close_shop):
		ActionCoordinator.shop_close_requested.connect(close_shop)
	session_changed.emit()


func is_inventory_open() -> bool:
	return inventory_open


func is_modal_open() -> bool:
	return not active_shop_id.is_empty() or not active_container_id.is_empty() or crafting_open or delivery_open


func get_active_shop_id() -> String:
	return active_shop_id


func get_active_shopkeeper_id() -> String:
	return active_shopkeeper_id


func get_active_container_id() -> String:
	return active_container_id


func is_crafting_open() -> bool:
	return crafting_open


func is_delivery_open() -> bool:
	return delivery_open


func toggle_inventory() -> void:
	if is_modal_open():
		close_shop()
		return
	inventory_open = not inventory_open
	session_changed.emit()


func open_shop(shop_id: String, npc_id: String = "") -> void:
	if shop_id.is_empty():
		return
	_clear_modals()
	active_shop_id = shop_id
	active_shopkeeper_id = npc_id
	inventory_open = false
	session_changed.emit()


func open_container(container_id: String) -> void:
	if container_id.is_empty():
		return
	_clear_modals()
	active_container_id = container_id
	inventory_open = false
	session_changed.emit()


func open_crafting() -> void:
	_clear_modals()
	crafting_open = true
	inventory_open = false
	session_changed.emit()


func open_delivery() -> void:
	_clear_modals()
	delivery_open = true
	inventory_open = false
	session_changed.emit()


func close_shop() -> void:
	if active_shop_id.is_empty() and active_shopkeeper_id.is_empty() and active_container_id.is_empty() and not crafting_open and not delivery_open and not inventory_open:
		return
	_clear_modals()
	session_changed.emit()


func close_modal() -> void:
	if not is_modal_open():
		return
	_clear_modals()
	session_changed.emit()


func _clear_modals() -> void:
	active_shop_id = ""
	active_shopkeeper_id = ""
	active_container_id = ""
	crafting_open = false
	delivery_open = false
