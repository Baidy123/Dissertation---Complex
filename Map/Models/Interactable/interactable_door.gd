extends AnimatableBody3D
@export var cost = 500
#var door_opend := 0
var map = null
var has_used = false
@export var map_path := "../../.."
@onready var world = $"../../.."
#var gui_path :=
var player_path = "../../Player"

	
func _on_interactable_component_interacted() -> void: 	
	if has_used:
		return
	if has_node(player_path):
		var local_player = get_node(player_path)
		if local_player.currency < cost:
			return
		local_player.currency -= cost
		world.door_unlocked += 1
		get_tree().call_group("Doors", "new_door_opened")
		has_used = true
		$AnimationPlayer.play("Open")
	
		#door_opend += 1
		#map.door_opened = door_opend
		await  get_tree().create_timer(3).timeout
		queue_free()
	else:
		print("no player found")
	
func _on_other_interactable_component_interacted() -> void:
	#await  get_tree().create_timer(3).timeout
	queue_free()
	
func _process(delta: float):
	if $InteractableComponent:
		$Label3D.text = "Cost " + str(cost) + " to open this area"
		$Label3D.visible = !!$InteractableComponent.get_character_hovered_by_cur_camera()
		if has_used:
			$Label3D.visible = false
func new_door_opened():
	#door_opend += 1
	cost += 500

	
