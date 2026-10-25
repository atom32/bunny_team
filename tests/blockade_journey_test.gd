extends "res://tests/blockade_test.gd"
## Explicit component placements/damage fixtures. Live input routes are separate.
const JOURNEY_PATH:="user://blockade_journey_test.json"

func _rear_packet(from: Vector3,to: Vector3,damage:=20.0,structure:=5.0) -> DamagePacket:
	var van: BlockadeVan=battle.area_root.get_node("Van")
	var query:=PhysicsRayQueryParameters3D.create(van.to_global(from),van.to_global(to),4)
	var hit:=van.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider==van,"controlled ray reaches the actual chassis surface: "+str(from))
	if hit.is_empty() or hit.collider!=van:return DamagePacket.new(damage,0,structure,battle.player,&"weapon.assault_rifle_01",&"player")
	return DamagePacket.new(damage,0,structure,battle.player,&"weapon.assault_rifle_01",&"player",hit.position,hit.normal,(to-from).normalized())

func _rear_continue(van: BlockadeVan) -> void:
	# Existing committed warning/burst, not a special weak-point attack contract.
	battle.player.position=Vector3(6,.1,10);await frames()
	var shots:=van.shots_fired;var broadcasts:=van.broadcasts
	van._physics_process(van.phase_remaining)
	for index in 4:van._physics_process(.22)
	check(van.shots_fired==shots+4 and van.phase==BlockadeVan.Phase.VENT,"PA cutoff and rear damage retain the ordinary four-shot burst and blue vent")
	check(van.broadcasts==broadcasts and not van.speaker_enabled and not van.destroyed,"cutting the broadcast never disables the gun or silently destroys the vehicle")
	check(not battle.session.blockade.van_down and not battle.session.blockade.escape_open and not battle.session.is_mission_completed() and not battle.area_root.get_node("NorthExit").can_extract(battle.session),"partial weak-point damage does not bypass the wreck, counterweight or extraction contract")

