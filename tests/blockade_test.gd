extends Node
var failures: Array[String] = []
var checks := 0
var battle: Node3D
const PATH := "user://blockade_test.json"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames() -> void:
	for tick in 4: await get_tree().physics_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args(): return
	for tick in 60: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png")) == OK,"capture saved")

func freeze() -> void:
	battle.player.set_physics_process(false)
	battle.area_root.get_node("Van").set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)

func load_battle() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false; add_child(battle); freeze()
	await frames()

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	if "--read" in OS.get_cmdline_user_args():
		await checkpoint_read();return
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
	var home: Node3D = load("res://scenes/presentation/slice/hideout.tscn").instantiate(); add_child(home);home.show_section("Operations")
	var choices := home.find_child("MissionChoice",true,false) as OptionButton
	var index := DeploymentPlan.STREET_MISSIONS.find(BlockadeStory.MISSION)
	check(index == 3 and choices.item_count == 6 and DeploymentPlan.STREET_MISSIONS[4]==MaintenanceStory.MISSION and DeploymentPlan.STREET_MISSIONS[5]==FinaleStory.MISSION,"operation menu preserves blockade fourth and adds maintenance fifth and finale sixth")
	choices.select(index);choices.item_selected.emit(index);await frames()
	check(home.find_child("MissionBriefing",true,false).text.contains(tr(BlockadeJourney.BRIEF)),"briefing teaches real mechanic instead of campus chores")
	check(home.find_child("LightingChoice",true,false).disabled,"authored dawn is not presented as a nonexistent night variant")
	await capture("blockade_operations")
	home.free();DeploymentPlan.selected_street_mission = &"streets_recon"
	check(DeploymentPlan.area_for_mission(BlockadeStory.MISSION) == BlockadeStory.AREA,"normal deployment resolves independent checkpoint")
	check(ContentDB.get_mission(BlockadeStory.MISSION).validate_definition(),"registered objective definition is valid")
	check(DeploymentPlan.deploy(profile,BlockadeStory.AREA,BlockadeStory.MISSION,PATH).error == OK,"transactional deployment saves a real sortie")
	SortieRuntime.get_current_session().blockade={} # Explicit original-map compatibility fixture.
	await load_battle()
	var world: Node3D = battle.area_root
	var van: BlockadeVan = world.get_node("Van")
	var session: SortieSession = battle.session
	check(not FlowMenu.is_open() and session.validate(),"world initializes without a recovery menu")
	check(battle.enemy_container.get_child_count() == 3,"only three preplaced sourced infected; no infinite reinforcements")
	check(session.campus.is_empty() and session.slice_context.is_empty() and not session.q02_active,"standalone encounter does not grant fictional campaign facts")
	check(world.get_node("Retreat").can_extract(session) and not world.get_node("NorthExit").can_extract(session),"south retreat open, north sealed before vehicle disabled")
	check(not van.sees(battle.player),"vehicle cannot acquire player beyond range at spawn")
	var radio: Dictionary = world.get_node("Radio").interact(battle.player,session)
	check(radio.success and radio.information == tr(BlockadeStory.INTRO),"spawn radio gives character dialogue and actual combat cues")
	check(not world.get_node("PASwitch").interact(battle.player,session).success,"remote cutoff interaction refused")
	battle.player.position = Vector3(0,0.1,10);await frames()
	check(van.sees(battle.player),"real LOS can acquire exposed player")
	van.phase_remaining = 0;van._physics_process(.01)
	check(van.phase == BlockadeVan.Phase.WARNING and van.get_node("WarningLine").visible,"acquisition starts visible 1.5-second red warning")
	var locked := van.aim_point
	battle.player.position.x = 6;await frames()
	var health: float = battle.player.health
	van._physics_process(1.5)
	check(van.phase == BlockadeVan.Phase.BURST and van.aim_point == locked,"warning freezes last observed point, never tracks later motion")
	for shot in 4:van._physics_process(.22)
	check(van.shots_fired == 4 and battle.player.health == health,"moving aside evades actual four raycast shots")
	check(van.phase == BlockadeVan.Phase.VENT and van.get_node("VentLight").visible,"burst opens visible 2.3-second vulnerability")
	var damage := DamagePacket.new(20,0,1,battle.player,&"weapon.assault_rifle_01",&"player")
	check(van.receive_damage(damage) == 20,"open vents take full real weapon damage")
	van._physics_process(2.3)
	check(is_equal_approx(van.receive_damage(damage),3.6),"closed armor reduces, but does not nullify rifle damage")
	check(van.receive_damage(DamagePacket.new(100,0,100,null,&"",&"enemy")) == 0,"infected cannot accidentally credit the player for the vehicle")
	battle.player.position = Vector3(0,.1,10);await frames()
	van.aim_point = battle.player.global_position + Vector3.UP * 1.1
	van._enter(BlockadeVan.Phase.BURST);van.burst_shots = 0
	health = battle.player.health
	van._physics_process(.22)
	check(battle.player.health < health and session.damage_taken > 0,"standing in the frozen line applies actual player damage and accounting")
	battle.player.position = Vector3(-4,.1,16);await frames()
	check(not van.sees(battle.player),"concrete cover blocks acquisition")
	van.aim_point = battle.player.global_position + Vector3.UP * 1.1
	health = battle.player.health;van._fire_locked_shot()
	check(battle.player.health == health,"physical cover also stops an already locked shot")
	# PA sound reaches normal hearing as a location observation, not player coordinates.
	var infected: EnemyController = battle.enemy_container.get_child(0)
	infected.position = Vector3(-10,0,-14);infected.awareness = EnemyAwareness.new();infected.ensure_awareness();infected.set_physics_process(true)
	van.speaker_remaining = 0;van._physics_process(.01)
	check(van.broadcasts > 0 and infected.awareness.last_known.is_equal_approx(van.global_position+Vector3.UP*3.5),"broadcast sends existing infected to the PA source")
	infected.set_physics_process(false)
	battle.player.position = world.get_node("PASwitch").position + Vector3.RIGHT
	check(world.get_node("PASwitch").interact(battle.player,session).success,"west service switch cuts independent PA power")
	check(BlockadeStory.done(session,&"blockade_speaker") and not van.speaker_enabled,"cutoff is an actual optional objective")
	var count := van.broadcasts
	van._physics_process(10)
	check(van.broadcasts == count and not van.destroyed,"cut stops future PA broadcasts, not the weapon or existing memory")
	check(not world.get_node("PASwitch").interact(battle.player,session).success,"cutoff cannot be repeated")
	van.phase = BlockadeVan.Phase.WARNING;van.phase_remaining = .71;van.burst_shots = 0;van.aim_point = Vector3(0,1.2,10);van.refresh()
	battle.player.position = Vector3(2,.1,-3);await frames();await capture("blockade_warning")
	var saved := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"legitimate live encounter checkpoint validates")
	var path := String(world.get_path_to(van))
	for forged in [{"phase":99},{"phase_remaining":10},{"speaker_enabled":true},{"aim_point":[100,0,100]},{"burst_shots":5},{"destroyed":true}]:
		var raw := saved.duplicate(true);raw.nodes[path].merge(forged,true)
		check(not SortieCheckpoint.validate_world(raw,battle),"invalid or contradictory vehicle state rejected: "+str(forged))
	get_tree().paused = true
	check(SortieRuntime.save_checkpoint() == OK,"saves exact mid-warning state through persistent service")
	if "--write" in OS.get_cmdline_user_args():
		battle.free();SortieRuntime.clear_session();await frames();AudioDirector.shutdown_for_test()
		print("BLOCKADE_CHECKPOINT_WRITE: ","PASS" if failures.is_empty() else "FAIL")
		get_tree().paused=false;get_tree().quit(0 if failures.is_empty() else 1);return
	var hp := van.current_structure_health
	battle.free();SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK,"disk profile reload resumes encounter")
	await load_battle()
	world = battle.area_root;session = battle.session;van = world.get_node("Van")
	check(not FlowMenu.is_open() and is_equal_approx(van.phase_remaining,.71) and van.phase == BlockadeVan.Phase.WARNING,"resumes exact telegraph timer, not a fresh full warning")
	check(van.current_structure_health == hp and not van.speaker_enabled and BlockadeStory.done(session,&"blockade_speaker"),"damaged vehicle and cut power survive roundtrip")
	check(van.aim_point.is_equal_approx(Vector3(0,1.2,10)),"frozen aim survives disk roundtrip")
	get_tree().paused = false
	van._enter(BlockadeVan.Phase.VENT)
	await capture("blockade_vent")
	var kills := session.enemies_defeated
	while not van.destroyed:van.receive_damage(damage)
	await frames()
	check(session.is_mission_completed() and world.get_node("NorthExit").can_extract(session),"physical vehicle destruction completes real mission and unlocks north exit")
	check(session.enemies_defeated == kills and van.visual.visible and not van.collision_shape.disabled,"disabled chassis remains cover; no fabricated humanoid kill credit")
	check(van.receive_damage(damage) == 0 and not van.cut_speaker(),"disabled vehicle grants no repeated completion or cutoff")
	await capture("blockade_disabled")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"completed vehicle checkpoint validates")
	get_tree().paused = true;check(SortieRuntime.save_checkpoint() == OK,"disabled state persists")
	battle.free();SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK,"disabled world resumes from disk")
	await load_battle();world=battle.area_root;session=battle.session;van=world.get_node("Van")
	check(van.destroyed and van.phase == BlockadeVan.Phase.WRECK and van.visual.visible and not van.collision_shape.disabled,"restored wreck stays visible and physical, with no resurrection")
	get_tree().paused=false
	check(world.get_node("NorthExit").extract(session),"newly opened north exit performs real extraction")
	var outcome := SortieRuntime.get_outcome()
	check(outcome != null and outcome.validate() and outcome.mission_completed and not BlockadeStory.ending(outcome).is_empty(),"actual outcome carries completed encounter and its debrief")
	battle.free();SortieRuntime.clear_session();await frames();AudioDirector.shutdown_for_test()
	print("BLOCKADE_TEST checks=",checks," failures=",failures)
	print("BLOCKADE_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func checkpoint_read() -> void:
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK,"separate process loads suspended encounter")
	await load_battle()
	var van: BlockadeVan = battle.area_root.get_node("Van")
	check(not FlowMenu.is_open(),"separate process restores without recovery")
	check(van.phase == BlockadeVan.Phase.WARNING and is_equal_approx(van.phase_remaining,.71),"separate process retains exact warning phase/time")
	check(is_equal_approx(van.current_structure_health,van.max_structure_health-23.6),"separate process retains real damaged health")
	check(not van.speaker_enabled and BlockadeStory.done(battle.session,&"blockade_speaker"),"separate process retains actual PA cutoff")
	var aim := van.aim_point
	check(aim.is_equal_approx(Vector3(0,1.2,10)),"separate process retains frozen aim point")
	battle.player.position=Vector3(-10,0,10)
	van._physics_process(.7)
	check(van.phase == BlockadeVan.Phase.WARNING,"warning does not fire early after resume")
	van._physics_process(.02)
	check(van.phase == BlockadeVan.Phase.BURST and van.aim_point == aim,"remaining warning expires without reacquiring moved player")
	check(battle.enemy_container.get_child_count() == 3 and battle.session.enemies_defeated == 0,"separate process does not invent deaths/reinforcements")
	battle.free();SortieRuntime.clear_session();await frames();AudioDirector.shutdown_for_test()
	print("BLOCKADE_CHECKPOINT_READ: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
