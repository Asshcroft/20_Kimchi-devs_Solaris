extends Node

enum MaterialType { METAL, GROUND, WOOD, GLASS }

@export var material_type: MaterialType

func _ready():
	var group_name: String = MaterialType.keys()[material_type].to_lower()
	_add_to_group_recursive(self, group_name)

func _add_to_group_recursive(node: Node, group_name: String):
	node.add_to_group(group_name)
	for child in node.get_children():
		_add_to_group_recursive(child, group_name)
