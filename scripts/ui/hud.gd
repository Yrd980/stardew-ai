extends Control

var message_timer := 0.0

@onready var status_label: Label = $TopBar/StatusLabel
@onready var help_label: Label = $TopBar/HelpLabel
@onready var quest_label: Label = $TopBar/QuestLabel
@onready var hotbar_label: Label = $BottomBar/HotbarLabel
@onready var message_label: Label = $BottomBar/MessageLabel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_label: Label = $InventoryPanel/InventoryLabel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_label: Label = $ShopPanel/ShopLabel
@onready var container_panel: PanelContainer = $ContainerPanel
@onready var container_label: Label = $ContainerPanel/ContainerLabel
@onready var crafting_panel: PanelContainer = $CraftingPanel
@onready var crafting_label: Label = $CraftingPanel/CraftingLabel
@onready var delivery_panel: PanelContainer = $DeliveryPanel
@onready var delivery_label: Label = $DeliveryPanel/DeliveryLabel


func _ready() -> void:
	inventory_panel.visible = false
	shop_panel.visible = false
	container_panel.visible = false
	crafting_panel.visible = false
	delivery_panel.visible = false
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
	if not CraftingService.crafting_changed.is_connected(_on_crafting_changed):
		CraftingService.crafting_changed.connect(_on_crafting_changed)
	if not MailService.deliveries_changed.is_connected(_on_deliveries_changed):
		MailService.deliveries_changed.connect(_on_deliveries_changed)
	if not ActionCoordinator.message_requested.is_connected(push_message):
		ActionCoordinator.message_requested.connect(push_message)
	if not UiSessionService.session_changed.is_connected(_on_session_changed):
		UiSessionService.session_changed.connect(_on_session_changed)
	_refresh_all()


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer = max(0.0, message_timer - delta)
		if message_timer == 0.0:
			message_label.text = ""


func toggle_inventory() -> void:
	UiSessionService.toggle_inventory()


func push_message(message: String) -> void:
	message_label.text = message
	message_timer = 3.5


func is_modal_open() -> bool:
	return UiSessionService.is_modal_open()


func handle_modal_input() -> void:
	if not is_modal_open():
		return
	if Input.is_action_just_pressed("cancel_modal") or Input.is_action_just_pressed("toggle_inventory"):
		UiSessionService.close_modal()
		return
	if UiSessionService.get_active_shop_id() != "":
		for index in range(GameState.HOTBAR_SLOTS):
			if Input.is_action_just_pressed("slot_%s" % (index + 1)):
				_buy_shop_index(index)
				return
		return
	if UiSessionService.get_active_container_id() != "":
		if Input.is_action_just_pressed("use_tool"):
			ActionCoordinator.run_action_request({
				"type": "container_store_selected",
				"container_id": UiSessionService.get_active_container_id()
			})
			_refresh_all()
			return
		for index in range(GameState.HOTBAR_SLOTS):
			if Input.is_action_just_pressed("slot_%s" % (index + 1)):
				ActionCoordinator.run_action_request({
					"type": "container_take_slot",
					"container_id": UiSessionService.get_active_container_id(),
					"slot_index": index
				})
				_refresh_all()
				return
		return
	if UiSessionService.is_crafting_open():
		var recipes := CraftingService.get_available_recipes()
		for index in range(min(GameState.HOTBAR_SLOTS, recipes.size())):
			if Input.is_action_just_pressed("slot_%s" % (index + 1)):
				ActionCoordinator.run_action_request({
					"type": "craft_recipe",
					"recipe_id": String(recipes[index].id)
				})
				_refresh_all()
				return
		return
	if UiSessionService.is_delivery_open() and Input.is_action_just_pressed("slot_1"):
		ActionCoordinator.run_action_request({"type": "claim_delivery"})
		_refresh_all()


func open_shop(shop_id: String, npc_id: String = "") -> void:
	UiSessionService.open_shop(shop_id, npc_id)


func close_shop() -> void:
	UiSessionService.close_shop()


func _refresh_all() -> void:
	_refresh_status()
	_refresh_help()
	_refresh_hotbar()
	_refresh_inventory()
	_refresh_quest()
	_refresh_shop()
	_refresh_container()
	_refresh_crafting()
	_refresh_delivery()


