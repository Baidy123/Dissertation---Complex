extends Control


@onready var character = get_node("../../Map/Player")
const WORLD = preload("res://Map/World.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if character and character.has_node("PlayerHUD"):
		character.get_node("PlayerHUD").set_visible(false)
		character.get_node("PlayerHUD").set_process_unhandled_input(false) 

func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_retry_pressed() -> void:
	Engine.time_scale = 1
	get_tree().change_scene_to_packed(WORLD)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
