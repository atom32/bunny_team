extends "res://tests/campus_chapter_test.gd"
## Explicit placement/damage fixtures. The earned route is campus_chapter_run.
var checks:=0
func chapter_path() -> String:return "user://campus_handoff_test.json"
func check(ok: bool,message: String) -> void:
	checks+=1;super.check(ok,message)
func frames(count:=3) -> void:
	for index in count:await get_tree().physics_frame
func freeze() -> void:
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.area_root.get_node("CampusSupplyHandoff").set_physics_process(false)
func walk_navigation(at: Vector3) -> bool:
	var nav: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path:=NavigationServer3D.map_get_path(nav,battle.player.global_position,at,true)
	if path.is_empty():return false
	battle.player.set_physics_process(true)
	var ok:=true
	for point in path:
		var reached:=false
		for tick in 900:
			await get_tree().physics_frame
			var gap: Vector3=point-battle.player.global_position;gap.y=0
			if gap.length()<.4:reached=true;break
			for action in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)
			var direction:=gap.normalized()
			Input.action_press("move_left" if direction.x<0 else "move_right",absf(direction.x))
			Input.action_press("move_forward" if direction.z<0 else "move_back",absf(direction.z))
		if not reached:
			var contacts:=[]
			for index in battle.player.get_slide_collision_count():contacts.append(str(battle.player.get_slide_collision(index).get_collider()))
			print("HANDOFF_NAV_DIAGNOSTIC ",JSON.stringify({"player":str(battle.player.position),"target":str(at),"waypoint":str(point),"path":str(path),"contacts":contacts,"paused":get_tree().paused}))
			ok=false;break
	for action in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)
	battle.player.set_physics_process(false)
	return ok and Vector2(battle.player.position.x-at.x,battle.player.position.z-at.z).length()<.8
