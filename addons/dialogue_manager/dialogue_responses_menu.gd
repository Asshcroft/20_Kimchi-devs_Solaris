@icon("./assets/responses_menu.svg")

## A [Container] for dialogue responses provided by [b]Dialogue Manager[/b].
class_name DialogueResponsesMenu extends VBoxContainer


## Emitted when a response is focused.
signal response_focused(response: Control)

## Emitted when a response is selected.
signal response_selected(response: Control)


## Optionally specify a control to duplicate for each response
@export var response_template: Control

## The action for accepting a response (is possibly overridden by parent dialogue balloon).
@export var next_action: StringName = &""

## Automatically set up focus neighbours when the responses list changes.
@export var auto_configure_focus: bool = true

## Automatically focus the first item when showing.
@export var auto_focus_first_item: bool = true

## Hide any responses where [code]is_allowed[/code] is false
@export var hide_failed_responses: bool = false

## The list of dialogue responses.
var responses: Array = []:
	set(value):
		responses = value
		_apply_responses()
	get:
		return responses

# The previously focused item in this menu.
var _previously_focused_item: Control = null


func _ready() -> void:
	visibility_changed.connect(func():
		if auto_focus_first_item and visible and get_menu_items().size() > 0:
			var first_item: Control = get_menu_items()[0]
			if first_item.is_inside_tree():
				first_item.grab_focus()
	)

	if is_instance_valid(response_template):
		response_template.hide()

	get_viewport().gui_focus_changed.connect(_on_focus_changed)


## Get the selectable items in the menu.
func get_menu_items() -> Array:
	var items: Array = []
	for child in get_children():
		if not child.visible: continue
		if "Disallowed" in child.name: continue
		items.append(child)

	return items


## Prepare the menu for keyboard and mouse navigation.
func configure_focus() -> void:
	var items = get_menu_items()
	for i in items.size():
		var item: Control = items[i]

		# Запрещаем Tab-навигацию, оставляем только программный фокус
		item.focus_mode = Control.FOCUS_CLICK 

		# Убираем соседей, чтобы стрелки и Tab ничего не делали
		item.focus_neighbor_top = item.get_path()
		item.focus_neighbor_bottom = item.get_path()
		item.focus_next = item.get_path()
		item.focus_previous = item.get_path()

		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item, item.get_meta("response")))

	_previously_focused_item = items[0]

	if auto_focus_first_item:
		items[0].grab_focus()


#region Internal


# Set up the visual side of things.
func _apply_responses() -> void:
	for item in get_children():
		if item == response_template: continue
		remove_child(item)
		item.queue_free()

	if responses.size() > 0:
		var response_count = 1 # Счетчик для цифр
		for response in responses:
			if hide_failed_responses and not response.is_allowed: continue

			var item: Control
			if is_instance_valid(response_template):
				item = response_template.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS)
				item.show()
			else:
				item = Button.new()
			
			item.name = "Response%d" % get_child_count()
			
			# Формируем текст с цифрой (например: "1. Привет")
			var prefix = str(response_count) + ". "
			if "response" in item:
				item.response = response
				# Если у твоего шаблона есть логика отображения текста, 
				# убедись, что она учитывает префикс или добавь его в поле текста шаблона
				if item.has_method("set_text"): 
					item.set_text(prefix + response.text)
			else:
				item.text = prefix + response.text

			item.set_meta("response", response)
			item.set_meta("number_index", response_count) # Запоминаем номер для быстрого поиска

			add_child(item)
			response_count += 1

		if auto_configure_focus:
			configure_focus()


#endregion

#region Signals


func _on_focus_changed(control: Control) -> void:
	if "Disallowed" in control.name: return
	if not control in get_menu_items(): return

	if _previously_focused_item != control:
		_previously_focused_item = control
		response_focused.emit(control)


func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return

	item.grab_focus()


# Изменяем эту функцию, чтобы она не реагировала на Enter/Пробел
func _on_response_gui_input(event: InputEvent, item: Control, response) -> void:
	if "Disallowed" in item.name: return

	# Оставляем только ЛКМ (если хочешь), остальное вырезаем
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		response_selected.emit(response)

func _unhandled_input(event: InputEvent) -> void:
		
	if not visible: return

	# Глушим Tab, чтобы он не переключал фокус
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		return

	# Твой код для цифр (1-9)
	if event is InputEventKey and event.pressed:
		var key_digit = -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			key_digit = event.keycode - KEY_1 + 1
		elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
			key_digit = event.keycode - KEY_KP_1 + 1
			
		if key_digit != -1:
			var items = get_menu_items()
			if key_digit <= items.size():
				var target_item = items[key_digit - 1]
				var response = target_item.get_meta("response")
				if response.is_allowed:
					get_viewport().set_input_as_handled()
					response_selected.emit(response)
#endregion
