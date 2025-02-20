extends StaticBody3D


var player_path = "../../Player"

func _on_interactable_component_interacted() -> void: 	
	if has_node(player_path):
		var local_player = get_node(player_path)
		local_player.upgrade_weapon()
		
func _process(delta: float):
	if $InteractableComponent:
		$InteractText.text = "Cost " + str(get_node(player_path).return_upgrade_costs()) + " to upgrade this weapon"
		$InteractText.visible = !!$InteractableComponent.get_character_hovered_by_cur_camera()
