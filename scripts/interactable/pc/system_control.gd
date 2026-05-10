extends PanelContainer


var panels: Array[PanelContainer] = []

@onready var first_button: Button = %first_button


func _ready() -> void:
	panels = [
		%Door_control
	]
	first_button.pressed.connect(show_panel.bind(panels[0]))
	
	show_panel(panels[0])
	first_button.grab_focus()
	
func show_panel(panel_to_show:PanelContainer) -> void:
	for panel in panels:
		panel.hide()
	panel_to_show.show()
