extends InteractableObjs

func _on_interacted(body: Variant) -> void:
	Global.play_sound(Global.button_sound)
	
