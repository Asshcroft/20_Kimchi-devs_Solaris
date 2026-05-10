extends Camera3D
class_name Hands_camera

@onready var fps_rig: Node3D = $hand_orig

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Плавное возвращение рук в исходную позицию
	fps_rig.position.x = lerp(fps_rig.position.x, 0.0, delta * 7.0)
	fps_rig.position.y = lerp(fps_rig.position.y, -0.5, delta * 10.0)

func sway(sway_amount: Vector2) -> void:
	# Реакция рук на движение мыши
	fps_rig.position.x -= sway_amount.x * 0.0005
	fps_rig.position.y += sway_amount.y * 0.0002
