extends InteractableObjs

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var next_location: Constants.GameScene
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var open = false

func toggle(_body):
	if _body.is_in_group("PlayerCharacter"):
		audio_stream_player_3d.play()
		open = !open
		if open and animation_player.animation_finished:
			animation_player.play("open")
		elif !open and animation_player.animation_finished:
			animation_player.play("close")

func _on_teleport_activation_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		var data = Constants.SCENE_DATA[next_location]
		SceneLoader.target_spawn_name = data["spawn"]
		SceneLoader.load_scene(data["path"])
