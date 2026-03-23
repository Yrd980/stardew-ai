extends Node

signal quest_log_changed

var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var quest_progress := {}


func _ready() -> void:
	if not FarmService.crop_harvested.is_connected(_on_crop_harvested):
		FarmService.crop_harvested.connect(_on_crop_harvested)
	if not EconomyService.purchase_completed.is_connected(_on_purchase_completed):
		EconomyService.purchase_completed.connect(_on_purchase_completed)
	if not EconomyService.shipment_settled.is_connected(_on_shipment_settled):
		EconomyService.shipment_settled.connect(_on_shipment_settled)
	if not ClockService.day_advanced.is_connected(_on_day_advanced):
		ClockService.day_advanced.connect(_on_day_advanced)


func reset_state() -> void:
	active_quests = []
	completed_quests = []
	quest_progress = {}
	quest_log_changed.emit()


func load_state(payload: Dictionary) -> void:
	active_quests = payload.get("active_quests", []).duplicate(true)
	completed_quests = payload.get("completed_quests", []).duplicate(true)
	quest_progress = payload.get("quest_progress", {}).duplicate(true)
	quest_log_changed.emit()


func build_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(true),
		"quest_progress": quest_progress.duplicate(true)
	}


func handle_npc_interaction(npc_id: String) -> Dictionary:
	var ready_quest_id := _find_ready_to_turn_in(npc_id)
	if not ready_quest_id.is_empty():
		return _complete_quest(ready_quest_id)
	var offered_quest_id := _find_offerable_quest(npc_id)
	if not offered_quest_id.is_empty():
		_activate_quest(offered_quest_id)
		record_event("npc_talked_to", {"npc_id": npc_id})
		var quest = GameState.get_quest_data(offered_quest_id)
		var progress_state: Dictionary = quest_progress.get(offered_quest_id, {})
		var accepted_message := "Quest started: %s." % (quest.title if quest else offered_quest_id)
		if progress_state.get("ready_to_turn_in", false):
			accepted_message += " Talk again to turn it in."
		return _result(true, accepted_message, 0, [{"type": "quest_accepted", "quest_id": offered_quest_id}])
	record_event("npc_talked_to", {"npc_id": npc_id})
	var active_quest_id := _find_active_quest_for_npc(npc_id)
	if not active_quest_id.is_empty():
		return _result(true, _build_progress_message(active_quest_id))
	var npc = GameState.get_npc_data(npc_id)
	return _result(true, npc.default_dialogue if npc else "Hello there.")


func has_completed_quest(quest_id: String) -> bool:
	return completed_quests.has(quest_id)


func record_event(event_type: String, payload: Dictionary) -> void:
	var changed := false
	for quest_id in active_quests:
		var quest = GameState.get_quest_data(quest_id)
		if quest == null:
			continue
		var state: Dictionary = quest_progress.get(quest_id, {})
		if state.get("ready_to_turn_in", false):
			continue
		var counts: Array = state.get("step_counts", []).duplicate(true)
		var steps: Array = quest.steps
		for index in range(steps.size()):
			var step: Dictionary = steps[index]
			if not _event_matches_step(event_type, payload, step):
				continue
			var current_count := int(counts[index])
			var required_count := int(step.get("required_count", 1))
			counts[index] = min(required_count, current_count + int(payload.get("count", 1)))
			changed = true
		state["step_counts"] = counts
		state["ready_to_turn_in"] = _is_quest_ready(quest, state)
		quest_progress[quest_id] = state
	if changed:
		quest_log_changed.emit()


func get_tracking_text() -> String:
	if active_quests.is_empty():
		return "Quest: Visit the merchant to get started."
	var quest_id := active_quests[0]
	var quest = GameState.get_quest_data(quest_id)
	if quest == null:
		return "Quest: %s" % quest_id
	var state: Dictionary = quest_progress.get(quest_id, {})
	if state.get("ready_to_turn_in", false):
		return "Quest: %s (Talk to %s)" % [quest.title, quest.giver_npc_id.capitalize()]
	var parts: Array = []
	var counts: Array = state.get("step_counts", [])
	for index in range(quest.steps.size()):
		var step: Dictionary = quest.steps[index]
		parts.append("%s/%s" % [int(counts[index]), int(step.get("required_count", 1))])
	return "Quest: %s [%s]" % [quest.title, ", ".join(parts)]


func _activate_quest(quest_id: String) -> void:
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return
	var quest = GameState.get_quest_data(quest_id)
	if quest == null:
		return
	var counts: Array = []
	for _step in quest.steps:
		counts.append(0)
	active_quests.append(quest_id)
	quest_progress[quest_id] = {"step_counts": counts, "ready_to_turn_in": false}
	quest_log_changed.emit()