func report() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("CAMPUS_HANDOFF_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args():return
	await frames(60)
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"render actual handoff staging")
func _ready() -> void:
	await get_tree().process_frame
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var profile: ProfileState
	if "--legacy-v4-read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"actual previous-export v4 checkpoint is accepted without changing its contract")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		battle.player.set_physics_process(false)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		var point:=battle.area_root.get_node("CampusSupplyHandoff") as CampusSupplyHandoff
		point.set_physics_process(false)
		check(not FlowMenu.is_open() and battle.session.campus.version==4 and not point.has_node("HandoffDoorLink"),"old v4 keeps original navigation geometry rather than receiving a silent map replacement")
		check(not battle.session.campus.supply_received and not ProfileRuntime.get_profile().campus_chapter.finished,"reading an old active sortie invents neither receipt nor completion")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"old v4 world remains strictly checkpointable")
		report();return
	if "--legacy-read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"genuine previous-code v3 world checkpoint is accepted")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		battle.player.set_physics_process(false)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		check(not FlowMenu.is_open() and battle.session.campus.version==3 and not battle.area_root.has_node("CampusSupplyHandoff"),"old signed world keeps its original actors, geometry and rule")
		check(not battle.session.campus.has("supply_received"),"old checkpoint never gains a fabricated field receipt")
		profile=ProfileRuntime.get_profile();var credits:=profile.credits
		await finish_world(true)
		check(profile.campus_chapter.finished and profile.credits==credits+CampusChapter.FINAL_REWARD,"genuine old supplied sortie still closes after its promised safe return")
		report();return
	if "--read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"separate process accepts pending handoff checkpoint")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		freeze()
		var point:=battle.area_root.get_node("CampusSupplyHandoff") as CampusSupplyHandoff
		check(not FlowMenu.is_open() and point.phase==CampusSupplyHandoff.Phase.MOVING and is_equal_approx(point.progress,1.0/3.0),"partial transfer preserves progress rather than crediting or restarting it")
		check(not battle.session.campus.supply_received and point.threats_remaining()==0,"no revived gunmen or invented receipt on restore")
		point._physics_process(2.4)
		check(battle.session.campus.supply_received,"restored physical transfer can finish")
		profile=ProfileRuntime.get_profile();var credits:=profile.credits
		await finish_world(true)
		check(profile.campus_chapter.finished and profile.credits==credits+CampusChapter.FINAL_REWARD,"only safe return settles restored receipt once")
		report();return
	profile=profile_at_batch2()
	for key in ["relays_returned","recorder_revealed","recorder_returned","branch_disconnected","power_returned","delivered_armor"]:profile.campus_chapter[key]=true
	profile.campus_chapter.delivered_ammo=60
	check(profile.validate(),"declared packed-supply fixture remains profile schema11")
	# A historical ten-field contract must not acquire new actors or obligations.
	await start_world(3)
	check(not battle.area_root.has_node("CampusSupplyHandoff") and not battle.session.campus.has("supply_received"),"v3 continuation keeps original extraction-only contract")
	var old_facts: Dictionary=battle.session.campus.duplicate(true)
	check(CampusChapter.valid_facts(old_facts,&"street_district"),"old ten-field facts remain accepted")
	battle.free();battle=null;SortieRuntime.clear_session();profile.sortie_checkpoint={}
	# A genuinely unpacked deployment must not display equipment that does not exist.
	profile.campus_chapter.delivered_armor=false;profile.campus_chapter.delivered_ammo=0
	await start_world();freeze()
	var unpacked:=battle.area_root.get_node("CampusSupplyHandoff") as CampusSupplyHandoff
	battle.player.position=unpacked.position+Vector3(0,0,.7);unpacked._physics_process(0)
	check(not battle.session.campus.gear_ready and not unpacked.get_node("Cargo").visible,"fresh unpacked sortie has no phantom armor/ammunition crate")
	check(not unpacked.introduced and not unpacked.interact(battle.player,battle.session).success,"unpacked sortie neither promises a nonexistent shipment nor sends it")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"unpacked physical world still produces a valid checkpoint")
	await capture("handoff_unpacked")
	battle.free();battle=null;SortieRuntime.clear_session();profile.sortie_checkpoint={}
	profile.campus_chapter.delivered_armor=true;profile.campus_chapter.delivered_ammo=60
	await start_world();freeze();await frames()
	var handoff:=battle.area_root.get_node("CampusSupplyHandoff") as CampusSupplyHandoff
	check(battle.session.campus.version==CampusChapter.FACTS_VERSION and not battle.session.campus.supply_received,"fresh supply sortie requires a real field receipt")
	await frames(10)
	var nav: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var gate_rect:=Rect2(-32.45,29.28,2.9,.84)
	var original_site: int=battle.area_root.task_index
	var original_box: Vector3=battle.area_root.get_node("RecordsIsolator").position
	for site in 4:
		battle.area_root.task_index=site
		var cabinet:=battle.area_root.get_node("RecordsIsolator") as Node3D
		cabinet.position=battle.area_root.get_node("RecordsIsolationSites/Site%d"%site).position
		var previous_mesh: NavigationMesh=battle.area_root.get_node("StreetNavigation").navigation_mesh
		var previous_iteration:=NavigationServer3D.map_get_iteration_id(nav)
		battle.area_root.configure_navigation()
		if previous_mesh!=battle.area_root.get_node("StreetNavigation").navigation_mesh:
			for tick in 600:
				await get_tree().physics_frame
				if NavigationServer3D.map_get_iteration_id(nav)>previous_iteration:break
			check(NavigationServer3D.map_get_iteration_id(nav)>previous_iteration,"navigation server actually publishes the selected cabinet variant")
		await frames(2)
		var cabinet_rect:=Rect2(cabinet.position.x-.735,cabinet.position.z-.52,1.47,1.04)
		for spawn: Vector3 in battle.area_root.SPAWNS:
			var path:=NavigationServer3D.map_get_path(nav,spawn,handoff.global_position+Vector3(0,0,1),true)
			var crosses:=false
			for index in maxi(0,path.size()-1):
				var a:=path[index];var b:=path[index+1]
				for step in int(ceil(a.distance_to(b)/.2))+1:
					var at:=a.lerp(b,minf(1,step*.2/maxf(.001,a.distance_to(b))))
					if gate_rect.has_point(Vector2(at.x,at.z)) or cabinet_rect.has_point(Vector2(at.x,at.z)):crosses=true
			var valid: bool=not path.is_empty() and path[path.size()-1].distance_to(handoff.global_position+Vector3(0,0,1))<.8 and not crosses
			if not valid:print("HANDOFF_VARIANT_DIAGNOSTIC ",JSON.stringify({"site":site,"spawn":str(spawn),"path":str(path),"crosses":crosses}))
			check(valid,"all six spawns and four solid-cabinet layouts route around real collision, not through the closed shutter or cabinet")
	battle.area_root.task_index=original_site;battle.area_root.get_node("RecordsIsolator").position=original_box;battle.area_root.configure_navigation();await frames(6)
	check(not handoff.get_node("HandoffDoorLink").enabled,"closed shutter has no enabled shortcut link")
	battle.player.position=Vector3(-30.78761,0,29.27907) # Exact observed failed-launcher location; declared component placement.
	check(await walk_navigation(handoff.global_position+Vector3(0,0,.7)),"real movement recovers from the observed inside-door location by routing around the closed physical shutter")
	await capture("handoff_closed_detour")
	check(handoff.threats_remaining()==2 and handoff.get_node("WestInfected").has_spawned,"two real covering gunmen and one finite infected are present")
	var before:=profile.inventory.to_dict();var carried: Dictionary=battle.session.inventory.to_dict()
	var retreat:=SortieCheckpoint.restore_session(SortieCheckpoint.session_data(battle.session));retreat.complete_extraction()
	var retreat_profile:=ProfileState.from_dict(profile.to_dict())
	CampusChapter.record_outcome(retreat_profile,SortieOutcome.create_from_session(retreat))
	check(not retreat_profile.campus_chapter.finished and retreat_profile.credits==profile.credits,"an immediate extraction cannot close the new chapter or grant its reward")
	check(battle.area_root.route_map._campus_map_points().any(func(entry):return entry.point==handoff),"field window is on the existing route map")
	battle.player.position=handoff.position+Vector3(9,0,0)
	check(not handoff.interact(battle.player,battle.session).success,"remote interaction cannot send the supplies")
	battle.player.position=handoff.position+Vector3(0,0,.7)
	check(not handoff.interact(battle.player,battle.session).success and handoff.phase==0,"living window gunmen block the handoff, not a work timer")
	var guard_key:="CampusSupplyHandoff/WestGuard"
	var living_guard: Dictionary=SortieCheckpoint.capture_world(battle).enemies[guard_key].duplicate(true)
	await capture("handoff_covered")
	for enemy in battle.enemy_container.get_children():
		if enemy.get_meta("spawn_key","") in ["CampusSupplyHandoff/WestGuard","CampusSupplyHandoff/EastGuard"]:enemy.take_damage(1000)
	await frames()
	check(handoff.threats_remaining()==0 and battle.enemy_container.get_child_count()>0,"only two window gunmen matter; other living enemies do not force full-map clearance")
	battle.session.campus.gear_ready=false
	check(not handoff.interact(battle.player,battle.session).success and handoff.phase==0,"window cannot invent unprepared equipment")
	battle.session.campus.gear_ready=true
	battle.player.interaction_component._physics_process(0)
	check(battle.player.position.z-handoff.global_position.z>(handoff.get_node("RollerTable").position.z+handoff.get_node("RollerTable").mesh.size.z*.5+battle.player.get_node("Hitbox").shape.radius),"normal interaction position is outside the transfer table footprint plus player capsule")
	check(battle.player.interaction_component._current_target==handoff,"actual nearest interaction selects the window, not the nearby old door")
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action=&"interact";event.pressed=pressed;get_viewport().push_input(event);await frames()
	check(handoff.phase==CampusSupplyHandoff.Phase.MOVING and not battle.session.campus.supply_received,"real E begins transfer without instantly crediting it")
	check(profile.inventory.to_dict()==before and battle.session.inventory.to_dict()==carried,"field handoff never consumes a second armor or ammunition stack")
	handoff._physics_process(.8)
	check(handoff.get_node("HandoffDoorLink").enabled,"door shortcut enables only after its real body clears the player")
	await frames(10)
	# A normal courtyard infected is frozen by this component fixture at the
	# doorway. Remove that declared actor obstruction, not the shutter collision.
	# Ordinary earned runs retain live AI and must fight/move around it normally.
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController and Vector2(enemy.global_position.x+31,enemy.global_position.z-32).length()<2:enemy.take_damage(1000)
	await frames()
	battle.player.position=Vector3(-31,0,27.2)
	check(await walk_navigation(handoff.global_position+Vector3(0,0,.7)),"real movement follows the newly opened link through the raised shutter without disabling collision")
	await capture("handoff_open_crossing")
	var world:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle) and SortieCheckpoint.restore_world(world,battle),"partly raised shutter and sliding crate roundtrip through strict world restore")
	check(is_equal_approx(handoff.progress,1.0/3.0) and not battle.session.campus.supply_received,"restored moving crate has exact partial progress and no early receipt")
	for mutation in ["received","progress","phase","gunman","spawn","missing_fact"]:
		var bad:=world.duplicate(true)
		match mutation:
			"received":bad.nodes.CampusSupplyHandoff.phase=2;bad.nodes.CampusSupplyHandoff.progress=1
			"progress":bad.nodes.CampusSupplyHandoff.progress=2
			"phase":bad.nodes.CampusSupplyHandoff.phase=0;bad.nodes.CampusSupplyHandoff.progress=.3
			"gunman":bad.enemies[guard_key]=living_guard.duplicate(true)
			"spawn":bad.nodes["CampusSupplyHandoff/WestGuard"].has_spawned=false
			"missing_fact":bad.campus.erase("supply_received")
		check(not SortieCheckpoint.validate_world(bad,battle),"reject inconsistent transfer checkpoint before mutation: "+mutation)
	await capture("handoff_moving")
	if "--write" in OS.get_cmdline_user_args():
		check(SortieRuntime.save_checkpoint()==OK,"persist partial transfer for a different process")
		report();return
	handoff._physics_process(2.4)
	check(battle.session.campus.supply_received and handoff.phase==2 and handoff.get_node("Cargo").position.z< -3.9,"receipt requires physical cargo to cross the window")
	check(not handoff.interact(battle.player,battle.session).success,"repeated E cannot repeat the transfer")
	check(not profile.campus_chapter.finished,"field receipt alone is not a safe return")
	world=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(world,battle) and handoff.phase==2 and handoff.get_node("Shutter").position.y>3.6,"received crate and raised shutter restore visibly without spawning more equipment")
	await capture("handoff_received")
	var failed:=SortieCheckpoint.restore_session(SortieCheckpoint.session_data(battle.session));failed.fail()
	var failed_profile:=ProfileState.from_dict(profile.to_dict());var credits:=profile.credits
	CampusChapter.record_outcome(failed_profile,SortieOutcome.create_from_session(failed))
	check(not failed_profile.campus_chapter.finished and failed_profile.credits==credits and failed_profile.campus_chapter.delivered_armor,"failure retains prior packing, does not award completion or demand a second purchase")
	await finish_world(true)
	check(profile.campus_chapter.finished and profile.credits==credits+CampusChapter.FINAL_REWARD,"safe extraction with actual receipt closes chapter and awards exactly once")
	for text in [CampusSupplyHandoff.INTRO,CampusSupplyHandoff.RECEIVED]:check(tr(text)!=text if TranslationServer.get_locale()=="zh_CN" else tr(text)==text,"field dialogue is localized")
	report()
