extends Node
## Exercise the actual player capsule against the authored streets/interior collision.
var battle: Node3D
var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _walk_to(target: Vector3) -> bool:
	var player: PlayerController = battle.player
	var map: RID = battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path := NavigationServer3D.map_get_path(map,player.global_position,target,true)
	if path.is_empty(): return false
	for waypoint in path:
		var reached := false
		for tick in 600:
			await get_tree().physics_frame
			var gap: Vector3 = waypoint-player.global_position
			gap.y=0
			if gap.length()<.22:
				reached=true
				break
			var motion := gap.normalized()*minf(player.get_movement_speed(),gap.length()*60.0)
			player.velocity.x=motion.x
			player.velocity.z=motion.z
			player.velocity.y=-.1 if player.is_on_floor() else player.velocity.y-24.0/60.0
			player.move_and_slide()
		if not reached:
			push_error("Capsule stuck at %s, waypoint %s"%[player.global_position,waypoint])
			return false
	player.velocity=Vector3.ZERO
	return Vector2(player.global_position.x-target.x,player.global_position.z-target.z).length()<1.5

func _run() -> void:
	var profile := ProfileRuntime.new_profile()
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon",plan.ammo_ids),profile)
	battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed=907
	add_child(battle)
	battle.result_transition_enabled=false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():
		enemy.set_physics_process(false)
		enemy.collision_layer=0
	var area: Node3D = battle.area_root
	var map: RID = area.get_node("StreetNavigation").get_navigation_map()
	for tick in 60:
		await get_tree().create_timer(.05).timeout
		NavigationServer3D.map_force_update(map)
		if not NavigationServer3D.map_get_path(map,battle.player.position,area.get_node("StreetTerminal").position,true).is_empty(): break
	var targets: Array[Node3D] = [area.get_node("StreetTerminal"),area.get_node("StreetSurvey")]
	for loot in area.loot_points:
		if loot.loot_table_id==&"prototype_high_value_loot":
			targets.append(loot)
			break
	for exit in area.find_children("*","ExtractionPoint",true,false):
		if exit.available:
			targets.append(exit)
			break
	for target in targets:
		if not await _walk_to(target.global_position):
			failures.append("Cannot physically reach "+target.name)
			break
		print("STREETS_WALK reached ",target.name," at ",battle.player.global_position)
		if target is ObjectiveInteractable:
			target.interact(battle.player,session)
			if target is RecordsTerminal:
				for frame in 600:
					await get_tree().physics_frame
					if session.get_objective_state(target.objective_id).status == ObjectiveState.Status.COMPLETED: break
		if target is ObjectiveReachZone: target.try_reach(battle.player)
	if failures.is_empty() and not session.is_mission_completed(): failures.append("Walk did not complete both mission objectives")
	battle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("STREETS_WALK_TEST failures=",failures)
	print("STREETS_WALK_TEST ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
