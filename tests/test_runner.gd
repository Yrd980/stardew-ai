extends SceneTree

const InventoryLogicScript = preload("res://scripts/logic/inventory_logic.gd")
const CropLogicScript = preload("res://scripts/logic/crop_logic.gd")
const SaveCodecScript = preload("res://scripts/logic/save_codec.gd")
const CropDataScript = preload("res://scripts/data/crop_data.gd")

var inventory_logic = InventoryLogicScript.new()
var crop_logic = CropLogicScript.new()
var save_codec = SaveCodecScript.new()


func _init() -> void:
	_run_inventory_tests()
	_run_crop_tests()
	_run_save_codec_tests()
	_run_resource_contract_tests()
	print("TESTS PASSED")
	quit()


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
		"money": 250,
		"clock": {"day": 2, "time_minutes": 420},
		"inventory": {"slots": [{"item_id": "parsnip", "count": 3}], "selected_index": 0},
		"economy": {"pending_shipments": [], "shop_purchase_counts": {}, "last_settlement_summary": {}},
		"npcs": {"npc_states": {}},
		"quests": {"active_quests": [], "completed_quests": [], "quest_progress": {}}
	}
	var encoded: Dictionary = save_codec.encode_state(payload)
	var decoded: Dictionary = save_codec.decode_state(encoded)
	_assert_true(decoded["clock"]["day"] == 2, "save decode should preserve nested data")
	_assert_true(decoded["inventory"]["slots"][0]["item_id"] == "parsnip", "save decode should preserve item id")
	_assert_true(decoded.has("economy") and decoded.has("npcs") and decoded.has("quests"), "save decode should migrate new runtime sections")


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
