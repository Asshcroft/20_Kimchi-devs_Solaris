extends Control

@onready var windows_base = $MarginContainer 

var current_window: Control
var buttons: Array = []
var pages: Array = []
var current_index: int = 0
var current_page_index: int = 0

func _ready():
	change_window("Menu")

func _input(event):
	if not is_visible_in_tree(): return
	
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left"):
		change_page(-1)
	elif event.is_action_pressed("ui_right"):
		change_page(1)

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: move_selection(-1)
			MOUSE_BUTTON_WHEEL_DOWN: move_selection(1)
			MOUSE_BUTTON_LEFT: select_current()
			MOUSE_BUTTON_RIGHT:
				if current_window and current_window.name != "Menu":
					change_window("Menu")
		get_viewport().set_input_as_handled()

func change_window(window_name: String):
	var next_window = windows_base.get_node_or_null(window_name)
	if !next_window: return

	if current_window: current_window.hide()
	current_window = next_window
	current_window.show()

	_setup_structure()

func _setup_structure():
	pages = []
	current_page_index = 0
	
	for child in current_window.get_children():
		if child is Control and not child is Button:
			if _has_any_button(child):
				pages.append(child)
	
	_refresh_content()

func _has_any_button(node) -> bool:
	for child in node.get_children():
		if child is Button: return true
		if _has_any_button(child): return true
	return false

func change_page(dir: int):
	if pages.is_empty(): return
	current_page_index = posmod(current_page_index + dir, pages.size())
	_refresh_content()

func _refresh_content():
	# 1. Видимость страниц
	if not pages.is_empty():
		for i in range(pages.size()):
			pages[i].visible = (i == current_page_index)
	
	# 2. Обновление счетчика страниц
	var page_label = current_window.get_node_or_null("Page")
	if page_label and page_label is Label:
		if pages.is_empty():
			page_label.text = "1 / 1" # Или page_label.hide()
		else:
			page_label.text = str(current_page_index + 1) + " / " + str(pages.size())
	
	# 3. Сбор кнопок
	buttons = []
	var search_root = pages[current_page_index] if not pages.is_empty() else current_window
	_find_buttons_recursive(search_root)
	
	current_index = 0
	update_focus()

func _find_buttons_recursive(node):
	for child in node.get_children():
		if child is Button and child.visible:
			buttons.append(child)
		elif child.get_child_count() > 0:
			_find_buttons_recursive(child)

func move_selection(dir):
	if buttons.is_empty(): return
	current_index = posmod(current_index + dir, buttons.size())
	update_focus()

func update_focus():
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i == current_index:
			btn.modulate = Color(2, 2, 0)
			btn.grab_focus()
		else:
			btn.modulate = Color(1, 1, 1)

func select_current():
	if buttons.is_empty(): return
	var btn = buttons[current_index]
	if btn.has_meta("target_menu"):
		change_window(btn.get_meta("target_menu"))
	else:
		btn.pressed.emit()