func _complete_quest(quest_id: String) -> Dictionary:
	var quest = GameState.get_quest_data(quest_id)
	if quest == null:
		return _result(true, "Quest complete.", 0, [{"type": "quest_completed", "quest_id": quest_id}])
	var reward_summary := _grant_rewards(quest.rewards)
	active_quests.erase(quest_id)
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
	quest_progress.erase(quest_id)
	quest_log_changed.emit()
	var message := "Quest complete: %s." % quest.title
	if not reward_summary.is_empty():
		message += " %s" % reward_summary.get("message", "")
	return _result(true, message, 0, [{
		"type": "quest_completed",
		"quest_id": quest_id,
		"rewards": reward_summary.get("rewards", [])
	}])


func _grant_rewards(rewards: Array) -> Dictionary:
	var granted: Array = []
	var total_money := 0
	for reward in rewards:
		if reward.has("money"):
			var amount := int(reward.get("money", 0))
			EconomyService.add_money(amount)
			total_money += amount
			granted.append({"money": amount})
		elif reward.has("item_id"):
			var item_id := String(reward.get("item_id", ""))
			var count := int(reward.get("count", 1))
			if InventoryService.can_add_item(item_id, count):
				InventoryService.add_item(item_id, count)
				granted.append({"item_id": item_id, "count": count})
	var parts: Array[String] = []
	if total_money > 0:
		parts.append("%sg" % total_money)
	for reward in granted:
		if reward.has("item_id"):
			var item = GameState.get_item_data(String(reward.get("item_id", "")))
			parts.append("%s x%s" % [item.display_name if item else reward.get("item_id", ""), int(reward.get("count", 1))])
	return {
		"rewards": granted,
		"message": "" if parts.is_empty() else "Rewards: %s." % ", ".join(parts)
	}


func _find_offerable_quest(npc_id: String) -> String:
	var quest_ids := GameState.quest_defs.keys()
	quest_ids.sort()
	for quest_id_variant in quest_ids:
		var quest_id := String(quest_id_variant)
		if active_quests.has(quest_id) or completed_quests.has(quest_id):
			continue
		var quest = GameState.get_quest_data(quest_id)
		if quest == null or String(quest.giver_npc_id) != npc_id:
			continue
		if _prerequisites_met(quest):
			return quest_id
	return ""


func _find_ready_to_turn_in(npc_id: String) -> String:
	for quest_id in active_quests:
		var quest = GameState.get_quest_data(quest_id)
		if quest == null or String(quest.giver_npc_id) != npc_id:
			continue
		if quest_progress.get(quest_id, {}).get("ready_to_turn_in", false):
			return quest_id
	return ""


func _find_active_quest_for_npc(npc_id: String) -> String:
	for quest_id in active_quests:
		var quest = GameState.get_quest_data(quest_id)
		if quest != null and String(quest.giver_npc_id) == npc_id:
			return quest_id
	return ""


func _prerequisites_met(quest) -> bool:
	for quest_id in quest.prerequisite_ids:
		if not completed_quests.has(quest_id):
			return false
	return true


func _is_quest_ready(quest, state: Dictionary) -> bool:
	var counts: Array = state.get("step_counts", [])
	for index in range(quest.steps.size()):
		var step: Dictionary = quest.steps[index]
		if int(counts[index]) < int(step.get("required_count", 1)):
			return false
	return true


func _event_matches_step(event_type: String, payload: Dictionary, step: Dictionary) -> bool:
	if String(step.get("event_type", "")) != event_type:
		return false
	var target_id := String(step.get("target_id", ""))
	if target_id.is_empty():
		return true
	return target_id == String(payload.get("npc_id", payload.get("item_id", payload.get("shop_id", ""))))


func _build_progress_message(quest_id: String) -> String:
	var quest = GameState.get_quest_data(quest_id)
	if quest == null:
		return "Keep going."
	var state: Dictionary = quest_progress.get(quest_id, {})
	if state.get("ready_to_turn_in", false):
		return "You're ready to turn in %s." % quest.title
	return "Working on %s." % quest.title


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}


func _on_crop_harvested(event: Dictionary) -> void:
	record_event("crop_harvested", event)


func _on_purchase_completed(result: Dictionary) -> void:
	var events: Array = result.get("events", [])
	for event in events:
		record_event(String(event.get("type", "")), event)


func _on_shipment_settled(summary: Dictionary) -> void:
	for shipment in summary.get("shipments", []):
		record_event("shipment_settled", {
			"item_id": String(shipment.get("item_id", "")),
			"count": int(shipment.get("count", 0))
		})


func _on_day_advanced(_day: int) -> void:
	record_event("day_advanced", {"count": 1})
