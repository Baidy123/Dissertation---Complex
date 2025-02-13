class_name InteractableComponent
extends Node

signal interacted()

var character_hovering = {}

func interact_with():
	interacted.emit()
	
func hover_cursor(character: CharacterBody3D):
	character_hovering[character] = Engine.get_process_frames()
	
func get_character_hovered_by_cur_camera() -> CharacterBody3D:
	for character in character_hovering.keys():
		var cur_cam = get_viewport().get_camera_3d() if get_viewport() else null
		if cur_cam in character.find_children("*", "Camera3D"):
			return character
	return null

func _process(_delta):
	for character in character_hovering.keys():
		if Engine.get_process_frames() - character_hovering[character] >1:
			character_hovering.erase(character)
