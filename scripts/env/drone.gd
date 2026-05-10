extends RigidBody3D

@onready var player: CharacterBody3D = $"../../Character"
@onready var raycast: RayCast3D = $RayCast3D

@export var speed: float = 4.0
@export var vertical_amplitude: float = 0.5
@export var vertical_frequency: float = 1.0
@export var height_offset: float = 1.0
@export var follow_distance: float = 100.0
@export var stop_distance: float = 5.0
@export var resume_distance: float = 6.0
@export var lerp_factor: float = 1.0
@export var lerp_factor_y: float = 0.05
@export var rotation_lerp_factor: float = 0.1
@export var obstacle_avoidance_distance: float = 3.0
@export var avoidance_strength: float = 3.0

var is_following: bool = true
var time: float = 0.0
var target_height: float = 0.0

func _ready() -> void:
	gravity_scale = 0.0
	if not player:
		push_error("Player node not assigned!")
		set_physics_process(false)
	else:
		target_height = player.global_position.y + height_offset
		global_transform.origin.y = target_height
	
	if not raycast:
		push_error("RayCast3D node not assigned!")
		set_physics_process(false)
	else:
		raycast.enabled = true
		raycast.target_position = Vector3(0, 0, -obstacle_avoidance_distance)

func _physics_process(delta: float) -> void:
	if not player or not raycast:
		return

	var current_position: Vector3 = global_transform.origin
	var player_position: Vector3 = player.global_position
	var distance_to_player: float = current_position.distance_to(player_position)

	if distance_to_player > follow_distance:
		is_following = false
	elif distance_to_player > resume_distance:
		is_following = true
	elif distance_to_player < stop_distance:
		is_following = false

	target_height = lerp(target_height, player_position.y + height_offset, lerp_factor_y)

	if is_following:
		var target_position: Vector3 = player_position + Vector3(0, height_offset, 0)
		var direction: Vector3 = (target_position - current_position).normalized()
		
		raycast.global_transform.basis = global_transform.basis
		raycast.force_raycast_update()
		
		var avoidance_vector: Vector3 = Vector3.ZERO
		if raycast.is_colliding():
			var normal: Vector3 = raycast.get_collision_normal()
			var right_vector: Vector3 = direction.cross(Vector3.UP).normalized()
			avoidance_vector = right_vector * avoidance_strength

			var temp_raycast: RayCast3D = RayCast3D.new()
			add_child(temp_raycast)
			temp_raycast.global_transform = raycast.global_transform
			temp_raycast.target_position = right_vector * obstacle_avoidance_distance
			temp_raycast.force_raycast_update()
			if temp_raycast.is_colliding():
				avoidance_vector = -right_vector * avoidance_strength
			temp_raycast.queue_free()

		var move_direction: Vector3 = (direction + avoidance_vector).normalized()
		var desired_velocity: Vector3 = move_direction * speed
		var velocity_change: Vector3 = desired_velocity - linear_velocity
		apply_central_force(velocity_change * mass)

		time += delta
		var vertical_offset: float = sin(time * vertical_frequency) * vertical_amplitude
		var desired_y: float = target_height + vertical_offset
		var y_diff: float = desired_y - current_position.y
		apply_central_force(Vector3(0, y_diff * mass * 5.0, 0))

	else:
		time += delta
		var vertical_offset: float = sin(time * vertical_frequency) * vertical_amplitude
		var desired_y: float = target_height + vertical_offset
		var y_diff: float = desired_y - current_position.y
		apply_central_force(Vector3(0, y_diff * mass * 5.0, 0))

		var horizontal_velocity: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
		apply_central_force(-horizontal_velocity * mass)

	# Плавный поворот к игроку
	var forward: Vector3 = -global_transform.basis.z
	var target_dir: Vector3 = (player_position - current_position).normalized()
	var rotation_axis: Vector3 = forward.cross(target_dir).normalized()
	var angle_diff: float = forward.angle_to(target_dir)

	if angle_diff > 0.01:
		var angular_velocity_target: Vector3 = rotation_axis * angle_diff / delta
		angular_velocity = angular_velocity.lerp(angular_velocity_target, rotation_lerp_factor)

	# Поддержание горизонтального положения
	var current_basis: Basis = global_transform.basis
	var desired_up: Vector3 = Vector3.UP
	var current_up: Vector3 = current_basis.y

	var up_correction_axis: Vector3 = current_up.cross(desired_up)
	var angle: float = current_up.angle_to(desired_up)

	if angle > 0.01:
		var correction_quat: Quaternion = Quaternion(up_correction_axis.normalized(), angle * rotation_lerp_factor)
		var corrected_basis: Basis = Basis(correction_quat) * current_basis
		global_transform.basis = corrected_basis.orthonormalized()