func _refresh_status() -> void:
	status_label.text = "Day %s  %s  Money %sg  Map %s" % [
		ClockService.day,
		GameState.format_time(ClockService.time_minutes),
		EconomyService.money,
		SceneRouter.current_map_id.capitalize()
	]
	if EconomyService.lifetime_earnings > 0:
		status_label.text += "  Earned %sg" % EconomyService.lifetime_earnings


func _refresh_help() -> void:
	if UiSessionService.get_active_shop_id() != "":
		help_label.text = "Shop 1-8 Buy  Tab/Esc Close"
	elif UiSessionService.get_active_container_id() != "":
		help_label.text = "Chest 1-8 Take  F Store selected  Tab/Esc Close"
	elif UiSessionService.is_crafting_open():
		help_label.text = "Crafting 1-8 Craft  Tab/Esc Close"
	elif UiSessionService.is_delivery_open():
		help_label.text = "Delivery 1 Claim  Tab/Esc Close"
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
			label = "%s x%s" % [_format_item_name(item_id, String(slot.get("quality", "normal"))), int(slot.get("count", 0))]
		lines.append("%s%s. %s" % [marker, index + 1, label])
	return "\n".join(lines)


func _refresh_inventory() -> void:
	var lines := ["Inventory"]
	for index in range(InventoryService.slots.size()):
		var slot: Dictionary = InventoryService.get_slot(index)
		var item_id := String(slot.get("item_id", ""))
		var label := "--"
		if not item_id.is_empty():
			label = "%s x%s" % [_format_item_name(item_id, String(slot.get("quality", "normal"))), int(slot.get("count", 0))]
		lines.append("%s. %s" % [index + 1, label])
	inventory_label.text = "\n".join(lines)
	inventory_panel.visible = UiSessionService.is_inventory_open()


func _refresh_quest() -> void:
	quest_label.text = QuestService.get_tracking_text()


func _refresh_shop() -> void:
	if UiSessionService.get_active_shop_id().is_empty():
		shop_panel.visible = false
		return
	shop_panel.visible = true
	container_panel.visible = false
	crafting_panel.visible = false
	delivery_panel.visible = false
	var active_shop_id := UiSessionService.get_active_shop_id()
	var active_shopkeeper_id := UiSessionService.get_active_shopkeeper_id()
	if not active_shopkeeper_id.is_empty() and not NpcService.is_shop_open(active_shop_id, active_shopkeeper_id):
		UiSessionService.close_modal()
		push_message("%s has stepped away from the counter." % _get_shopkeeper_name(active_shopkeeper_id))
		return
	var shop = GameState.get_shop_data(active_shop_id)
	if shop == null:
		shop_label.text = "Shop unavailable."
		return
	var lines := [shop.display_name]
	if not String(shop.greeting).is_empty():
		lines.append(shop.greeting)
	lines.append("")
	var visible_stock := EconomyService.get_available_shop_stock(active_shop_id)
	for index in range(visible_stock.size()):
		var entry: Dictionary = visible_stock[index]
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
	for entry in shop.stock:
		if EconomyService.is_stock_entry_available(entry):
			continue
		var item_id := String(entry.get("item_id", ""))
		var item = GameState.get_item_data(item_id)
		lines.append("- %s  %s" % [
			item.display_name if item else item_id,
			EconomyService.describe_stock_requirement(entry)
		])
	lines.append("")
	lines.append("Money: %sg" % EconomyService.money)
	lines.append("Press 1-%s to buy one item." % min(GameState.HOTBAR_SLOTS, visible_stock.size()))
	shop_label.text = "\n".join(lines)


func _refresh_container() -> void:
	if UiSessionService.get_active_container_id().is_empty():
		container_panel.visible = false
		return
	container_panel.visible = true
	shop_panel.visible = false
	crafting_panel.visible = false
	delivery_panel.visible = false
	var lines := ["Chest", "", "F. Store selected stack"]
	var slots: Array = WorldState.get_container_slots(UiSessionService.get_active_container_id())
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		var item_id := String(slot.get("item_id", ""))
		var label := "--"
		if not item_id.is_empty():
			label = "%s x%s" % [_format_item_name(item_id, String(slot.get("quality", "normal"))), int(slot.get("count", 0))]
		lines.append("%s. %s" % [index + 1, label])
	container_label.text = "\n".join(lines)


