extends Resource
class_name InteractableResource

@export var Name: String
@export var Num: int


func outline(root: Node) -> void:
	if not root:
		return
	
	var mesh_root := root.find_child("Mesh", true, false)
	if not mesh_root:
		push_warning("Node3D с именем 'Mesh' не найден")
		return



func remove_outline(root: Node) -> void:
	if not root:
		return
	
	var mesh_root := root.find_child("Mesh", true, false)
	if not mesh_root:
		push_warning("Node3D с именем 'Mesh' не найден")
		return
	
	_remove_outline_recursive(mesh_root)


func _remove_outline_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		# убираем ТОЛЬКО overlay, основной материал не трогаем
		node.material_overlay = null
	
	for child in node.get_children():
		_remove_outline_recursive(child)
