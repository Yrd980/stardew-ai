extends CharacterBody2D

var current_map = null
var hud: Node

@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if not ActorService.actor_changed.is_connected(_on_actor_changed):
		ActorService.actor_changed.connect(_on_actor_changed)
	_sync_from_actor()


func _process(_delta: float) -> void:
	_sync_from_actor()


func set_hud(target: Node) -> void:
	hud = target


func _sync_from_actor() -> void:
	global_position = ActorService.get_player_world_position()


func _on_actor_changed(actor_id: String) -> void:
	if actor_id != "player":
		return
	_sync_from_actor()
