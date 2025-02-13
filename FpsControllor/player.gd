class_name Player
extends CharacterBody3D

@export var sensitivity : float = 0.006
@export var jump_velocity:= 6.0

var wish_dir = Vector3.ZERO
var camera_aligned_wish_dir = Vector3.ZERO

const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time = 0.0

#Character stats
@export var health := 100.0
@export var max_health := 100.0

@export var aptitude : String = " "
@export var attribute_available_points :int = 6

@export var attributes = {
	"constitution" : 4,
	"strength" : 5,
	"perception" : 6
}
@export var skill_available_points :int = 10

@export var skills = {
	"endurance" = 0,
	"resilience" = 0,
	"melee" = 0,
	"intimidation" = 0,
	"handguns" = 0,
	"longguns" = 0
}

var skills_influence = {
	"endurance" : 1,
	"resilience" : 0,
	"melee" : 1,
	"intimidation" : 0,
	"handguns" : 0,
	"longguns" : 0
} 

var skills_attribute = {
	"endurance": 0,
	"resilience": 0,
	"melee": 0,
	"intimidation": 0,
	"handguns": 0,
	"longguns": 0
}
@export var perk_available_points :int = 0

@export var perks = {
	"1a" : false,
	"1b" : false,
	"1c" : false,
	"2a" : false,
	"2b" : false,
	"2c" : false,
	"3a" : false,
	"3b" : false,
	"3c" : false,
}
@export var experience = {
	"curr_lvl_exp" : 0,
	"total_exp" : 0,
	"req_exp" : 0
}
@export var curr_level = 1


#Ground movement settings
@export var walk_speed:= 6.0
@export var sprint_multi:= 1.5
@export var ground_accel:= 14.0
@export var ground_decel:= 10.0
@export var ground_friction:= 6.0
@export var climb_speed = 6.0

#Air movement settings
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0


var noclip_speed_multi := 4.0
var noclip := false

const MAX_STEP_HEIGHT = 0.5
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor := -INF

const VIEW_MODEL_LAYER = 9
const WORLD_MODEL_LAYER = 2
const CROUCH_TRANSLATE = 0.7

var is_crouched := false



func _ready() -> void:
	update_viwe_and_world_model_masks()
		

func update_viwe_and_world_model_masks():
	for child in %WorldModel.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1,false)
		child.set_layer_mask_value(WORLD_MODEL_LAYER,true)
	for child in %ViewModel.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1,false)
		child.set_layer_mask_value(VIEW_MODEL_LAYER,true)
		if child is GeometryInstance3D:
			child.cast_shadow = false
	%Camera3D.set_cull_mask_value(WORLD_MODEL_LAYER,false)
	
var dmg_reduce_rate : float = 0
func take_damage(damage: float, dmg_type: String):
	if $LevellingSystem.die_hard_active:
		return
	if perks["3b"] == true:
		if dmg_type == "explosion":
			return
	var final_damage = damage * (max(0.5, 1 - skills_influence["resilience"]))
	if perks["1c"] == true:
		final_damage = $LevellingSystem.tough_skin(final_damage)
	health -= int(final_damage)
	if perks["2a"] == true:
		$LevellingSystem.deserter()
	if health <= 0:
		if perks["3c"] == true:
			$LevellingSystem.die_hard()
			health = 1
		else:
			health = 0
			get_tree().change_scene_to_file("res://StarterScene.tscn")
	
	
var is_sprinting :bool = false 
var sprint_limit: float = 5.0 * skills_influence["endurance"]
var sprint_remaining_time := sprint_limit
var sprint_cooldown: float = 3.0
var sprint_cooldown_remaining: float = 0.0
func get_speed() -> float:
	var speed = walk_speed
	if is_crouched:
		speed *=  0.75
	if  is_sprinting:
		speed *= sprint_multi * skills_influence["endurance"]
	if $LevellingSystem.deserter_active :
		speed *= 2
	return speed
	
func is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle
	


func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: 
		result = PhysicsTestMotionResult3D.new()
		
	var param = PhysicsTestMotionParameters3D.new()
	param.from = from
	param.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), param, result)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * sensitivity)
			%Camera3D.rotate_x(-event.relative.y * sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad((90)))
	if event.is_action_pressed("bullettime") and perks["1b"]:
		$LevellingSystem.bullet_time()

