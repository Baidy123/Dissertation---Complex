class_name WeaponManager
extends Node3D

@export var allow_shoot : bool = true

@export var current_weapon : WeaponResource :
	set(v):
		if v != current_weapon:
			if current_weapon:
				current_weapon.is_equipped = false
			current_weapon = v;
			if is_inside_tree():
				update_weapon_model()
@export var equipped_weapons : Array[WeaponResource]

@export var player : CharacterBody3D
@export var bullet_raycast : RayCast3D


@export var view_model_container : Node3D
@export var world_model_container : Node3D

var current_weapon_view_model_muzzle : Node3D
var current_weapon_world_model_muzzle : Node3D


var current_weapon_view_model : Node3D
var current_weapon_world_model : Node3D
	
@onready var audio_stream_player = $AudioStreamPlayer3D


func update_weapon_model():
	if current_weapon_view_model != null and is_instance_valid(current_weapon_view_model):
		current_weapon_view_model.queue_free()
		is_reloading = false

		current_weapon_view_model.get_parent().remove_child(current_weapon_view_model)
	if current_weapon_world_model != null and is_instance_valid(current_weapon_world_model):
		current_weapon_world_model.queue_free()
		is_reloading = false
		current_weapon_world_model.get_parent().remove_child(current_weapon_world_model)
	if current_weapon != null:
		current_weapon.weapon_manager = self
		if view_model_container and current_weapon.view_model:
			current_weapon_view_model = current_weapon.view_model.instantiate()
			current_weapon_view_model.position = current_weapon.view_model_pos
			current_weapon_view_model.rotation = current_weapon.view_model_rot
			current_weapon_view_model.scale = current_weapon.view_model_scale
			apply_clip_and_fov_shader_to_view_model(current_weapon_view_model)
			view_model_container.add_child(current_weapon_view_model)
			if current_weapon_view_model.get_node_or_null("AnimationPlayer"):
				current_weapon_view_model.get_node_or_null("AnimationPlayer").connect("current_animation_changed", current_anim_changed)
		if world_model_container and current_weapon.world_model:
			current_weapon_world_model = current_weapon.world_model.instantiate()
			world_model_container.add_child(current_weapon_world_model)
			current_weapon_world_model.position = current_weapon.world_model_pos
			current_weapon_world_model.rotation = current_weapon.world_model_rot
			current_weapon_world_model.scale = current_weapon.world_model_scale
		current_weapon.is_equipped = true
		if player.has_method("update_viwe_and_world_model_masks"):
			player.update_viwe_and_world_model_masks()
	current_weapon_view_model_muzzle = view_model_container.find_child("Muzzle", true, false) if current_weapon_view_model else null
	current_weapon_world_model_muzzle = world_model_container.find_child("Muzzle", true, false) if current_weapon_world_model else null

func apply_clip_and_fov_shader_to_view_model(node3d : Node3D, fov_or_negative_for_unchanged = -1.0):
	var all_mesh_instances = node3d.find_children("*", "MeshInstance3D")
	if node3d is MeshInstance3D:
		all_mesh_instances.push_back(node3d)
	for mesh_instance in all_mesh_instances:
		var mesh = mesh_instance.mesh
		# Important to turn shadow casting off for view model or will cause issues with both
		# view model, casting shadows on itself once unclipped, & also will look weird casting on world.
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface_idx in mesh.get_surface_count():
			var base_mat = mesh.surface_get_material(surface_idx)
			if not base_mat is BaseMaterial3D: continue
			var weapon_shader_material := ShaderMaterial.new()
			weapon_shader_material.shader = preload("res://FpsControllor/weapon_manager/weapon_clip_and_fov_shader.gdshader")
			weapon_shader_material.set_shader_parameter("texture_albedo", base_mat.albedo_texture)
			weapon_shader_material.set_shader_parameter("texture_metallic", base_mat.metallic_texture)
			weapon_shader_material.set_shader_parameter("texture_roughness", base_mat.roughness_texture)
			weapon_shader_material.set_shader_parameter("texture_normal", base_mat.normal_texture)
			weapon_shader_material.set_shader_parameter("albedo", base_mat.albedo_color)
			weapon_shader_material.set_shader_parameter("metallic", base_mat.metallic)
			weapon_shader_material.set_shader_parameter("specular", base_mat.metallic_specular)
			weapon_shader_material.set_shader_parameter("roughness", base_mat.roughness)
			weapon_shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)
			var tex_channels = { 0: Vector4(1., 0., 0., 0.), 1: Vector4(0., 1., 0., 0.), 2: Vector4(0., 0., 1., 0.), 3: Vector4(1., 0., 0., 1.), 4: Vector4() }
			weapon_shader_material.set_shader_parameter("metallic_texture_channel", tex_channels[base_mat.metallic_texture_channel])
			mesh.surface_set_material(surface_idx, weapon_shader_material)
			
