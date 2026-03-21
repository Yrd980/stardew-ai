extends SceneTree

const InventoryLogicScript = preload("res://scripts/logic/inventory_logic.gd")
const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")
const SaveCodecScript = preload("res://scripts/logic/save_codec.gd")
const CropDataScript = preload("res://scripts/data/crop_data.gd")

var inventory_logic = InventoryLogicScript.new()
var crop_logic = CropLogicScript.new()
var save_codec = SaveCodecScript.new()


func _init() -> void:
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	_ensure_runtime_ready()
	_run_inventory_tests()
	_run_crop_tests()
	_run_save_codec_tests()
	_run_resource_contract_tests()
	_run_service_contract_tests()
	_run_action_coordinator_tests()
	_run_architecture_boundary_tests()
	print("TESTS PASSED")
	quit()


func _ensure_runtime_ready() -> void:
	if _game_state().item_defs.is_empty():
		_game_state().load_databases()
	_game_state().start_new_game()


func _game_state():
	return get_root().get_node("GameState")


func _clock_service():
	return get_root().get_node("ClockService")


func _inventory_service():
	return get_root().get_node("InventoryService")


func _world_state():
	return get_root().get_node("WorldState")


func _save_manager():
	return get_root().get_node("SaveManager")


func _farm_service():
	return get_root().get_node("FarmService")


func _economy_service():
	return get_root().get_node("EconomyService")


func _npc_service():
	return get_root().get_node("NpcService")


func _action_coordinator():
	return get_root().get_node("ActionCoordinator")


func _scene_router():
	return get_root().get_node("SceneRouter")


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _run_inventory_tests() -> void:
	var slots: Array = inventory_logic.empty_slots(3)
	var result: Dictionary = inventory_logic.add_item(slots, "parsnip", 12, 10)
	_assert_true(int(result["leftover"]) == 0, "inventory should fit across two stacks")
	var next_slots: Array = result["slots"]
	_assert_true(next_slots[0]["count"] == 10 and next_slots[1]["count"] == 2, "inventory stacking failed")
	next_slots = inventory_logic.remove_amount(next_slots, 0, 10)
	_assert_true(String(next_slots[0]["item_id"]).is_empty(), "slot should clear when count reaches zero")


func _run_crop_tests() -> void:
	var crop_def = CropDataScript.new()
	crop_def.id = "parsnip_crop"
	crop_def.growth_days = PackedInt32Array([1, 1, 1, 1])
	var soils: Dictionary = {"farm": {"5,5": {"tilled": true, "watered": true}}}
	var crops: Dictionary = {"farm": {"5,5": {"crop_id": "parsnip_crop", "days_watered": 0}}}
	var next_day: Dictionary = crop_logic.advance_world(soils, crops, {"parsnip_crop": crop_def})
	_assert_true(int(next_day["crops_by_map"]["farm"]["5,5"]["days_watered"]) == 1, "watered crop should advance")
	_assert_true(not next_day["soils_by_map"]["farm"]["5,5"]["watered"], "soil should dry overnight")
	_assert_true(crop_logic.get_stage(4, crop_def) == 3, "final crop stage should be last stage")


func _run_save_codec_tests() -> void:
	var payload: Dictionary = {
		"save_version": 2,
		"clock": {"day": 2, "time_minutes": 420},
		"inventory": {"slots": [{"item_id": "parsnip", "count": 3}], "selected_index": 0},
		"economy": {"money": 250, "pending_shipments": [], "shop_purchase_counts": {}, "last_settlement_summary": {}},
		"quests": {"active_quests": [], "completed_quests": [], "quest_progress": {}}
	}
	var encoded: Dictionary = save_codec.encode_state(payload)
	var decoded: Dictionary = save_codec.decode_state(encoded)
	_assert_true(decoded["clock"]["day"] == 2, "save decode should preserve nested data")
	_assert_true(decoded["inventory"]["slots"][0]["item_id"] == "parsnip", "save decode should preserve item id")
	_assert_true(decoded.has("economy") and decoded.has("quests"), "save decode should migrate runtime sections")
	_assert_true(int(decoded["economy"]["money"]) == 250, "save decode should preserve money ownership inside economy")


func _run_resource_contract_tests() -> void:
	var merchant = load("res://resources/npcs/merchant.tres")
	var schedule = load("res://resources/schedules/merchant_daily.tres")
	var shop = load("res://resources/shops/mae_seed_shop.tres")
	var quest_1 = load("res://resources/quests/01_meet_merchant.tres")
	var quest_2 = load("res://resources/quests/02_buy_first_seeds.tres")
	var quest_3 = load("res://resources/quests/03_ship_first_crop.tres")
	_assert_true(merchant != null and schedule != null and shop != null, "new NPC and shop resources should load")
	_assert_true(String(merchant.schedule_id) == "merchant_daily", "merchant should point at its schedule")
	_assert_true(schedule.entries.size() == 3, "merchant schedule should have morning, daytime, and evening slots")
	_assert_true(shop.stock.size() == 1 and String(shop.stock[0]["item_id"]) == "parsnip_seeds", "starter shop stock should sell parsnip seeds")
	_assert_true(quest_1 != null and quest_2 != null and quest_3 != null, "starter quest chain resources should load")
	_assert_true(quest_2.prerequisite_ids.has("01_meet_merchant"), "quest chain should require meeting Mae before shopping")
	_assert_true(quest_3.prerequisite_ids.has("02_buy_first_seeds"), "shipping quest should come after buying seeds")


