class_name CameraShake
extends Node3D

var is_shaking := false

@export var fade_rect: ColorRect          # сюда закинешь ColorRect
@export_range(0.0, 1.0) var target_alpha := 0.0
@export var fade_duration := 1.5           # как быстро темнеет
@onready var vhs: ColorRect = $fade_effect_layer/VHS

func shake_camera(duration: float, strength: float) -> void:
	if is_shaking:
		return
	
	is_shaking = true
	
	var original_position: Vector3 = position
	var start_time := Time.get_ticks_msec() / 1000.0
	

	while (Time.get_ticks_msec() / 1000.0) - start_time < duration:
		position = original_position + Vector3(
			randf_range(-strength, strength),
			randf_range(-strength, strength),
			0.0
		)
		await get_tree().process_frame
	
	position = original_position
	is_shaking = false


func fade_to_dark(from_alpha: float, to_alpha: float) -> void:
	var time := 0.0
	
	while time < fade_duration:
		time += get_process_delta_time()
		var t = clamp(time / fade_duration, 0.0, 1.0)
		
		fade_rect.color.a = lerp(from_alpha, to_alpha, t)
		
		await get_tree().process_frame
	
func toggle_glitch() -> void:
	vhs.visible = !vhs.visible

func _ready()->void:
	fade_to_dark(1.0,0.0)
	
	## Мгновенно делает экран черным
func flash_black() -> void:
	if is_instance_valid(fade_rect):
		fade_rect.color.a = 1.0
	
