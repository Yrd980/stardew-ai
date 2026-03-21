class_name CropLogic
extends RefCounted

func get_total_growth_days(crop_def) -> int:
	var total: int = 0
	for days in crop_def.growth_days:
		total += int(days)
	return total


func get_stage(days_watered: int, crop_def) -> int:
	var threshold: int = 0
	for index in range(crop_def.growth_days.size()):
		threshold += int(crop_def.growth_days[index])
		if days_watered < threshold:
			return index
	return max(0, crop_def.growth_days.size() - 1)


func is_mature(crop_state: Dictionary, crop_def) -> bool:
	return int(crop_state.get("days_watered", 0)) >= get_total_growth_days(crop_def)


func advance_world(soils_by_map: Dictionary, crops_by_map: Dictionary, crop_defs: Dictionary) -> Dictionary:
	var next_soils: Dictionary = soils_by_map.duplicate(true)
	var next_crops: Dictionary = crops_by_map.duplicate(true)
	for map_id in next_soils.keys():
		var soils: Dictionary = next_soils[map_id]
		for key in soils.keys():
			var soil: Dictionary = soils[key]
			var crop_state: Dictionary = next_crops.get(map_id, {}).get(key, {})
			if soil.get("watered", false) and not crop_state.is_empty():
				crop_state["days_watered"] = int(crop_state.get("days_watered", 0)) + 1
				next_crops[map_id][key] = crop_state
			soil["watered"] = false
			soils[key] = soil
		next_soils[map_id] = soils
	return {"soils_by_map": next_soils, "crops_by_map": next_crops}
