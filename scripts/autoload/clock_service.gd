extends Node

signal clock_changed(day: int, time_minutes: int)
signal day_advanced(day: int)

const DAY_START_MINUTES := 6 * 60
const DAY_END_MINUTES := 22 * 60
const PASSIVE_STEP_MINUTES := 10

var day := 1
var time_minutes := 9 * 60
var paused := false

@onready var _timer := Timer.new()


func _ready() -> void:
	_timer.wait_time = 2.0
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	if paused:
		return
	if time_minutes >= DAY_END_MINUTES:
		return
	advance_time(PASSIVE_STEP_MINUTES)


func reset_clock() -> void:
	day = 1
	time_minutes = 9 * 60
	paused = false
	clock_changed.emit(day, time_minutes)


func load_state(payload: Dictionary) -> void:
	day = int(payload.get("day", 1))
	time_minutes = int(payload.get("time_minutes", 9 * 60))
	paused = false
	clock_changed.emit(day, time_minutes)


func build_save_data() -> Dictionary:
	return {"day": day, "time_minutes": time_minutes}


func advance_time(minutes: int) -> void:
	time_minutes = min(DAY_END_MINUTES, time_minutes + minutes)
	clock_changed.emit(day, time_minutes)


func sleep_and_advance_day() -> void:
	day += 1
	time_minutes = DAY_START_MINUTES
	WorldState.process_new_day(GameState.crop_defs)
	clock_changed.emit(day, time_minutes)
	day_advanced.emit(day)

