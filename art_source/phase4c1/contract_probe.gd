extends SceneTree
var out := OS.get_environment("BUNNY_EVIDENCE")
var checks := {}
var max_origin_error := 0.0
var max_direction_error := 0.0
var max_visual_bore_error := 0.0

func _initialize() -> void:
	_run.call_deferred()

func _physics_signature(enemy: Node3D) -> Array:
	var records := []
	for child in enemy.get_children():
		if child is CollisionShape3D:
			records.append([str(child.transform),child.shape.radius,child.shape.height,child.disabled])
	records.append([enemy.collision_layer,enemy.collision_mask,enemy.navigation_agent.radius,enemy.navigation_agent.height,enemy.navigation_agent.avoidance_enabled,enemy.navigation_agent.path_desired_distance,enemy.navigation_agent.target_desired_distance])
	return records

func _wreck_signature(wreck: Node3D) -> Array:
	var records := []
	for body in wreck.get_children():
		if body is RigidBody3D:
			var collision: CollisionShape3D
			for child in body.get_children():
				if child is CollisionShape3D: collision=child
			records.append([body.name,str(body.transform),body.mass,body.collision_layer,body.collision_mask,str(body.linear_velocity),str(body.angular_velocity),str(collision.shape.size)])
		elif body is ConeTwistJoint3D:
			records.append([body.name,str(body.transform),str(body.node_a),str(body.node_b)])
		elif body is Timer:
			records.append([body.wait_time,body.one_shot])
	return records

func _run() -> void:
	var control_scene := PackedScene.new()
	var control_root := CharacterBody3D.new()
	control_root.set_script(load("res://scripts/enemies/enemy_controller.gd"))
	control_scene.pack(control_root)
	control_root.free()
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	seed(472)
	var before = control_scene.instantiate()
	world.add_child(before)
	before.set_physics_process(false)
	var old_rng := randf()
	seed(472)
	var after = load("res://scenes/enemies/enemy.tscn").instantiate()
	world.add_child(after)
	after.set_physics_process(false)
	var new_rng := randf()
	await process_frame
	await process_frame
	checks["spawn_rng_unchanged"] = old_rng == new_rng
	checks["collision_and_navigation_unchanged"] = _physics_signature(before) == _physics_signature(after)
	var adapter = after.get_node("EnemyDronePresentation")
	checks["visible_drone_instantiated"] = adapter.visual != null and adapter.gun != null
	checks["old_rendering_hidden_not_deleted"] = not after.humanoid_visual.animation_source_model.visible and not after.humanoid_visual.character_model.visible and not after.humanoid_visual.weapon_visual.visible
	checks["real_legacy_animation_rig_retained"] = after.humanoid_visual.character_skeleton.get_bone_count() >= 90 and after.humanoid_visual.animation_tree.active
	for i in 360:
		var time := float(i) / 60.0
		var speed: float = [0.0,1.15,3.2][int(i/120.0)]
		var aim := Vector3(sin(time*.8)*9.0, 1.05 + sin(time)*.5, -8.0)
		for actor in [before,after]:
			actor.rotation.y = sin(time*.4)*1.4
			actor.humanoid_visual.update_visual(aim,Vector3(sin(time),0,cos(time)),speed,1.0/60.0)
			if i%37==0: actor.humanoid_visual.fire_recoil()
		adapter._sync_visual(1.0/60.0)
		max_origin_error=maxf(max_origin_error,before.humanoid_visual.get_muzzle_position().distance_to(after.humanoid_visual.get_muzzle_position()))
		max_direction_error=maxf(max_direction_error,before.humanoid_visual.get_muzzle_direction().distance_to(after.humanoid_visual.get_muzzle_direction()))
		max_visual_bore_error=maxf(max_visual_bore_error,adapter.gun.global_position.distance_to(after.humanoid_visual.get_muzzle_position()))
		await process_frame
	checks["360_fire_origin_samples_equal"] = max_origin_error < .00001
	checks["360_fire_direction_samples_equal"] = max_direction_error < .00001
	checks["visible_bore_tracks_gameplay_muzzle"] = max_visual_bore_error < .00001
	var outcomes := []
	var wrecks := []
	for actor in [before,after]:
		actor.transform=Transform3D.IDENTITY
		seed(9081)
		var damage: float=actor.receive_damage(DamagePacket.new(999,0,0,null,&"probe",&"",Vector3.ZERO,Vector3.ZERO,Vector3(1.0,0.2,-.3)))
		var wreck: Node3D
		for child in world.get_children():
			if child is RagdollProxy and not child in wrecks: wreck=child
		outcomes.append({"damage":damage,"health":actor.health,"dead":actor.is_dead,"queued":actor.is_queued_for_deletion(),"next_rng":randf(),"wreck":_wreck_signature(wreck)})
		wrecks.append(wreck)
	checks["damage_death_physics_rng_unchanged"] = outcomes[0]==outcomes[1]
	var skinned := 0
	for body in wrecks[1].get_children():
		if body is RigidBody3D and not body.get_node("Mesh").visible and body.get_child_count()==3: skinned+=1
	checks["six_existing_death_bodies_visually_reskinned"] = skinned==6
	checks["no_new_collision_in_asset"] = adapter.visual.find_children("*","CollisionObject3D",true,false).is_empty()
	var result := {"checks":checks,"samples":360,"max_origin_error_m":max_origin_error,"max_direction_error":max_direction_error,"max_visual_bore_error_m":max_visual_bore_error,"method":"Same production controller and inputs; old visual vs presentation-child scene. Old rig retained, not bypassed."}
	var f:=FileAccess.open(out.path_join("contract.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	print(JSON.stringify(result))
	world.queue_free()
	await process_frame
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)
