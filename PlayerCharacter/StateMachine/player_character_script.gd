extends CharacterBody3D

class_name PlayerCharacter

@export_group("Movement variables")
var move_speed: float
var move_accel: float
var move_deccel: float
var input_direction: Vector2
var move_direction: Vector3
var desired_move_speed: float
@export var desired_move_speed_curve: Curve #accumulated speed
@export var max_desired_move_speed: float = 30.0
@export var in_air_move_speed_curve: Curve
@export var hit_ground_cooldown: float = 0.1
var hit_ground_cooldown_ref: float
@export var bunny_hop_dms_incre: float = 3.0
@export var auto_bunny_hop: bool = false
var last_frame_position: Vector3
var last_frame_velocity: Vector3
var was_on_floor: bool
var walk_or_run: String = "WalkState"
@export var lose_vel_if_hit_wall_in_air : bool = false
@export var lose_dms_if_hit_wall_in_air : bool = false
@export var base_hitbox_height: float = 2.0
@export var base_model_height: float = 1.0
@export var height_change_duration: float = 0.15

@export_group("Crouch variables")
@export var crouch_speed: float = 6.0
@export var crouch_accel: float = 12.0
@export var crouch_deccel: float = 11.0
@export var continious_crouch: bool = false
@export var crouch_hitbox_height: float = 1.2
@export var crouch_model_height: float = 0.6

@export_group("Walk variables")
@export var walk_speed: float = 9.0
@export var walk_accel: float = 11.0
@export var walk_deccel: float = 10.0

@export_group("Run variables")
@export var run_speed: float = 12.0
@export var run_accel: float = 10.0
@export var run_deccel: float = 9.0
@export var continious_run: bool = false

@export_group("Jump variables")
@export var jump_height: float = 2.0
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_fall: float = 0.35
@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@export var jump_cooldown: float = 0.25
var jump_cooldown_ref: float
@export var nb_jumps_in_air_allowed: int = 1
var nb_jumps_in_air_allowed_ref: int
var jump_buff_on: bool = false
var buffered_jump: bool = false
@export var coyote_jump_cooldown: float = 0.3
var coyote_jump_cooldown_ref: float
var coyote_jump_on: bool = false
@export_range(0.1, 1.0, 0.05) var in_air_input_multiplier: float = 1.0

@export_group("Slide variables")
var slide_direction: Vector3 = Vector3.ZERO
@export var use_desired_move_speed: bool = false
@export var slide_speed: float = 12.0
@export var slide_accel: float = 23.0
@export var slide_time: float = 1.2
var slide_time_ref: float
@export var time_bef_can_slide_again: float = 1.5
var time_bef_can_slide_again_ref: float
@export_range(0.0, 90.0, 0.1) var max_slope_angle: float = 75.0
@export_range(0.0, 0.1, 0.001) var uphill_tolerance : float = 0.05
@export var amount_velocity_lost_per_sec: float = 4.0
@export var slope_sliding_dms_incre: float = 2.0
@export var slope_sliding_ms_incre: float = 2.0
@export var priority_over_crouch: bool = true
@export var continious_slide: bool = true
var slide_buff_on: bool = false
@export var slide_hitbox_height: float = 1.0
@export var slide_model_height: float = 0.5

@export_group("Dash variables")
var dash_direction: Vector3 = Vector3.ZERO
@export var dash_speed: float = 120.0
@export var dash_time: float = 0.11
var dash_time_ref: float
@export var nb_dashs_allowed: int = 3
var nb_dashs_allowed_ref: int
@export var time_bef_can_dash_again: float = 0.8
var time_bef_can_dash_again_ref: float
@export var time_bef_reload_dash: float = 3.0
var time_bef_reload_dash_ref: float
var velocity_pre_dash : Vector3
var has_dashed : bool = false

@export_group("Fly variables")
@export var fly_speed: float = 20.0
@export var fly_accel: float = 15.0
@export var fly_deccel: float = 15.0
@export var fly_boost_multiplier: float = 3.0
var fly_boost_on: bool = false

