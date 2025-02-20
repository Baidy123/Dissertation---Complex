extends CharacterBody3D


var player = null
var state_machine

const SPEED = 5

const ATTACK_RANGE = 2.0

@export var base_health := 100
var health = 100
@export var base_dmg := 25
var dmg = 30

@export var player_path := "../Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
#@onready var level = player.curr_level
var is_dead = false
var attack_range = ATTACK_RANGE

const MAX_STEP_HEIGHT = 0.5
signal zombie_died()

func get_zombie_hp(player_level: int) -> int:
	return round(base_health + 30 * player_level + 2 * pow(player_level, 2))

func get_zombie_damage(player_level: int) -> int:
	return round(25 + 5 * player_level)
	
func _ready():
	$Hp.visible = true
	player = get_node(player_path)
	var level_for_init = player.curr_level
	health = get_zombie_hp(level_for_init)
	dmg = get_zombie_damage(level_for_init)
	$Hp.text = str(health)
	#print(health)
	#var level = player.curr_level
	state_machine = anim_tree.get("parameters/playback")
	
func _snap_up_to_stairs_check(delta) -> bool :
	#if not is_on_floor() and not _snapped_to_stairs_last_frame : 
		#return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0,MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if(_run_body_test_motion(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT * 2, 0), down_check_result) 
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_travel() - self.global_position).y > MAX_STEP_HEIGHT: 
			return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_collision_point() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding():
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			#_snapped_to_stairs_last_frame = true
			return true
	return false
	
func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: 
		result = PhysicsTestMotionResult3D.new()
		
	var param = PhysicsTestMotionParameters3D.new()
	param.from = from
	param.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), param, result)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector3.ZERO
	if self.global_position.y < -0.6:
		emit_signal("zombie_died")
		queue_free()
		
	if !nav_agent.is_target_reachable() and player.is_on_floor():
		attack_range = ATTACK_RANGE * 3
	else:
		attack_range = ATTACK_RANGE
		
	match state_machine.get_current_node():
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
	
	_snap_up_to_stairs_check(delta)
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
	if is_dead:
		return
	health -= dmg * critical_multi
	player.currency += 10 * critical_multi
	$Hp.text = str(health)
	#print(health)
	if health <= 0:
		if not is_dead:
			is_dead = true
		$Hp.visible = false
		var level = player.curr_level
		player.currency += 100
		var exp = get_experience_per_zombie(level)
		player.gain_exp(exp)
		if $CollisionShape3D:
			$CollisionShape3D.queue_free()
		anim_tree.set("parameters/conditions/die", true)
		emit_signal("zombie_died")
		await get_tree().create_timer(6).timeout
		queue_free()