func _refresh_crafting() -> void:
	if not UiSessionService.is_crafting_open():
		crafting_panel.visible = false
		return
	crafting_panel.visible = true
	shop_panel.visible = false
	container_panel.visible = false
	delivery_panel.visible = false
	var lines := ["Workbench", ""]
	var recipes := CraftingService.get_available_recipes()
	if recipes.is_empty():
		lines.append("No recipes unlocked yet.")
	else:
		for index in range(min(GameState.HOTBAR_SLOTS, recipes.size())):
			var recipe = recipes[index]
			lines.append("%s. %s" % [index + 1, _format_recipe_line(recipe)])
	lines.append("")
	lines.append("Permits arrive through the delivery box.")
	crafting_label.text = "\n".join(lines)


func _refresh_delivery() -> void:
	if not UiSessionService.is_delivery_open():
		delivery_panel.visible = false
		return
	delivery_panel.visible = true
	shop_panel.visible = false
	container_panel.visible = false
	crafting_panel.visible = false
	var lines := ["Delivery Box", ""]
	var claimable := MailService.get_claimable_deliveries()
	if claimable.is_empty():
		lines.append("Nothing is ready today.")
	else:
		lines.append("1. Claim %s" % String(claimable[0].get("title", "Delivery")))
	if MailService.pending_deliveries.size() > claimable.size():
		lines.append("")
		lines.append("More orders are still in transit.")
	delivery_label.text = "\n".join(lines)


func _buy_shop_index(index: int) -> void:
	var active_shop_id := UiSessionService.get_active_shop_id()
	var active_shopkeeper_id := UiSessionService.get_active_shopkeeper_id()
	var visible_stock := EconomyService.get_available_shop_stock(active_shop_id)
	if index < 0 or index >= visible_stock.size():
		return
	var entry: Dictionary = visible_stock[index]
	ActionCoordinator.purchase_shop_item(active_shop_id, String(entry.get("item_id", "")), 1, active_shopkeeper_id)
	_refresh_all()


func _get_shopkeeper_name(npc_id: String) -> String:
	var npc = GameState.get_npc_data(npc_id)
	return npc.display_name if npc else npc_id.capitalize()


func _on_runtime_changed(_day: int, _time_minutes: int) -> void:
	_refresh_status()


func _on_money_changed(_amount: int) -> void:
	_refresh_status()
	_refresh_shop()


func _on_inventory_changed() -> void:
	_refresh_hotbar()
	if UiSessionService.is_inventory_open():
		_refresh_inventory()
	if UiSessionService.get_active_container_id() != "":
		_refresh_container()


func _on_selection_changed(_index: int) -> void:
	_refresh_hotbar()


func _on_map_changed(_map_id: String) -> void:
	_refresh_status()


func _on_quest_changed() -> void:
	_refresh_quest()


func _on_shipments_changed() -> void:
	_refresh_shop()


func _on_crafting_changed() -> void:
	_refresh_crafting()


func _on_deliveries_changed() -> void:
	_refresh_delivery()


func _on_session_changed() -> void:
	_refresh_help()
	_refresh_inventory()
	_refresh_shop()
	_refresh_container()
	_refresh_crafting()
	_refresh_delivery()


func _format_item_name(item_id: String, quality: String) -> String:
	var item = GameState.get_item_data(item_id)
	var display_name: String = item.display_name if item else item_id
	match quality:
		"silver":
			return "Silver %s" % display_name
		"gold":
			return "Gold %s" % display_name
		_:
			return display_name


func _format_recipe_line(recipe) -> String:
	var ingredient_parts := []
	for ingredient in recipe.ingredients:
		var item_id := String(ingredient.get("item_id", ""))
		var item = GameState.get_item_data(item_id)
		ingredient_parts.append("%s x%s" % [item.display_name if item else item_id, int(ingredient.get("count", 1))])
	return "%s (%s)" % [recipe.display_name, ", ".join(ingredient_parts)]
