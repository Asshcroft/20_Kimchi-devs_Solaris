extends Node3D
@export var resource: InteractableResource

func _ready() -> void:
	pass # Replace with function body.


func use() -> void:
	resource.outline(self)

func unuse() -> void:
	resource.remove_outline(self)
