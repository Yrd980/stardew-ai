extends Control

var inventory_open := false
var message_timer := 0.0

@onready var status_label: Label = $TopBar/StatusLabel
@onready var help_label: Label = $TopBar/HelpLabel
@onready var hotbar_label: Label = $BottomBar/HotbarLabel
@onready var message_label: Label = $BottomBar/MessageLabel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_label: Label = $InventoryPanel/InventoryLabel


func _ready() -> void:
	inventory_panel.visible = false
	_refresh()


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer = max(0.0, message_timer - delta)
		if message_timer == 0.0:
			message_label.text = ""
	_refresh()


func toggle_inventory() -> void:
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	_refresh_inventory()


func push_message(message: String) -> void:
	message_label.text = message
	message_timer = 3.5


func _refresh() -> void:
	status_label.text = "Day %s  %s  Money %sg  Map %s" % [
		ClockService.day,
		GameState.format_time(ClockService.time_minutes),
		GameState.money,
		SceneRouter.current_map_id.capitalize()
	]
	help_label.text = "Move WASD  Use F  Interact E  Inventory Tab  Save F5"
	hotbar_label.text = _build_hotbar_text()
	if inventory_open:
		_refresh_inventory()


func _build_hotbar_text() -> String:
	var lines := ["Hotbar"]
	for index in range(min(GameState.HOTBAR_SLOTS, InventoryService.slots.size())):
		var slot: Dictionary = InventoryService.get_slot(index)
		var marker := ">" if index == InventoryService.selected_index else " "
		var item_id := String(slot.get("item_id", ""))
		var label := "--"
		if not item_id.is_empty():
			var item = GameState.get_item_data(item_id)
			label = "%s x%s" % [item.display_name if item else item_id, int(slot.get("count", 0))]
		lines.append("%s%s. %s" % [marker, index + 1, label])
	return "\n".join(lines)


func _refresh_inventory() -> void:
	var lines := ["Inventory"]
	for index in range(InventoryService.slots.size()):
		var slot: Dictionary = InventoryService.get_slot(index)
		var item_id := String(slot.get("item_id", ""))
		var label := "--"
		if not item_id.is_empty():
			var item = GameState.get_item_data(item_id)
			label = "%s x%s" % [item.display_name if item else item_id, int(slot.get("count", 0))]
		lines.append("%s. %s" % [index + 1, label])
	inventory_label.text = "\n".join(lines)
