class_name WeaponResource
extends Resource

@export var name : String
@export var icon : Texture2D

@export_range(1,9) var slot : int = 1
@export_range(1,10) var slot_priority : int = 1

@export var view_model : PackedScene
@export var world_model : PackedScene


@export var view_model_pos : Vector3
@export var view_model_rot : Vector3
@export var view_model_scale := Vector3(1,1,1)

@export var world_model_pos : Vector3
@export var world_model_rot : Vector3
@export var world_model_scale := Vector3(1,1,1)

@export var view_idle_anim : String
@export var view_equip_anim : String
@export var view_reload_anim : String
@export var view_shoot_anim : String


@export var shoot_sound : AudioStream
@export var reload_sound : AudioStream
@export var unholster_sound : AudioStream


#weapon logic
@export var current_ammo :=INF
@export var magazine_capacity :=INF
@export var reserve_ammo :=INF
@export var max_reserve_ammo :=INF
@export var auto_fire := false
@export var max_fire_rate_ms : float = 50
@export var impact_force := 5.0
@export var v_recoil : float
@export var h_recoil : float
@export var damage = 10

@export var bullet_spread : float = 1
@export var bullet_range : float = 100

var weapon_manager : WeaponManager

var trigger_down := false:
	set(v):
		if trigger_down != v:
			trigger_down = v
			if trigger_down:
				on_trigger_down()
			else:
				on_trigger_up()
				
var is_equipped := false:
	set(v):
		if is_equipped != v:
			is_equipped = v
			if is_equipped:
				on_equip()
			else:
				on_unequip()


var last_fire_time = -INF
func on_process(delta):
	if trigger_down and auto_fire and Time.get_ticks_msec() - last_fire_time >= max_fire_rate_ms:
		if current_ammo > 0:
			fire_shot()
			
func on_trigger_down():
	if Time.get_ticks_msec() - last_fire_time >= max_fire_rate_ms and current_ammo > 0:
		fire_shot()

	
func on_trigger_up():
	pass
	
func get_amount_can_reload() -> int:
	var wish_reload = magazine_capacity - current_ammo
	var can_reload = min(wish_reload, reserve_ammo)
	return can_reload
	

func reload_pressed():
	if view_reload_anim and weapon_manager.get_anim() == view_reload_anim:
		weapon_manager.is_reloading = false
		return
	if get_amount_can_reload() <= 0:
		weapon_manager.is_reloading = false
		return
	var cancel_cb = (func():
		weapon_manager.stop_sounds())
	if slot == 2:
		weapon_manager.play_anim(view_reload_anim, reload, cancel_cb, get_player_handguns())
	else: 
		weapon_manager.play_anim(view_reload_anim, reload, cancel_cb, get_player_longguns())
	weapon_manager.queue_anim(view_idle_anim)
	weapon_manager.play_sound(reload_sound)

func reload():
	var can_reload = get_amount_can_reload()
	if can_reload < 0:
		weapon_manager.is_reloading = false
		return
	elif magazine_capacity == INF or current_ammo == INF:
		current_ammo = magazine_capacity
		weapon_manager.is_reloading = false
	else:
		current_ammo += can_reload
		reserve_ammo -= can_reload
		weapon_manager.is_reloading = false
	
func on_equip():
	if !pack_rat :
		if check_perk_pr():
			max_reserve_ammo *= 2
			#reserve_ammo *= 2
	weapon_manager.play_sound(unholster_sound)
	weapon_manager.play_anim(view_equip_anim)
	weapon_manager.queue_anim(view_idle_anim)


func on_unequip():
	pass
	

func get_player_velocity():
	return weapon_manager.get_parent().velocity.length()
	
func check_perk_cb():
	return weapon_manager.get_parent().perks["2b"]

var pack_rat := false
func check_perk_pr():
	pack_rat = weapon_manager.get_parent().perks["2c"]
	return weapon_manager.get_parent().perks["2c"]

func get_player_handguns():
	#print(weapon_manager.get_parent().skills_influence["handguns"])
	return weapon_manager.get_parent().skills_influence["handguns"]

func get_player_longguns():
	return weapon_manager.get_parent().skills_influence["longguns"]

var num_shots_fired : int = 0
func fire_shot():
	weapon_manager.play_anim(view_shoot_anim)
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(view_idle_anim)
	
	var raycast = weapon_manager.bullet_raycast
	raycast.rotation.x = weapon_manager.get_current_recoil().x
	raycast.rotation.y = weapon_manager.get_current_recoil().y

	var spread_x := randf_range(get_player_velocity() * bullet_spread * -0.5, get_player_velocity() * bullet_spread *  0.5)
	var spread_y := randf_range(get_player_velocity() * bullet_spread * -0.5, get_player_velocity() * bullet_spread * 0.5)
	if spread_x >= 5:
		spread_x = 5
	if spread_x <= -5:
		spread_x = -5
	if spread_y >= 5:
		spread_y = 5
	if spread_y <= -5:
		spread_y = -5
	
	#print(spread_x)
	if check_perk_cb() == true:
		raycast.target_position = Vector3(spread_x * 0.1,spread_y *0.1,-abs(bullet_range))
	else:
		#handgun
		if slot == 2:
			#print(max(0, (1- get_player_handguns())))
			raycast.target_position = Vector3(max(0.5, (1- get_player_handguns())) * spread_x,max(0.5, (1- get_player_handguns())) * 
												spread_y,-abs(bullet_range))
		#longgun
		else:
			raycast.target_position = Vector3(max(0.5, (1- get_player_longguns())) * spread_x,max(0.5, (1- get_player_longguns())) * 
												spread_y,-abs(bullet_range))
	raycast.force_raycast_update()
	
	var bullet_target_pos = raycast.global_transform * raycast.target_position
	
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		var nrml = raycast.get_collision_normal()
		var pt = raycast.get_collision_point()
		BulletDecalPool.spawn_bullet_decal(pt, nrml, obj, raycast.global_basis)
		if obj is RigidBody3D:
			obj.apply_impulse(-nrml * impact_force / obj.mass, pt -obj.global_position)
		if obj.has_method("take_damage"):
			obj.take_damage(self.damage, " ")
			
	weapon_manager.show_muzzle_flash()
	if num_shots_fired % 3 == 0:
		weapon_manager.make_bullet_trail(bullet_target_pos)
	#handgun
	if slot == 2:
		weapon_manager.apply_recoil(max(0.5, (1- get_player_handguns())) * v_recoil, 
									max(0.5, (1- get_player_handguns())) * h_recoil)
	#longgun
	else:
		weapon_manager.apply_recoil(max(0.5, (1- get_player_longguns())) * v_recoil, 
									max(0.5, (1- get_player_longguns())) * h_recoil)
	last_fire_time = Time.get_ticks_msec()
	current_ammo -= 1
	num_shots_fired += 1
