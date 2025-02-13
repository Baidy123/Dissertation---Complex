extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
var has_init_sheet_opened = false
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("charactersheet"):
		if not has_node("CharacterSheet"):
			var character_sheet = load("res://FpsControllor/levelling_system/character_sheet.tscn").instantiate()
			add_child(character_sheet)
		elif has_node("CharacterSheet"):
			get_node("CharacterSheet").queue_free()
	if event.is_action_pressed("initsheet") and !has_init_sheet_opened:
		has_init_sheet_opened = true
		if not has_node("InitialSheet"):
			var init_sheet = load("res://FpsControllor/levelling_system/initial_sheet.tscn").instantiate()
			add_child(init_sheet)
		#elif has_node("InitialSheet"):
			#get_node("InitialSheet").queue_free()
			
