extends Area3D

var last_outlined: Node = null
var last_interactable: Node = null

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body: Node) -> void:
	# Подсветка
	if body.has_method("set_outline"):
		body.set_outline(true)
		last_outlined = body



func _on_body_exited(body: Node) -> void:
	# Снятие подсветки
	if body == last_outlined and body.has_method("set_outline"):
		body.set_outline(false)
		last_outlined = null

	# Сброс взаимодействия
	if body == last_interactable or (body.get_parent() == last_interactable):
		last_interactable = null
