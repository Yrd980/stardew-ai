class_name SaveCodec
extends RefCounted

const CURRENT_SAVE_VERSION := 3

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
	return decoded
