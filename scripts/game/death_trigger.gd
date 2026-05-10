extends Node3D
const BALLOON = preload("uid://cptragtsx3wur")
@export var dialogue_resource: DialogueResource
@onready var barrier: StaticBody3D = $"../barrier"

var jump_counter:int = 0;

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("PlayerCharacter"):
		get_tree().call_group("dialogue_balloon", "queue_free")
		Global.input_locked = true
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		if jump_counter == 0:
			balloon.start(dialogue_resource,"start")
		elif jump_counter == 1:
			balloon.start(dialogue_resource,"first_reapet")
		else:
			balloon.start(dialogue_resource,"second_reapet")
			barrier_spawn()
		jump_counter += 1
			
func barrier_spawn()->void:
	barrier.global_position = Vector3(273.872,-10,-147)
	barrier.visible = true