@export_group("Gravity variables")
@onready var jump_gravity: float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)

@export_group("Keybind variables")
@export var move_forward_action: String = ""
@export var move_backward_action: String = ""
@export var move_left_action: String = ""
@export var move_right_action: String = ""
@export var run_action: String = ""
@export var crouch_action: String = ""
@export var jump_action: String = ""
@export var slide_action: String = ""
@export var dash_action: String = ""
@export var fly_action: String = ""

@export_group("Time Travel Variables")
@export var position_offset: Vector3 = Vector3(10000, 0, 0)
@export var canvas_animation_player: AnimationPlayer
@export var coldown: Timer
var is_alternate_place: bool = false


# References
@onready var cam_holder: Node3D = $CameraHolder
@onready var cam: Camera3D = %Camera
@onready var hitbox: CollisionShape3D = $Hitbox
@onready var state_machine: Node = $StateMachine
@onready var hud: CanvasLayer = $HUD
@onready var floor_check: RayCast3D = %FloorCheck
var MOUSE_SENS: float = 0.001
@onready var bullet_point: Marker3D = %Bullet_Point
@onready var projectile_point: Marker3D = %Bullet_Point_for_projectile
@onready var blood: TextureRect = %blood
@onready var blood_fill: ColorRect = %Blood_fill
var blood_tween: Tween
@onready var guider: Node3D = $CameraHolder/Camera/GUIDER
@onready var anim_player = guider.get_node("AnimationPlayer")
var guider_holding: bool = false

const BALLOON_POPUP = preload("uid://djsivhdq3s1w4")
@export var popup_resource: DialogueResource

# --- Logic Functions ---
func show_blood(damage: int, custom_intensity: float = -1.0, duration: float = 1.0, show_main: bool = true, show_fill: bool = true) -> void:
	var max_damage := 50.0

	# Расчет интенсивности
	var intensity: float = custom_intensity if custom_intensity >= 0 else clamp(damage / max_damage, 0.1, 0.5)
	var fill_intensity = intensity * 0.6

	# Если всё выключено — выходим
	if not show_main and not show_fill:
		return

	if blood_tween and blood_tween.is_valid():
		blood_tween.kill()



	blood_tween = create_tween()
	blood_tween.set_trans(Tween.TRANS_SINE)
	blood_tween.set_ease(Tween.EASE_OUT)

	# --- 1. ФАЗА ПОЯВЛЕНИЯ (25% времени) ---
	var appear_time = duration * 0.10

	if show_main:
		blood_tween.parallel().tween_property(blood, "modulate:a", intensity, appear_time)
	if show_fill:
		blood_tween.parallel().tween_property(blood_fill, "color:a", fill_intensity, appear_time)

	# --- 2. ФАЗА УДЕРЖАНИЯ (50% времени) ---
	blood_tween.set_parallel(false) # Переключаемся на последовательное выполнение для паузы
	blood_tween.tween_interval(duration * 1.0)
	blood_tween.set_parallel(true) # Снова параллельно для исчезновения

	# --- 3. ФАЗА ИСЧЕЗНОВЕНИЯ (25% времени) ---
	var fade_time = duration * 0.45

	if show_main:
		blood_tween.tween_property(blood, "modulate:a", 0.0, fade_time)
	if show_fill:
		blood_tween.tween_property(blood_fill, "color:a", 0.0, fade_time)


func slow_down(time: float, multiplier: float = 0.1) -> void:
	# Временное замедление (например от урона)
	var old_walk = walk_speed
	var old_run = run_speed
	walk_speed *= multiplier
	run_speed *= multiplier
	await get_tree().create_timer(time).timeout
	walk_speed = old_walk
	run_speed = old_run


func get_damage(damage: int) -> void:
	slow_down(1.0, 0.5)
	cam.shake_camera(0.2, 0.2)
	show_blood(damage)


