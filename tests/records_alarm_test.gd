extends Node3D
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		await read_work_saved()
		await read_saved()
		return
	await terminal_work_contract()
	var p := ProfileRuntime.new_profile()
	var deployed := DeploymentPlan.deploy(p,&"street_district",&"streets_recon","user://records_alarm.json")
	check(deployed.error == OK,"durable deployment succeeds")
	SortieRuntime.layout_seed = 907
	var session: SortieSession = deployed.session
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed = 907
	add_child(battle)
	battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await get_tree().physics_frame
	var terminal = battle.area_root.get_node("StreetTerminal")
	var alarm: RecordsAlarm = terminal.get_node("RecordsAlarm")
	alarm.set_process(false) # Test controls simulated time; production uses _process.
	check(alarm.phase == RecordsAlarm.Phase.IDLE,"new sortie starts without alarm")
	check(not alarm.arm(session),"cannot arm before records are recovered")
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"before")
	battle.player.global_position = terminal.global_position + Vector3(0,0,1)
	terminal.set_process(false)
	check(terminal.interact(battle.player,session).success,"actual terminal interaction succeeds")
	check(terminal.remaining == 8.0 and alarm.phase == RecordsAlarm.Phase.IDLE,"local copy does not instantly complete or start alarm")
	terminal.tick(8.0)
	check(alarm.phase == RecordsAlarm.Phase.WARNING and alarm.remaining == 25.0,"terminal signal arms advertised countdown")
	check(not alarm.arm(session),"duplicate arm cannot restart countdown")
	alarm.tick(7.5)
	check(alarm.remaining == 17.5,"countdown consumes simulation time")
	get_tree().paused = true
	alarm.tick(10.0)
	check(alarm.remaining == 17.5,"pause freezes countdown")
	get_tree().paused = false
	check(SortieRuntime.save_checkpoint() == OK,"pending alarm saved in production checkpoint")
	# Preserve this real save for a separate reader process; subsequent assertions
	# deliberately change state and must not replace the cross-process fixture.
	SortieRuntime.checkpoint_path = ""
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"warning")
	var saved := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"pending alarm accepted by whole-world validator")
	alarm.tick(2.0)
	check(SortieCheckpoint.restore_world(saved,battle),"whole-world restore succeeds")
	check(alarm.remaining == 17.5 and alarm.phase == RecordsAlarm.Phase.WARNING,"restore preserves remaining alarm time")
	var bad := saved.duplicate(true)
	bad.records_alarm.remaining = -1.0
	var before: Vector3 = battle.player.global_position
	check(not SortieCheckpoint.restore_world(bad,battle),"malformed countdown rejects whole world")
	check(battle.player.global_position == before and alarm.remaining == 17.5,"failed restore does not mutate player or event")
	for raw in [null,[],{"phase":1,"remaining":0},{"phase":1,"remaining":26},{"phase":3,"remaining":0},{"phase":0,"remaining":1},{"phase":2,"remaining":1},{"phase":1.5,"remaining":1},{"phase":1,"remaining":INF},{"phase":1,"remaining":NAN},{"phase":1,"remaining":2,"extra":true}]:
		check(not RecordsAlarm.valid_snapshot(raw),"reject invalid event field: "+str(raw))
	for raw in [{},{"phase":0,"remaining":0},{"phase":1,"remaining":25},{"phase":2,"remaining":0}]:
		check(RecordsAlarm.valid_snapshot(raw),"accept valid event phase")
	var enemies: Array[Node] = battle.enemy_container.get_children()
	check(enemies.size() >= 3,"production scene supplies real enemy fixtures")
	var nearby: EnemyController = enemies[0]
	var distant: EnemyController = enemies[1]
	var engaged: EnemyController = enemies[2]
	nearby.global_position = alarm.global_position + Vector3(3,0,0)
	distant.global_position = alarm.global_position + Vector3(70,0,0)
	engaged.global_position = alarm.global_position + Vector3(-3,0,0)
	for enemy in [nearby,distant,engaged]:
		enemy.ensure_awareness()
		enemy.awareness.state = EnemyAwareness.State.PATROL
		enemy.awareness.target_visible = false
		enemy.awareness.last_known = Vector3(90,0,90)
		enemy.set_physics_process(true)
	engaged.awareness.state = EnemyAwareness.State.COMBAT
	engaged.awareness.target_visible = true
	var exits_before: Array[bool] = []
	var exits: Array[Node] = battle.area_root.find_children("*","ExtractionPoint",true,false)
	for exit in exits: exits_before.append(exit.can_extract(session))
	alarm.tick(17.5)
	check(alarm.phase == RecordsAlarm.Phase.SOUNDED and alarm.remaining == 0,"countdown emits once and completes")
	check(nearby.awareness.state == EnemyAwareness.State.INVESTIGATE,"nearby real guard investigates audible alarm")
	check(nearby.awareness.last_known.is_equal_approx(alarm.global_position),"guard receives terminal location, not live player position")
	check(distant.awareness.state == EnemyAwareness.State.PATROL,"out-of-range guard receives no alert")
	check(engaged.awareness.state == EnemyAwareness.State.COMBAT and engaged.awareness.last_known == Vector3(90,0,90),"confirmed visual contact takes priority over sound")
	nearby.awareness.last_known = Vector3(80,0,80)
	alarm.tick(100)
	check(nearby.awareness.last_known == Vector3(80,0,80),"spent alarm never repeats or tracks player")
	for enemy in enemies: enemy.set_physics_process(false)
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"sounded")
	check(battle.enemy_container.get_child_count() == enemies.size(),"alarm spawns no enemies")
	for i in exits.size(): check(exits[i].can_extract(session) == exits_before[i],"alarm does not close or change exit condition")
	var legacy := saved.duplicate(true)
	legacy.erase("records_alarm")
	check(SortieCheckpoint.restore_world(legacy,battle),"pre-event checkpoint remains loadable")
	check(alarm.phase == RecordsAlarm.Phase.SOUNDED,"old completed records do not create a retroactive alarm")
	check(SortieCheckpoint.restore_world(saved,battle),"pending checkpoint can still be resumed")
	var free_exit: ExtractionPoint
	for exit in exits:
		if exit.can_extract(session): free_exit = exit
	check(free_exit.extract(session),"extraction remains usable during warning")
	alarm.tick(100)
	check(alarm.remaining == 17.5,"finished sortie cannot emit delayed combat noise")
	battle.free()
	await finish()