func get_interactable_component_at_shapecast() -> InteractableComponent:
	for i in %InteractShapeCast3D.get_collision_count():
		# Allow colliding with player
		if i > 0 and %InteractShapeCast3D.get_collider(0) != $".":
			return null
		var collider = %InteractShapeCast3D.get_collider(i)
		if collider and collider.get_node_or_null("InteractableComponent") is InteractableComponent:
			return collider.get_node_or_null("InteractableComponent")
	return null
		
var _saved_camera_global_pos = null
func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %CameraSmooth.global_position

func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	%CameraSmooth.global_position.y = _saved_camera_global_pos.y
	%CameraSmooth.position.y = clampf(%CameraSmooth.position.y, -0.8, 0.8) # Clamp incase teleported
	var move_amount = max(self.velocity.length() * delta, walk_speed/2 * delta)
	%CameraSmooth.position.y = move_toward(%CameraSmooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %CameraSmooth.global_position
	if %CameraSmooth.position.y == 0:
		_saved_camera_global_pos = null # Stop smoothing camera

func _snap_down_to_stairs_check():
	var did_snap := false
	%StairsBelowRayCast3D.force_raycast_update()
	var is_floor_below :bool = %StairsBelowRayCast3D.is_colliding() and not is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == _last_frame_was_on_floor 
	if not is_on_floor() and self.velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and is_floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap
	

			
func _snap_up_to_stairs_check(delta) -> bool :
	if not is_on_floor() and not _snapped_to_stairs_last_frame : 
		return false
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
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false

var target_recoil := Vector2.ZERO
var current_recoil := Vector2.ZERO
const RECOIL_APPLY_SPEED : float = 10.0
const RECOIL_RECOVER_SPEED : float = 7.0

func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
			const MY_APPROX_MASS_KG = 80.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.25:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			# 5.0 is a magic number, adjust to your needs
			var push_force = mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)
			
func add_recoil(pitch: float, yaw: float) -> void:
	if perks["2b"] == true:
		target_recoil.x = $LevellingSystem.cowboy(pitch)
		target_recoil.y = $LevellingSystem.cowboy(yaw)
	else:
		target_recoil.x += pitch
		target_recoil.y += yaw

func get_current_recoil() -> Vector2:
	return current_recoil

func update_recoil(delta: float) -> void:
	# Slowly move target recoil back to 0,0
	target_recoil = target_recoil.lerp(Vector2.ZERO, RECOIL_RECOVER_SPEED * delta)
	
	# Slowly move current recoil to the target recoil
	var prev_recoil = current_recoil
	current_recoil = current_recoil.lerp(target_recoil, RECOIL_APPLY_SPEED * delta)
	var recoil_difference = current_recoil - prev_recoil
	
	# Rotate player/camera to current recoil
	rotate_y(recoil_difference.y)
	%Camera3D.rotate_x(recoil_difference.x)
	%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	
func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)
	
