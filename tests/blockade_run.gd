extends "res://tests/streets_combat_run.gd"
## Generated movement/fire and ordinary nearest interactions: live actors, finite ammunition.
## Explicit first-mission sandbox fixture, not an earned story run.

func _controls(destination: Vector3) -> void:
	super._controls(destination)
	var van: BlockadeVan = battle.area_root.get_node("Van")
	if van.destroyed or van.phase != BlockadeVan.Phase.VENT: return
	# Keep ordinary infected targeting when they are close enough to threaten the player.
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController and not enemy.is_dead and battle.player_visibility.can_see_enemy(enemy) and enemy.global_position.distance_to(battle.player.global_position) < 9: return
	var origin: Vector3 = battle.player.global_position + Vector3.UP * 1.25
	var query := PhysicsRayQueryParameters3D.create(origin, van.global_position + Vector3.UP * 1.25, 6)
	query.exclude = [battle.player.get_rid()]
	var hit: Dictionary = battle.player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider != van: return
	for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
	var aim: Vector3 = battle.player.global_position.direction_to(van.global_position)
	_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z)
	Input.action_press("fire")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var profile := ProfileRuntime.new_profile();profile.first_mission_completed = true
	if DeploymentPlan.deploy(profile,BlockadeStory.AREA,BlockadeStory.MISSION,"user://blockade_run.json").error != OK:
		push_error("Encounter deployment failed");get_tree().quit(1);return
	battle = load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.weapon_fired.connect(func(_recoil: float):fired+=1)
	var world: Node3D = battle.area_root
	var van: BlockadeVan = world.get_node("Van")
	for tick in 45:await get_tree().physics_frame
	if not await approach_checkpoint(world):failures.append("New approach failed")
	for point in [world.get_node("PASwitch").global_position,Vector3(-9,0,-1),Vector3(0,0,1)]:
		if not await _walk(point): failures.append("Cannot reach "+str(point));break
		if point == world.get_node("PASwitch").global_position:
			if not world.get_node("PASwitch").interact(battle.player,battle.session).success:failures.append("Physical PA cutoff failed")
		print("BLOCKADE_RUN route=",point," hp=",battle.player.health," shots=",fired)
	var captured := {}
	for tick in 7200:
		if not failures.is_empty():break
		await get_tree().physics_frame
		if van.destroyed or battle.player.is_dead:break
		var destination := Vector3(0,0,1)
		if van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.BURST]:
			destination.x = -5.0 if van.aim_point.x >= 0 else 5.0
		_controls(destination)
		if van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.VENT] and not captured.has(van.phase):
			captured[van.phase]=true;await shot("blockade_run_"+str(van.phase))
	for action in ACTIONS:Input.action_release(action)
	await shot("blockade_run_disabled")
	if not van.destroyed or battle.player.is_dead:failures.append("Did not survive/disable vehicle through real weapon fire")
	if fired == 0 or van.shots_fired == 0:failures.append("No actual exchange of fire")
	var session: SortieSession = battle.session
	if failures.is_empty():
		if not await leave_yard(world) or not await _walk(world.get_node("NorthExit").global_position) or not world.get_node("NorthExit").extract(session):failures.append("Could not reach or extract through newly opened north gate")
	for action in ACTIONS:Input.action_release(action)
	if session.status != SortieSession.Status.COMPLETED or not session.is_mission_completed():failures.append("Encounter did not produce completed sortie")
	print("BLOCKADE_RUN shots=",fired," van_shots=",van.shots_fired," broadcasts=",van.broadcasts," kills=",session.enemies_defeated," health=",battle.player.health," route_facts=",session.blockade," failure=",failures)
	battle.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("BLOCKADE_RUN: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _walk(target: Vector3) -> bool:
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path:=PackedVector3Array()
	for tick in 600:
		await get_tree().physics_frame
		path=NavigationServer3D.map_get_path(map,battle.player.global_position,target,true)
		if not path.is_empty() and path[-1].distance_to(target)<1:break
	if path.is_empty() or path[-1].distance_to(target)>=1:
		failures.append("Unreachable path: "+str(battle.player.position)+" -> "+str(target)+" / "+str(path));return false
	for point in path:
		var reached:=false
		for tick in 1200:
			await get_tree().physics_frame
			if battle.player.is_dead:return false
			var gap: Vector3=point-battle.player.position;gap.y=0
			if gap.length()<.45:reached=true;break
			_controls(point)
		if not reached:failures.append("New route stuck: "+str(battle.player.position)+" -> "+str(point));return false
	_release();return true

func _release() -> void:
	for action in ACTIONS:Input.action_release(action)

func use_nearest(point: Node3D) -> Dictionary:
	battle.player.interaction_component._physics_process(0)
	if battle.player.interaction_component._current_target!=point:return {"success":false}
	return battle.player.interaction_component.interact_with_current()

func approach_checkpoint(world: Node3D) -> bool:
	if battle.session.blockade.is_empty():return true
	if "--street" in OS.get_cmdline_user_args():
		if not await _walk(Vector3(0,0,27)):return false
		var chain:=world.get_node("StreetChain") as BlockadeStreetChain
		for tick in 600:
			await get_tree().physics_frame
			if chain.destroyed:break
			if battle.player.is_dead:return false
			_controls(battle.player.position)
			var query:=PhysicsRayQueryParameters3D.create(battle.player.position+Vector3.UP*1.25,chain.position,4)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.collider==chain:
				for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
				var aim: Vector3=battle.player.position.direction_to(chain.position);aim.y=0;aim=aim.normalized()
				_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z);Input.action_press("fire")
		_release()
		if not chain.destroyed or not battle.session.blockade.alarm:return false
		await shot("checkpoint_chain_entry")
		return await _walk(Vector3(0,0,17))
	for point in [Vector3(-7,0,41),Vector3(-18,0,41)]:
		if not await _walk(point):return false
	_release()
	var light:=world.get_node("Searchlight") as BlockadeSearchlight
	for tick in 600:
		await get_tree().physics_frame
		if light.sweep_time>.9 and light.sweep_time<2.1:break
	if not await _walk(world.get_node("ServiceLever").position):return false
	_release()
	if not use_nearest(world.get_node("ServiceLever")).success:return false
	await shot("checkpoint_quiet_shutter")
	if battle.session.blockade.alarm:failures.append("Quiet cover/timing route was detected");return false
	return await _walk(Vector3(-15,0,17))

func leave_yard(world: Node3D) -> bool:
	if battle.session.blockade.is_empty():return true
	if not battle.session.blockade.van_down or battle.session.is_mission_completed():return false
	await shot("checkpoint_wreck_not_finished")
	if not await _walk(world.get_node("EscapeLever").position):return false
	_release()
	if not use_nearest(world.get_node("EscapeLever")).success:return false
	for tick in 600:
		await get_tree().physics_frame
		if battle.player.is_dead:return false
		if battle.session.blockade.escape_open:break
		_controls(battle.player.position)
	_release();await shot("checkpoint_north_shutter_open")
	return battle.session.blockade.escape_open and battle.session.is_mission_completed()
