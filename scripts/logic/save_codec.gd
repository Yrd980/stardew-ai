class_name SaveCodec
extends RefCounted

const CURRENT_SAVE_VERSION := 5

func encode_state(payload: Dictionary) -> Dictionary:
	var encoded: Dictionary = payload.duplicate(true)
	encoded["save_version"] = int(encoded.get("save_version", CURRENT_SAVE_VERSION))
	return encoded


func decode_state(payload: Dictionary) -> Dictionary:
	var decoded: Dictionary = payload.duplicate(true)
	var save_version := int(decoded.get("save_version", 1))
	decoded["save_version"] = save_version
	if not decoded.has("economy"):
		decoded["economy"] = {
			"money": 250,
			"pending_shipments": [],
			"shop_purchase_counts": {},
			"last_settlement_summary": {},
			"lifetime_earnings": 0,
			"shipment_history": []
		}
	elif not decoded["economy"].has("money"):
		decoded["economy"]["money"] = 250
	if not decoded["economy"].has("pending_shipments"):
		decoded["economy"]["pending_shipments"] = []
	if not decoded["economy"].has("shop_purchase_counts"):
		decoded["economy"]["shop_purchase_counts"] = {}
	if not decoded["economy"].has("last_settlement_summary"):
		decoded["economy"]["last_settlement_summary"] = {}
	if not decoded["economy"].has("lifetime_earnings"):
		decoded["economy"]["lifetime_earnings"] = 0
	if not decoded["economy"].has("shipment_history"):
		decoded["economy"]["shipment_history"] = []
	if not decoded.has("quests"):
		decoded["quests"] = {
			"active_quests": [],
			"completed_quests": [],
			"quest_progress": {}
		}
	if not decoded.has("crafting"):
		decoded["crafting"] = {
			"known_recipe_ids": [],
			"unlocked_recipe_ids": []
		}
	if not decoded.has("mail"):
		decoded["mail"] = {
			"pending_deliveries": []
		}
	if not decoded.has("actors"):
		var scene_router_payload: Dictionary = decoded.get("scene_router", {})
		var world_payload: Dictionary = decoded.get("world", {})
		var player_positions: Dictionary = world_payload.get("player_positions", {})
		var current_map_id := String(scene_router_payload.get("current_map_id", "farm"))
		var player_position: Dictionary = player_positions.get(current_map_id, player_positions.get("farm", {"x": 160.0, "y": 208.0}))
		decoded["actors"] = {
			"player": {
				"map_id": current_map_id,
				"cell": {"x": 4, "y": 6},
				"world_position": {
					"x": float(player_position.get("x", 160.0)),
					"y": float(player_position.get("y", 208.0))
				},
				"facing": "down"
			}
		}
	elif not decoded["actors"].has("player"):
		decoded["actors"]["player"] = {
			"map_id": "farm",
			"cell": {"x": 4, "y": 6},
			"world_position": {"x": 160.0, "y": 208.0},
			"facing": "down"
		}
	if not decoded.has("world"):
		decoded["world"] = {}
	if not decoded["world"].has("player_positions"):
		decoded["world"]["player_positions"] = {}
	if not decoded["world"].has("soils_by_map"):
		decoded["world"]["soils_by_map"] = {}
	if not decoded["world"].has("crops_by_map"):
		decoded["world"]["crops_by_map"] = {}
	if not decoded["world"].has("placeables_by_map"):
		decoded["world"]["placeables_by_map"] = {}
	if not decoded["world"].has("containers_by_id"):
		decoded["world"]["containers_by_id"] = {}
	if not decoded.has("inventory"):
		decoded["inventory"] = {
			"slots": [],
			"selected_index": 0
		}
	var slots: Array = decoded["inventory"].get("slots", [])
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		if not slot.has("quality"):
			slot["quality"] = "normal"
		slots[index] = slot
	decoded["inventory"]["slots"] = slots
	return decoded
