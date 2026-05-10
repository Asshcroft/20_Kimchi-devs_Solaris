extends Node3D

@export var player_path: NodePath
@export var turn_speed: float = 3.0
@export var gun_max_speed: float = 25.0
@export var gun_acceleration: float = 5.0
@export var dialogue_resource: DialogueResource

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton3D = $Armature/Skeleton3D
@onready var gun_audio: AudioStreamPlayer3D = $Armature/Skeleton3D/GunAudio # Узел должен быть в сцене

const BALLOON = preload("uid://cptragtsx3wur")
const HEAD_CORRECTION = -1.4
const NECK_CORRECTION = 3.14159

var bone_head_idx: int
var bone_neck_idx: int
var bone_gun_idx: int

var player: Node3D = null
var is_active: bool = false
var allowed: bool = false
var has_been_activated: bool = false
var current_gun_speed: float = 0.0
var gun_timer: float = 0.0


func _ready():
	bone_head_idx = skeleton.find_bone("head")
	bone_neck_idx = skeleton.find_bone("body")
	bone_gun_idx = skeleton.find_bone("gun")
	
	if has_node(player_path):
		player = get_node(player_path)

func _on_detection_area_body_entered(body):
	if body == player and !has_been_activated:
		animation_player.play("setting")
		%setting_sound.play()
		is_active = true
		Global.input_locked = true
		var balloon: Node = BALLOON.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(dialogue_resource, "activated")
		has_been_activated = !has_been_activated

func _on_detection_area_body_exited(body):
	if body == player:
		is_active = false

func _process(delta):
	if not is_active or not is_instance_valid(player) or not allowed:
		return
	
	rotate_to_target(delta)
	process_gun_logic(delta)

func rotate_to_target(delta):
	var target_pos = player.global_position
	var local_target = skeleton.to_local(target_pos)
	var step = turn_speed * delta

	# Шея
	var neck_pose = skeleton.get_bone_global_pose(bone_neck_idx)
	var neck_target = Vector3(local_target.x, neck_pose.origin.y, local_target.z)
	var target_neck_transform = neck_pose.looking_at(neck_target, Vector3.UP).rotated_local(Vector3.UP, NECK_CORRECTION)
	target_neck_transform.origin = neck_pose.origin
	skeleton.set_bone_global_pose_override(bone_neck_idx, neck_pose.interpolate_with(target_neck_transform, step), 1.0, true)

	skeleton.force_update_all_bone_transforms()

	# Голова
	var head_pose = skeleton.get_bone_global_pose(bone_head_idx)
	var target_head_transform = head_pose.looking_at(local_target, Vector3.UP).rotated_local(Vector3.RIGHT, HEAD_CORRECTION)
	target_head_transform.origin = head_pose.origin
	skeleton.set_bone_global_pose_override(bone_head_idx, head_pose.interpolate_with(target_head_transform, step), 1.0, true)

func process_gun_logic(delta):
	if not Global.is_firing:
		return

	gun_timer += delta
	if animation_player.is_playing():
		pass
	else:
		animation_player.play("fly")
	if gun_timer >= 10.0:
		stop_gun()
		return

	# Разгон
	current_gun_speed = move_toward(current_gun_speed, gun_max_speed, gun_acceleration * delta)
	
	# Вращение (Forward — ось Z кости)
	var gun_pose = skeleton.get_bone_global_pose(bone_gun_idx)
	gun_pose = gun_pose.rotated_local(Vector3.FORWARD, current_gun_speed * delta)
	skeleton.set_bone_global_pose_override(bone_gun_idx, gun_pose, 1.0, true)
	
	# Звук
	if not gun_audio.playing:
		gun_audio.play()
	gun_audio.pitch_scale = lerp(0.5, 2.0, current_gun_speed / gun_max_speed)

func stop_gun():
	Global.is_firing = false
	Global.input_locked = false
	gun_timer = 0.0
	current_gun_speed = 0.0
	gun_audio.stop()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "setting":
		allowed = true
		
