extends "res://tests/campus_chapter_test.gd"
## Controlled component fixture: placed player, frozen unrelated enemies. The
## observed guard uses normal hearing/navigation/physics; not an earned route.
var checks := 0
var pa: CampusRelayDiversion
var initial_enemies := 0

func chapter_path() -> String: return "user://campus_relay_diversion_test.json"

func check(ok: bool, message: String) -> void:
	checks += 1
	super.check(ok, message)

func report() -> void:
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session(); AudioDirector.shutdown_for_test()
	print("CAMPUS_RELAY_DIVERSION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func freeze_actors() -> void:
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)

func start_world(version := CampusChapter.FACTS_VERSION) -> void:
	check(version == CampusChapter.FACTS_VERSION, "declared fixture uses the current relay contract")
	check(DeploymentPlan.deploy(ProfileRuntime.get_profile(), &"street_district", &"streets_recon", chapter_path()).error == OK, "fixture deploys through the normal session service")
	# A declared component seed selects the east entrance, keeping the west guard
	# outside the ordinary 24m safe-spawn exclusion. Not an earned campaign save.
	var rng := RandomNumberGenerator.new()
	for seed in range(1, 100):
		rng.seed = seed
		if rng.randi_range(0, 5) == 5:
			SortieRuntime.layout_seed = seed; break
	battle = load("res://scenes/battle/battle.tscn").instantiate(); battle.result_transition_enabled = false; add_child(battle)
	freeze_actors()
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--read" in args or "--legacy-read" in args:
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path()) == OK, "independent process resumes original signed component checkpoint")
		battle = load("res://scenes/battle/battle.tscn").instantiate(); battle.result_transition_enabled = false; add_child(battle)
		freeze_actors()
		if "--legacy-read" in args:
			check(int(battle.area_root.get_meta("map_revision")) == 5 and not battle.area_root.has_node("CampusRelayDiversion"), "real older relay map stays unchanged and gains no PA")
			check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle), battle), "older relay remains strictly checkpointable")
			report(); return
		pa = battle.area_root.get_node("CampusRelayDiversion")
		check(pa.phase == CampusRelayDiversion.Phase.PLAYING and pa.remaining > 0 and pa.remaining < pa.DURATION, "restore retains partially used PA, not a new activation")
		check(pa.introduced and pa.get_node("Speaker/Lamp").visible and pa.get_node("Switch").rotation_degrees.z < -50, "restored visible switch and lamp match saved use")
		check(not pa.interact(battle.player, battle.session).success, "resume cannot restart or extend the broadcast")
		for tick in 600:
			await get_tree().physics_frame
			if pa.phase == CampusRelayDiversion.Phase.SPENT: break
		check(pa.phase == CampusRelayDiversion.Phase.SPENT and pa.remaining == 0 and not pa.get_node("Speaker/Lamp").visible, "restored sound expires normally without quest credit")
		check(battle.session.campus.relays.is_empty(), "broadcast never repairs a relay or invents progress")
		report(); return
	profile_at_batch2(); await start_world()
	pa = battle.area_root.get_node_or_null("CampusRelayDiversion")
	var spawn_keys:=[]
	for enemy in battle.enemy_container.get_children():spawn_keys.append(enemy.get_meta("spawn_key", ""))
	print("PA_COMPONENT_LAYOUT: ",JSON.stringify({"spawn":str(battle.player.position),"enemies":spawn_keys}))
	check(pa != null and int(battle.area_root.get_meta("map_revision")) == 7, "fresh relay outing includes optional PA on its own map revision")
	if pa == null: report(); return
	initial_enemies = battle.enemy_container.get_child_count()
	check(initial_enemies > 0 and pa.find_children("*", "EnemySpawnPoint", true, false).is_empty(), "PA adds no enemy spawn or extra wave to the ordinary campus layout")
	check(battle.session.campus.version == 5 and not battle.area_root.has_node("CampusMedicalRunners"), "no new campus contract or unrelated carrier in relay outing")
	var map: RID = battle.area_root.get_node("StreetNavigation").get_navigation_map()
	for tick in 600:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(map) > 0: break
	for at: Vector3 in [pa.position, pa.get_node("Speaker").global_position]:
		var path:=PackedVector3Array()
		for tick in 600:
			await get_tree().physics_frame
			path = NavigationServer3D.map_get_path(map, battle.player.global_position, at, true)
			if not path.is_empty() and path[-1].distance_to(at) < .6:break
		print("PA_COMPONENT_PATH: ",JSON.stringify({"target":str(at),"points":path.size(),"end":str(path[-1]) if not path.is_empty() else "unreachable","iteration":NavigationServer3D.map_get_iteration_id(map)}))
		check(not path.is_empty() and path[-1].distance_to(at) < .6, "authored PA control and real sound origin lie on reachable navigation")
	var before_inventory: Dictionary = battle.session.inventory.to_dict()
	var before_relays: Array = battle.session.campus.relays.duplicate()
	check(not pa.interact(battle.player, battle.session).success, "PA cannot be triggered remotely")
	battle.player.global_position = pa.global_position + Vector3(0, 0, 1)
	var guard: EnemyController
	for enemy in battle.enemy_container.get_children():
		if enemy.get_meta("spawn_key", "") == "StreetPMC1": guard = enemy; break
	check(guard != null, "existing west service-road guard is present")
	if guard == null: report(); return
	guard.set_physics_process(true)
	var start := guard.global_position
	var origin: Vector3 = pa.get_node("Speaker").global_position
	battle.player.interaction_component._physics_process(0)
	check(battle.player.interaction_component._current_target == pa, "ordinary nearest-target system selects the physical PA switch")
	check(battle.player.interaction_component.interact_with_current().success, "ordinary interaction starts one finite broadcast")
	check(pa.phase == CampusRelayDiversion.Phase.PLAYING and pa.remaining == pa.DURATION, "activation neither waits for a work timer nor grants success")
	check(guard.awareness.state == EnemyAwareness.State.INVESTIGATE and guard.awareness.last_known.distance_to(origin) < .1, "guard hears the remote speaker, not the player's switch position")
	for tick in 180: await get_tree().physics_frame
	check(guard.global_position.distance_to(start) > 2 and guard.global_position.distance_to(origin) < start.distance_to(origin) - 2, "existing live guard physically walks toward the sound through ordinary navigation")
	check(not pa.interact(battle.player, battle.session).success, "repeated interaction cannot refresh the diversion")
	check(battle.session.inventory.to_dict() == before_inventory and battle.session.campus.relays == before_relays, "sound neither gives loot nor repairs relays")
	var world := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world, battle), "partly active PA and actually moved enemy produce valid checkpoint")
	var corrupt := world.duplicate(true)
	corrupt.nodes.CampusRelayDiversion.phase = 0
	check(not SortieCheckpoint.validate_world(corrupt, battle), "ready phase cannot retain playing countdown")
	corrupt = world.duplicate(true); corrupt.nodes.CampusRelayDiversion.remaining = 9.0
	check(not SortieCheckpoint.validate_world(corrupt, battle), "checkpoint cannot extend the broadcast")
	corrupt = world.duplicate(true); corrupt.nodes.CampusRelayDiversion.introduced = false
	check(not SortieCheckpoint.validate_world(corrupt, battle), "playing state requires actual introduction or use")
	if "--write" in args:
		check(SortieRuntime.save_checkpoint() == OK, "normal checkpoint service durably saves partially playing PA")
		report(); return
	for tick in 600:
		await get_tree().physics_frame
		if pa.phase == CampusRelayDiversion.Phase.SPENT: break
	check(pa.phase == CampusRelayDiversion.Phase.SPENT and not pa.interact(battle.player, battle.session).success, "spent PA does not loop or generate another use")
	check(battle.session.campus.relays.is_empty() and battle.enemy_container.get_child_count() == initial_enemies, "end of sound does not complete work, spawn or kill enemies")
	report()
