class_name Interactable
extends Node2D

@export var prompt := "Interact"
@export var radius := 20.0


func can_be_interacted_with(target_world: Vector2, actor_world: Vector2) -> bool:
	return global_position.distance_to(target_world) <= radius and global_position.distance_to(actor_world) <= radius * 2.0


func interact(_player: Node, _hud: Node) -> void:
	pass

