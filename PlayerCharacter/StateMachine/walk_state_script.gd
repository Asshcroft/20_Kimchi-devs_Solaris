extends State

class_name WalkState

var state_name : String = "Walk"
@onready var walk_timer: Timer = $"../../sounds/walk_timer"
var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	verifications()

func verifications() -> void:
	play_char.move_speed = play_char.walk_speed
	play_char.move_accel = play_char.walk_accel
	play_char.move_deccel = play_char.walk_deccel
	play_char.floor_snap_length = 1.0
	
	if play_char.jump_cooldown > 0.0:
		play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref:
		play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref:
		play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_dashed:
		play_char.has_dashed = false

func physics_update(delta : float) -> void:
	check_if_floor()
	applies(delta)
	play_char.gravity_apply(delta)
	input_management()
	move(delta)

func check_if_floor() -> void:
	if !play_char.is_on_floor() and !play_char.is_on_wall():
		if play_char.velocity.y < 0.0:
			transitioned.emit(self, "InairState")
	
	if play_char.is_on_floor():
		if play_char.auto_bunny_hop and play_char.hit_ground_cooldown > 0.0 and play_char.input_direction != Vector2.ZERO and play_char.jump_cooldown < 0.0:
			transitioned.emit(self, "JumpState")
		if play_char.jump_buff_on and play_char.jump_cooldown < 0.0:
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")

func applies(delta : float) -> void:
	if play_char.hit_ground_cooldown > 0.0:
		play_char.hit_ground_cooldown -= delta

func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0:
			transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(play_char.run_action):
		play_char.walk_or_run = "RunState"
		transitioned.emit(self, "RunState")
		
	if Input.is_action_just_pressed(play_char.fly_action):
		transitioned.emit(self, "FlyState")

func move(delta : float) -> void:
	if play_char.move_speed > 3.0:
		walk_timer.wait_time = 0.5
	else:
		walk_timer.wait_time = 1.2
	
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	play_char.move_direction = (play_char.cam_holder.global_basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y)).normalized()
	
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if play_char.move_direction and play_char.is_on_floor():
		play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_direction.x * play_char.move_speed, play_char.move_accel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_direction.z * play_char.move_speed, play_char.move_accel * delta)
		
		if abs(play_char.velocity.x) > 1.7 or abs(play_char.velocity.z) > 1.7:
			if has_method("play_sound"):
				play_sound(state_name, walk_timer)
				
		if play_char.hit_ground_cooldown <= 0:
			play_char.desired_move_speed = play_char.velocity.length()
	else:
		transitioned.emit(self, "IdleState")
