extends Node3D
const PATH := "user://records_isolation.json"
const UPLINK_PATH := "user://records_isolation_uplink.json"
var failures: Array[String] = []
var checks := 0
var battle: Node3D
var alarm: RecordsAlarm
var terminal: RecordsTerminal
var box: RecordsIsolator
var feedback: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message);push_error(message)

func bind_world() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate();battle.loot_seed=907;battle.result_transition_enabled=false;add_child(battle)
	alarm = battle.area_root.get_node("StreetTerminal/RecordsAlarm");alarm.set_process(false)
	terminal = battle.area_root.get_node("StreetTerminal");terminal.set_process(false)
	box = battle.area_root.get_node("RecordsIsolator")
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	battle.player.interaction_component.interaction_finished.connect(func(message: String,_success: bool):feedback.append(message))

func approach() -> void: battle.player.global_position=box.global_position+Vector3(0,0,-1.2)

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	battle.player.aim_direction=Vector3(0,0,-1);battle.player_visibility.refresh();box._refresh_visual()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"native capture: "+name)

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	if "--read" in OS.get_cmdline_user_args():
		var profile := SaveService.load_profile(PATH,false)
		check(profile!=null,"separate process reads actual partial-isolation save")
		if profile:
			ProfileRuntime._profile=profile
			check(SortieRuntime.resume_saved(PATH)==OK,"production resume accepts new work state")
			bind_world()
			check(is_equal_approx(alarm.isolation_remaining,2.7) and alarm.actor==battle.player,"exact partial timer and actual player rebound across process")
			alarm.tick(2.7)
			check(alarm.phase==RecordsAlarm.Phase.ISOLATED,"resumed isolation finishes without resetting work")
			battle.free();SortieRuntime.clear_session()
		var uplink := SaveService.load_profile(UPLINK_PATH,false)
		check(uplink!=null,"separate process reads quiet urgent-download save")
		if uplink:
			ProfileRuntime._profile=uplink
			check(SortieRuntime.resume_saved(UPLINK_PATH)==OK,"quiet uplink resumes through production API")
			bind_world()
			check(terminal.urgent and terminal.remaining==3 and alarm.phase==RecordsAlarm.Phase.ISOLATED,"JSON numeric phase permits active quiet uplink, without replaying a bell")
			terminal.tick(3)
			check(battle.session.get_objective_state(&"streets_terminal").status==ObjectiveState.Status.COMPLETED,"quiet uplink completes after fresh-process restore")
		await finish();return
	var profile := ProfileRuntime.new_profile()
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).error==OK,"finite normal campus deployment succeeds")
	SortieRuntime.layout_seed=907;bind_world()
	for _tick in 45: await get_tree().physics_frame
	var nav: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	NavigationServer3D.map_force_update(nav)
	for index in 4:
		var site: Node3D=battle.area_root.get_node("RecordsIsolationSites/Site%d"%index)
		var nearest:=NavigationServer3D.map_get_closest_point(nav,site.global_position)
		var gap:=Vector2(nearest.x-site.position.x,nearest.z-site.position.z)
		check(gap.length()<=battle.player.interaction_component.interaction_radius,"authored cabinet has a reachable point within the actual interaction radius: %d / %s"%[index,nearest])
		if index==battle.area_root.task_index:check(not Rect2(-.735,-.52,1.47,1.04).has_point(gap),"active cabinet's solid body and player radius are excluded from walkable space")
		var record: Vector3=battle.area_root.terminals[index]
		var path:=NavigationServer3D.map_get_path(nav,record,nearest,true)
		check(path.size()>1 and record.distance_to(nearest)>6,"box is a reachable detour from record site, not a second terminal button: %d"%index)
	approach()
	check(alarm.can_isolate(battle.player,battle.session),"real cabinet can be reached from front")
	check(battle.area_root.route_map._bell_map_marker().label=="BELL JUNCTION / 4s","fresh map marks available bell work")
	var impact: KinematicCollision3D=battle.player.move_and_collide(Vector3(0,0,2.4))
	check(impact!=null and impact.get_collider()==box,"actual player body stops at solid cabinet, not inside its mesh")
	approach()
	var initial:=SortieCheckpoint.capture_world(battle)
	check(initial.map_revision==5 and SortieCheckpoint.validate_world(initial,battle),"new solid-cabinet navigation and initial world validate")
	check(not box.interact(null,battle.session).success,"missing actor rejected")
	check(not box.interact(battle.player,null).success,"missing active session rejected")
	battle.player.global_position+=Vector3(8,0,0)
	check(not box.interact(battle.player,battle.session).success,"distant interaction rejected")
	approach()
	var wall:=StaticBody3D.new();wall.collision_layer=4
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(2,2,.1);wall.add_child(shape);add_child(wall)
	wall.global_position=box.global_position+Vector3(0,1,-.6)
	await get_tree().physics_frame
	check(not alarm.can_isolate(battle.player,battle.session),"cannot reach through a real wall")
	wall.free();await get_tree().physics_frame
	check(box.interact(battle.player,battle.session).success and alarm.isolation_remaining==4,"four-second work starts at physical cabinet")
	check(not box.interact(battle.player,battle.session).success,"repeat input cannot restart active work")
	alarm.tick(1.3)
	var partial:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(partial,battle) and is_equal_approx(alarm.isolation_remaining,2.7),"partial work is valid whole-world state")
	var bad_partial:=partial.duplicate(true);bad_partial.records_alarm.isolation_remaining=5.0
	var before_position: Vector3=battle.player.position
	check(not SortieCheckpoint.restore_world(bad_partial,battle) and battle.player.position==before_position and is_equal_approx(alarm.isolation_remaining,2.7),"malformed isolation deadline fails whole-world restore without partial mutation")
	check(SortieRuntime.save_checkpoint()==OK,"partial work durably saved by production API")
	SortieRuntime.checkpoint_path=""
	get_tree().paused=true;alarm.tick(99)
	check(is_equal_approx(alarm.isolation_remaining,2.7),"pause freezes isolation")
	get_tree().paused=false
	var hp: float=battle.player.health
	battle.player.receive_damage(DamagePacket.new(.25))
	check(battle.player.health<hp and alarm.isolation_remaining==0,"actual fractional damage packet interrupts work")
	check(feedback.back()==tr("ISOLATION INTERRUPTED / Hit. Start again when safe."),"interruption explains the actual hit")
	check(SortieCheckpoint.restore_world(partial,battle) and is_equal_approx(alarm.isolation_remaining,2.7),"restore exact partial work without replaying completion")
	var hurt_partial:=partial.duplicate(true);hurt_partial.player.health-=20
	check(SortieCheckpoint.restore_world(hurt_partial,battle) and alarm.observed_health==battle.player.health,"restored work observes saved health, not fresh-spawn health")
	battle.player.health_changed.emit(battle.player.health,battle.player.max_health)
	check(is_equal_approx(alarm.isolation_remaining,2.7),"unchanged health after restore is not a fictitious hit")
	battle.player.global_position+=Vector3(8,0,0);alarm.tick(.1)
	check(alarm.isolation_remaining==0 and alarm.phase==RecordsAlarm.Phase.IDLE,"leaving cancels work, not the original alarm contract")
	check(SortieCheckpoint.restore_world(initial,battle),"deterministic fixture reset")
	box.interact(battle.player,battle.session);alarm.tick(4)
	check(alarm.phase==RecordsAlarm.Phase.ISOLATED and alarm.remaining==0,"preemptive isolation completes")
	check(battle.area_root.route_map._bell_map_marker().label=="BELL WIRE / ISOLATED","map reports isolated bell rather than work duration")
	check(not alarm.sound_now(battle.session),"fast-uplink alarm has no working bell after isolation")
	var quiet:=SortieCheckpoint.capture_world(battle)
	await shot("bell_isolated")
	battle.player.global_position=terminal.global_position+Vector3(1,0,0)
	check(terminal.interact(battle.player,battle.session).success,"terminal still has power")
	var response:=terminal.interact(battle.player,battle.session)
	check(response.success and response.message=="UPLINK / 3s; bell isolated." and terminal.urgent,"fast path truthfully reports disconnected bell")
	var urgent:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(urgent,battle),"quiet urgent work and isolated bell restore together")
	SortieRuntime.checkpoint_path=UPLINK_PATH
	check(SortieRuntime.save_checkpoint()==OK,"quiet urgent uplink saved for a separate process")
	SortieRuntime.checkpoint_path=""
	terminal.tick(3)
	check(battle.session.get_objective_state(&"streets_terminal").status==ObjectiveState.Status.COMPLETED and alarm.phase==RecordsAlarm.Phase.ISOLATED,"quiet fast uplink awards same real records objective once")
	check(not terminal.interact(battle.player,battle.session).success,"isolation does not duplicate records reward")
	check(SortieCheckpoint.restore_world(initial,battle),"reset before pending-alarm route")
	battle.session.record_objective_interaction(&"streets_terminal");check(alarm.arm(battle.session),"normal records still arm bell")
	alarm.tick(18)
	check(box.interact(battle.player,battle.session).success,"can reach box after recovering records")
	alarm.tick(4)
	check(alarm.phase==RecordsAlarm.Phase.ISOLATED,"four-second detour wins while seven seconds remain")
	check(SortieCheckpoint.restore_world(initial,battle),"reset deadline fixture")
	battle.session.record_objective_interaction(&"streets_terminal");alarm.arm(battle.session);alarm.tick(21)
	box.interact(battle.player,battle.session);alarm.tick(4)
	check(alarm.phase==RecordsAlarm.Phase.SOUNDED and alarm.isolation_remaining==0,"exact tie loses to bell; large delta cannot skip alarm")
	check(feedback.back()==tr("TOO LATE / The bell rang. Guards keep what they heard."),"late work reports consequence instead of pretending silence")
	check(not box.interact(battle.player,battle.session).success,"already-sounded bell cannot be undone")
	check(battle.area_root.route_map._bell_map_marker().label=="BELL ALREADY RANG" and battle.area_root.route_map._bell_map_marker().color==box.status_color(),"spent map label and color match actual cabinet; no false 4s task")
	battle.area_root.route_map.expanded=true
	await shot("bell_too_late")
	battle.area_root.route_map.expanded=false
	for raw in [null,[],{"phase":3,"remaining":1},{"phase":3,"remaining":0},{"phase":2,"remaining":0,"isolation_remaining":1},{"phase":0,"remaining":0,"isolation_remaining":-1},{"phase":0,"remaining":0,"isolation_remaining":5},{"phase":0,"remaining":0,"isolation_remaining":NAN},{"phase":0,"remaining":0,"isolation_remaining":INF},{"phase":0,"remaining":0,"extra":0}]:
		check(not RecordsAlarm.valid_snapshot(raw),"reject invalid isolation state: "+str(raw))
		if raw is Dictionary and raw.has("isolation_remaining") and typeof(raw.isolation_remaining)==TYPE_FLOAT and not is_finite(raw.isolation_remaining): continue
		check(not RecordsAlarm.valid_snapshot(JSON.parse_string(JSON.stringify(raw))),"reject invalid state after JSON numeric conversion: "+str(raw))
	var legacy:=initial.duplicate(true);legacy.records_alarm={"phase":1,"remaining":17.5}
	check(SortieCheckpoint.restore_world(legacy,battle) and alarm.isolation_remaining==0 and alarm.remaining==17.5,"old two-field pending alarm retains exact deadline")
	legacy.erase("records_alarm")
	check(SortieCheckpoint.restore_world(legacy,battle) and alarm.phase==RecordsAlarm.Phase.SOUNDED,"old completed records invent no retroactive alarm or isolation")
	check(SortieCheckpoint.restore_world(quiet,battle),"quiet fixture restores without completing tasks")
	var inventory_before: Dictionary=battle.session.inventory.to_dict()
	check(not alarm.begin_isolation(battle.player,battle.session),"completed operation cannot repeat")
	check(battle.session.inventory.to_dict()==inventory_before,"no free inventory or economic reward")
	await finish()

func finish() -> void:
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("RECORDS_ISOLATION_TEST: ","PASS" if failures.is_empty() else "FAIL"," / ",checks," checks")
	get_tree().quit(0 if failures.is_empty() else 1)
