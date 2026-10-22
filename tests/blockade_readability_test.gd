extends "res://tests/blockade_test.gd"
const PRIOR_LAYOUT := "dea44b6b23863434d7495534d73302129175f4b293a2d08118f3a57c2cd8646a"
const POLISH_PATH := "user://blockade_readability.json"

func aim_at_van(van: BlockadeVan) -> void:
	battle.player.aim_direction = battle.player.global_position.direction_to(van.global_position)
	battle.player_visibility.refresh()

func contrast(a: Color, b: Color) -> float:
	var x := a.srgb_to_linear();var y := b.srgb_to_linear()
	var l1 := x.r*.2126+x.g*.7152+x.b*.0722;var l2 := y.r*.2126+y.g*.7152+y.b*.0722
	return (maxf(l1,l2)+.05)/(minf(l1,l2)+.05)

func gate_ray() -> Dictionary:
	return battle.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,-18),Vector3(0,1,-24),4))

func _run() -> void:
	GameLanguage.set_language("zh_CN",false);SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,BlockadeStory.AREA,BlockadeStory.MISSION,POLISH_PATH).error == OK,"normal encounter deploys")
	SortieRuntime.get_current_session().blockade={} # Explicit original-map compatibility fixture.
	await load_battle()
	var world: Node3D = battle.area_root
	var van: BlockadeVan = world.get_node("Van")
	var readout: Control = world.get_node("BlockadeReadoutLayer/BlockadeReadout")
	check(battle.checkpoint_layout_signature == PRIOR_LAYOUT,"authored collision/navigation match actual prior exported build signature")
	check(is_equal_approx(world.get_node("Concrete5Body").position.y,.85) and not gate_ray().is_empty(),"closed traffic blast shield is real ballistic collision")
	check(not world.get_node("NorthExit").can_extract(battle.session) and not world.get_node("NorthGateLink").enabled,"traffic gate, navigation link and extraction start locked")
	var nav: RID = world.get_node("StreetNavigation").get_navigation_map()
	# The first nonzero map iteration may still be the empty world map,
	# before its authored region has synchronized. Do not test topology yet.
	var navigation_ready := false
	for tick in 120:
		navigation_ready = NavigationServer3D.map_get_iteration_id(nav)>0 and NavigationServer3D.map_get_closest_point(nav,Vector3(0,0,-18)).distance_to(Vector3(0,0,-18))<.1 and NavigationServer3D.map_get_closest_point(nav,Vector3(0,0,-24)).distance_to(Vector3(0,0,-24))<.1
		if navigation_ready: break
		await get_tree().physics_frame
	check(navigation_ready,"authored navigation synchronized before closed-gate topology query")
	var closed_path := NavigationServer3D.map_get_path(nav,Vector3(0,0,-18),Vector3(0,0,-24),true)
	check(not closed_path.is_empty() and Array(closed_path).any(func(point):return absf(point.x)>2.5),"closed-gate navigation routes around the physical blocker / iteration=%d path=%s" % [NavigationServer3D.map_get_iteration_id(nav),closed_path])
	check(not readout.card.visible,"distant spawn reveals no exact vehicle health")
	check(world.get_node("PowerIndicators").visible and world.get_node("PASwitch/PowerOn").visible,"live PA circuit has lit cable and switch indicators")
	for control in readout.find_children("*","Control",true,false):check(control.mouse_filter == Control.MOUSE_FILTER_IGNORE,"readout never consumes aiming/fire input: "+control.name)
	battle.player.position=Vector3(0,.1,14);aim_at_van(van)
	for tick in 45:await get_tree().physics_frame
	readout.update_readout(0)
	check(battle.player_visibility.in_view(van.global_position) and not readout.card.visible,"off-screen vehicle does not reveal precise phase or health")
	battle.player.position=Vector3(0,.1,1);aim_at_van(van)
	for tick in 45:await get_tree().physics_frame
	readout.update_readout(0)
	check(van.observed() and readout.card.visible,"observed vehicle has a screen-space legible state card")
	check(readout.title.text == tr("BLOCKADE VAN / %d / %d") % [360,360],"health card displays actual structure values")
	battle.player.aim_world_point=van.global_position+Vector3.UP*1.2
	var trace:Dictionary=battle.player_visibility.aim_trace()
	check(not trace.blocked and trace.point.distance_to(van.global_position)<5,"observed hostile vehicle is a valid aim target, not false muzzle obstruction")
	battle.hud.set_perception(battle.player_visibility,battle.camera)
	check(not battle.hud.cover_hint.visible,"aiming at vehicle does not wrongly tell player that cover blocks the shot")
	for entry in [[&"gunfire","GUNFIRE"],[&"gunshot","GUNFIRE"],[&"alarm","BROADCAST / ALARM"],[&"mechanism","MACHINERY"],[&"movement","MOVEMENT"],[&"footstep","MOVEMENT"]]:
		battle.player_visibility.heard_kind = entry[0];battle.player_visibility.heard_remaining = 1.0;battle.player_visibility.heard_direction=Vector3.FORWARD
		battle.hud.set_perception(battle.player_visibility,battle.camera)
		check(battle.hud.sound_hint.text == tr("HEARD / %s / %s") % [tr(entry[1]),tr("N")],"hearing categorizes sound without invented position/range: "+str(entry[0]))
	battle.player_visibility.heard_remaining=0
	check(contrast(FieldManualStyle.INK,FieldManualStyle.PAPER)>=7,"health text has strong paper-card contrast")
	check(contrast(FieldManualStyle.ACCENT,FieldManualStyle.PAPER)>=4.5 and contrast(FieldManualStyle.SUCCESS,FieldManualStyle.PAPER)>=4.5,"attack and vent text colors meet minimum contrast")
	battle.player.aim_direction=Vector3.BACK;await frames();readout.update_readout(0)
	check(not readout.card.visible,"turning away hides precise live phase and health")
	battle.player.position=Vector3(20,.1,8);aim_at_van(van);await frames();readout.update_readout(0)
	check(not readout.card.visible,"a real tall building prevents status-card wallhack")
	battle.player.aim_world_point=van.global_position+Vector3.UP*1.2
	check(battle.player_visibility.aim_trace().blocked,"real building in front of vehicle retains genuine obstruction warning")
	battle.player.position=Vector3(0,.1,-3);aim_at_van(van)
	for tick in 45:await get_tree().physics_frame
	van.aim_point=Vector3(0,1.2,10);van._enter(BlockadeVan.Phase.WARNING);readout.update_readout(0)
	check(AudioDirector.last_cue == &"blockade_lock","visible lock emits the dedicated charge cue")
	check(van.get_node("WarningTarget").visible and van.get_node("WarningTarget").global_position.is_equal_approx(Vector3(0,.065,10)),"warning impact ring marks frozen aim, not moving player")
	check(readout.state_label.text.contains(tr("LOCKED / MOVE")) and is_equal_approx(readout.phase_bar.value,1.5),"lock instruction and timer come from authoritative phase")
	var lock := van.aim_point;battle.player.position.x=2;await frames();van._physics_process(.2);readout.update_readout(0)
	check(van.aim_point==lock and van.get_node("WarningTarget").global_position.x==0,"moving player does not move the ground reticle")
	check(is_equal_approx(readout.phase_bar.value,van.phase_remaining),"phase bar follows real remaining time, not a separate UI clock")
	get_tree().paused=true;van.set_physics_process(true);var remaining:=van.phase_remaining
	await frames();check(van.phase_remaining==remaining,"pause freezes authoritative warning and its displayed time")
	van.set_physics_process(false);get_tree().paused=false
	await capture("readability_warning")
	van._enter(BlockadeVan.Phase.VENT);readout.update_readout(0)
	check(AudioDirector.last_cue == &"blockade_vent" and readout.state_label.text.contains(tr("VENT OPEN / FIRE")),"coolant cue and readable firing window agree")
	check(not van.get_node("WarningTarget").visible and van.get_node("VentLight").visible,"warning marker clears when cyan cooling panels open")
	var packet:=DamagePacket.new(20,0,5,battle.player,&"weapon.assault_rifle_01",&"player")
	van.receive_damage(packet);readout.update_readout(0)
	check(readout.hit_label.text == tr("VENT HIT / -%d") % 20 and readout.health.value==340,"real vent hit reports full damage and updates health")
	check(van.receive_damage(DamagePacket.new(0,0,0,battle.player,&"",&"player"))==0,"zero damage cannot fabricate a confirmation")
	for dimensions in [Vector2i(1280,720),Vector2i(960,540),Vector2i(1600,900)]:
		get_tree().root.size=dimensions;await frames();readout.update_readout(0);await frames()
		var rect:Rect2=readout.card.get_global_rect();var view:=get_viewport().get_visible_rect()
		check(view.encloses(rect),"state card fits viewport: "+str(dimensions))
		check(rect.position.y>=64 and rect.end.y<view.end.y-170,"state card avoids pause and weapon regions: "+str(dimensions))
		check(readout.title.get_theme_font_size("font_size")>=16 and readout.state_label.get_theme_font_size("font_size")>=18,"screen-space type does not shrink with 3D distance")
		await capture("readability_vent_"+str(dimensions.x))
	get_tree().root.size=Vector2i(1280,720);await frames()
	van._enter(BlockadeVan.Phase.IDLE);van.receive_damage(packet);readout.update_readout(0)
	check(readout.hit_label.text==tr("ARMOR HIT / -%d / WAIT FOR BLUE VENTS") % 4,"armored hit explains weak damage without changing the 3.6 damage rule")
	battle.player.position=world.get_node("PASwitch").position+Vector3.RIGHT
	check(world.get_node("PASwitch").interact(battle.player,battle.session).success,"actual service switch cuts PA")
	check(not world.get_node("PowerIndicators").visible and not world.get_node("PASwitch/PowerOn").visible and world.get_node("PASwitch/PowerOff").visible,"cut has immediate visible circuit consequences")
	check(world.get_node("PASwitch/Lever").rotation.x<0 and world.get_node("Van/GunActive").visible,"switch lever flips, but the separate gun power stays on")
	check(not gate_ray().is_empty(),"PA cutoff alone cannot open north traffic shield")
	await capture("readability_pa_off")
	# Use normal locomotion to prove the old traffic collider blocks the centre lane.
	battle.player.position=Vector3(0,.1,-18);battle.player.set_physics_process(true);Input.action_press("move_forward")
	for tick in 65:await get_tree().physics_frame
	Input.action_release("move_forward");battle.player.set_physics_process(false)
	check(battle.player.position.z>-21,"real player movement cannot walk through closed traffic shield")
	van._enter(BlockadeVan.Phase.VENT)
	while not van.destroyed:van.receive_damage(packet)
	await frames()
	check(is_equal_approx(world.get_node("Concrete5Body").position.y,4.3) and is_equal_approx(world.get_node("Concrete5").position.y,4.3),"disabling vehicle raises both traffic mesh and its collider")
	check(gate_ray().is_empty() and world.get_node("NorthExit").can_extract(battle.session) and world.get_node("NorthGateLink").enabled,"open centre lane and extraction now agree")
	check(not world.get_node("Van/GunActive").visible and world.get_node("Van/DisabledMark").visible,"disabled vehicle shows gun power loss")
	var open_path := NavigationServer3D.map_get_path(nav,Vector3(0,0,-18),Vector3(0,0,-24),true)
	check(not open_path.is_empty() and not Array(open_path).any(func(point):return absf(point.x)>2.5),"open navigation link crosses the newly cleared centre lane")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"derived hardware does not add contradictory saved flags")
	get_tree().paused=true;check(SortieRuntime.save_checkpoint()==OK,"saves actual completed vehicle world")
	battle.free();SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(POLISH_PATH) and SortieRuntime.resume_saved(POLISH_PATH)==OK,"loads completed world through persistent service")
	await load_battle();world=battle.area_root;van=world.get_node("Van");get_tree().paused=false
	check(not FlowMenu.is_open() and is_equal_approx(world.get_node("Concrete5Body").position.y,4.3) and gate_ray().is_empty(),"restored wreck derives open physical traffic gate")
	check(not world.get_node("PowerIndicators").visible and world.get_node("PASwitch/Lever").rotation.x<0,"restored cutoff derives dark circuit and flipped switch")
	battle.player.position=Vector3(0,.1,-18);battle.player.set_physics_process(true);Input.action_press("move_forward")
	for tick in 65:await get_tree().physics_frame
	Input.action_release("move_forward");battle.player.set_physics_process(false)
	check(battle.player.position.z<-23,"real player can now pass through previously blocked centre lane")
	aim_at_van(van);await frames();await capture("readability_gate_open")
	battle.free();SortieRuntime.clear_session();await frames();AudioDirector.shutdown_for_test()
	print("BLOCKADE_READABILITY_TEST checks=",checks," failures=",failures)
	print("BLOCKADE_READABILITY_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
