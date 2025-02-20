extends Control



#var skill_available_points : int
#var attribute_available_points : int 
var currency :int 
var selected_item_id := ""
var selected_item_type := ""
var door_opened :int = 0
#
#var constitution_add = 0
#var strength_add = 0
#var perception_add = 0
#
#var endurance_add = 0
#var resilience_add = 0
#var melee_add = 0
#var intimidation_add = 0
#var handguns_add = 0
#var longguns_add = 0
@onready var character = get_node("../../Map/Player")
@onready var levelling_sys = get_node("../../Map/Player/LevellingSystem")

func _ready() -> void:
	
	if character and character.has_node("PlayerHUD"):
		character.get_node("PlayerHUD").set_visible(false)
		character.get_node("PlayerHUD").set_process_unhandled_input(false) 
		
	for button in get_tree().get_nodes_in_group("WeaponButtons"):
		button.set_disabled(false)
		# 让每个按钮的 pressed 信号连接到同一个函数，并传入按钮名字(或自定义 ID)
		button.pressed.connect(_on_weapon_button_pressed.bind(button.get_name()))
	%PurchaseButton.pressed.connect(_on_purchase_button_pressed)
	$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/NameLabel.text = ""
	$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/CostLabel.text = ""
	$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/DescLabel.text = ""
	$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = ""
	#$HBoxContainer/VBoxContainer/Attributes.set_visible(true)
	#$HBoxContainer/VBoxContainer/Skills.set_visible(false)
	$HBoxContainer/VBoxContainer/Weapons.set_visible(true)
	$HBoxContainer/VBoxContainer/Perks.set_visible(false)
	currency = character.currency
	#load_stats()
	load_perks()
	_update_weapon_buttons()
	#attribute_available_points = character.attribute_available_points
	#skill_available_points = character.skill_available_points
	
	#for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
		#button.set_disabled(true)
		#button.set_visible(false)
	#for button in get_tree().get_nodes_in_group("AttributeMinusButtons"):
		#button.set_disabled(true)
		#button.set_visible(false)
	#%AttributeAvailablePoints.set_text("Points: " + str(attribute_available_points))
	#if attribute_available_points == 0:
		#$HBoxContainer/VBoxContainer/Attributes/AttributeName/AttributePoints.set_visible(false)
		#$HBoxContainer/VBoxContainer/Attributes/AttributeName/AttributePoints/AttributeConfirm.set_visible(false)
	#else:
		#for button in get_tree().get_nodes_in_group("AttributePlusButtons"):
			#button.set_disabled(false)
			#button.set_visible(true)
	
	#elif $HBoxContainer/VBoxContainer/Skills.visible == true:
		
	#for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
		#button.set_disabled(true)
		#button.set_visible(false)
		##print(button.get_parent().get_parent().name.to_lower())
		#button.pressed.connect(increase_skill.bind(button.get_parent().get_parent().name)) 
	#for button in get_tree().get_nodes_in_group("SkillMinusButtons"):
		#button.set_disabled(true)
		#button.set_visible(false)
		#button.pressed.connect(decrease_skill.bind(button.get_parent().get_parent().name)) 
	#%SkillAvailablePoints.set_text("Points: " + str(skill_available_points))
	%PerkPoints.set_text("$ " + str(character.currency))
	#if skill_available_points == 0:
		#pass
		#$HBoxContainer/VBoxContainer/Attribute/AttributeName/AttributePoints.set_visible(false)
	#else:
		#for button in get_tree().get_nodes_in_group("SkillPlusButtons"):
			#button.set_disabled(false)
			#button.set_visible(true)
func _on_weapon_button_pressed(weapon_button_name: String) -> void:

	selected_item_id = weapon_button_name.to_lower()

	# 从字典里获取相应信息
	if character.weapons.has(selected_item_id):
		var w_info = character.weapons[selected_item_id]
		selected_item_type = w_info["type"]
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/NameLabel.text = w_info["name"]
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/CostLabel.text = "Cost: " + str(w_info["price"])
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/DescLabel.text = w_info["description"]
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = ""
	else:
		# 如果没找到
		selected_item_id = ""
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/NameLabel.text = ""
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/CostLabel.text = ""
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/DescLabel.text = "Weapon not found..."
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = ""
		

