# manual_responsive_ui.gd
extends Control

@export var resolution_scales := {
	"3840x2160": 2.0,
	"2560x1440": 1.4,
	"1920x1080": 1.0,
	"1600x900": 0.9,
	"1366x768": 0.8,
	"1280x720": 0.75,
	"960x540": 0.55,
	"854x480": 0.5,
}

@export var default_scale := 1.0

func _ready():
	# вызов отложенно — чтобы вьюпорт точно уже имел корректный размер
	call_deferred("_update_scale")
	# подключаемся к сигналу изменения размера вьюпорта
	get_viewport().connect("size_changed", Callable(self, "_update_scale"))

func _get_viewport_size() -> Vector2:
	# несколько способов получить размер — берем первый валидный
	var vp = get_viewport()
	# 1) Попробуем свойство size
	if vp and vp.has_method("get_visible_rect"):
		var r = vp.get_visible_rect()
		if r.size.x > 0 and r.size.y > 0:
			return r.size
	return Vector2(1920, 1080)

func _update_scale():
	var size = _get_viewport_size()
	# отладочный вывод — можешь убрать позже
	print_debug("Viewport size:", size)

	var res_key = str(int(size.x)) + "x" + str(int(size.y))
	var s = default_scale
	if res_key in resolution_scales:
		s = resolution_scales[res_key]
	# Важно: для Control-нод нужно менять rect_scale (не scale)
	scale = Vector2.ONE * s
