extends Node

@onready var anim = $"../AnimationPlayer"
@onready var animation_player_2: AnimationPlayer = $"../AnimationPlayer2"

var pressed_a: bool = false
var pressed_b: bool = false
@onready var a1: AudioStreamPlayer3D = $"sci-fi_container/AudioStreamPlayer3D"
@onready var a2: AudioStreamPlayer3D = $"sci-fi_container2/AudioStreamPlayer3D"
@onready var a3: AudioStreamPlayer3D = $"sci-fi_container4/AudioStreamPlayer3D"



# Предположим, теперь у каждой платформы свой плеер и свой звук
@onready var anim_1 = $"../AnimationPlayer1"
@onready var anim_a = $"../AnimationPlayerA"
@onready var anim_b = $"../AnimationPlayerB"

func _toggle_animation(player: AnimationPlayer, anim_name: String, audio: AudioStreamPlayer3D) -> void:
	if player.is_playing():
		return
	
	# Если мы в начале — играем вперед, если в конце — назад
	if player.current_animation_position == 0:
		player.play(anim_name)
	else:
		player.play_backwards(anim_name)
	
	audio.play()

# Примеры вызова для твоих платформ:

func move_independent(_body):
	_toggle_animation(anim_1, "move_box1", a3)

func move_linked_a(_body):
	_toggle_animation(anim_a, "link_a", a1)

func move_linked_b(_body):
	_toggle_animation(anim_b, "link_b", a2)
