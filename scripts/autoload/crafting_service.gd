extends Node

const InventoryLogicScript = preload("res://scripts/logic/inventory_logic.gd")

signal crafting_changed

var known_recipe_ids: Array[String] = []
var unlocked_recipe_ids: Array[String] = []


func reset_state() -> void:
	known_recipe_ids = []
	unlocked_recipe_ids = []
	crafting_changed.emit()


func load_state(payload: Dictionary) -> void:
	known_recipe_ids = payload.get("known_recipe_ids", []).duplicate()
	unlocked_recipe_ids = payload.get("unlocked_recipe_ids", []).duplicate()
	crafting_changed.emit()


func build_save_data() -> Dictionary:
	return {
		"known_recipe_ids": known_recipe_ids.duplicate(),
		"unlocked_recipe_ids": unlocked_recipe_ids.duplicate()
	}


func unlock_recipes(recipe_ids: Array) -> Array:
	var unlocked: Array = []
	for recipe_id_variant in recipe_ids:
		var recipe_id := String(recipe_id_variant)
		if recipe_id.is_empty():
			continue
		if not known_recipe_ids.has(recipe_id):
			known_recipe_ids.append(recipe_id)
		if not unlocked_recipe_ids.has(recipe_id):
			unlocked_recipe_ids.append(recipe_id)
			unlocked.append(recipe_id)
	crafting_changed.emit()
	return unlocked


func get_available_recipes() -> Array:
	var recipes: Array = []
	for recipe_id in known_recipe_ids:
		var recipe = GameState.get_recipe_data(String(recipe_id))
		if recipe != null and ClockService.day >= int(recipe.unlock_day):
			recipes.append(recipe)
	return recipes


func craft_recipe(recipe_id: String) -> Dictionary:
	var recipe = GameState.get_recipe_data(recipe_id)
	if recipe == null or not known_recipe_ids.has(recipe_id):
		return _result(false, "That recipe is not available.")
	if not _has_ingredients(recipe.ingredients):
		return _result(false, "Missing ingredients for %s." % recipe.display_name)
	if not _can_receive_outputs(recipe.outputs):
		return _result(false, "Inventory full. Make room before crafting.")
	_consume_ingredients(recipe.ingredients)
	for output in recipe.outputs:
		InventoryService.add_item(String(output.get("item_id", "")), int(output.get("count", 1)), String(output.get("quality", "normal")))
	return _result(true, "Crafted %s." % recipe.display_name, 10, [{
		"type": "recipe_crafted",
		"recipe_id": recipe_id
	}])


func _has_ingredients(ingredients: Array) -> bool:
	for ingredient in ingredients:
		var needed := int(ingredient.get("count", 1))
		var found := 0
		for slot in InventoryService.slots:
			if String(slot.get("item_id", "")) != String(ingredient.get("item_id", "")):
				continue
			found += int(slot.get("count", 0))
		if found < needed:
			return false
	return true


func _can_receive_outputs(outputs: Array) -> bool:
	var inventory_logic = InventoryLogicScript.new()
	var simulated: Array = inventory_logic.clone_slots(InventoryService.slots)
	for output in outputs:
		var item = GameState.get_item_data(String(output.get("item_id", "")))
		if item == null:
			return false
		var result: Dictionary = inventory_logic.add_item(
			simulated,
			String(output.get("item_id", "")),
			int(output.get("count", 1)),
			int(item.max_stack),
			String(output.get("quality", "normal"))
		)
		if int(result.get("leftover", 0)) > 0:
			return false
			simulated = result.get("slots", []).duplicate(true)
	return true


func _consume_ingredients(ingredients: Array) -> void:
	for ingredient in ingredients:
		var remaining := int(ingredient.get("count", 1))
		for index in range(InventoryService.slots.size()):
			if remaining <= 0:
				break
			var slot := InventoryService.get_slot(index)
			if String(slot.get("item_id", "")) != String(ingredient.get("item_id", "")):
				continue
			var used: int = min(remaining, int(slot.get("count", 0)))
			InventoryService.remove_amount(index, used)
			remaining -= used


func _result(success: bool, message: String, time_cost: int = 0, events: Array = [], directives: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"time_cost": time_cost,
		"events": events,
		"directives": directives
	}
