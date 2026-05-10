extends Node3D

class_name CameraObject

# --- Настройки камеры ---
@export_group("Camera variables")
@export_range(0.0, 1.0, 0.001) var x_axis_sensibility : float = 0.15
@export_range(0.0, 1.0, 0.001) var y_axis_sensibility : float = 0.15
@export_range(-90.0, 0.0, 0.1) var max_up_angle_view : float = -89.0
@export_range(0.0, 90.0, 0.1) var max_down_angle_view : float = 89.0

@export_group("fov variables")
@export var cam_fov_per_state : Dictionary[String, Vector2] = {
	"Default" : Vector2(90.0, 0.2),
	"Idle" : Vector2(90.0, 0.2),
	"Walk" : Vector2(90.0, 0.2),
	"Run" : Vector2(100.0, 0.2),
	"Fly" : Vector2(90.0, 0.2)
}

@export_group("Zoom variables")
@export var zoom_action : String = "zoom" # Убедитесь, что это имя есть в Input Map
@export_range(1.0, 100.0, 1.0) var zoom_val : float = 40.0
@export_range(0.0, 3.0, 0.01) var zoom_duration : float = 0.2
var current: Node = null
@export_group("Lean & Tilt")
@export var enable_lean : bool = true
@export var enable_forward_tilt : bool = true
@export var enable_side_tilt : bool = true
@export var cam_lean_per_state : Dictionary[String, Vector2] = {
	"Default" : Vector2(0.0, 7.5),
}

@export_group("Bob variables")
@export var enable_headbob : bool = true
@export_range(0.0, 0.5, 0.001) var bob_pitch : float = 0.02
@export_range(0.0, 0.5, 0.001) var bob_roll : float = 0.01
@export_range(1.0, 20.0, 0.1) var bob_frequency : float = 12.0

@export_category("Holding_Objects")
@export var throwForce = 7.5
@export var followSpeed = 5.0
@export var followDistance = 2.0
@export var maxDistanceFromCamera = 4.0
@export var dropBelowPlayer = false

var heldObject: RigidBody3D


# --- Служебные переменные ---
var state : String
var mouse_pitch : float = 0.0
var step_timer : float = 0.0
var zoom_on : bool = false
var last_input_y : float = 0.0
var tilt_tween : Tween

@onready var camera : Camera3D = $Camera
@onready var play_char = $".." # CharacterBody3D
@onready var shape_cast_3d: ShapeCast3D = $Camera/ShapeCast3D
@onready var label: Label = $Camera/ShapeCast3D/Label
@onready var hud: CanvasLayer = $"../HUD"

@export_group("Focus Settings")
@export var focus_target: Node3D = null # Объект для фокуса (назначай сюда цель)
@export var focus_stiffness: float = 5.0 # Скорость возврата к цели
@export var focus_mouse_influence: float = 0.5 # Насколько мышь может "оттягивать"

var focus_offset: Vector2 = Vector2.ZERO
func _ready() -> void:
	hud.visible= true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera:
		mouse_pitch = rotation.x

func _input(event) -> void:

	if event is InputEventMouseMotion:
		if focus_target:
			# Если фокус включен, мышь просто "оттягивает" камеру
			focus_offset.x -= event.relative.x * x_axis_sensibility * focus_mouse_influence
			focus_offset.y -= event.relative.y * y_axis_sensibility * focus_mouse_influence
			# Ограничим, чтобы игрок не вывернул шею
			focus_offset = focus_offset.limit_length(30.0)
		# 1. Крутим ПЕРСОНАЖА влево-вправо (ось Y)
		else:
			play_char.rotate_y(deg_to_rad(-event.relative.x * x_axis_sensibility))

			# 2. Накапливаем наклон ГОЛОВЫ вверх-вниз (ось X)
			mouse_pitch -= deg_to_rad(event.relative.y * y_axis_sensibility)
			mouse_pitch = clamp(mouse_pitch, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))

			# Применяем наклон к голове
			rotation.x = mouse_pitch
		if not shape_cast_3d.is_colliding():
			_clear_current()
			return
		var collided = shape_cast_3d.get_collision_result()[0]["collider"]
		if collided != current:
			_switch_current(collided)

func _safe_unuse(obj: Node) -> void:
	if obj and obj.has_method("unuse"):
		obj.unuse()

func _switch_current(new_obj: Node) -> void:
	if current:
		_safe_unuse(current)
	if new_obj:
		current = new_obj
		if current.is_in_group("Pick_Up"):
			current.use()


func _clear_current() -> void:
	if is_instance_valid(current):
		_safe_unuse(current)
	current = null

func _physics_process(delta: float) -> void:
	activate()
	handle_holding_object()

func _process(delta: float) -> void:
	handle_focus(delta) # Добавляем это
	state = play_char.state_machine.curr_state_name

	apply_lean(delta)
	apply_tilt(delta)
	apply_bob(delta)
	handle_zoom()

# --- Логика эффектов (применяется к CAMERA, а не к SELF) ---

func apply_lean(delta: float) -> void:
	if not enable_lean: return
	var target_z = cam_lean_per_state.get(state, cam_lean_per_state["Default"])[0]
	var lerp_speed = cam_lean_per_state.get(state, cam_lean_per_state["Default"])[1]
	camera.rotation.z = lerp(camera.rotation.z, target_z, lerp_speed * delta)

