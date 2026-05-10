extends Control

@export var select_sound: AudioStreamPlayer

func _on_start_pressed() -> void:
	select_sound.play()
	get_tree().change_scene_to_file("res://terrain/loc_1.tscn")


func _on_exit_pressed() -> void:
	select_sound.play()
	await select_sound.finished
	get_tree().quit()
