extends Control



var skill_available_points : int
var attribute_available_points : int 
var perk_available_points :int 

var constitution_add = 0
var strength_add = 0
var perception_add = 0

var endurance_add = 0
var resilience_add = 0
var melee_add = 0
var intimidation_add = 0
var handguns_add = 0
var longguns_add = 0
@onready var character = get_node("../../Player")
@onready var levelling_sys = get_node("../../Player/LevellingSystem")

func _ready() -> void:
	if character and character.has_node("PlayerHUD"):
		character.get_node("PlayerHUD").set_visible(false)
		character.get_node("PlayerHUD").set_process_unhandled_input(false) 
		
	$HBoxContainer/VBoxContainer/Attributes.set_visible(true)
	$HBoxContainer/VBoxContainer/Skills.set_visible(false)
	$HBoxContainer/VBoxContainer/Perks.set_visible(false)
	load_stats()
	load_perks()
	attribute_available_points = character.attribute_available_points
	skill_available_points = character.skill_available_points
	
	for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
		button.set_disabled(true)
		button.set_visible(false)
	for button in get_tree().get_nodes_in_group("AttributeMinusButtons"):
		button.set_disabled(true)
		button.set_visible(false)
	%AttributeAvailablePoints.set_text("Points: " + str(attribute_available_points))
	if attribute_available_points == 0:
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/AttributePoints.set_visible(false)
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/AttributePoints/AttributeConfirm.set_visible(false)
	else:
		for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
			button.set_disabled(false)
			button.set_visible(true)
	
	#elif $HBoxContainer/VBoxContainer/Skills.visible == true:
		
	for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
		button.set_disabled(true)
		button.set_visible(false)
		#print(button.get_parent().get_parent().name.to_lower())
		button.pressed.connect(increase_skill.bind(button.get_parent().get_parent().name)) 
	for button in get_tree().get_nodes_in_group("SkillMinusButtons"):
		button.set_disabled(true)
		button.set_visible(false)
		button.pressed.connect(decrease_skill.bind(button.get_parent().get_parent().name)) 
	%SkillAvailablePoints.set_text("Points: " + str(skill_available_points))
	%PerkPoints.set_text("Points: " + str(character.perk_available_points))
	if skill_available_points == 0:
		pass
		#$HBoxContainer/VBoxContainer/Attribute/AttributeName/AttributePoints.set_visible(false)
	else:
		for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
			button.set_disabled(false)
			button.set_visible(true)


func load_stats():
	if character:
		#if $HBoxContainer/VBoxContainer/Attributes.visible == true:
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/MarginContainer/VBoxContainer/Level.set_text("Lvl." + str(character.curr_level))
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/MarginContainer/VBoxContainer/Aptitude.set_text(str(character.aptitude))
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/MarginContainer/VBoxContainer/Exp.set_text("Exp. :" + str(character.experience["curr_lvl_exp"]) + "/" 
																												+ str(character.experience["req_exp"]))
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/Constitution/Panel/Stats/Value.set_text(str(character.attributes["constitution"]))
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/Strength/Panel/Stats/Value.set_text(str(character.attributes["strength"]))
		$HBoxContainer/VBoxContainer/Attributes/AttributeName/Perception/Panel/Stats/Value.set_text(str(character.attributes["perception"]))
		#elif $HBoxContainer/VBoxContainer/Skills.visible == true:
		$HBoxContainer/VBoxContainer/Skills/SkillName/Endurance/Panel/Stats/Value.set_text(str(character.skills["endurance"]))
		$HBoxContainer/VBoxContainer/Skills/SkillName/Resilience/Panel/Stats/Value.set_text(str(character.skills["resilience"]))
		$HBoxContainer/VBoxContainer/Skills/SkillName/Melee/Panel/Stats/Value.set_text(str(character.skills["melee"]))
		$HBoxContainer/VBoxContainer/Skills/SkillName/Intimidation/Panel/Stats/Value.set_text(str(character.skills["intimidation"]))
		$HBoxContainer/VBoxContainer/Skills/SkillName/Handguns/Panel/Stats/Value.set_text(str(character.skills["handguns"]))
		$HBoxContainer/VBoxContainer/Skills/SkillName/LongGuns/Panel/Stats/Value.set_text(str(character.skills["longguns"]))
	else: return
	

