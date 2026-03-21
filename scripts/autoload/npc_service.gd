extends Node

signal npc_states_changed

var npc_states := {}


func _ready() -> void:
	if not ClockService.clock_changed.is_connected(_on_clock_changed):
		ClockService.clock_changed.connect(_on_clock_changed)
	if not ClockService.day_advanced.is_connected(_on_day_advanced):
		ClockService.day_advanced.connect(_on_day_advanced)


func reset_state() -> void:
	npc_states = {}
	refresh_states()


func load_state(payload: Dictionary) -> void:
	refresh_states()


func build_save_data() -> Dictionary:
	return {}


func refresh_states() -> void:
	var next_states := {}
	for npc_id in GameState.npc_defs.keys():
		var npc = GameState.get_npc_data(String(npc_id))
		if npc == null:
			continue
		var schedule = GameState.get_schedule_data(String(npc.schedule_id))
		if schedule == null or schedule.entries.is_empty():
			next_states[String(npc_id)] = {
				"map_id": String(npc.home_map_id),
				"cell": {"x": 0, "y": 0},
				"facing": "down",
				"current_entry_index": -1,
				"interaction_mode": "talk"
			}
			continue
		var entry_index := _find_active_entry_index(schedule.entries, ClockService.time_minutes)
		var entry: Dictionary = schedule.entries[entry_index]
		next_states[String(npc_id)] = {
			"map_id": String(entry.get("map_id", npc.home_map_id)),
			"cell": _normalize_cell(entry.get("cell", {"x": 0, "y": 0})),
			"facing": String(entry.get("facing", "down")),
			"current_entry_index": entry_index,
			"interaction_mode": String(entry.get("behavior", "talk"))
		}
	npc_states = next_states
	npc_states_changed.emit()


func get_npc_state(npc_id: String) -> Dictionary:
	return npc_states.get(npc_id, {})


func get_npcs_for_map(map_id: String) -> Array:
	var projections: Array = []
	for npc_id in npc_states.keys():
		var state: Dictionary = npc_states[npc_id]
		if String(state.get("map_id", "")) != map_id:
			continue
		var npc = GameState.get_npc_data(String(npc_id))
		if npc == null:
			continue
		projections.append({
			"npc_id": String(npc_id),
			"display_name": String(npc.display_name),
			"shop_id": String(npc.shop_id),
			"state": state.duplicate(true)
		})
	return projections


func is_shop_open(shop_id: String, npc_id: String = "") -> bool:
	if not npc_id.is_empty():
		var npc = GameState.get_npc_data(npc_id)
		var state := get_npc_state(npc_id)
		return npc != null and String(npc.shop_id) == shop_id and String(state.get("interaction_mode", "")) == "shop"
	for known_npc_id in npc_states.keys():
		var npc = GameState.get_npc_data(String(known_npc_id))
		if npc == null or String(npc.shop_id) != shop_id:
			continue
		var state: Dictionary = npc_states[known_npc_id]
		if String(state.get("interaction_mode", "")) == "shop":
			return true
	return false


func interact_with_npc(npc_id: String) -> Dictionary:
	var npc = GameState.get_npc_data(npc_id)
	if npc == null:
		return _result(false, "Nobody is here.")
	var quest_result := QuestService.handle_npc_interaction(npc_id)
	var state := get_npc_state(npc_id)
	var interaction_mode := String(state.get("interaction_mode", "talk"))
	var open_shop := interaction_mode == "shop" and not String(npc.shop_id).is_empty()
	var directives := {}
	if open_shop:
		directives["open_shop"] = {
			"shop_id": String(npc.shop_id),
			"npc_id": npc_id
		}
	return _result(
		true,
		String(quest_result.get("message", npc.default_dialogue if not String(npc.default_dialogue).is_empty() else "%s nods at you." % npc.display_name)),
		0,
		quest_result.get("events", []),
		directives
	)


func _find_active_entry_index(entries: Array, time_minutes: int) -> int:
	var active_index := 0
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		if time_minutes >= int(entry.get("start_minutes", 0)):
			active_index = index
	return active_index


func _normalize_cell(value) -> Dictionary:
	if value is Vector2i:
		return {"x": value.x, "y": value.y}
	if value is Dictionary:
		return {"x": int(value.get("x", 0)), "y": int(value.get("y", 0))}
	return {"x": 0, "y": 0}


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}


func _on_clock_changed(_day: int, _time_minutes: int) -> void:
	refresh_states()


func _on_day_advanced(_day: int) -> void:
	refresh_states()