func _run_service_contract_tests() -> void:
	_reset_runtime()
	var till_result: Dictionary = _farm_service().till_cell("farm", Vector2i(5, 10))
	_assert_action_result_shape(till_result, "farm till")
	_assert_true(till_result.get("success", false), "farm till should succeed on empty soil")

	_reset_runtime()
	_clock_service().load_state({"day": 1, "time_minutes": 360})
	var purchase_result: Dictionary = _economy_service().purchase_item("mae_seed_shop", "parsnip_seeds", 1)
	_assert_action_result_shape(purchase_result, "economy purchase")
	_assert_true(purchase_result.get("success", false), "purchase should succeed while the shop is open")

	var npc_result: Dictionary = _npc_service().interact_with_npc("merchant")
	_assert_action_result_shape(npc_result, "npc interaction")
	_assert_true(npc_result.get("directives", {}).has("open_shop"), "merchant interaction should request opening the shop when available")

	_inventory_service().reset_inventory(_game_state().INVENTORY_SLOTS)
	_inventory_service().add_item("parsnip", 1)
	_inventory_service().select_slot(0)
	var ship_result: Dictionary = _economy_service().queue_selected_stack_for_shipping()
	_assert_action_result_shape(ship_result, "queue shipment")
	_assert_true(ship_result.get("success", false), "shipping should queue a sellable item")

	var sleep_result: Dictionary = _clock_service().sleep_and_advance_day()
	_assert_action_result_shape(sleep_result, "sleep")
	_assert_true(sleep_result.get("events", []).size() >= 1, "sleep should report its day-advance event")


func _run_action_coordinator_tests() -> void:
	_reset_runtime()
	var start_minutes: int = int(_clock_service().time_minutes)
	var till_result: Dictionary = _action_coordinator().use_selected_slot("farm", Vector2i(5, 10), true)
	_assert_true(till_result.get("success", false), "coordinator should route hoe use through the farm service")
	_assert_true(int(_clock_service().time_minutes) == start_minutes + 5, "coordinator should advance time for successful tool actions")
	_assert_true(_world_state().get_soil("farm", Vector2i(5, 10)).get("tilled", false), "coordinator should mutate world state through the service layer")

	_reset_runtime()
	_inventory_service().reset_inventory(_game_state().INVENTORY_SLOTS)
	_inventory_service().add_item("parsnip", 1)
	_inventory_service().select_slot(0)
	start_minutes = _clock_service().time_minutes
	var ship_result: Dictionary = _action_coordinator().run_action_request({"type": "ship_selected"})
	_assert_true(ship_result.get("success", false), "coordinator should route shipping requests")
	_assert_true(int(_clock_service().time_minutes) == start_minutes + 5, "coordinator should advance time for queued shipping")
	_assert_true(_economy_service().pending_shipments.size() == 1, "shipping request should queue exactly one shipment entry")

	_reset_runtime()
	_clock_service().load_state({"day": 1, "time_minutes": 570})
	start_minutes = _clock_service().time_minutes
	var purchase_result: Dictionary = _action_coordinator().purchase_shop_item("mae_seed_shop", "parsnip_seeds", 1, "merchant")
	_assert_true(purchase_result.get("success", false), "coordinator should route shop purchases")
	_assert_true(int(_clock_service().time_minutes) == start_minutes + 10, "coordinator should advance time for successful purchases")
	_assert_true(int(_economy_service().money) == _game_state().STARTING_MONEY - 20, "shop purchase should spend money through economy ownership")


func _run_architecture_boundary_tests() -> void:
	_reset_runtime()
	var save_snapshot: Dictionary = _save_manager().build_save_snapshot()
	_assert_true(save_snapshot.has("scene_router"), "save snapshot should persist the current map through scene router")
	_assert_true(not save_snapshot.has("npcs"), "save snapshot should not persist derived NPC projection state")
	_assert_true(not save_snapshot.get("world", {}).has("current_map_id"), "world save data should not own current map id anymore")

	_scene_router().set_current_map("farm")
	_scene_router().request_map_change("shop", "from_farm")
	_assert_true(_scene_router().current_map_id == "farm", "map change requests should not mutate map ownership before loading completes")

	_clock_service().load_state({"day": 1, "time_minutes": 360})
	_npc_service().load_state({
		"npc_states": {
			"merchant": {
				"map_id": "ghost",
				"cell": {"x": 99, "y": 99},
				"interaction_mode": "talk"
			}
		}
	})
	var merchant_state: Dictionary = _npc_service().get_npc_state("merchant")
	_assert_true(String(merchant_state.get("map_id", "")) == "farm", "npc state should be derived from the schedule after load")
	_assert_true(merchant_state.get("cell", {}).get("x", -1) == 6, "npc load should ignore stale persisted projection coordinates")


func _reset_runtime() -> void:
	_game_state().start_new_game()


func _assert_action_result_shape(result: Dictionary, label: String) -> void:
	_assert_true(result.has("success"), "%s should include success" % label)
	_assert_true(result.has("message"), "%s should include message" % label)
	_assert_true(result.has("time_cost"), "%s should include time_cost" % label)
	_assert_true(result.has("events"), "%s should include events" % label)
	_assert_true(result.has("directives"), "%s should include directives" % label)
