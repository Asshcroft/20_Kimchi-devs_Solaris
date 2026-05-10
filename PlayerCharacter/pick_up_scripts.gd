extends Node

var EYE_equipped: bool = false
var hud: CanvasLayer = null
var eye_effects: Control = null

func eye_equip():
	await get_tree().create_timer(2.0).timeout
	eye_effects.act()
	EYE_equipped = true
	hud.visible = true
