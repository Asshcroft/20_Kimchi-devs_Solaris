# Global.gd
extends Node

var input_locked:bool = false
var player: CharacterBody3D # Или какой у тебя там тип
var started: bool = false
var is_firing: bool = false
var is_autoplay: bool = false
var plot: Node3D
var allowed_teleport: bool = false
const glitch_sound = preload("uid://cpynrg1kt34dx")
const popup_sound = preload("uid://c5lt5f5glvl4o")
const cursor_sound = preload("uid://dy3m7jqckvcac")
const teleportation_sound = preload("uid://d01b73bjw8hbv")
const button_sound = preload("uid://dg1j674osbqnc")
var audio_player: AudioStreamPlayer

func _ready()->void:
	# Создаем плеер программно при запуске игры
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	# Назначаем аудио-шину (создай шину "Voices" в микшере, если хочешь)
	audio_player.bus = &"Master"

func spawn()->void:
	if player:
		input_locked = false
		player.global_position = Vector3(271,-16,-134)


func change(timer)->void:
	player.attempt_teleport()
	allowed_teleport = false
	await get_tree().create_timer(timer).timeout
	allowed_teleport = true

func play_sound(sound: AudioStream, params: Dictionary = {}) -> AudioStreamPlayer:
	if sound == null:
		push_error("Попытка воспроизвести пустой звук!")
		return null

	var p = AudioStreamPlayer.new()
	p.stream = sound
	
	# Настройки из словаря (с дефолтными значениями)
	var pitch = params.get("pitch", 1.0)
	var volume = params.get("volume", 0.0)
	var fade_in = params.get("fade_in", 0.0)
	var fade_out = params.get("fade_out", 0.0)
	var bus = params.get("bus", "Master") # Можно указать шину (например, "Music")

	p.pitch_scale = pitch
	p.bus = bus
	add_child(p)

	# --- Логика появления (Fade-in) ---
	if fade_in > 0:
		p.volume_db = -80.0
		var tw_in = create_tween()
		tw_in.tween_property(p, "volume_db", volume, fade_in).set_trans(Tween.TRANS_SINE)
	else:
		p.volume_db = volume

	p.play()

	# --- Логика автоматического затухания в конце (Fade-out) ---
	if fade_out > 0:
		var tw_out = create_tween()
		var start_time = max(0.0, sound.get_length() - fade_out)
		tw_out.tween_property(p, "volume_db", -80.0, fade_out).set_delay(start_time)
		tw_out.finished.connect(p.queue_free)
	else:
		p.finished.connect(p.queue_free)

	return p

## Функция для принудительной плавной остановки любого плеера
func stop_sound(player: AudioStreamPlayer, fade_duration: float = 0.0) -> void:
	if not is_instance_valid(player) or not player.playing:
		return

	if fade_duration > 0:
		var tw = create_tween()
		tw.tween_property(player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tw.finished.connect(player.queue_free)
	else:
		player.queue_free()
		

func play_voice(audio_key: String) -> void:
	var path = "res://dialogues/voices/" + audio_key + ".mp3"
	
	if ResourceLoader.exists(path):
		var stream = load(path)
		audio_player.stream = stream
		audio_player.play()
	else:
		push_error("Глобальный Voice: Файл не найден через ResourceLoader: " + path)

func stop() -> void:
	if audio_player.is_playing():
		audio_player.stop()