func capture(battle: Node, label: String) -> void:
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		check(DisplaySettings.apply_preferences(false,resolution) == OK,"isolated display preferences apply")
		for locale in ["en","zh_CN"]:
			GameLanguage.set_language(locale,false)
			battle.area_root.route_map.expanded = label == "before"
			for frame in 8: await get_tree().process_frame
			var map: Control = battle.area_root.route_map
			var card: Rect2 = map.status_panel.get_global_rect()
			check(map.get_viewport_rect().encloses(card),"route status stays in viewport "+locale)
			check(card.position.y >= 60 and card.end.y <= 178,"status clears pause button and expanded-map details")
			check(not map.map_hint.get_global_rect().intersects(map.alarm_hint.get_global_rect()),"map and alarm labels do not overlap")
			check(map.alarm_hint.get_visible_line_count() == map.alarm_hint.get_line_count(),"alarm caption has no hidden lines")
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			check(image.get_size() == resolution,"capture proves actual resolution")
			image.save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(label+"_"+locale+"_"+str(resolution.x)+".png"))

func finish() -> void:
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("RECORDS_ALARM: "+failure)
	print("RECORDS_ALARM_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func terminal_work_contract() -> void:
	SortieRuntime.clear_session()
	var deployed := DeploymentPlan.deploy(ProfileRuntime.new_profile(),&"street_district",&"streets_recon","user://records_work.json")
	check(deployed.error == OK,"records work fixture deploys")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await get_tree().physics_frame
	var terminal: RecordsTerminal = battle.area_root.get_node("StreetTerminal")
	var alarm: RecordsAlarm = terminal.get_node("RecordsAlarm")
	terminal.set_process(false)
	alarm.set_process(false)
	var session: SortieSession = battle.session
	var player: PlayerController = battle.player
	var feedback: Array[String] = []
	player.interaction_component.interaction_finished.connect(func(message: String, _success: bool): feedback.append(message))
	player.global_position = terminal.global_position + Vector3(0,0,1)
	var initial := SortieCheckpoint.capture_world(battle)
	check(not terminal.interact(null,session).success,"no actor cannot retrieve records")
	check(terminal.interact(player,session).success and terminal.remaining == 8,"normal copy starts with advertised work")
	terminal.tick(2)
	check(terminal.remaining == 6 and session.get_objective_state(&"streets_terminal").status != ObjectiveState.Status.COMPLETED,"partial copy does not award objective")
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"copy")
	get_tree().paused = true
	terminal.tick(99)
	check(terminal.remaining == 6,"pause freezes records work")
	get_tree().paused = false
	var partial := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(partial,battle),"partial download is valid durable world state")
	terminal.tick(1)
	check(SortieCheckpoint.restore_world(partial,battle) and terminal.remaining == 6,"world restore preserves exact work deadline")
	player.health_changed.emit(player.health-.25,player.max_health)
	check(terminal.remaining == 0 and session.get_objective_state(&"streets_terminal").status != ObjectiveState.Status.COMPLETED,"even fractional damage interrupts work without reward")
	check(feedback.back() == tr("RECORDS INTERRUPTED / Hit. Progress lost; retry when safe."),"damage interruption reports its actual cause through production interaction feedback")
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"interrupted")
	check(terminal.interact(player,session).success,"interrupted copy can restart")
	player.global_position += Vector3(20,0,0)
	terminal.tick(.1)
	check(terminal.remaining == 0 and not terminal.interact(player,session).success,"leaving cancels and distant use is rejected")
	check(feedback.back() == tr("RECORDS INTERRUPTED / Too far away. Return to restart."),"leaving reports distance rather than damage")
	var feedback_count := feedback.size()
	terminal.tick(.1)
	check(feedback.size() == feedback_count,"interruption feedback does not spam on idle frames")
	check(SortieCheckpoint.restore_world(initial,battle),"fixture returns to unstarted valid state")
	check(terminal.interact(player,session).success,"copy restarts locally")
	terminal.tick(2)
	check(terminal.interact(player,session).success and terminal.urgent and terminal.remaining == 3,"second interaction opts into faster uplink")
	check(alarm.phase == RecordsAlarm.Phase.SOUNDED and session.get_objective_state(&"streets_terminal").status != ObjectiveState.Status.COMPLETED,"urgent consequence occurs BEFORE reward, not after escape")
	if "--capture" in OS.get_cmdline_user_args(): await capture(battle,"uplink")
	check(not terminal.interact(player,session).success and terminal.remaining == 3,"repeat input cannot refresh or shorten urgent deadline")
	var urgent_world := SortieCheckpoint.capture_world(battle)
	check(SortieRuntime.save_checkpoint() == OK,"active urgent download durably saved for separate process")
	SortieRuntime.checkpoint_path = ""
	check(SortieCheckpoint.restore_world(urgent_world,battle) and terminal.urgent and terminal.remaining == 3,"urgent mode/deadline and spent alarm restore together")
	var bad := urgent_world.duplicate(true)
	bad.records_alarm = {"phase":0,"remaining":0.0}
	check(not SortieCheckpoint.restore_world(bad,battle) and terminal.urgent,"reject urgent work without its alert atomically")
	for raw in [null,[],{"remaining":-1,"urgent":false},{"remaining":9,"urgent":false},{"remaining":4,"urgent":true},{"remaining":0,"urgent":true},{"remaining":NAN,"urgent":false},{"remaining":INF,"urgent":false},{"remaining":1,"urgent":1},{"remaining":1,"urgent":false,"extra":true}]:
		check(not RecordsTerminal.valid_snapshot(raw),"reject malformed work state: "+str(raw))
	player.health_changed.emit(player.health-1,player.max_health)
	check(terminal.remaining == 0 and alarm.phase == RecordsAlarm.Phase.SOUNDED,"interrupting uplink does not undo its noise consequence")
	check(terminal.interact(player,session).success and terminal.interact(player,session).success,"can retry after interruption without fake objective")
	check(not alarm.sound_now(session),"spent alarm cannot repeat")
	terminal.tick(2.9)
	check(session.get_objective_state(&"streets_terminal").status != ObjectiveState.Status.COMPLETED,"urgent work still requires actual duration")
	terminal.tick(.2)
	check(session.get_objective_state(&"streets_terminal").status == ObjectiveState.Status.COMPLETED and terminal.remaining == 0,"urgent completion awards same objective exactly once: status=%s remaining=%s session=%s distance=%s" % [session.get_objective_state(&"streets_terminal").status,terminal.remaining,session.status,player.global_position.distance_to(terminal.global_position)])
	check(not terminal.interact(player,session).success,"completed terminal cannot restart")
	var legacy := SortieCheckpoint.capture_world(battle)
	legacy.erase("records_work")
	check(SortieCheckpoint.restore_world(legacy,battle) and terminal.remaining == 0,"existing completed saves require no fabricated download")
	battle.free()
	SortieRuntime.clear_session()

