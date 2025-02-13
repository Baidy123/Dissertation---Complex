class_name ShotgunWeaponResource
extends WeaponResource

@export var bullet_amt : int = 7
#@export var bullet_spread : float = 100

func fire_shot():
	weapon_manager.play_anim(view_shoot_anim)
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(view_idle_anim)
	
	var raycast = weapon_manager.bullet_raycast
	raycast.rotation.x = weapon_manager.get_current_recoil().x
	raycast.rotation.y = weapon_manager.get_current_recoil().y
	for i in range(bullet_amt):
		var spread_x := randf_range(bullet_spread * -1, bullet_spread)
		var spread_y := randf_range(bullet_spread * -1, bullet_spread)
		raycast.target_position = Vector3(spread_x,spread_y,-abs(bullet_range))
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
				obj.take_damage(self.damage)
			
		weapon_manager.show_muzzle_flash()
		if num_shots_fired % 3 == 0:
			weapon_manager.make_bullet_trail(bullet_target_pos)
	weapon_manager.apply_recoil(v_recoil, h_recoil)

	last_fire_time = Time.get_ticks_msec()
	current_ammo -= 1
	num_shots_fired += 1
