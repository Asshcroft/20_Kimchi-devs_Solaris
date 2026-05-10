extends MarginContainer


var panels: Array[Control] = []

@onready var journal: Button = %Journal
@onready var system_control: Button = %System_control

func _ready() -> void:
	panels = [
		%VBoxContainer,%Journal_Panel,%System_control_Panel
	]
	journal.pressed.connect(show_panel.bind(panels[1]))
	system_control.pressed.connect(show_panel.bind(panels[2]))
	show_panel(panels[0])
	
func show_panel(panel_to_show:PanelContainer) -> void:
	for panel in panels:
		panel.hide()
	panel_to_show.show()