var _cur_ladder_climbing : Area3D = null
func _handle_ladder_physics() -> bool:
	# Keep track of whether already on ladder. If not already, check if overlapping a ladder area3d.
	var was_climbing_ladder := _cur_ladder_climbing and _cur_ladder_climbing.overlaps_body(self)
	if not was_climbing_ladder:
		_cur_ladder_climbing = null
		for ladder in get_tree().get_nodes_in_group("ladder_area3d"):
			if ladder.overlaps_body(self):
				_cur_ladder_climbing = ladder
				break
	if _cur_ladder_climbing == null:
		return false
	
	# Set up variables. Most of this is going to be dependent on the player's relative position/velocity/input to the ladder.
	var ladder_gtransform : Transform3D = _cur_ladder_climbing.global_transform
	var pos_rel_to_ladder := ladder_gtransform.affine_inverse() * self.global_position
	
	var forward_move := Input.get_action_strength("up") - Input.get_action_strength("down")
	var side_move := Input.get_action_strength("right") - Input.get_action_strength("left")
	var ladder_forward_move = ladder_gtransform.affine_inverse().basis * %Camera3D.global_transform.basis * Vector3(0, 0, -forward_move)
	var ladder_side_move = ladder_gtransform.affine_inverse().basis * %Camera3D.global_transform.basis * Vector3(side_move, 0, 0)
	
	# Strafe velocity is simple. Just take x component rel to ladder of both
	var ladder_strafe_vel : float = climb_speed * (ladder_side_move.x + ladder_forward_move.x)
	# For climb velocity, there are a few things to take into account:
	# If strafing directly into the ladder, go up, if strafing away, go down
	var ladder_climb_vel : float = climb_speed * -ladder_side_move.z
	# When pressing forward & facing the ladder, the player likely wants to move up. Vice versa with down.
	# So we will bias the direction (up/down) towards where we are looking by 45 degrees to give a greater margin for up/down detect.
	var up_wish := Vector3.UP.rotated(Vector3(1,0,0), deg_to_rad(-45)).dot(ladder_forward_move)
	ladder_climb_vel += climb_speed * up_wish
	
	# Only begin climbing ladders when moving towards them & prevent sticking to top of ladder when dismounting
	# Trying to best match the player's intention when climbing on ladder
	var should_dismount = false
	if not was_climbing_ladder:
		var mounting_from_top = pos_rel_to_ladder.y > _cur_ladder_climbing.get_node("TopOfLadder").position.y
		if mounting_from_top:
			# They could be trying to get on from the top of the ladder, or trying to leave the ladder.
			if ladder_climb_vel > 0: should_dismount = true
		else:
			# If not mounting from top, they are either falling or on floor.
			# In which case, only stick to ladder if intentionally moving towards
			if (ladder_gtransform.affine_inverse().basis * wish_dir).z >= 0: should_dismount = true
		# Only stick to ladder if very close. Helps make it easier to get off top & prevents camera jitter
		if abs(pos_rel_to_ladder.z) > 0.1: should_dismount = true
	
	# Let player step off onto floor
	if is_on_floor() and ladder_climb_vel <= 0: should_dismount = true
	
	if should_dismount:
		_cur_ladder_climbing = null
		return false
	
	# Allow jump off ladder mid climb
	if was_climbing_ladder and Input.is_action_just_pressed("jump"):
		self.velocity = _cur_ladder_climbing.global_transform.basis.z * jump_velocity * 1.5
		_cur_ladder_climbing = null
		return false
	
	self.velocity = ladder_gtransform.basis * Vector3(ladder_strafe_vel, ladder_climb_vel, 0)
	#self.velocity = self.velocity.limit_length(climb_speed) # Uncomment to turn off ladder boosting
	
	# Snap player onto ladder
	pos_rel_to_ladder.z = 0
	self.global_position = ladder_gtransform * pos_rel_to_ladder
	
	move_and_slide()
	return true

func _handle_air_physics(delta):
	#if abi_to_jt == true and jump_twice == false and Input.is_action_just_pressed("jump"):
			#self.velocity.y = jump_velocity
			#jump_twice = true
	##Full control in air
	#if full_control_in_air == true:
		#self.velocity.x = wish_dir.x * 6.2
		#self.velocity.z = wish_dir.z * 6.2
		#self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		##print(self.velocity.length())
	if perks["1a"] == true:
		$LevellingSystem.qinggong(delta)
	#BHOP in air
	else:
		self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
		var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
		var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
		
		if add_speed_till_cap > 0:
			var  accel_speed = air_accel * air_move_speed * delta
			accel_speed = min(accel_speed, add_speed_till_cap)
			self.velocity += accel_speed * wish_dir
			#print(self.velocity.length()
		


func _handle_ground_physics(delta):
	#self.velocity.x = wish_dir.x * get_speed()
	#self.velocity.z = wish_dir.z * get_speed()
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	#print(self.velocity.length())
	_headbob_effect(delta)
	
@onready var _original_capsule_height = $CollisionShape3D.shape.height
func _handle_crouch(delta):
	if Input.is_action_just_pressed("crouch") and not is_crouched:
		is_crouched = !is_crouched
	elif Input.is_action_just_pressed("crouch") and is_crouched and not self.test_move(self.global_transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouched = !is_crouched
		
	if is_crouched:
		%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE, 7.0 * delta)
		$CollisionShape3D.shape.height = _original_capsule_height - CROUCH_TRANSLATE
	else:
		%Head.position.y = move_toward(%Head.position.y, 0.0, 7.0 * delta)
		$CollisionShape3D.shape.height = _original_capsule_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2
	
func _handle_noclip(delta) -> bool:
	if Input.is_action_just_pressed("_noclip") and OS.has_feature("debug"):
		noclip_speed_multi = 3.0
		noclip = !noclip
	$CollisionShape3D.disabled = noclip
	if noclip:
		var speed = get_speed() * noclip_speed_multi
		if Input.is_action_pressed("sprint"):
			speed *= 3.0
		if Input.is_action_pressed("jump"):
			camera_aligned_wish_dir.y = 1.0
		elif Input.is_action_pressed("crouch"):
			camera_aligned_wish_dir.y = -1.0
		self.velocity = camera_aligned_wish_dir * speed
		self.global_position += self.velocity * delta
		
	return noclip
	
