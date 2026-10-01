extends Node
## Simulated controller inputs with the real player, enemy AI, ammo, collision and outcomes.
const ACTIONS := ["move_left","move_right","move_forward","move_back","aim_left","aim_right","aim_up","aim_down","fire"]
var battle: Node3D
var fired := 0
var reloads := 0
var failures: Array[String] = []
var recovered_ids: Array[String] = []

func _ready() -> void: _run.call_deferred()

func _axis(negative: String, positive: String, value: float) -> void:
	if value < -.01: Input.action_press(negative,-value)
	elif value > .01: Input.action_press(positive,value)

func _controls(destination: Vector3) -> void:
	for action in ACTIONS: Input.action_release(action)
	var player: PlayerController = battle.player
	var gap := destination-player.global_position
	gap.y=0
	var motion := gap.normalized() if gap.length()>.25 else Vector3.ZERO
	_axis("move_left","move_right",motion.x)
	_axis("move_forward","move_back",motion.z)
	var aim := motion if motion!=Vector3.ZERO else player.aim_direction
	var nearest: EnemyController
	var distance := 24.0
	for candidate in battle.enemy_container.get_children():
		if not candidate is EnemyController: continue
		var enemy := candidate as EnemyController
		if enemy.is_dead: continue
		var separation := player.global_position.distance_to(enemy.global_position)
		if separation>=distance: continue
		var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.25,enemy.global_position+Vector3.UP*1.25,6)
		ray.exclude=[player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider==enemy:
			nearest=enemy
			distance=separation
	if nearest:
		aim=player.global_position.direction_to(nearest.global_position)
		aim.y=0
		aim=aim.normalized()
		Input.action_press("fire")
	_axis("aim_left","aim_right",aim.x)
	_axis("aim_up","aim_down",aim.z)
	var weapon: Dictionary = player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY)
	if int(weapon.get("magazine",0))==0 and player.can_reload(): player.reload_weapon()

func _walk(target: Vector3) -> bool:
	var map: RID = battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path := NavigationServer3D.map_get_path(map,battle.player.global_position,target,true)
	if path.is_empty(): return false
	for waypoint in path:
		var reached := false
		for tick in 900:
			await get_tree().physics_frame
			if battle.player.is_dead: return false
			var gap: Vector3 = waypoint-battle.player.global_position
			gap.y=0
			if gap.length()<.55:
				reached=true
				break
			_controls(waypoint)
		if not reached:
			push_error("COMBAT RUN stuck %s heading to %s"%[battle.player.global_position,waypoint])
			return false
	return true

func _run() -> void:
	if DisplayServer.get_name()!="headless": get_tree().root.size=Vector2i(1600,1000)
	var profile := ProfileRuntime.new_profile()
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon",plan.ammo_ids),profile)
	battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed=907
	var arguments := OS.get_cmdline_user_args()
	var seed_argument := arguments.find("--combat-seed")
	if seed_argument>=0 and seed_argument+1<arguments.size():
		battle.loot_seed=int(arguments[seed_argument+1])
	get_tree().root.add_child(battle)
	get_tree().current_scene=battle
	battle.result_transition_enabled=false
	battle.player.weapon_fired.connect(func(_recoil: float): fired+=1)
	var starts := {}
	for enemy in battle.enemy_container.get_children(): starts[enemy]=enemy.global_position
	var area: Node3D = battle.area_root
	print("STREETS_COMBAT_LAYOUT seed=",battle.loot_seed," spawn=",area.selected_spawn," task=",area.task_index," exits=",area.active_exit_names)
	var map: RID = area.get_node("StreetNavigation").get_navigation_map()
	for tick in 60:
		await get_tree().create_timer(.05).timeout
		NavigationServer3D.map_force_update(map)
		if not NavigationServer3D.map_get_path(map,battle.player.position,area.get_node("StreetTerminal").position,true).is_empty(): break
	var targets: Array[Node3D] = [area.get_node("StreetTerminal"),area.get_node("StreetSurvey")]
	var loot_room: int = (area.task_index+1)%4
	for loot in area.loot_points:
		if loot.loot_table_id==&"prototype_high_value_loot" and loot.position.distance_to(area.ROOMS[loot_room])<9:
			targets.append(loot)
			break
	for exit in area.find_children("*","ExtractionPoint",true,false):
		if exit.available:
			targets.append(exit)
			break
	for target in targets:
		if not await _walk(target.global_position):
			failures.append("Could not survive/reach "+target.name)
			break
		print("STREETS_COMBAT reached ",target.name," health=",battle.player.health," fired=",fired)
		if DisplayServer.get_name()!="headless" and "--combat-capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("/tmp/streets_combat_%s.png"%target.name)
		if target is ObjectiveInteractable:
			target.interact(battle.player,session)
			if battle.player.reload_weapon(): reloads+=1
		if target is LootSpawnPoint:
			for pickup in target.get_children():
				if pickup is LootPickup:
					var id: String = pickup.item_instance.instance_id
					if pickup.interact(battle.player,session).success: recovered_ids.append(id)
		if target is ExtractionPoint: target.extract(session)
	for action in ACTIONS: Input.action_release(action)
	var moved := 0
	var kills := 0
	for enemy in starts:
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(starts[enemy])>1: moved+=1
		if not is_instance_valid(enemy) or enemy.is_dead: kills+=1
	if fired==0 or moved==0 or kills==0: failures.append("No verified combat/navigation activity")
	if reloads==0: failures.append("No successful ammo reload")
	if not session.is_mission_completed(): failures.append("Objectives incomplete")
	if session.status!=SortieSession.Status.COMPLETED: failures.append("Extraction incomplete")
	if recovered_ids.is_empty(): failures.append("No indoor loot recovered")
	if session.status==SortieSession.Status.COMPLETED:
		if SortieOutcomeService.commit_outcome(profile,SortieOutcomeService.create_outcome(session))!=OK: failures.append("Outcome commit failed")
		for id in recovered_ids:
			if not profile.inventory.contains(id): failures.append("Recovered instance missing from warehouse")
	print("STREETS_COMBAT_RUN fired=",fired," reloads=",reloads," kills=",kills," moved_enemies=",moved," recovered=",recovered_ids.size()," failures=",failures)
	battle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("STREETS_COMBAT_RUN ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
