extends "res://scripts/world/interactable.gd"

var npc_id := ""

@onready var body: Polygon2D = $Body
@onready var name_label: Label = $NameLabel


func setup_projection(projection: Dictionary, map_scene: Node) -> void:
	npc_id = String(projection.get("npc_id", ""))
	var state: Dictionary = projection.get("state", {})
	position = map_scene.cell_to_world(Vector2i(int(state.get("cell", {}).get("x", 0)), int(state.get("cell", {}).get("y", 0))))
	prompt = "Talk to %s" % String(projection.get("display_name", npc_id))
	if is_node_ready():
		_refresh_visuals(projection)
	else:
		call_deferred("_refresh_visuals", projection)


func _refresh_visuals(projection: Dictionary) -> void:
	var display_name := String(projection.get("display_name", npc_id.capitalize()))
	name_label.text = display_name
	var npc = GameState.get_npc_data(npc_id)
	if npc != null and not String(npc.shop_id).is_empty():
		body.color = Color("d7ab5a")
	else:
		body.color = Color("7db0d4")

func build_action_request() -> Dictionary:
	return {"type": "npc_interaction", "npc_id": npc_id}