#func return_req_exp():
	#experience["req_exp"] = $LevellingSystem.experience_required
	
func gain_exp(amt: int):
	$LevellingSystem.gain_experience(amt)
	#return_req_exp()
	
func on_level_up(skill_points_gain: int):

	health = max_health
	skill_available_points += skill_points_gain
	curr_level = $LevellingSystem.curr_level
	if curr_level %2 == 0:
		skill_available_points += skill_points_gain
		perk_available_points += 1
		$PlayerHUD.get_node("Reminder").set_text("Level Up!!!" + "\n" + "New Perk Point Gained!!!")
		$PlayerHUD.get_node("Reminder").set_visible(true)
	else:
		$PlayerHUD.get_node("Reminder").set_text("Level Up!!!")
		$PlayerHUD.get_node("Reminder").set_visible(true)
	await get_tree().create_timer(3.0).timeout
	$PlayerHUD.get_node("Reminder").set_visible(false)
@onready var animation_tree : AnimationTree = $"WorldModel/desert droid container/AnimationTree"
@onready var state_machine_playback : AnimationNodeStateMachinePlayback = $"WorldModel/desert droid container/AnimationTree".get("parameters/playback")

func update_animations():
	if noclip or (not is_on_floor() and not _snapped_to_stairs_last_frame):
		state_machine_playback.travel("MidJump")
		return
		
	var rel_vel = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / get_speed())
	var rel_vel_xz = Vector2(rel_vel.x, -rel_vel.z)
	
	if is_crouched:
		state_machine_playback.travel("CrouchBlendSpace2D")
		animation_tree.set("parameters/CrouchBlendSpace2D/blend_position", rel_vel_xz)
	elif Input.is_action_pressed("sprint"):
		state_machine_playback.travel("RunBlendSpace2D")
		animation_tree.set("parameters/RunBlendSpace2D/blend_position", rel_vel_xz)
	else:
		state_machine_playback.travel("WalkBlendSpace2D")
		animation_tree.set("parameters/WalkBlendSpace2D/blend_position", rel_vel_xz)
		
func _process(delta) -> void:
	if get_interactable_component_at_shapecast():
		get_interactable_component_at_shapecast().hover_cursor(self)
		if Input.is_action_just_pressed("interact"):
			get_interactable_component_at_shapecast().interact_with()
			
	update_animations()
	update_recoil(delta)
			
func _physics_process(delta: float) -> void:

	var input_dir := Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	camera_aligned_wish_dir = %Camera3D.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	if sprint_cooldown_remaining > 0.0:
		sprint_cooldown_remaining -= delta
		if sprint_cooldown_remaining < 0.0:
			sprint_cooldown_remaining = 0.0
	var wants_to_sprint = Input.is_action_pressed("sprint")
	if wants_to_sprint:
		if sprint_cooldown_remaining <= 0.0 and sprint_remaining_time > 0.0:
			is_sprinting = true
		else:
			is_sprinting = false
	else:
		is_sprinting = false
	if is_sprinting:
		sprint_remaining_time -= delta
		if sprint_remaining_time <= 0.0:
			sprint_remaining_time = 0.0
			is_sprinting = false
			sprint_cooldown_remaining = sprint_cooldown
	else:
		sprint_remaining_time = min(sprint_remaining_time + delta, sprint_limit)
		
	if is_on_floor():
		_last_frame_was_on_floor = Engine.get_physics_frames()
		_handle_crouch(delta)
	
	if not _handle_noclip(delta) and not _handle_ladder_physics():
		if is_on_floor() or _snapped_to_stairs_last_frame:
			$LevellingSystem.jump_twice = false
			_handle_ground_physics(delta)

			if is_crouched:
				if Input.is_action_just_pressed("jump"):
					is_crouched = false
			elif Input.is_action_just_pressed("jump"):
				self.velocity.y = jump_velocity
				
		else:
			_handle_air_physics(delta)
		if not _snap_up_to_stairs_check(delta):
			_push_away_rigid_bodies()
			move_and_slide()
			_snap_down_to_stairs_check()
	_slide_camera_smooth_back_to_origin(delta)