func read_work_saved() -> void:
	var profile := SaveService.load_profile("user://records_work.json",false)
	check(profile != null,"separate process loads partial urgent download")
	if not profile: return
	ProfileRuntime._profile = profile
	check(SortieRuntime.resume_saved("user://records_work.json") == OK,"partial work resumes through production save API")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var terminal: RecordsTerminal = battle.area_root.get_node("StreetTerminal")
	terminal.set_process(false)
	check(terminal.remaining == 3 and terminal.urgent and terminal.actor == battle.player and terminal.session == battle.session,"exact deadline and actual actor rebound across process")
	check(terminal.get_node("RecordsAlarm").phase == RecordsAlarm.Phase.SOUNDED,"resume does not reset already emitted alert")
	terminal.tick(3)
	check(battle.session.get_objective_state(&"streets_terminal").status == ObjectiveState.Status.COMPLETED,"resumed download completes without restarting")
	battle.free()
	SortieRuntime.clear_session()

func read_saved() -> void:
	var p := SaveService.load_profile("user://records_alarm.json",false)
	check(p != null,"second process loads actual profile")
	if not p:
		await finish()
		return
	ProfileRuntime._profile = p
	check(SortieRuntime.resume_saved("user://records_alarm.json") == OK,"second process resumes saved sortie")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var alarm: RecordsAlarm = battle.area_root.get_node("StreetTerminal/RecordsAlarm")
	alarm.set_process(false)
	check(alarm.phase == RecordsAlarm.Phase.WARNING and alarm.remaining == 17.5,"separate process preserves phase and exact simulation deadline")
	check(battle.session.get_objective_state(&"streets_terminal").status == ObjectiveState.Status.COMPLETED,"records objective survives alongside alarm")
	alarm.tick(17.4)
	check(alarm.phase == RecordsAlarm.Phase.WARNING,"resumed alarm does not fire early")
	alarm.tick(.2)
	check(alarm.phase == RecordsAlarm.Phase.SOUNDED,"resumed alarm fires at remaining deadline")
	check(SortieRuntime.save_checkpoint() == OK,"spent event can be saved")
	battle.free()
	await finish()
