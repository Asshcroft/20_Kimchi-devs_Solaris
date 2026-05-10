extends Node3D

var is_open: bool = false

@export var door_mesh: Node3D
@export var closed_rotation: Vector3 = Vector3(0, 0, 0)
@export var open_rotation: Vector3 = Vector3(0, -150, 0)
@export var anim_time: float = 0.7
@onready var germo_sound: AudioStreamPlayer3D = $germo_sound

func open_door() -> void:
	if door_mesh and not is_open:
		var tween = get_tree().create_tween()
		tween.tween_property(door_mesh, "rotation_degrees", open_rotation, anim_time)
		is_open = true

func close_door() -> void:
	if door_mesh and is_open:
		var tween = get_tree().create_tween()
		tween.tween_property(door_mesh, "rotation_degrees", closed_rotation, anim_time)
		is_open = false

func toggle_door() -> void:
	if germo_sound.playing:
		return
	else:
		germo_sound.play()
	if is_open:
		close_door()
	else:
		open_door()
