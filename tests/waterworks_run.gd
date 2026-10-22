extends "res://tests/streets_combat_run.gd"

func capture_delivery(title: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(title+".png"))

func _walk(target: Vector3) -> bool:
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path:=PackedVector3Array()
	for tick in 600:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(map)==0:continue
		path=NavigationServer3D.map_get_path(map,battle.player.position,target,true)
		if not path.is_empty() and path[-1].distance_to(target)<=1.2:break
	if path.is_empty() or path[-1].distance_to(target)>1.2:
		push_error("Water route cannot actually reach target: "+str(target));return false
	return await super._walk(target)

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var branch := "tanker" if "--tanker" in OS.get_cmdline_user_args() else "public"
	var profile := ProfileRuntime.new_profile();profile.first_mission_completed=true
	var request := DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,"user://waterworks_run.json")
	if request.error != OK: push_error("Waterworks deployment failed");get_tree().quit(1);return
	var session := SortieRuntime.get_current_session()
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.weapon_fired.connect(func(_recoil: float):fired+=1)
	var world: Node3D = battle.area_root
	var nav: RID = world.get_node("StreetNavigation").get_navigation_map()
	for tick in 90:
		await get_tree().physics_frame
		if not NavigationServer3D.map_get_path(nav,battle.player.global_position,world.get_node("Battery").global_position,true).is_empty():break
	print("WATERWORKS_NAV polygons=",world.get_node("StreetNavigation").navigation_mesh.get_polygon_count()," start=",battle.player.position," closest=",NavigationServer3D.map_get_closest_point(nav,battle.player.position))
	for name in ["Battery","Decoy","Pump","PublicValve" if branch=="public" else "TankerValve"]:
		var point: WaterworksAction = world.get_node(name)
		if not await _walk(point.global_position):failures.append("Cannot reach "+name);break
		for action in ACTIONS:Input.action_release(action)
		var result := point.interact(battle.player,session)
		if not result.success: failures.append("Action rejected "+name+": "+str(result));break
		if name=="Pump":
			for tick in 1800:
				await get_tree().physics_frame
				_controls(battle.player.global_position)
				if point.remaining==0 and not WaterworksStory.done(session,&"water_pump"):point.interact(battle.player,session)
				if WaterworksStory.done(session,&"water_pump") or battle.player.is_dead:break
			if not WaterworksStory.done(session,&"water_pump"):failures.append("Could not install under actual AI pressure");break
		if name in ["PublicValve","TankerValve"] and not point.confirm_delivery():failures.append("Choice confirmation failed")
		print("WATERWORKS_RUN reached ",name," health=",battle.player.health," shots=",fired)
		if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("waterworks_run_"+branch+"_"+name+".png"))
	await capture_delivery("water_delivery_pending_"+branch)
	if failures.is_empty() and not battle.player.is_dead:
		if branch=="public":
			if "--shoot-public" in OS.get_cmdline_user_args():
				if not await _walk(Vector3(-27,0,-15.5)):failures.append("Cannot reach relief shooting position")
				var latch: WaterPublicLatch=world.get_node("Latch")
				for tick in 600:
					await get_tree().physics_frame
					if latch.destroyed or battle.player.is_dead:break
					_controls(battle.player.position)
					for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
					var aim: Vector3=battle.player.position.direction_to(latch.position)
					_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z);Input.action_press("fire")
				if not latch.destroyed or session.waterworks.public_fix!="shot":failures.append("Actual bullets did not release latch")
			else:
				var wheel: WaterDeliveryControl=world.get_node("Bypass")
				if not await _walk(wheel.position) or not wheel.interact(battle.player,session).success:failures.append("Cannot operate west pressure bypass")
		else:
			var lever: WaterDeliveryControl=world.get_node("LoadingLever")
			if not await _walk(lever.position) or not lever.interact(battle.player,session).success:failures.append("Cannot raise loading gate")
			var truck: WaterTanker=world.get_node("Tanker")
			if not await _walk(truck.position+Vector3.LEFT*2.4) or not truck.interact(battle.player,session).success:failures.append("Cannot release real truck handbrake")
			for tick in 1200:
				await get_tree().physics_frame;_controls(battle.player.position)
				if tick==120:await capture_delivery("water_truck_moving")
				if session.is_mission_completed() or battle.player.is_dead:break
			if not session.is_mission_completed():failures.append("Truck did not physically arrive")
			if not await _walk(Vector3(22,0,-31)) or not await _walk(Vector3(22,0,-38)):failures.append("Cannot flank loading wall")
		for action in ACTIONS:Input.action_release(action)
		print("WATERWORKS_RUN onsite=",session.waterworks," health=",battle.player.health," shots=",fired)
	if session.is_mission_completed() and not battle.player.is_dead:
		if branch=="public":
			if not await _walk(Vector3(-38,0,-20)):failures.append("Cannot enter supplied courtyard")
			await capture_delivery("water_courtyard_people")
		var exit: ExtractionPoint=world.get_node("PublicExit" if branch=="public" else "TankerExit")
		if not await _walk(exit.global_position) or battle.player.global_position.distance_to(exit.global_position)>battle.player.interaction_component.interaction_radius or not exit.interact(battle.player,session).success:failures.append("Selected physical extraction failed")
	await capture_delivery("water_delivery_arrived_"+branch)
	for action in ACTIONS:Input.action_release(action)
	if session.status!=SortieSession.Status.COMPLETED or not session.is_mission_completed():failures.append("Real mission/extraction incomplete")
	if fired==0 or session.enemies_defeated==0:failures.append("No actual combat")
	if failures.is_empty():
		if SortieRuntime.finalize_sortie("user://waterworks_run.json") != OK or ProfileRuntime.get_profile().waterworks_memory != ("water_public" if branch == "public" else "water_tanker"): failures.append("Actual combat route did not persist matching base memory")
	var evidence:=OS.get_environment("BUNNY_EVIDENCE")
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("water_route.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"method":"synthetic controller inputs, live AI/ammo/physics; not human playtime","branch":branch,"facts":session.waterworks,"shots":fired,"kills":session.enemies_defeated,"damage":session.damage_taken,"health":battle.player.health,"status":session.status,"failures":failures},"	"));file.close()
	print("WATERWORKS_RUN branch=",branch," shots=",fired," kills=",session.enemies_defeated," health=",battle.player.health," failures=",failures)
	battle.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("WATERWORKS_RUN: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
