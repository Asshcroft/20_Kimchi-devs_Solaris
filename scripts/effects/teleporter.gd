extends Node3D

@onready var animator = $AnimationPlayer
@onready var animator2 = $AnimationPlayer2
@onready var sounds: AudioStreamPlayer3D = $sounds
@onready var particles: GPUParticles3D = $particles
@onready var particles_2: GPUParticles3D = $particles2

func _ready() -> void:
	idle()

func idle()->void:
	animator.play("idle")
	
func active() -> void:
	animator2.play("active")
	particles.emitting = true
	particles_2.emitting = true
	sounds.pitch_scale = 2.0
	sounds.play()

	var tween := create_tween()
	tween.tween_property(
		sounds,
		"pitch_scale",
		0.5,
		10.0 # длительность в секундах
	)
	tween.tween_callback(Callable(sounds, "stop"))
