extends CharacterBody3D


var player = null
var state_machine

const SPEED = 4

const ATTACK_RANGE = 2.0

@export var base_health := 100
var health = 100
@export var base_dmg := 25
var dmg = 30

@export var player_path := "../Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
#@onready var level = player.curr_level


# Called when the node enters the scene tree for the first time.
func get_zombie_hp(player_level: int) -> int:
	return round(base_health + 30 * player_level + 2 * pow(player_level, 2))

func get_zombie_damage(player_level: int) -> int:
	return round(25 + 5 * player_level)
	
func _ready():
	player = get_node(player_path)
	var level_for_init = player.curr_level
	health = get_zombie_hp(level_for_init)
	dmg = get_zombie_damage(level_for_init)
	print(health)
	#var level = player.curr_level
	state_machine = anim_tree.get("parameters/playback")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walk":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Run":
			# Navigation
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	# Conditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	
	move_and_slide()

func get_experience_per_zombie(level: int) -> int:
	return round(100 + 10 * level + 0.1 * pow(level, 4))
	
func _target_in_range():
	if anim_tree.get("parameters/conditions/attack"):
		return global_position.distance_to(player.global_position) < 1.2 * ATTACK_RANGE
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	




func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.take_damage(dmg)


func _on_area_3d_body_part_hit(dmg, critical_multi) -> void:
	#print("hit")
	health -= dmg * critical_multi
	player.currency += 10 * critical_multi

	if health <= 0:
		var level = player.curr_level
		player.currency += 100
		var exp = get_experience_per_zombie(level)
		player.gain_exp(exp)
		if $CollisionShape3D:
			$CollisionShape3D.queue_free()
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(6).timeout
		queue_free()
