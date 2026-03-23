extends Node

const BRIDGE_ROOT := "user://openclaw_bridge"
const COMMANDS_DIR := "user://openclaw_bridge/commands"
const RESULTS_DIR := "user://openclaw_bridge/results"
const SNAPSHOT_PATH := "user://openclaw_bridge/snapshot.json"
const ROOM_DIRECTORY_PATH := "user://openclaw_bridge/room_directory.json"
const EVENTS_PATH := "user://openclaw_bridge/events.jsonl"

@onready var _poll_timer := Timer.new()


func _ready() -> void:
	_ensure_bridge_layout()
	_write_state_exports()
	_poll_timer.wait_time = 0.25
	_poll_timer.one_shot = false
	_poll_timer.autostart = true
	add_child(_poll_timer)
	_poll_timer.timeout.connect(_on_poll_timer)


func _on_poll_timer() -> void:
	_process_command_queue()
	_write_state_exports()


func _ensure_bridge_layout() -> void:
	for path in [BRIDGE_ROOT, COMMANDS_DIR, RESULTS_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _process_command_queue() -> void:
	var command_files := _list_json_files(COMMANDS_DIR)
	command_files.sort()
	for file_name in command_files:
		var command_path := "%s/%s" % [COMMANDS_DIR, file_name]
		var payload: Dictionary = _read_json_file(command_path)
		var result := {}
		if payload.is_empty():
			result = {
				"command_id": file_name.trim_suffix(".json"),
				"actor_id": "player",
				"success": false,
				"message": "Could not parse command JSON.",
				"time_cost": 0,
				"events": [],
				"directives": {}
			}
		else:
			result = AgentCommandService.handle_command(payload)
		_write_json_file("%s/%s" % [RESULTS_DIR, file_name], result)
		_append_event(result)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(command_path))


func _write_state_exports() -> void:
	_write_json_file(SNAPSHOT_PATH, AgentSnapshotService.build_snapshot())
	_write_json_file(ROOM_DIRECTORY_PATH, AgentSnapshotService.build_room_directory())


func _append_event(result: Dictionary) -> void:
	var file := FileAccess.open(EVENTS_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(EVENTS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(result))


func _write_json_file(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


func _list_json_files(path: String) -> Array:
	var dir := DirAccess.open(path)
	if dir == null:
		return []
	var files: Array = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
