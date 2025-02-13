class_name LevellingSystem
extends Node3D
@export var player : Player

@export var curr_level : int = 1
@export var max_level : int = 12
@export var skill_points_gained : int = 10

var constitution : int = 0
var strength : int = 0
var perception : int = 0

#var experience : int = 0
#var experience_total : int = 0
var experience_required : int = get_required_experience(curr_level + 1)


@export var slow_factor = 0.5
@export var dmg_reduce_rate = 0.5

@export var speed_boost_multiplier: float = 2.0
@export var perk_requirement = {
	"1a": {
		"name": "qinggong",
		"description": "Enables double jumping and significantly enhances aerial maneuverability.",
		"attribute": {"constitution": 6},
		"skill": {"endurance": 60},
		"points": 1
	},
	"1b": {
		"name": "bullet time",
		"description": "Slows down time.",
		"attribute": {"perception": 6},
		"skill": {"longguns": 60},
		"points": 1
	},
	"1c": {
		"name": "tough skin",
		"description": "Significantly reduces damage from enemy attacks.",
		"attribute": {"constitution": 9},
		"skill": {"resilience": 100},
		"points": 1
	},
	"2a": {
		"name": "deserter",
		"description": "Greatly increases the character's movement speed in seconds after being attacked .",
		"attribute": {"constitution": 4},
		"skill": {"endurance": 45},
		"points": 1
	},
	"2b": {
		"name": "cowboy",
		"description": "Greatly improves weapon accuracy while moving, reduces recoil.",
		"attribute": {"perception": 9},
		"skill": {"handguns": 100},
		"points": 1
	},
	"2c": {
		"name": "pack rat",
		"description": "Doubles the character's ammunition reserves.",
		"attribute": {"constitution": 4},
		"skill": {"endurance": 45},
		"points": 1
	},
	"3a": {
		"name": "vampire",
		"description": "Restores a small amount of health after attacking an enemy in melee combat.",
		"attribute": {"strength": 6},
		"skill": {"melee": 60},
		"points": 1
	},
	"3b": {
		"name": "flak jacket",
		"description": "Prevents the character from taking damage from explosions.",
		"attribute": {"constitution": 4},
		"skill": {"resilience": 45},
		"points": 1
	},
	"3c": {
		"name": "die hard",
		"description": " Grants 2 seconds of invincibility when taking a fatal hit, with a cooldown of 4 minutes.",
		"attribute": {"strength": 9},
		"skill": {"intimidation": 100},
		"points": 1
	}
}
@export var bullet_time_cd := 0.0
@export var deserter_cd := 0.0
@export var die_hard_cd := 0.0

func _ready() -> void:
	constitution = player.attributes["constitution"]
	strength = player.attributes["strength"]
	perception = player.attributes["perception"]
	curr_level = player.curr_level
	player.experience["req_exp"] = experience_required

func get_required_experience(level):
	if curr_level < max_level:
		return round(200 * (pow(level, 2) + level * 4))
	else :
		return 0 #round(200 * (pow(max_level - 1, 2) + (max_level - 1) * 4))
		
func gain_experience(amount):
	if curr_level >= max_level:
		player.experience["curr_lvl_exp"] = 0
		return
	if curr_level < max_level:
		player.experience["total_exp"] += amount
		player.experience["curr_lvl_exp"] += amount
		while player.experience["curr_lvl_exp"] >= experience_required:
			player.experience["curr_lvl_exp"] -= experience_required
			level_up()
			if curr_level >= max_level:
				player.experience["curr_lvl_exp"] = 0
				break

func level_up():
	if curr_level < max_level:
		curr_level += 1
		experience_required = get_required_experience(curr_level + 1)
		player.experience["req_exp"] = experience_required
		if player and player.has_method("on_level_up"):
			player.on_level_up(skill_points_gained)
			print(curr_level)
			
			print(experience_required)
			

		#print("Level up! current level:", curr_level)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("gain_exp"):
		gain_experience(10000)
		print(player.experience["total_exp"])
		print(player.experience["curr_lvl_exp"])
		#player.take_damage(20, " ")
	
		
#PERKS
#1a
var jump_twice = false
func qinggong(delta: float) -> void:
	if not jump_twice and Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_velocity * 1.2
		jump_twice = true

	var base_multiplier = 1.0
	if deserter_active:
		base_multiplier *= 2.0   
	if player.is_sprinting:
		base_multiplier *= player.sprint_multi 

	player.velocity.x = player.wish_dir.x * player.walk_speed * base_multiplier
	player.velocity.z = player.wish_dir.z * player.walk_speed * base_multiplier

	player.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * 0.8


var is_bullet_time_active = false
#1b
func bullet_time():
	if is_bullet_time_active:
		return  
	if bullet_time_cd != 0:
		return
	bullet_time_cd = 5.0
	is_bullet_time_active = true
	Engine.time_scale = slow_factor  
	await get_tree().create_timer(1 * slow_factor).timeout
	Engine.time_scale = 1.0  
	is_bullet_time_active = false
	bullet_time_cold_down()
	
func bullet_time_cold_down():
	await get_tree().create_timer(bullet_time_cd).timeout
	bullet_time_cd = 0
	$"../PlayerHUD".get_node("BulletTimeReminder").set_text("Bullet Time is ready...")
	$"../PlayerHUD".get_node("BulletTimeReminder").set_visible(true)
	await get_tree().create_timer(3.0).timeout
	$"../PlayerHUD".get_node("BulletTimeReminder").set_visible(false)
	
#1c
func tough_skin(dmg: float):
	return dmg * dmg_reduce_rate

#2a
var deserter_active: bool = false
func deserter():
	if deserter_cd != 0:
		return
	deserter_cd = 10
	deserter_active = true
	await get_tree().create_timer(2.0).timeout
	deserter_active = false
	deserter_cold_down()
	
func deserter_cold_down():
	await get_tree().create_timer(deserter_cd).timeout
	deserter_cd = 0
	$"../PlayerHUD".get_node("DieHardReminder").set_text("Die Hard is ready...")
	$"../PlayerHUD".get_node("DieHardReminder").set_visible(true)
	await get_tree().create_timer(3.0).timeout
	$"../PlayerHUD".get_node("DieHardReminder").set_visible(false)
	
#2b
func cowboy(recoil: float):
	return recoil * 0.1

#3c
var die_hard_active : bool = false
func die_hard():
	if die_hard_cd != 0:
		get_tree().change_scene_to_file("res://StarterScene.tscn")
		return
	die_hard_cd = 60
	die_hard_active = true
	await get_tree().create_timer(2.0).timeout
	die_hard_active = false
	die_hard_cold_down()
	
func die_hard_cold_down():
	await get_tree().create_timer(die_hard_cd).timeout
	die_hard_cd = 0
	
func update_influence_from_skills():
	player.skills_influence["endurance"] = 1 + max(0, player.skills["endurance"] -15) * 0.005
	player.skills_influence["resilience"] = max(0, player.skills["resilience"] -15) * 0.003
	player.skills_influence["melee"] = 1 + max(0, player.skills["melee"] -15) * 0.05
	player.skills_influence["intimidation"] = max(0, player.skills["intimidation"] -15) * 0.005
	player.skills_influence["handguns"] = max(0, player.skills["handguns"] -15) * 0.0025
	player.skills_influence["longguns"] = max(0, player.skills["longguns"] -15) * 0.0025
	#print(character.skills_influence["handguns"])