func _rear_component() -> void:
	SortieRuntime.clear_session()
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,BlockadeStory.AREA,BlockadeStory.MISSION,JOURNEY_PATH).error==OK,"rear fixture uses normal fresh v3 deployment")
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var van: BlockadeVan=world.get_node("Van")
	check(session.blockade.version==3 and int(world.get_meta("map_revision"))==2 and van.has_rear_radiator() and van.has_node("RearRadiator"),"v3 enables the visible rear radiator on the existing v2 collision map")
	check(van.max_structure_health==360 and van.find_children("*","CollisionShape3D",true,false).size()==1 and (van.collision_shape.shape as BoxShape3D).size==Vector3(3.8,3.1,7),"radiator adds no health, collider or inflated rear hitbox")
	var rear:=_rear_packet(Vector3(0,1.25,-8),Vector3(0,1.25,0))
	var front:=_rear_packet(Vector3(0,1.25,8),Vector3(0,1.25,0))
	var side:=_rear_packet(Vector3(-7,1.25,0),Vector3(0,1.25,0))
	var top:=_rear_packet(Vector3(0,6,0),Vector3(0,2,0))
	check(van.rear_hit(rear) and not van.rear_hit(front) and not van.rear_hit(side) and not van.rear_hit(top),"only the real rear-face hit qualifies; front, side and roof do not")
	van.phase=BlockadeVan.Phase.IDLE;van.phase_remaining=1.0
	check(is_equal_approx(van.receive_damage(rear),20),"closed-armor rear face takes ordinary full rifle damage")
	for packet in [front,side,top]:check(is_equal_approx(van.receive_damage(packet),3.6),"other real surfaces retain the original closed-armor multiplier")
	var structural:=_rear_packet(Vector3(.5,1.25,-8),Vector3(.5,1.25,0),0,12)
	check(van.rear_hit(structural) and is_equal_approx(van.receive_damage(structural),12),"rear damage still uses max of real bullet and structure damage, not a new bonus multiplier")
	for at in [Vector2(-1.31,1.25),Vector2(1.31,1.25),Vector2(0,.54),Vector2(0,1.96)]:
		var outside:=_rear_packet(Vector3(at.x,at.y,-8),Vector3(at.x,at.y,0))
		check(not van.rear_hit(outside),"actual rear-face impact outside the marked radiator is armored: "+str(at))
	var absent:=DamagePacket.new(20,0,5,battle.player,&"fixture",&"player")
	var no_normal:=DamagePacket.new(20,0,5,battle.player,&"fixture",&"player",rear.hit_position)
	var blast:=DamagePacket.new(60,0,50,battle.player,&"weapon.rocket_launcher_01",&"player",van.global_position,Vector3.FORWARD,Vector3.FORWARD)
	check(not van.rear_hit(absent) and not van.rear_hit(no_normal) and not van.rear_hit(blast),"missing hit data, zero normal and the actual RPG center-blast packet shape cannot impersonate a rear-face shot")
	check(is_equal_approx(van.receive_damage(no_normal),3.6) and is_equal_approx(van.receive_damage(blast),10.8),"unlocated and explosion-center damage preserve the ordinary armor calculation")
	# Explicit compatibility behavior fixture only; not evidence of old-code disk provenance.
	session.blockade.version=2
	check(not van.has_rear_radiator() and not van.rear_hit(rear) and is_equal_approx(van.receive_damage(rear),3.6),"preserved v2 rules do not acquire the new weak point")
	session.blockade.version=3
	van.phase=BlockadeVan.Phase.VENT;van.phase_remaining=2.3
	check(is_equal_approx(van.receive_damage(front),20) and is_equal_approx(van.receive_damage(rear),20),"blue vents retain full damage on every surface without double-counting the rear")
	battle.player.position=world.get_node("PASwitch").position+Vector3.RIGHT;await frames()
	check(world.get_node("PASwitch").interact(battle.player,session).success and not van.speaker_enabled,"actual nearby PA switch still cuts broadcasts independently")
	van.phase=BlockadeVan.Phase.WARNING;van.phase_remaining=.71;van.burst_shots=0;van.aim_point=Vector3(0,1.2,10);van.refresh()
	var hp:=van.current_structure_health
	var saved:=SortieCheckpoint.capture_world(battle)
	check(hp>0 and hp<360 and SortieCheckpoint.validate_world(saved,battle) and not saved.nodes.has("Van/RearRadiator"),"actual partial rear damage and the unchanged warning persist without a radiator state field")
	van.current_structure_health+=1;van.phase_remaining=.1
	check(SortieCheckpoint.restore_world(saved,battle) and is_equal_approx(van.current_structure_health,hp) and is_equal_approx(van.phase_remaining,.71),"full world restore reinstates exact partial health and the committed warning")
	if "--rear-write" in OS.get_cmdline_user_args():
		check(SortieRuntime.save_checkpoint()==OK,"partial rear damage commits through the existing checkpoint writer")
		var file:=FileAccess.open("user://rear_expected.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"health":hp,"remaining":van.phase_remaining,"blockade":session.blockade.duplicate()}));file.close()
		return
	await _rear_continue(van)

func _rear_read() -> void:
	check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process loads actual partial rear damage")
	await load_battle()
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://rear_expected.json"))
	var van: BlockadeVan=battle.area_root.get_node("Van")
	check(not FlowMenu.is_open() and van.has_rear_radiator() and is_equal_approx(van.current_structure_health,expected.health) and battle.session.blockade==expected.blockade,"disk continuation retains exact damaged health and v3 route facts")
	check(van.phase==BlockadeVan.Phase.WARNING and is_equal_approx(van.phase_remaining,expected.remaining) and not van.speaker_enabled and SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"disk continuation preserves the original partial burst warning, cutoff and legal world")
	var rear:=_rear_packet(Vector3(0,1.25,-8),Vector3(0,1.25,0))
	check(van.rear_hit(rear) and is_equal_approx(van.receive_damage(rear),20),"restored actor still takes a real full-damage rear-face hit without respawning its health")
	await _rear_continue(van)

func freeze() -> void:
	super.freeze()
	if battle.area_root.has_node("Passage"):battle.area_root.get_node("Passage").set_physics_process(false)
	if battle.area_root.has_node("Searchlight"):battle.area_root.get_node("Searchlight").set_physics_process(false)

func finish_journey() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("BLOCKADE_JOURNEY_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func write_pending() -> void:
	check(SortieRuntime.save_checkpoint()==OK,"durable partial route written for another process")
	finish_journey()

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",false)
	if "--rear-read" in args:
		await _rear_read();finish_journey();return
	if "--rear" in args or "--rear-write" in args:
		await _rear_component();finish_journey();return
	if "--read" in args or "--legacy-read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process accepts actual partial route")
		await load_battle()
		var world: Node3D=battle.area_root
		var van: BlockadeVan=world.get_node("Van")
		if "--legacy-read" in args:
			check(not FlowMenu.is_open() and battle.session.blockade.is_empty() and int(world.get_meta("map_revision"))==1 and not world.has_node("Passage"),"genuine previous-code snapshot retains old geometry and van-only contract")
			check(van.phase==BlockadeVan.Phase.WARNING and van.phase_remaining>.8 and van.phase_remaining<1.2,"old committed burst warning survives restart")
			van.receive_damage(DamagePacket.new(5000,0,5000,battle.player,&"fixture",&"player"))
			check(battle.session.is_mission_completed() and world.get_node("NorthExit").can_extract(battle.session),"legacy vehicle disable still directly opens original exit")
			check(world.get_node("NorthExit").extract(battle.session) and SortieRuntime.finalize_sortie(JOURNEY_PATH)==OK and ProfileRuntime.get_profile().blockade_cleared,"genuine legacy contract can still settle a safe return")
		else:
			var route:=world.get_node("Passage") as BlockadePassage
			check(not FlowMenu.is_open() and int(world.get_meta("map_revision"))==2,"v2 signed map restores without replacing it with legacy")
			if battle.session.blockade.version==2:check(not van.has_rear_radiator() and not van.has_node("RearRadiator"),"actual v2 continuation keeps the old vehicle without a new weak point")
			if "--chain" in args:
				check(world.get_node("StreetChain").current_structure_health==14 and not battle.session.blockade.alarm,"partial real chain damage survives without false alarm or opening")
			elif "--gate" in args:
				check(is_equal_approx(route.escape_progress,.325) and is_equal_approx(world.get_node("EscapeGate").position.y,1.625),"moving counterweight progress and actual collider height survive")
				check(battle.session.blockade.van_down and not battle.session.is_mission_completed(),"vehicle wreck is not a free completed breakout")
				route._physics_process(2)
				check(battle.session.is_mission_completed(),"resumed physical gate can finish opening")
			else:
				var light:=world.get_node("Searchlight") as BlockadeSearchlight
				check(is_equal_approx(light.sweep_time,.2) and is_equal_approx(light.exposure,.2) and not battle.session.blockade.alarm,"sweep phase and partial exposure survive without a new alarm")
			check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"restored route remains strict-valid")
		finish_journey();return
	SortieRuntime.clear_session()
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,BlockadeStory.AREA,BlockadeStory.MISSION,JOURNEY_PATH).error==OK,"normal fresh sortie selects new route")
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var route:=world.get_node("Passage") as BlockadePassage
	var light:=world.get_node("Searchlight") as BlockadeSearchlight
	var chain:=world.get_node("StreetChain") as BlockadeStreetChain
	var van: BlockadeVan=world.get_node("Van")
	check(not FlowMenu.is_open() and not get_tree().paused,"component starts without a hidden pause/recovery overlay")
	check(chain.visual.mesh.size==Vector3(1,.8,.18),"chain visual is its actual small plate, not a duplicate van-mesh resource")
	check(world.get_node("ServiceGate/PanelBody/CollisionShape3D").shape.size.x==4 and world.get_node("StreetGate/PanelBody/CollisionShape3D").shape.size.x==6 and world.get_node("EscapeGate/PanelBody/CollisionShape3D").shape.size.x==4,"three gate meshes/colliders do not alias different widths")
	check(session.blockade==BlockadeJourney.initial(BlockadeStory.AREA) and int(world.get_meta("map_revision"))==2,"fresh v3 facts keep authored v2 collision map")
	check(battle.enemy_container.get_child_count()==3 and not session.is_mission_completed(),"three existing actors; both finite response groups start inactive")
	check(world.get_node("Retreat").can_extract(session) and not world.get_node("NorthExit").can_extract(session),"south retreat stays open before either confrontation")
	var snapshot:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(snapshot,battle) and SortieCheckpoint.restore_world(snapshot,battle),"idle full route captures and restores")
	for bad in [null,[],{}, {"version":2,"alarm":false,"van_down":false,"escape_open":true}, {"version":2,"alarm":1,"van_down":false,"escape_open":false}]:
		var data:=SortieCheckpoint.session_data(session);data.blockade=bad
		if typeof(bad)==TYPE_DICTIONARY and bad.is_empty():continue # Empty is the intentional original contract.
		check(SortieCheckpoint.restore_session(data)==null,"malformed or contradictory route facts refused")
	battle.player.position=Vector3(0,.1,25);await frames()
	var hit: Dictionary=battle.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.25,25),Vector3(0,1.25,20),4))
	check(not hit.is_empty() and hit.collider==chain,"real red chain is in front of the separate ballistic shutter")
	var side_hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(2.5,1.25,25),Vector3(2.5,1.25,20),4))
	check(not side_hit.is_empty() and side_hit.collider==world.get_node("StreetGate/PanelBody"),"unbroken street shutter has no human-sized side gap from a wrong shared collider")
	check(chain.receive_damage(DamagePacket.new(10,8,0,battle.player,&"fixture",&"player"))==10 and chain.current_structure_health==14,"ordinary bullet damage, not only explosives, weakens actual chain")
	check(not session.blockade.alarm and world.get_node("StreetGate").position.y==0,"partial chain damage does not silently open gate or call guards")
	if "--write" in args and "--chain" in args:write_pending();return
	# Actual cover and perception tests; placements are explicitly controlled.
	light.sweep_time=0;battle.player.position=Vector3(-4,0,43);await frames()
	check(not light.sees(battle.player),"delivery van physically blocks the searchlight ray")
	battle.player.position=Vector3(2,0,38);await frames()
	check(light.sees(battle.player),"exposed actor inside real sweep cone is detected")
	light._physics_process(.2)
	check(is_equal_approx(light.exposure,.2) and not session.blockade.alarm,"partial exposure is not instant unavoidable detection")
	if "--write" in args and "--gate" not in args:write_pending();return
	light._physics_process(.2);freeze()
	check(session.blockade.alarm and battle.enemy_container.get_child_count()==5,"sustained visible exposure releases exactly two finite actors")
	light._physics_process(8);route.alarm()
	check(battle.enemy_container.get_child_count()==5,"repeated sweep or alarm cannot spawn another wave")
	check(chain.receive_damage(DamagePacket.new(20,8,0,battle.player,&"fixture",&"player"))==14 and chain.destroyed,"last real hit breaks chain")
	check(world.get_node("StreetGate").position.y==4 and world.get_node("StreetLink").enabled,"broken chain raises physical street shutter and its nav link")
	battle.player.position=world.get_node("ServiceLever").position+Vector3.BACK
	check(world.get_node("ServiceLever").interact(battle.player,session).success and world.get_node("ServiceGate").position.y==4,"independent quiet lever also changes actual collision")
	check(not world.get_node("EscapeLever").interact(battle.player,session).success,"escape lever cannot be used remotely or before vehicle disable")
	van.receive_damage(DamagePacket.new(5000,0,5000,battle.player,&"fixture",&"player"));freeze()
	check(session.blockade.van_down and van.destroyed and not session.is_mission_completed(),"vehicle disabled is an intermediate state, not completed new contract")
	check(battle.enemy_container.get_child_count()==7 and not world.get_node("NorthExit").can_extract(session),"two finite north-yard enemies activate while final exit stays locked")
	var failed:=SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session));failed.fail()
	var failed_outcome:=SortieOutcome.create_from_session(failed)
	check(failed_outcome!=null and not failed_outcome.mission_completed and failed_outcome.blockade.van_down and not failed_outcome.blockade.escape_open,"death after wreck carries incomplete real facts, not a finished breakout reward")
	light.refresh_visual();check(not light.footprint.visible and not light.get_node("Head/Beam").visible,"disabled vehicle leaves the approach searchlight dark")
	battle.player.position=world.get_node("EscapeLever").position+Vector3.LEFT
	check(world.get_node("EscapeLever").interact(battle.player,session).success,"nearby real lever releases physical counterweight")
	route._physics_process(.5)
	check(is_equal_approx(route.escape_progress,.325) and not session.blockade.escape_open and not session.is_mission_completed(),"gate moves independently; partial lift grants no completion")
	snapshot=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(snapshot,battle) and SortieCheckpoint.restore_world(snapshot,battle),"mid-lift collider and facts restore coherently")
	for path in ["Alarm0","EscapeRam"]:
		var forged:=snapshot.duplicate(true);forged.nodes[path].has_spawned=false
		check(not SortieCheckpoint.validate_world(forged,battle),"world alarm/wreck and once-only activation flags must agree")
	var forged:=snapshot.duplicate(true);forged.nodes.Passage.escape_progress=1
	check(not SortieCheckpoint.validate_world(forged,battle),"physical gate cannot claim fully raised while mission facts are pending")
	if "--gate" in args and "--write" in args:write_pending();return
	route._physics_process(2)
	check(session.is_mission_completed() and session.blockade.escape_open and world.get_node("EscapeLink").enabled and world.get_node("EscapeGate").position.y==5,"fully raised gate, objective, collision and navigation agree")
	check(not profile.blockade_cleared,"field opening alone does not grant a persistent victory")
	snapshot=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(snapshot,battle),"cleared yard can be suspended without respawning either response")
	check(world.get_node("NorthExit").extract(session) and SortieRuntime.finalize_sortie(JOURNEY_PATH)==OK and profile.blockade_cleared,"only actual safe return settles completed new contract")
	for line in [BlockadeJourney.INTRO,BlockadeJourney.SERVICE,BlockadeJourney.ALARM,BlockadeJourney.DOWN,BlockadeJourney.OPENING,BlockadeJourney.CLEAR,BlockadeJourney.END]:
		check(TranslationServer.translate(line)!=line if TranslationServer.get_locale()=="zh_CN" else TranslationServer.translate(line)==line,"scene has complete bilingual text")
	finish_journey()