func _on_purchase_button_pressed() -> void:
	if selected_item_id == "":
		%Warning.text = "No weapon selected."
		return

	if not character.weapons.has(selected_item_id):
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = "Invalid weapon."
		return

	var w_info = character.weapons[selected_item_id]
	var cost = w_info["price"]

	# 1. 检查玩家金钱
	if currency < cost:
		%Warning.text = "Not enough money!"
		return
	match w_info["type"]:
		"weapon":
			_buy_weapon_logic(w_info)
		"medkit":
			_buy_medkit_logic(w_info)
		_:
			# 其它类型, 按需扩展
			$ItemInfo/WarningLabel.text = "Unknown item type!"
	## 2. 扣除金钱
	#currency -= cost
	#character.weapons[selected_item_id]["owned"] = true
	#_update_weapon_buttons()
	#selected_item_id = ""
	#
	#
	## 4. 加载对应的 .tres 并添加到玩家的武器管理器
	#var weapon_file_path = w_info["file_path"]
	#var weapon_resource = load(weapon_file_path)
	#if weapon_resource == null:
		#$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = "Weapon resource not found: " + weapon_file_path
		#return
#
	## 假设你的 Player 节点或 WeaponManager 有一个 add_weapon(res) 方法
	#var weapon_manager = get_node("../../Player/WeaponManager")  # 修改成你实际的路径
	#if weapon_manager and weapon_manager.has_method("add_weapon"):
		#weapon_manager.add_weapon(weapon_resource)
	#else:
		#$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = "Can't add weapon. WeaponManager not found or missing add_weapon method."
#
	## 5. 提示购买成功
	#%Warning.text = "Purchase success!"
func _buy_weapon_logic(info: Dictionary) -> void:
	if info["owned"] == true:
		%Warning.text = "You already own this weapon!"
		return
	
	# 扣钱
	currency -= info["price"]

	# 设置 owned = true
	info["owned"] = true
	
	# 隐藏按钮 (若你想让已拥有武器按钮消失)
	_update_weapon_buttons()
	
	var weapon_file_path = info["file_path"]
	var weapon_resource = load(weapon_file_path)
	if weapon_resource == null:
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = "Weapon resource not found: " + weapon_file_path
		return

	# 假设你的 Player 节点或 WeaponManager 有一个 add_weapon(res) 方法
	var weapon_manager = get_node("../../Map/Player/WeaponManager")  # 修改成你实际的路径
	if weapon_manager and weapon_manager.has_method("add_weapon"):
		weapon_manager.add_weapon(weapon_resource)
	else:
		$HBoxContainer/VBoxContainer/Weapons/WeaponInfo/Panel/MarginContainer/Info/WeaponInfo/WarningLabel.text = "Can't add weapon. WeaponManager not found or missing add_weapon method."

	%Warning.text = "Purchase success!"

func _update_weapon_buttons() -> void:
	# 更新货币 Label
	%Currency.text = "$ " + str(currency)

	# 1) 取得 "WeaponName" 容器
	var parent_node = $HBoxContainer/VBoxContainer/Weapons/WeaponName
	var child_count = parent_node.get_child_count()

	# 2) 计算“本次要显示多少个按钮”
	#    (例：默认3个 + 每 door_opened 累积2个就+1可见按钮)
	var default_visible = 4
	var extra_for_doors = floor(door_opened / 2)  # door_opened每2加1
	var total_visible = default_visible + extra_for_doors

	# 3) 遍历所有子节点(每个子节点 = 一个武器按钮)
	for i in range(child_count):
		var wbutton = parent_node.get_child(i+1)
		# 取得按钮名称当作武器ID(或你可以 self-defined)
		#print(i)
		var w_id = wbutton.name.to_lower()  
		#print(w_id)

		# 如果 player.weapons 里没有这个w_id，就隐藏掉
		if not character.weapons.has(w_id):
			#wbutton.visible = false
			continue

		var w_info = character.weapons[w_id]

		match w_info["type"]:
			"weapon":
				# 首先判断“owned”是否存在 & 是否 true
				if w_info.has("owned") and w_info["owned"] == true:
					wbutton.visible = false
				else:
					# 检查当前 i 与 total_visible
					if i+1 < total_visible:
						wbutton.visible = true
					else:
						wbutton.visible = false

			"medkit":
				# 没有 "owned" bool, 而是 "owned_quantity" 
				# 只要 "owned_quantity" < "max_quantity" 就显示按钮 (或你自己需求)
				if w_info.has("owned_quantity") and w_info.has("max_quantity"):
					if w_info["owned_quantity"] < w_info["max_quantity"]:
						wbutton.visible = true
						return
					else:
						wbutton.visible = false
						return
				else:
					# 没有这俩字段也可选默认显示
					wbutton.visible = true
					return
