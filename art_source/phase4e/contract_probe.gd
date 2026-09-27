extends SceneTree
var out := OS.get_environment("BUNNY_EVIDENCE")
var checks := {}
var max_origin_error := 0.0
var max_direction_error := 0.0
var max_visual_bore_error := 0.0
var origin_sum := 0.0
var direction_sum := 0.0
var samples := []

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
	control_root.set_script(load("res://art_source/phase4e/oracle/legacy_enemy.gd"))
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
	var adapter = after.presentation
	checks["visible_drone_instantiated"] = adapter.visual != null and adapter.gun != null
	checks["no_humanoid_skeleton_or_animation_tree"] = after.find_children("*","Skeleton3D",true,false).is_empty() and after.find_children("*","AnimationTree",true,false).is_empty()
	checks["native_muzzle_owned_by_presentation"] = adapter.muzzle == after.get_node("EnemyPresentation/WeaponPresentation/FireReload/WeaponMount/Muzzle")
	for i in 360:
		var time := float(i) / 60.0
		var speed: float = [0.0,1.15,3.2][int(i/120.0)]
		var aim := Vector3(sin(time*.8)*9.0, 1.05 + sin(time)*.5, -8.0)
		for actor in [before,after]:
			actor.rotation.y = sin(time*.4)*1.4
			var presentation = before.humanoid_visual if actor == before else after.presentation
			presentation.update_visual(aim,Vector3(sin(time),0,cos(time)),speed,1.0/60.0)
			if i%37==0: presentation.fire_recoil()
		adapter._sync_visual(1.0/60.0)
		var origin_delta: float = before.humanoid_visual.get_muzzle_position().distance_to(after.presentation.get_muzzle_position())
		var direction_delta: float = before.humanoid_visual.get_muzzle_direction().distance_to(after.presentation.get_muzzle_direction())
		origin_sum += origin_delta
		direction_sum += direction_delta
		max_origin_error = maxf(max_origin_error, origin_delta)
		max_direction_error = maxf(max_direction_error, direction_delta)
		max_visual_bore_error=maxf(max_visual_bore_error,adapter.gun.global_position.distance_to(after.presentation.get_muzzle_position()))
		samples.append({"frame":i,"speed":speed,"old_origin":str(before.humanoid_visual.get_muzzle_position()),"native_origin":str(after.presentation.get_muzzle_position()),"old_direction":str(before.humanoid_visual.get_muzzle_direction()),"native_direction":str(after.presentation.get_muzzle_direction()),"origin_delta_m":origin_delta,"direction_delta":direction_delta})
		await process_frame
	checks["360_fire_origin_samples_equal"] = max_origin_error < .00001
	checks["360_fire_direction_samples_equal"] = max_direction_error < .00001
	checks["visible_bore_tracks_gameplay_muzzle"] = max_visual_bore_error < .00001
	# Additional coverage does not replace or dilute the original 360-sample oracle.
	var stress_max_origin := 0.0
	var stress_max_direction := 0.0
	for i in 120:
		var time := float(i) / 20.0
		var dt: float = [1.0/120.0, 1.0/60.0, 1.0/30.0][i % 3]
		var position := Vector3(sin(time)*20.0, 0.25*cos(time), cos(time)*15.0)
		var aim := position + Vector3(3.0*sin(time), 1.05, -9.0)
		for actor in [before, after]:
			actor.position = position
			actor.rotation.y = time
			if i % 60 == 0: actor.take_damage(1.0, Vector3.RIGHT)
			var presentation = before.humanoid_visual if actor == before else after.presentation
			presentation.update_visual(aim, Vector3.FORWARD, 3.2, dt)
			if i % 19 == 0: presentation.fire_recoil()
		stress_max_origin = maxf(stress_max_origin, before.humanoid_visual.get_muzzle_position().distance_to(after.presentation.get_muzzle_position()))
		stress_max_direction = maxf(stress_max_direction, before.humanoid_visual.get_muzzle_direction().distance_to(after.presentation.get_muzzle_direction()))
		await process_frame
	checks["additional_120_translation_hit_recoil_samples"] = stress_max_origin < 0.00001 and stress_max_direction < 0.00001
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
	var result := {"checks":checks,"samples":360,"max_origin_error_m":max_origin_error,"max_direction_error":max_direction_error,"max_visual_bore_error_m":max_visual_bore_error,"mean_origin_error_m":origin_sum/360.0,"mean_direction_error":direction_sum/360.0,"additional_120_max_origin_delta_m":stress_max_origin,"additional_120_max_direction_delta":stress_max_direction,"sample_rows":samples,"tolerance":0.00001,"method":"Frozen a40b765 controller / unchanged original HumanoidRetargetVisual and CharacterCombatRig vs native production KITE-07. Same original 360 inputs; no new-vs-new oracle."}
	var f:=FileAccess.open(out.path_join("contract.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	var compact := result.duplicate()
	compact.erase("sample_rows")
	print(JSON.stringify(compact))
	world.queue_free()
	await process_frame
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(1 if checks.values().has(false) else 0)
