extends Control

var inventory_open := false
var message_timer := 0.0
var active_shop_id := ""
var active_shopkeeper_id := ""

@onready var status_label: Label = $TopBar/StatusLabel
@onready var help_label: Label = $TopBar/HelpLabel
@onready var quest_label: Label = $TopBar/QuestLabel
@onready var hotbar_label: Label = $BottomBar/HotbarLabel
@onready var message_label: Label = $BottomBar/MessageLabel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_label: Label = $InventoryPanel/InventoryLabel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_label: Label = $ShopPanel/ShopLabel


func _ready() -> void:
	inventory_panel.visible = false
	shop_panel.visible = false
	if not ClockService.clock_changed.is_connected(_on_runtime_changed):
		ClockService.clock_changed.connect(_on_runtime_changed)
	if not EconomyService.money_changed.is_connected(_on_money_changed):
		EconomyService.money_changed.connect(_on_money_changed)
	if not InventoryService.inventory_changed.is_connected(_on_inventory_changed):
		InventoryService.inventory_changed.connect(_on_inventory_changed)
	if not InventoryService.selection_changed.is_connected(_on_selection_changed):
		InventoryService.selection_changed.connect(_on_selection_changed)
	if not SceneRouter.current_map_changed.is_connected(_on_map_changed):
		SceneRouter.current_map_changed.connect(_on_map_changed)
	if not QuestService.quest_log_changed.is_connected(_on_quest_changed):
		QuestService.quest_log_changed.connect(_on_quest_changed)
	if not EconomyService.pending_shipments_changed.is_connected(_on_shipments_changed):
		EconomyService.pending_shipments_changed.connect(_on_shipments_changed)
	if not ActionCoordinator.message_requested.is_connected(push_message):
		ActionCoordinator.message_requested.connect(push_message)
	if not ActionCoordinator.shop_requested.is_connected(open_shop):
		ActionCoordinator.shop_requested.connect(open_shop)
	if not ActionCoordinator.shop_close_requested.is_connected(close_shop):
		ActionCoordinator.shop_close_requested.connect(close_shop)
	_refresh_all()


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer = max(0.0, message_timer - delta)
		if message_timer == 0.0:
			message_label.text = ""


func toggle_inventory() -> void:
	if is_modal_open():
		close_shop()
		return
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	_refresh_inventory()


func push_message(message: String) -> void:
	message_label.text = message
	message_timer = 3.5


func is_modal_open() -> bool:
	return shop_panel.visible


func handle_modal_input() -> void:
	if not is_modal_open():
		return
	if Input.is_action_just_pressed("cancel_modal") or Input.is_action_just_pressed("toggle_inventory"):
		close_shop()
		return
	for index in range(GameState.HOTBAR_SLOTS):
		if Input.is_action_just_pressed("slot_%s" % (index + 1)):
			_buy_shop_index(index)
			return


func open_shop(shop_id: String, npc_id: String = "") -> void:
	if shop_id.is_empty():
		return
	active_shop_id = shop_id
	active_shopkeeper_id = npc_id
	shop_panel.visible = true
	inventory_open = false
	inventory_panel.visible = false
	_refresh_help()
	_refresh_shop()


func close_shop() -> void:
	active_shop_id = ""
	active_shopkeeper_id = ""
	shop_panel.visible = false
	_refresh_help()


func _refresh_all() -> void:
	_refresh_status()
	_refresh_help()
	_refresh_hotbar()
	_refresh_inventory()
	_refresh_quest()
	_refresh_shop()


func _refresh_status() -> void:
	status_label.text = "Day %s  %s  Money %sg  Map %s" % [
		ClockService.day,
		GameState.format_time(ClockService.time_minutes),
		EconomyService.money,
		SceneRouter.current_map_id.capitalize()
	]


func _refresh_help() -> void:
	if is_modal_open():
		help_label.text = "Shop 1-8 Buy  Tab/Esc Close"
	else:
		help_label.text = "Move WASD  Use F  Interact E  Inventory Tab  Save F5"


func _refresh_hotbar() -> void:
	hotbar_label.text = _build_hotbar_text()


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


func _refresh_quest() -> void:
	quest_label.text = QuestService.get_tracking_text()


func _refresh_shop() -> void:
	if not is_modal_open():
		return
	if not active_shopkeeper_id.is_empty() and not NpcService.is_shop_open(active_shop_id, active_shopkeeper_id):
		close_shop()
		push_message("Mae has stepped away from the counter.")
		return
	var shop = GameState.get_shop_data(active_shop_id)
	if shop == null:
		shop_label.text = "Shop unavailable."
		return
	var lines := [shop.display_name]
	if not String(shop.greeting).is_empty():
		lines.append(shop.greeting)
	lines.append("")
	for index in range(shop.stock.size()):
		var entry: Dictionary = shop.stock[index]
		var item_id := String(entry.get("item_id", ""))
		var item = GameState.get_item_data(item_id)
		var purchased := EconomyService.get_purchase_count(active_shop_id, item_id)
		var daily_limit := int(entry.get("daily_limit", 0))
		var remaining_text := "no limit" if daily_limit <= 0 else "%s left" % max(0, daily_limit - purchased)
		lines.append("%s. %s  %sg  %s" % [
			index + 1,
			item.display_name if item else item_id,
			int(entry.get("price", 0)),
			remaining_text
		])
	lines.append("")
	lines.append("Money: %sg" % EconomyService.money)
	lines.append("Press 1-%s to buy one item." % min(GameState.HOTBAR_SLOTS, shop.stock.size()))
	shop_label.text = "\n".join(lines)


func _buy_shop_index(index: int) -> void:
	var shop = GameState.get_shop_data(active_shop_id)
	if shop == null:
		return
	if index < 0 or index >= shop.stock.size():
		return
	var entry: Dictionary = shop.stock[index]
	ActionCoordinator.purchase_shop_item(active_shop_id, String(entry.get("item_id", "")), 1, active_shopkeeper_id)
	_refresh_all()


func _on_runtime_changed(_day: int, _time_minutes: int) -> void:
	_refresh_status()


func _on_money_changed(_amount: int) -> void:
	_refresh_status()
	_refresh_shop()


func _on_inventory_changed() -> void:
	_refresh_hotbar()
	if inventory_open:
		_refresh_inventory()


func _on_selection_changed(_index: int) -> void:
	_refresh_hotbar()


func _on_map_changed(_map_id: String) -> void:
	_refresh_status()


func _on_quest_changed() -> void:
	_refresh_quest()


func _on_shipments_changed() -> void:
	_refresh_shop()
