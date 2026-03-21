class_name InventoryLogic
extends RefCounted

func empty_slots(size: int) -> Array:
	var slots: Array = []
	for _i in range(size):
		slots.append({"item_id": "", "count": 0})
	return slots


func clone_slots(slots: Array) -> Array:
	var copy: Array = []
	for slot in slots:
		copy.append(slot.duplicate(true))
	return copy


func add_item(slots: Array, item_id: String, amount: int, max_stack: int) -> Dictionary:
	var next_slots: Array = clone_slots(slots)
	var remaining: int = amount
	for slot in next_slots:
		if remaining <= 0:
			break
		if slot["item_id"] != item_id:
			continue
		var room: int = max_stack - int(slot["count"])
		if room <= 0:
			continue
		var moved: int = min(room, remaining)
		slot["count"] = int(slot["count"]) + moved
		remaining -= moved
	for slot in next_slots:
		if remaining <= 0:
			break
		if slot["item_id"] != "":
			continue
		var moved: int = min(max_stack, remaining)
		slot["item_id"] = item_id
		slot["count"] = moved
		remaining -= moved
	return {"slots": next_slots, "leftover": remaining}


func remove_amount(slots: Array, index: int, amount: int) -> Array:
	var next_slots: Array = clone_slots(slots)
	if index < 0 or index >= next_slots.size():
		return next_slots
	var slot: Dictionary = next_slots[index]
	var next_count: int = max(0, int(slot["count"]) - amount)
	if next_count == 0:
		slot["item_id"] = ""
		slot["count"] = 0
	else:
		slot["count"] = next_count
	next_slots[index] = slot
	return next_slots
