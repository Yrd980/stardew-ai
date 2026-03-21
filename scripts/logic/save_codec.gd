class_name SaveCodec
extends RefCounted

const CURRENT_SAVE_VERSION := 2

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
			"pending_shipments": [],
			"shop_purchase_counts": {},
			"last_settlement_summary": {}
		}
	if not decoded.has("npcs"):
		decoded["npcs"] = {"npc_states": {}}
	if not decoded.has("quests"):
		decoded["quests"] = {
			"active_quests": [],
			"completed_quests": [],
			"quest_progress": {}
		}
	return decoded
