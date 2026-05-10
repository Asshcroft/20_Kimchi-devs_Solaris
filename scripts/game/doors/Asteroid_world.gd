extends Node3D
@onready var camera_shake: CameraShake = $"../PlayerCharacter/CameraHolder/Camera"
@onready var camera: CameraObject = $"../PlayerCharacter/CameraHolder"
const BALLOON = preload("uid://cptragtsx3wur")
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@onready var turret_player: AnimationPlayer = $"../Dimension1/turret/AnimationPlayer"
@onready var label: Label = $"../PlayerCharacter/HUD/Label"
func _ready() -> void:
	start()
	

func start() -> void:
	label.visible = false
	turret_player.play("setting")
	camera_shake.toggle_glitch()
	var glitch_sound = Global.play_sound(Global.glitch_sound)
	await get_tree().create_timer(2.0).timeout
	Global.stop_sound(glitch_sound)
	camera_shake.toggle_glitch()
	await get_tree().create_timer(1.0).timeout
	start_dialogue()
	await get_tree().create_timer(14.0).timeout
	camera.focus_target = get_node("../door_wooden")
	await get_tree().create_timer(3.0).timeout
	camera.focus_target = null
	


func start_dialogue() -> void:
	var balloon: Node = BALLOON.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource,dialogue_start)

	
@export var turret: Node3D
const EPIC_HIT = preload("uid://c6ecw8hy2aq86")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("PlayerCharacter"):
		$"../AudioStreamPlayer3D".stream = EPIC_HIT
		$"../AudioStreamPlayer3D".autoplay = false
		$"../AudioStreamPlayer3D".stop()
		
		Global.input_locked = true
		camera.focus_target = turret
		Global.is_firing = true
		turret.is_active = true
		dash_to_target(turret, body.global_position)
		
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(dialogue_resource, "ending")
		
		await get_tree().create_timer(3.9).timeout
		
		$"../AudioStreamPlayer3D".play()
		%Camera.flash_black()
		label.visible = true
		await get_tree().create_timer(3.0).timeout
		get_tree().quit()

		



func dash_to_target(object_to_move: Node3D, target_pos: Vector3) -> void:
	var stop_distance: float = 10.0 # Дистанция, на которой объект затормозит
	
	# Считаем направление от объекта к игроку
	var direction = (target_pos - object_to_move.global_position).normalized()
	
	# Новая точка финиша = Позиция игрока минус (направление * дистанция)
	var final_pos = target_pos - (direction * stop_distance)
	
	var tween = create_tween()
	tween.tween_property(object_to_move, "global_position", final_pos, 10.0)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