var is_reloading = false
func reload_weapon():
	if is_reloading:
		return
	is_reloading = true
	current_weapon.reload_pressed()
		

func play_sound(sound: AudioStream):
	if sound:
		if audio_stream_player.stream != sound:
			audio_stream_player.stream = sound
		audio_stream_player.play()

func stop_sounds():
	audio_stream_player.stop()
	

var last_played_anim : String = ""
var current_anim_finished_callback
var current_anim_cancelled_callback

func play_anim(name : String, finished_callback = null, cancelled_callback = null, play_speed = 0.0):
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	anim_player.speed_scale = 1 + play_speed * 1.5
	if last_played_anim and get_anim() == last_played_anim and current_anim_cancelled_callback is Callable:
		current_anim_cancelled_callback.call() # Last anim didn't finish yet
	
	if not anim_player or not anim_player.has_animation(name):
		if finished_callback is Callable:
			finished_callback.call() # Treat empty animations as finishing immediately
		return
	
	current_anim_finished_callback = finished_callback
	current_anim_cancelled_callback = cancelled_callback
	last_played_anim = name
	anim_player.clear_queue()
	anim_player.seek(0.0)
	anim_player.play(name)

func queue_anim(name : String):
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player: return
	anim_player.queue(name)


func current_anim_changed(new_anim : StringName):
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if new_anim != last_played_anim and current_anim_finished_callback is Callable:
		current_anim_finished_callback.call()
	last_played_anim = anim_player.current_animation
	if last_played_anim != anim_player.current_animation:
		current_anim_finished_callback = null
		current_anim_cancelled_callback = null

func get_anim() -> String:
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player: return ""
	return anim_player.current_animation
	


func show_muzzle_flash():
	if current_weapon_view_model_muzzle:
		$ViewMuzzleFlash.emitting = true
	if current_weapon_world_model_muzzle:
		$WorldMuzzleFlash.emitting = true


func make_bullet_trail(target_pos : Vector3):
	if current_weapon_view_model_muzzle == null:
		return
	var muzzle = current_weapon_view_model_muzzle
	var bullet_dir = (target_pos - muzzle.global_position).normalized()
	var start_pos = muzzle.global_position + bullet_dir*0.25
	if (target_pos - start_pos).length() > 3.0:
		var bullet_tracer = preload("res://FpsControllor/weapon_manager/bullet_tracer.tscn").instantiate()
		player.add_sibling(bullet_tracer)
		bullet_tracer.global_position = start_pos
		bullet_tracer.target_pos = target_pos
		bullet_tracer.look_at(target_pos)

func apply_recoil(ver_recoil : float, hor_recoil : float):
	var random_recoil := Vector2(randf_range(-1, 1), randf_range(0.5, 1)) 
	var recoil = random_recoil
	if player.is_crouched :
		player.add_recoil(recoil.y * ver_recoil * 0.5, -recoil.x * hor_recoil * 0.3)
	else:
		player.add_recoil(recoil.y * ver_recoil, -recoil.x * hor_recoil)
	
func get_current_recoil():
	return player.get_current_recoil() if player.has_method("get_current_recoil") else Vector2()

func _unhandled_input(event) -> void:
	if current_weapon and is_inside_tree() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("shoot") and allow_shoot and not is_reloading:
			current_weapon.trigger_down = true
		elif event.is_action_released("shoot"):
			current_weapon.trigger_down = false
		if event.is_action_pressed("reload") and not current_weapon.trigger_down:

			reload_weapon()
			
func add_weapon(new_weapon: Resource) -> void:
	equipped_weapons.append(new_weapon)
	print("Weapon added:", new_weapon)
	
func _ready() -> void:
	update_weapon_model()

func _process(delta: float) -> void:
	if current_weapon:
		current_weapon.on_process(delta)
	if current_weapon_view_model_muzzle:
		$ViewMuzzleFlash.global_position = current_weapon_view_model_muzzle.global_position
	if current_weapon_world_model_muzzle:
		$WorldMuzzleFlash.global_position = current_weapon_world_model_muzzle.global_position
