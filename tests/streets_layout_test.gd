extends Node
var failures: Array[String] = []
func _ready() -> void: _run.call_deferred()
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message);push_error(message)
	else: print("PASS ",message)
func _run() -> void:
	var profile := ProfileRuntime.new_profile()
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon",plan.ammo_ids),profile)
	check(session!=null,"Streets mission and area are registered")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed=907
	add_child(battle)
	battle.result_transition_enabled=false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var area = battle.area_root
	check(area.route_map.actor == battle.player,"Route map tracks the deployed player")
	var map_key := InputEventKey.new()
	map_key.physical_keycode = KEY_M
	map_key.pressed = true
	area.route_map._unhandled_key_input(map_key)
	check(area.route_map.expanded,"M opens the in-raid route map")
	area.route_map._unhandled_key_input(map_key)
	check(not area.route_map.expanded,"M closes the route map")
	var map: RID = area.get_node("StreetNavigation").get_navigation_map()
	for tick in 60:
		await get_tree().create_timer(.05).timeout
		NavigationServer3D.map_force_update(map)
		if not NavigationServer3D.map_get_path(map,battle.player.global_position,area.get_node("StreetTerminal").position,true).is_empty(): break
	var seen := {}
	# Cabin-height fire must hit the car, not pass through its visual roof.
	var car_position := Vector3(42,0,-14)
	var cover_ray := PhysicsRayQueryParameters3D.create(car_position+Vector3(0,1.2,-4),car_position+Vector3(0,1.2,2),4)
	var cover_hit: Dictionary = battle.player.get_world_3d().direct_space_state.intersect_ray(cover_ray)
	check(not cover_hit.is_empty() and cover_hit.collider.is_in_group("streets_vehicle"),"Sedan cabin blocks a firing ray at shoulder height ("+str(cover_hit.get("collider"))+")")
	var canopy: Area3D = area.find_child("CameraCanopy",true,false)
	var tree: Node3D = canopy.get_parent()
	var leaf_mesh := canopy.get_node("CanopyLeaves") as MultiMeshInstance3D
	var foliage_ray := PhysicsRayQueryParameters3D.create(tree.global_position+Vector3(-3,3.15,0),tree.global_position+Vector3(3,3.15,0),4)
	var space: PhysicsDirectSpaceState3D = battle.player.get_world_3d().direct_space_state
	check(space.intersect_ray(foliage_ray).is_empty(),"Foliage does not become a solid bullet shield")
	foliage_ray.from.y=1.3;foliage_ray.to.y=1.3
	check(not space.intersect_ray(foliage_ray).is_empty(),"Tree trunk retains real collision")
	var camera_position: Vector3 = battle.camera.global_position
	var camera_basis: Basis = battle.camera.global_basis
	var actor := Node3D.new();battle.add_child(actor);actor.global_position=tree.global_position
	battle.camera.global_position=tree.global_position+Vector3(0,8,4)
	for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,actor,.05)
	check(leaf_mesh.transparency>.8,"Instanced foliage fades when it hides the actor")
	check(camera_basis.is_equal_approx(battle.camera.global_basis),"Foliage occlusion never changes camera angle")
	actor.global_position+=Vector3.RIGHT*20
	for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,actor,.05)
	check(leaf_mesh.transparency<.01,"Instanced foliage restores after the actor clears it")
	battle.camera.global_position=camera_position
	actor.queue_free()
	for seed_value in range(1,25):
		var rng := RandomNumberGenerator.new();rng.seed=seed_value
		var markers: Array = battle._get_area_group_nodes(&"player_spawn_point")
		var spawn: Node3D = markers[rng.randi_range(0,markers.size()-1)]
		area.configure_sortie_layout(spawn,rng)
		seen[area.selected_spawn]=true
		check(area.active_exit_names.size()==2,"Seed %d assigns two far-side exits"%seed_value)
		var targets: Array[Node3D] = [area.get_node("StreetTerminal"),area.get_node("StreetSurvey")]
		for exit in area.find_children("*","ExtractionPoint",true,false):
			if exit.available:
				targets.append(exit)
				check(spawn.position.distance_to(exit.position)>60,"Assigned exit crosses the district")
			else: check(not exit.can_extract(session),"Unassigned exit rejects extraction")
		for target in targets:
			var path := NavigationServer3D.map_get_path(map,spawn.position,target.position,true)
			check(not path.is_empty() and path[-1].distance_to(target.position)<1.5,"Seed %d reaches %s (end %s target %s)"%[seed_value,target.name,path[-1] if not path.is_empty() else Vector3.ZERO,target.position])
		var high_count := 0
		for loot in area.loot_points:
			if not loot.enabled: continue
			if loot.loot_table_id==&"prototype_high_value_loot": high_count+=1
			var loot_path := NavigationServer3D.map_get_path(map,spawn.position,loot.position,true)
			check(not loot_path.is_empty() and loot_path[-1].distance_to(loot.position)<1.5,"Loot %s accessible (end %s target %s)"%[loot.name,loot_path[-1] if not loot_path.is_empty() else Vector3.ZERO,loot.position])
		check(high_count==4,"High-value loot remains inside four risk-bearing interiors")
		for point in area.enemy_points:
			if point.initial_spawn: check(point.position.distance_to(spawn.position)>24,"PMC does not spawn beside player")
	check(seen.size()==6,"Seeded deployment covers all six player spawn candidates")
	var basis: Basis = battle.camera.global_basis
	for step in 30:
		battle.player.position=Vector3(-20,.1,-20)+Vector3.RIGHT*step*.1
		battle.player.aim_direction=Vector3.LEFT if step%2 else Vector3.FORWARD
		battle._process(1./60.)
	check(basis.is_equal_approx(battle.camera.global_basis),"Follow/aim changes never alter camera angle")
	var body := VisualFactory.static_box(battle,Vector3(7,6,1),battle.camera.global_position.lerp(battle.player.global_position+Vector3.UP, .5),Color.GRAY,"TestOccluder")
	await get_tree().physics_frame
	for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,battle.player,.05)
	check(body.get_node("Mesh").transparency>.8,"Occlusion fades geometry without moving the camera")
	check(not body.find_children("*","CollisionShape3D",false,false)[0].disabled,"Fading keeps collision active")
	body.position.x+=200
	await get_tree().physics_frame
	for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,battle.player,.05)
	check(body.get_node("Mesh").transparency<.01,"Occluder opacity restores after sightline clears")
	var records := area.get_node("StreetTerminal") as ObjectiveInteractable
	check(records.interact(battle.player,session).success,"Records interaction advances the current mission")
	check(area.get_node("StreetSurvey").try_reach(battle.player),"Opposite courtyard advances the survey objective")
	check(session.is_mission_completed(),"Records and survey complete the district mission")
	for exit in area.find_children("*","ExtractionPoint",true,false):
		if exit.available:
			check(exit.extract(session),"An assigned exit completes the district sortie")
			break
	battle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("STREETS_LAYOUT_TEST failures=",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
