extends StaticBody3D

var gui_path := "../../../GUI"
func _on_interactable_component_interacted() -> void: 	
	if has_node(gui_path):
		var gui = get_node(gui_path)
		gui.open_store()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
