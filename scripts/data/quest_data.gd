class_name QuestData
extends Resource

@export var id := ""
@export var title := ""
@export_multiline var description := ""
@export var giver_npc_id := ""
@export var prerequisite_ids: Array[String] = []
@export var steps := []
@export var rewards := []
