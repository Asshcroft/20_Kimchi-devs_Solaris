extends Control

@onready var mouse_cursor: AnimatedSprite2D = $mouse_cursor

var pc_mouse_pos: Vector2 = Vector2.ZERO
var move_speed: float = 400.0 # Скорость движения курсора

func _process(delta: float):
	update_cursor_pos(delta)

func update_cursor_pos(delta: float):
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		pc_mouse_pos += input_vector * move_speed * delta
		
		# Ограничение, чтобы курсор не улетал за экран
		var screen_size = get_viewport_rect().size
		pc_mouse_pos = pc_mouse_pos.clamp(Vector2.ZERO, screen_size)
		
		mouse_cursor.position = pc_mouse_pos
