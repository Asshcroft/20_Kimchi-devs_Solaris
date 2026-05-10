extends Node

signal progress_changed(progress)
signal load_finished
var loading_screen: PackedScene = preload("uid://bmlkb5iidnkm")
var loaded_resource: PackedScene
var scene_path: String
var progress: Array = []
var use_sub_threads: bool = true
var target_spawn_name: String = ""

func _ready() -> void:
	set_process(false)

func load_scene(_scene_path: String) -> void:
	scene_path = _scene_path
	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)
	await new_load_screen.loading_screen_ready
	start_load()

func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)

func _process(_delta: float) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	progress_changed.emit(progress[0])

	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			printerr("Error loading scene: %s" % scene_path)
			set_process(false)
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			
			get_tree().change_scene_to_packed(loaded_resource)

			await get_tree().tree_changed
			_reposition_player()


			load_finished.emit()
			set_process(false)

func _reposition_player() -> void:
	if target_spawn_name == "":
		return

	await get_tree().process_frame

	var current_scene = get_tree().current_scene
	var spawn_marker = current_scene.find_child(target_spawn_name, true, false)
	var player = get_tree().get_first_node_in_group("PlayerCharacter")

	if not spawn_marker or not player:
		return

	if not spawn_marker.is_inside_tree() or not player.is_inside_tree():
		await get_tree().process_frame

	player.global_position = spawn_marker.global_position

	var forward_vector = spawn_marker.global_transform.basis.z
	var look_target = player.global_position - forward_vector
	look_target.y = player.global_position.y
	player.look_at(look_target)

	target_spawn_name = ""
