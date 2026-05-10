extends StaticBody3D
class_name PCstatic

var player:PlayerCharacter
var view_model_cam:Hands_camera

var is_using:bool = false
var show_hands:bool = true
@onready var camera_3d: Camera3D = $Camera3D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var pc_control: Control = $SubViewport/Pc_control
@onready var pc_sounds: AudioStreamPlayer3D = $pc_sounds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("PlayerCharacter")
	view_model_cam = get_tree().get_first_node_in_group("hands_camera")
	
func toggle_use():
	is_using = !is_using
	show_hands = !show_hands
	camera_3d.current = is_using
	view_model_cam.visible = show_hands
	pc_sounds.pitch_scale = 1.5
	pc_sounds.play()

func _unhandled_input(event: InputEvent) -> void:
	if !is_using:
		return
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			toggle_use()
			Global.input_locked = false
		else:
			sub_viewport.push_input(event)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = event.button_index
			mouse_event.pressed = event.pressed
			mouse_event.position = pc_control.pc_mouse_pos
			mouse_event.global_position = pc_control.pc_mouse_pos
			sub_viewport.push_input(mouse_event)
	elif event is InputEventMouseMotion:
		pc_control.pc_mouse_pos += event.relative
		pc_control.pc_mouse_pos.x = clamp(pc_control.pc_mouse_pos.x,0.0,sub_viewport.size.x-10.0)
		pc_control.pc_mouse_pos.y = clamp(pc_control.pc_mouse_pos.y,0.0,sub_viewport.size.y-10.0)
		pc_control.update_cursor_pos()
