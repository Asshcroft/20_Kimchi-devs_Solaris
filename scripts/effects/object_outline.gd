extends Node3D

var original_materials := {}
var outlined_material: Material

func _ready():
	outlined_material = load("res://materials/object_outline_material.tres")
	_save_original_materials(self)  # Рекурсивно сохраняем материалы

func _save_original_materials(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			original_materials[child] = child.material_overlay
		_save_original_materials(child)  # Рекурсия для вложенных мешей

func set_outline(enable: bool) -> void:
	for mesh in original_materials.keys():
		if enable:
			mesh.material_overlay = outlined_material
		else:
			mesh.material_overlay = original_materials[mesh]