func apply_tilt(delta: float) -> void:
	if state == "Fly": return

	# Боковой наклон при стрейфах
	if enable_side_tilt:
		var target_tilt = -play_char.input_direction.x * 0.05 # Сила наклона
		camera.rotation.z = lerp(camera.rotation.z, target_tilt, 10.0 * delta)

	# Резкий наклон при начале движения (вперед-назад)
	if enable_forward_tilt:
		var move_input = play_char.input_direction.y
		if sign(move_input) != sign(last_input_y) and move_input != 0:
			if tilt_tween: tilt_tween.kill()
			tilt_tween = create_tween()
			var strength = -move_input * 0.02
			tilt_tween.tween_property(camera, "rotation:x", strength, 0.1).set_trans(Tween.TRANS_SINE)
			tilt_tween.tween_property(camera, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
		last_input_y = move_input

func apply_bob(delta: float) -> void:
	var speed = Vector2(play_char.velocity.x, play_char.velocity.z).length()

	if speed > 0.1 and play_char.is_on_floor():
		step_timer += delta * speed * (bob_frequency / 10.0)
	else:
		step_timer = lerp(step_timer, 0.0, 10.0 * delta)
		camera.h_offset = lerp(camera.h_offset, 0.0, 10.0 * delta)
		camera.v_offset = lerp(camera.v_offset, 0.0, 10.0 * delta)
		return

	if enable_headbob:
		var bob_val = sin(step_timer)
		camera.v_offset = bob_val * (speed * 0.01)
		camera.h_offset = cos(step_timer * 0.5) * (speed * 0.005)
		# Небольшое покачивание по осям
		camera.rotation.x = lerp(camera.rotation.x, bob_val * bob_pitch, 5.0 * delta)
		camera.rotation.z = lerp(camera.rotation.z, bob_val * bob_roll, 5.0 * delta)

func handle_zoom() -> void:
	if zoom_action == "": return

	if Input.is_action_just_pressed(zoom_action):
		zoom_on = !zoom_on
		var target_fov = cam_fov_per_state.get(state, cam_fov_per_state["Default"])[0]
		if zoom_on: target_fov -= zoom_val

		var tw = create_tween()
		tw.tween_property(camera, "fov", target_fov, zoom_duration).set_trans(Tween.TRANS_SINE)

func set_held_object(body:RigidBody3D):
	heldObject = body

func drop_held_object():
	heldObject = null

func throw_held_object():
	var obj = heldObject
	drop_held_object()
	obj.apply_central_impulse(-camera.global_transform.basis.z * throwForce * 10)

func handle_holding_object():
	if Input.is_action_just_pressed("Shoot"):
		if heldObject != null: throw_held_object()

	if Input.is_action_just_pressed("interact"):

		if heldObject != null: drop_held_object()
		elif shape_cast_3d.is_colliding():
			var obj = shape_cast_3d.get_collider(0)
			#if obj.has_method("open_gate"):
				#obj.open_gate()
			if obj is PCstatic:
				Global.input_locked = true
				obj.toggle_use()
			#elif obj.is_in_group("Pick_Up"):
				#_clear_current()
			#elif obj.is_in_group("Interactable"):
				#set_held_object(shape_cast_3d.get_collision_result()[0]["collider"])
	if heldObject != null:
		var targetPos = camera.global_transform.origin + (camera.global_basis * Vector3(0,-0.5,-followDistance))
		var objectPos = heldObject.global_transform.origin
		heldObject.linear_velocity = (targetPos-objectPos) * followSpeed
		if heldObject.global_position.distance_to(camera.global_position) > maxDistanceFromCamera:
			drop_held_object()

		if dropBelowPlayer:
			drop_held_object()

func activate():
	label.text = ""
	if shape_cast_3d.is_colliding():
		var collider = shape_cast_3d.get_collider(0)
		if collider is InteractableObjs:
			label.text = collider.get_prompt()
			if collider.prompt_input != "":
				if Input.is_action_just_pressed(collider.prompt_input):
					collider.interact(owner)
					
func handle_focus(delta: float) -> void:
	if not focus_target: 
		focus_offset = Vector2.ZERO
		return
	
	# 1. Вычисляем, куда нужно смотреть (целевой базис)
	var target_pos = focus_target.global_position
	var look_at_transform = global_transform.looking_at(target_pos, Vector3.UP)
	
	# 2. Плавно поворачиваем основной базис к цели
	global_transform.basis = global_transform.basis.slerp(look_at_transform.basis, focus_stiffness * delta)
	
	# 3. ФИКС ГОРИЗОНТА: Сбрасываем наклон (Z) и пересчитываем углы
	# Это гарантирует, что камера не "завалится" набок
	var euler = global_rotation
	euler.z = 0 # Обнуляем крен
	global_rotation = euler
	
	# 4. Обработка "пружины" для мыши
	focus_offset = focus_offset.lerp(Vector2.ZERO, focus_stiffness * delta)
	
	# 5. Применяем смещение мыши БЕЗОПАСНО
	# Вместо локальной ротации, которая крутит все оси, 
	# мы просто добавляем градусы к углам Эйлера
	rotation.y += deg_to_rad(focus_offset.x * delta * 10.0)
	rotation.x += deg_to_rad(focus_offset.y * delta * 10.0)
	
	# Ограничиваем вертикальный взгляд, чтобы не перевернуться
	rotation.x = clamp(rotation.x, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))

	# Обновляем mouse_pitch для плавного выхода из режима фокуса
	mouse_pitch = rotation.x
