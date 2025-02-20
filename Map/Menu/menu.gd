extends VBoxContainer


const WORLD = preload("res://Map/World.tscn")

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_packed(WORLD)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	$Label.text = "It Just Works..."

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1


func _on_resume_pressed() -> void:
	get_parent().queue_free()