func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c:= get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			if abs(push_dir.y) > 0.1:  # Adjust this threshold if needed
				continue
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0.,velocity_diff_in_push_dir)
			const MY_APPROX_MASS_KG = 80.0
			var mass_ratio = min(1.,MY_APPROX_MASS_KG/c.get_collider().mass)
			push_dir.y = 0
			var push_force = mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir*velocity_diff_in_push_dir*push_force, c.get_position() - c.get_collider().global_position)


func _ready() -> void:
	Global.player = self
	hit_ground_cooldown_ref = hit_ground_cooldown
	jump_cooldown_ref = jump_cooldown
	jump_cooldown = -1.0
	nb_jumps_in_air_allowed_ref = nb_jumps_in_air_allowed
	coyote_jump_cooldown_ref = coyote_jump_cooldown
	slide_time_ref = slide_time
	time_bef_can_slide_again_ref = time_bef_can_slide_again
	time_bef_can_slide_again = -1.0
	time_bef_can_dash_again_ref = time_bef_can_dash_again
	time_bef_can_dash_again = -1.0
	time_bef_reload_dash_ref = time_bef_reload_dash
	time_bef_reload_dash = -1.0
	nb_dashs_allowed_ref = nb_dashs_allowed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	modify_physics_properties()

	if Global.input_locked:
		velocity = Vector3.ZERO
		return
	if Input.is_action_just_pressed("tab"): # по умолчанию Tab
		if not anim_player.is_playing():
			if guider_holding:
				Global.play_sound(Global.cursor_sound)
				anim_player.play("untake")
			else:
				Global.play_sound(Global.cursor_sound)
				anim_player.play("take")
			guider_holding = !guider_holding
	if Input.is_action_just_pressed("TP"):
		if coldown.is_stopped() and Global.allowed_teleport:
			var result = await attempt_teleport()
			if result == "error":
				await get_tree().create_timer(1.0).timeout
				var balloon: Node = BALLOON_POPUP.instantiate()
				get_tree().current_scene.add_child(balloon)
				balloon.start(popup_resource,"start")
			coldown.start()
	_push_away_rigid_bodies()
	move_and_slide()


func modify_physics_properties() -> void:
	last_frame_position = global_position
	last_frame_velocity = velocity
	was_on_floor = !is_on_floor()


func gravity_apply(delta: float) -> void:
	if velocity.y >= 0.0:
		velocity.y += jump_gravity * delta
	else:
		velocity.y += fall_gravity * delta


func tween_hitbox_height(state_hitbox_height : float) -> void:
	var hitbox_tween: Tween = create_tween()
	if hitbox != null:
		hitbox_tween.tween_method(func(v): set_hitbox_height(v), hitbox.shape.height,
		state_hitbox_height, height_change_duration)
	else:
		hitbox_tween.tween_interval(0.1)
	hitbox_tween.finished.connect(Callable(hitbox_tween, "kill"))


func set_hitbox_height(value: float) -> void:
	if hitbox.shape is CapsuleShape3D:
		hitbox.shape.height = value


func attempt_teleport()->String:
	canvas_animation_player.play("teleportation")
	await get_tree().create_timer(0.5).timeout
	var offset = position_offset if not is_alternate_place else -position_offset
	var target_pos = global_position + offset
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	
	# Создание временной уменьшенной формы для проверки коллизий
	if hitbox.shape is CapsuleShape3D:
		var reduced_shape = CapsuleShape3D.new()
		# Уменьшение на 5% позволяет избежать ложных столкновений с полом и стенами
		reduced_shape.radius = hitbox.shape.radius * 0.75
		reduced_shape.height = hitbox.shape.height * 0.75
		query.shape = reduced_shape
	else:
		query.shape = hitbox.shape 
	
	query.transform = Transform3D(global_transform.basis, target_pos)
	query.collision_mask = collision_mask 
	query.exclude = [self.get_rid()] 
	
	var result = space_state.intersect_shape(query, 1)
	
	if result.is_empty():
		Global.play_sound(Global.teleportation_sound)
		global_position = target_pos
		
		is_alternate_place = !is_alternate_place
		return "good"
	else:
		return "error"

func _on_timer_timeout() -> void:
	pass # Replace with function body.
