extends CanvasLayer

@onready var store_scene = load("res://FpsControllor/levelling_system/store.tscn")
@onready var died_scene = load("res://Map/Menu/died_menu.tscn")
@onready var init_sheet_scene = load("res://FpsControllor/levelling_system/initial_sheet.tscn")
@onready var pause_menu_scene = load("res://Map/Menu/pause_menu.tscn")
@onready var world = $".."
var has_init = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
var has_init_sheet_opened = false
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		if has_node("Store"):
			Engine.time_scale = 1
			get_node("Store").queue_free()
	if event.is_action_pressed("ui_cancel"):
		if has_node("CharacterSheet"):
			get_node("CharacterSheet").queue_free()
		else:
			pause_game()

			
			
	if event.is_action_pressed("charactersheet"):
		if not has_node("CharacterSheet"):
			var character_sheet = load("res://FpsControllor/levelling_system/character_sheet.tscn").instantiate()
			add_child(character_sheet)
			Engine.time_scale = 0
		elif has_node("CharacterSheet"):
			get_node("CharacterSheet").queue_free()
	#if event.is_action_pressed("initsheet") and !has_init_sheet_opened:
		#has_init_sheet_opened = true
		#if not has_node("InitialSheet"):
			#var init_sheet = load("res://FpsControllor/levelling_system/store.tscn").instantiate()
			#add_child(init_sheet)
		#if not has_node("Store"):
			#var store = load("res://FpsControllor/levelling_system/Store.tscn").instantiate()
			#add_child(store)
		#elif has_node("Store"):
			#get_node("Store").queue_free()
		#elif has_node("InitialSheet"):
			#get_node("InitialSheet").queue_free()
func open_store():
	if not has_node("Store"):
		var store = store_scene.instantiate()
		store.door_opened = world.door_unlocked
		Engine.time_scale = 0
		add_child(store)
		
func pause_game():
		if not has_node("PauseMenu"):
			var pause_menu = pause_menu_scene.instantiate()
			Engine.time_scale = 0
			add_child(pause_menu)
		else:
			get_node("PauseMenu").queue_free()
			
			
func _on_player_died() -> void:
	var died_menu = died_scene.instantiate()
	Engine.time_scale = 0
	add_child(died_menu)

func init_sheet():
	if has_init:
		return
	has_init = true
	var init_sheet = init_sheet_scene.instantiate()
	add_child(init_sheet)
	Engine.time_scale = 0
	