func _buy_medkit_logic(info: Dictionary) -> void:
	var owned_q = info["owned_quantity"]
	var max_q = info["max_quantity"]
	var item_id = info["name"]
	# 检查是否达到上限
	if owned_q >= max_q:
		%Warning.text = "You cannot carry more " + item_id
		return
	
	# 扣钱
	currency -= info["price"]
	
	# owned_quantity +1
	info["owned_quantity"] = owned_q + 1
	
	# 如果达到上限，就可以（可选）隐藏或禁用按钮
	#if info["owned_quantity"] >= max_q:
		#
		#var button_path = "HBoxContainer/VBoxContainer/Weapons/WeaponName/%s" %item_id
		#if has_node(button_path):
			#get_node(button_path).visible = false
	
	# 也要把数量同步到玩家(若你有 Player 脚本管理背包)
	# get_node("/root/Player").increase_medkit(1)
	_update_weapon_buttons()
	%Warning.text = "You bought 1 " + info["name"] + "! (Now you have " + str(info["owned_quantity"]) + ")"

func load_perks():
	if not character:
		return
	
	for button in get_tree().get_nodes_in_group("PerksButtons"):
		var perk_id = button.get_name().to_lower()
		var child_node = null
		button.tooltip_text =  str(levelling_sys.perk_requirement[perk_id]["name"].to_upper()
								+ ": " + levelling_sys.perk_requirement[perk_id]["description"])
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


				
	if req_dict.has("currency"):
		var required_val =  req_dict["currency"]
		if currency < required_val:
			return false

	return true


	
func spend_perk_points(perk_id: String):
	if not character:
		return
	if not levelling_sys.perk_requirement.has(perk_id):
		return
	var req_dict = levelling_sys.perk_requirement[perk_id]
	var cost = 1
	if req_dict.has("currency"):
		cost = req_dict["currency"]
	character.perks[perk_id] = true
	currency -= cost
	%PerkPoints.set_text("$ " + str(currency))
	for button in get_tree().get_nodes_in_group("PerksButtons"):
		if button.get_name().to_lower() == perk_id:
			if button.has_node("TextureRect"):
				var child_node = button.get_node("TextureRect")
				child_node.visible = character.perks[perk_id]  
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			load_perks()
			break




func _process(delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
	
func _exit_tree(): 

	if character and character.has_node("PlayerHUD"):
		character.get_node("PlayerHUD").visible = true  
		character.get_node("PlayerHUD").set_process_unhandled_input(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	character.currency = currency
	



func _on_attribute_pressed() -> void:
	$HBoxContainer/VBoxContainer/Weapons.show()
	$HBoxContainer/VBoxContainer/Perks.hide()
	_update_weapon_buttons()
	
	


func _on_skills_pressed() -> void:
	$HBoxContainer/VBoxContainer/Attributes.hide()
	$HBoxContainer/VBoxContainer/Skills.show()
	$HBoxContainer/VBoxContainer/Perks.hide()



func _on_perks_pressed() -> void:
	$HBoxContainer/VBoxContainer/Weapons.hide()
	$HBoxContainer/VBoxContainer/Perks.show()
	load_perks()
