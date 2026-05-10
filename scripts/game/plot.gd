extends Node3D
@onready var camera_shake: CameraShake = $"../PlayerCharacter/CameraHolder/Camera"
const BALLOON = preload("uid://cptragtsx3wur")
@export var dialogue_resource_1: DialogueResource
@export var dialogue_resource_2: DialogueResource
@export var dialogue_start: String = "start"
@onready var camera: CameraObject = $"../PlayerCharacter/CameraHolder"
@onready var ship: Node3D = $"../ship"
const cool_music = preload("uid://clyfq3dfco23h")
const WOOSH = preload("uid://6nnogywcjn22")
var first_tp: bool = false
var desert_entered: bool = false
var valley_entered: bool = false
var is_opened: bool = false
func _ready() -> void:
	Global.input_locked = false
	Global.plot = self
	if !Global.started:
		Global.started = !Global.started
		start()
	
const BALLOON_POPUP = preload("uid://djsivhdq3s1w4")
@export var popup_resource: DialogueResource
func first_message() -> void:
	await get_tree().create_timer(0.5).timeout
	Global.play_sound(Global.popup_sound)
	var balloon: Node = BALLOON_POPUP.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(popup_resource,"start")

@export var popup2_resource: DialogueResource
func second_message() -> void:
	await get_tree().create_timer(0.5).timeout
	Global.play_sound(Global.popup_sound)
	var balloon: Node = BALLOON_POPUP.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(popup2_resource,"start")
	
func start() -> void:
	camera.focus_target = get_node("../ship/Marker")
	camera_shake.toggle_glitch()
	var glitch_sound = Global.play_sound(Global.glitch_sound)
	await get_tree().create_timer(2.0).timeout
	Global.stop_sound(glitch_sound)
	camera_shake.toggle_glitch()
	var cool_music = Global.play_sound(cool_music, {"fade_in": 2.0, "volume": -10.0,})
	camera_shake.shake_camera(2.0,0.2)
	await get_tree().create_timer(2.0).timeout
	
	camera_shake.shake_camera(4.0,0.5)
	await get_tree().create_timer(4.0).timeout
	camera_shake.shake_camera(8.0,1.0)
	await get_tree().create_timer(4.0).timeout
	
	camera.focus_target = null
	start_dialogue()
	await get_tree().create_timer(4.0).timeout
	Global.stop_sound(cool_music,0.2)
	await get_tree().create_timer(2.0).timeout
	Global.play_sound(WOOSH,{"pitch":1.0,"volume" : 7.0})
	%AudioStreamPlayer3D.play()

func start_dialogue() -> void:
	Global.input_locked = true
	var balloon: Node = BALLOON.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource_1,dialogue_start)

func gate_open(_body) -> void:
	if is_opened:
		return
	is_opened = true
	Global.change(17)
	await get_tree().create_timer(1.0).timeout
	camera_shake.shake_camera(1.0,0.5)
	await get_tree().create_timer(2.0).timeout
	camera_shake.shake_camera(13.0,0.3)
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	ship.queue_free()



func _on_first_teleported(body) -> void:
	if body.is_in_group("PlayerCharacter"):
		if first_tp:
			return
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(dialogue_resource_2,dialogue_start)
		first_tp = true


func _on_desert_entered(body) -> void:
	if body.is_in_group("PlayerCharacter"):
		if desert_entered:
			return
		desert_entered = true
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(dialogue_resource_2,"desert_entered")


func _on_valley_entered(body) -> void:
	if body.is_in_group("PlayerCharacter"):
		if valley_entered:
			return
		valley_entered = true
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(dialogue_resource_2,"valley_entered")