func load_perks():
	if not character:
		return
	
	for button in get_tree().get_nodes_in_group("PerksButtons"):
		var perk_id = button.get_name().to_lower()
		var child_node = null
		button.tooltip_text =  str(levelling_sys.perk_requirement[perk_id]["name"].to_upper()
								+ ": " + levelling_sys.perk_requirement[perk_id]["description"]
								+ "\n" + 
								"requirement: "+ "\n" + str(levelling_sys.perk_requirement[perk_id]["attribute"])
								+ "\n" + 
								str(levelling_sys.perk_requirement[perk_id]["skill"]) )
		button.pressed.connect(spend_perk_points.bind(button.name.to_lower())) 
		if button.has_node("TextureRect"):
			child_node = button.get_node("TextureRect")

		
		if perk_id in character.perks and character.perks[perk_id] == true:
			
			if child_node:
				child_node.visible = true
			
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:

			if check_perk_requirements(perk_id):
			
				
				if child_node:
					child_node.visible = false
				button.disabled = false
			else:
				
				if child_node:
					child_node.visible = false
				button.disabled = true


func check_perk_requirements(perk_id: String) -> bool:
	if not levelling_sys.perk_requirement.has(perk_id):
		return false  

	var req_dict =  levelling_sys.perk_requirement[perk_id]

	if req_dict.has("attribute"):
		for attr_name in req_dict["attribute"]:
			var required_val = req_dict["attribute"][attr_name]
			var current_val = character.attributes[attr_name] if character.attributes.has(attr_name) else 0
			if current_val < required_val:
				return false
	if req_dict.has("skill"):
		for skill_name in req_dict["skill"]:
			var required_val = req_dict["skill"][skill_name]
			var current_val = character.skills[skill_name] if character.skills.has(skill_name) else 0
			if current_val < required_val:
				return false
				
	if req_dict.has("points"):
		var required_val =  req_dict["points"]
		if character.perk_available_points < required_val:
			return false

	return true

func increase_attribute(stat: String):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") +1)
	%AttributeName.get_node(stat + "/Panel/Stats/Change").set_text("+" + str(
												get(stat.to_lower() + "_add")) + " ")
	%AttributeName.get_node(stat + "/Panel/Min").set_disabled(false)
	%AttributeName.get_node(stat + "/Panel/Min").set_visible(true)
	attribute_available_points -= 1
	%AttributeAvailablePoints.set_text("Points: " + str(attribute_available_points))
	if attribute_available_points == 0:
		for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
			button.set_disabled(true)
			button.set_visible(false)
	print(stat + "Plus")
	
func decrease_attribute(stat: String):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") -1)
	if get(stat.to_lower() + "_add") == 0:
		%AttributeName.get_node(stat + "/Panel/Min").set_disabled(true)
		%AttributeName.get_node(stat + "/Panel/Min").set_visible(false)
		%AttributeName.get_node(stat + "/Panel/Stats/Change").set_text("")
	else :
		%AttributeName.get_node(stat + "/Panel/Stats/Change").set_text("+" + str(
												get(stat.to_lower() + "_add")) + " ")
	attribute_available_points += 1
	%AttributeAvailablePoints.set_text("Points: " + str(attribute_available_points))
	for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
		button.set_disabled(false)
		button.set_visible(true)
	print((stat + "Minus"))
	
func increase_skill(stat: String):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") +1)
	%SkillName.get_node(stat + "/Panel/Stats/Change").set_text("+" + str(
												get(stat.to_lower() + "_add")) + " ")
	%SkillName.get_node(stat + "/Panel/Min").set_disabled(false)
	%SkillName.get_node(stat + "/Panel/Min").set_visible(true)
	skill_available_points -= 1
	%SkillAvailablePoints.set_text("Points: " + str(skill_available_points))
	if skill_available_points == 0:
		for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
			button.set_disabled(true)
			button.set_visible(false)
	print(stat + "Plus")
	
