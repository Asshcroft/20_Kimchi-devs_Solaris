extends Node

class_name State

signal transitioned

const METAL = preload("uid://8vixw4eb2xxd")
const GROUND = preload("uid://culqvlh7m87mw")
const WOODEN = preload("uid://dbrdxtjsy7jgr")
const SILENCE = preload("uid://b5i8e10lmiry1")
var sounds_walking = [SILENCE,METAL,GROUND,WOODEN]
var last_material : int = 0


func get_floor_material():
	var collider = %FloorCheck.get_collider()
	if collider:
		if collider.is_in_group("metal"):
			last_material = 1
			return 1
		elif collider.is_in_group("ground"):
			last_material = 2
			return 2
		elif collider.is_in_group("wooden"):
			last_material = 3
			return 3
		else:
			return last_material
	else:
		last_material = 0
		return 0
	

func play_sound(state_name,sound_timer):
	if sound_timer.is_stopped():
		%sound_player.volume_db = -10.0
		if state_name == "Walk" or state_name == "Run":
			%sound_player.stream = sounds_walking[get_floor_material()]
			%sound_player.pitch_scale = randf_range(0.85,1.15)
		elif state_name == "Crouch":
			%sound_player.stream = sounds_walking[get_floor_material()]
			%sound_player.pitch_scale = randf_range(0.85,1.15)
			%sound_player.volume_db = -15.0
		elif state_name == "Jump":
			%sound_player.stream = sounds_walking[get_floor_material()]
			%sound_player.pitch_scale = randf_range(0.85,1.15)
			%sound_player.volume_db = 0.0
			
		elif state_name == "Inair":
			pass
		else:
			pass
		%sound_player.play()
		sound_timer.start()

func enter(_char_reference : CharacterBody3D):
	#enter state
	pass
	
func exit():
	#exit state
	pass
	
func update(_delta : float):
	#process update
	pass
	
func physics_update(_delta : float):
	#physics_process update
	pass 
