extends Node

const SaveCodecScript = preload("res://scripts/logic/save_codec.gd")

var save_codec = SaveCodecScript.new()

const SAVE_PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload: Dictionary = save_codec.encode_state(GameState.build_save_payload())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	if parse_result != OK:
		return false
	var payload: Dictionary = save_codec.decode_state(json.data)
	GameState.apply_save_payload(payload)
	return true