func decrease_skill(stat: String):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") -1)
	if get(stat.to_lower() + "_add") == 0:
		%SkillName.get_node(stat + "/Panel/Min").set_disabled(true)
		%SkillName.get_node(stat + "/Panel/Min").set_visible(false)
		%SkillName.get_node(stat + "/Panel/Stats/Change").set_text("")
	else :
		%SkillName.get_node(stat + "/Panel/Stats/Change").set_text("+" + str(
												get(stat.to_lower() + "_add")) + " ")
	skill_available_points += 1
	%SkillAvailablePoints.set_text("Points: " + str(skill_available_points))
	for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
		button.set_disabled(false)
		button.set_visible(true)
	print((stat + "Minus"))
	
func spend_perk_points(perk_id: String):
	if not character:
		return
	if not levelling_sys.perk_requirement.has(perk_id):
		return
	var req_dict = levelling_sys.perk_requirement[perk_id]
	var cost = 1
	if req_dict.has("points"):
		cost = req_dict["points"]
	character.perks[perk_id] = true
	character.perk_available_points -= cost
	%PerkPoints.set_text("Points: " + str(character.perk_available_points))
	for button in get_tree().get_nodes_in_group("PerksButtons"):
		if button.get_name().to_lower() == perk_id:
			if button.has_node("TextureRect"):
				var child_node = button.get_node("TextureRect")
				child_node.visible = character.perks[perk_id]  
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			load_perks()
			break

	
func _on_attribute_confirm_pressed() -> void:
	if strength_add + constitution_add + perception_add == 0:
		print("Nothing changed")
	else :
		character.attribute_available_points = attribute_available_points
		character.attributes["constitution"] += constitution_add
		character.attributes["strength"] += strength_add
		character.attributes["perception"] += perception_add
		character.skills["endurance"] += constitution_add * 5
		character.skills["resilience"] += constitution_add * 5
		character.skills["melee"] += strength_add * 5
		character.skills["intimidation"] += strength_add * 5
		character.skills["handguns"] += perception_add * 5
		character.skills["longguns"] += perception_add * 5
		
		strength_add = 0
		constitution_add = 0
		perception_add = 0
		load_stats()
		for button in get_tree().get_nodes_in_group("AttributeMinusButtons"):
			button.set_visible(false)
		for label in get_tree().get_nodes_in_group("AttributeChangeLabels"):
			label.set_text(" ")
		if attribute_available_points == 0:
			$HBoxContainer/VBoxContainer/Attributes/AttributeName/AttributePoints/AttributeConfirm.set_visible(false)

func _on_skill_confirm_pressed() -> void:
	if endurance_add + resilience_add + melee_add + intimidation_add + handguns_add + longguns_add == 0:
		print("Nothing changed")
	else :
		character.skill_available_points = skill_available_points
		character.skills["endurance"] += endurance_add
		character.skills["resilience"] += resilience_add
		character.skills["melee"] += melee_add
		character.skills["intimidation"] +=intimidation_add
		character.skills["handguns"] += handguns_add
		character.skills["longguns"] += longguns_add
		endurance_add = 0
		resilience_add = 0
		melee_add = 0
		intimidation_add = 0
		handguns_add = 0
		longguns_add = 0
		load_stats()
		for button in get_tree().get_nodes_in_group("SkillMinusButtons"):
			button.set_visible(false)
		for label in get_tree().get_nodes_in_group("SkillChangeLabels"):
			label.set_text(" ")




func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		

	
func _exit_tree(): 
	#character.sprint_multi *= 1+character.skills["endurance"]*0.01
	#print(character.sprint_multi)
	levelling_sys.update_influence_from_skills()
	if character and character.has_node("PlayerHUD"):
		character.get_node("PlayerHUD").visible = true  
		character.get_node("PlayerHUD").set_process_unhandled_input(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	



func _on_attribute_pressed() -> void:
	$HBoxContainer/VBoxContainer/Attributes.show()
	$HBoxContainer/VBoxContainer/Skills.hide()
	$HBoxContainer/VBoxContainer/Perks.hide()

	
	


func _on_skills_pressed() -> void:
	$HBoxContainer/VBoxContainer/Attributes.hide()
	$HBoxContainer/VBoxContainer/Skills.show()
	$HBoxContainer/VBoxContainer/Perks.hide()



func _on_perks_pressed() -> void:
	$HBoxContainer/VBoxContainer/Attributes.hide()
	$HBoxContainer/VBoxContainer/Skills.hide()
	$HBoxContainer/VBoxContainer/Perks.show()
	load_perks()
