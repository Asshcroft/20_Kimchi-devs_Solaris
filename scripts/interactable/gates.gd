extends Node3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer2
var pressed = false
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _on_stand_button_interacted(_body: Variant) -> void:
	if pressed:
		return
	pressed = true
	animation_player.play("Open/Gates")
	audio_stream_player_3d.play()
