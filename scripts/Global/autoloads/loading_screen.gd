extends CanvasLayer

signal loading_screen_ready

@export var animation_player: AnimationPlayer
@export var animation_player_effects: AnimationPlayer

func _ready() -> void:
	await animation_player.animation_finished
	loading_screen_ready.emit()

func _on_progress_changed(_new_value: float) -> void:
	if _new_value != 1.0:
		if !animation_player_effects.is_playing():
			animation_player_effects.play("loading_effects")
func _on_load_finished() -> void:
	animation_player.play_backwards("transition")
	await animation_player.animation_finished
	queue_free()
