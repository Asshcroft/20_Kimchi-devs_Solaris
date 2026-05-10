extends StaticBody3D

@onready var sub_viewport: SubViewport = $"../SubViewport"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		sub_viewport.push_input(event)
	elif event is InputEventMouseButton:
		var mouse_event = event.duplicate()
		sub_viewport.push_input(mouse_event)
