extends Node
const PATH := "user://sortie_checkpoint_test.json"
var failures: Array[String] = []
var checks := 0
var battle: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--read" in args:
		await _read_cross_process()
	elif "--write" in args:
		await _prepare_world(false)
		check(SortieRuntime.save_checkpoint() == OK, "cross-process write")
		var file := FileAccess.open(PATH + ".expected", FileAccess.WRITE)
		file.store_string(JSON.stringify(ProfileRuntime.get_profile().to_dict()))
		file.close()
		print("CHECKPOINT_WRITER_READY")
		if "--wait-for-kill" in args: return
	else:
		_schema_compatibility()
		await _roundtrip(false)
		await _roundtrip(true)
		await _terminal_outcomes()
	await _cleanup()
	for failure in failures: push_error("CHECKPOINT: " + failure)
	print("SORTIE_CHECKPOINT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	FlowMenu.close()
	if is_instance_valid(battle):
		battle.free()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.4).timeout

func _schema_compatibility() -> void:
	var previous := ProfileState.create_new().to_dict()
	previous.erase("sortie_checkpoint")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 2, "profile": previous})); file.close()
	var loaded := SaveService.load_profile(PATH, false)
	check(loaded != null and loaded.sortie_checkpoint.is_empty() and _same(loaded.inventory.to_dict(), previous.inventory), "schema-2 economy profile migrates without a fabricated active sortie")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 3, "profile": previous})); file.close()
	check(SaveService.load_profile(PATH, false) == null, "schema-3 missing checkpoint field rejected")

func _prepare_world(first: bool) -> void:
	get_tree().paused = false
	SortieRuntime.clear_session()
	ProfileRuntime._profile = ArmoryFixture.create_profile()
	var profile := ProfileRuntime.get_profile()
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area" if first else &"street_district", &"first_mission" if first else &"streets_recon", plan.ammo_ids), profile)
	check(session != null, "actual sortie activated")
	check(SortieRuntime.begin_persistence(PATH) == OK, "deployment durable before scene creation")
	check(SaveService.load_profile(PATH, false).sortie_checkpoint.world.is_empty(), "pre-arrival recovery boundary")
	SortieRuntime.layout_seed = 907
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().process_frame
	get_tree().paused = true
	var player: PlayerController = battle.player
	player.position += Vector3(1.5, 0, 0.5)
	player.health = 137.0
	player.velocity = Vector3(1, 0, -2)
	player._dodge_time = 0.08
	player._dodge_cooldown_time = 0.44
	player._dodge_direction = Vector3.RIGHT
	player._shot_cooldown = 0.09
	var primary := player.get_weapon_instance(LoadoutState.SLOT_WEAPON_PRIMARY)
	check(session.fire_weapon(primary.instance_id), "consume actual loaded round")
	player._reload_remaining_by_weapon[primary.instance_id] = 0.65
	player._footstep_distance = 0.73
	check(player._activate_weapon_slot(LoadoutState.SLOT_WEAPON_SECONDARY), "secondary selected independently of reload")
	var points: Array = battle.area_root.find_children("*", "LootSpawnPoint", true, false)
	for point in points:
		var items: Array = point.get_children().filter(func(child): return child is LootPickup)
		if items.size() > 0:
			check(items[0].try_pickup(session) == LootPickup.PickupResult.SUCCESS, "actual pickup consumed before checkpoint")
			break
	var exchange_cargo := ItemInstance.new(&"material.scrap",1)
	check(session.inventory.add_item_preserving_instance(exchange_cargo), "exchange cargo available before checkpoint")
	var exchanged := false
	for point in points:
		for pickup in point.get_children():
			if pickup is LootPickup and not pickup.consumed and pickup.exchange_cargo(session,exchange_cargo.instance_id) == LootPickup.PickupResult.SUCCESS:
				exchanged = true
				break
		if exchanged: break
	check(exchanged and not session.inventory.contains(exchange_cargo.instance_id), "actual exchange leaves original cargo in persisted world")
	var enemies: Array = battle.enemy_container.get_children().filter(func(child): return child is EnemyController)
	var defeated: EnemyController = enemies[0]
	defeated.take_damage(10000)
	# Apply real death/pickup queue removals without advancing simulation.
	await get_tree().process_frame
	check(session.enemies_defeated == 1, "kill belongs to session, not replayed on restore")
	for door in battle.area_root.find_children("*", "Door", true, false): door.open(); break
	for barrier in battle.area_root.find_children("*", "DestructibleWorldObject", true, false):
		barrier.receive_damage(DamagePacket.new(0, 0, 10000))
		break
	if first:
		var director: Node = battle.get_node("FirstMissionDirector")
		director.stage = director.Stage.TERMINAL
		director.elapsed = 121.5
		director.patrol_looted = true
		director._refresh_guide()
		var terminal: Node = battle.area_root.find_child("PrototypeTerminal", true, false)
		player.global_position = terminal.global_position + Vector3.RIGHT
		check(terminal.interact(player, session).success, "real timed terminal starts")
		terminal._process(5.5) # Deterministic elapsed-time fixture, not a wall-clock wait.
		check(terminal.investigation_remaining == 2.5, "partial terminal countdown has meaningful saved progress")
		check(SortieRuntime.save_checkpoint() == OK, "partial terminal saved")
		var investigation := SortieCheckpoint.capture_world(battle)
		terminal.investigation_remaining = 0
		check(SortieCheckpoint.restore_world(investigation, battle) and terminal.investigation_remaining == 2.5, "partial terminal restores instead of restarting")
		terminal._process(2.5)
		check(director.stage == director.Stage.CHOICE and session.is_mission_completed(), "restored terminal completes once through actual objective signal")
		var exit: Node = battle.area_root.find_child("ExtractionPoint", true, false)
		player.global_position = exit.global_position + Vector3.RIGHT
		check(exit.interact(player, session).success, "real timed extraction starts")
		exit._process(4.5)
		battle.area_root.find_child("LocalAlertEvent", true, false).trigger()
		director.reinforcements_remaining = 0.0
	for enemy in battle.enemy_container.get_children():
		if not enemy is EnemyController: continue
		enemy.take_damage(12, Vector3.LEFT)
		enemy._engaged = true
		enemy.target = player
		enemy._update_presentation(0.08, player.global_position + Vector3.UP, 0.6)
		enemy._telegraph_shot()
		break
	var rocket := PlayerController.ROCKET_SCENE.instantiate()
	if not first:
		var planned := false
		for enemy in battle.enemy_container.get_children():
			if not enemy is EnemyController or enemy.tactics.role != EnemyTactics.Role.FLANKER: continue
			enemy.ensure_awareness()
			enemy.awareness.state = EnemyAwareness.State.COMBAT
			enemy.awareness.target_visible = true
			enemy.awareness.last_known = enemy.position + Vector3.FORWARD * 10
			enemy.tactics.destination(enemy, 0)
			enemy.tactics.plan_remaining = 1.25
			planned = enemy.tactics.has_plan
			break
		check(planned, "checkpoint fixture includes an actual selected flank plan with partial interval")
	battle.add_child(rocket)
	rocket.position = player.position + Vector3.UP * 1.3 + Vector3(3, 0, 0)
	rocket.setup(player, Vector3.FORWARD, ContentDB.get_weapon(&"weapon.rocket_launcher_01"))
	rocket.traveled = 4.75
	check(SortieRuntime.save_checkpoint() == OK, "world/session checkpoint saved atomically")

func _roundtrip(first: bool) -> void:
	await _prepare_world(first)
	var expected := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	var warehouse := ProfileRuntime.get_profile().inventory.to_dict()
	var muzzles := {}
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController:
			muzzles[enemy.get_meta("spawn_key")] = [enemy.presentation.get_muzzle_position(), enemy.presentation.get_muzzle_direction()]
	check(SortieCheckpoint.restore_session(expected.session) != null, "session JSON contract valid")
	check(SortieCheckpoint.validate_world(expected.world, battle), "entire world contract valid")
	check(not SortieRuntime.start_sortie(ProfileRuntime.get_profile().create_sortie_request(), ProfileRuntime.get_profile()), "cannot redeploy over pending sortie")
	check(SupplyService.transact("buy", "weapon.pistol_01", 1, PATH).error == ERR_BUSY, "base trade locked while pending")
	var corrupt: Dictionary = expected.session.duplicate(true)
	corrupt.weapons[corrupt.weapons.keys()[0]].rounds = -1
	check(SortieCheckpoint.restore_session(corrupt) == null, "negative loaded rounds rejected")
	corrupt = expected.session.duplicate(true)
	corrupt.kills = 0.5
	check(SortieCheckpoint.restore_session(corrupt) == null, "fractional counters rejected")
	var broken: Dictionary = expected.world.duplicate(true)
	broken.nodes.erase(broken.nodes.keys()[0])
	check(not SortieCheckpoint.validate_world(broken, battle), "incomplete/incompatible layout blocked")
	broken = expected.world.duplicate(true)
	broken.layout = "different-navigation-or-collision"
	check(not SortieCheckpoint.validate_world(broken, battle), "changed collision/navigation layout blocked")
	broken = expected.world.duplicate(true)
	broken.player.health = 10000
	check(not SortieCheckpoint.validate_world(broken, battle), "invalid player state rejected")
	var disk := FileAccess.get_file_as_string(PATH)
	SortieRuntime.checkpoint_path = "user://missing_checkpoint_directory/profile.json"
	check(SortieRuntime.save_checkpoint() != OK, "disk failure reported")
	check(FileAccess.get_file_as_string(PATH) == disk and _same(ProfileRuntime.get_profile().sortie_checkpoint, expected), "disk failure preserves last good checkpoint")
	battle.free()
	SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH), "load actual file")
	ProfileRuntime.get_profile().sortie_checkpoint.world = {}
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA, "missing battle world cannot silently respawn a fresh map")
	check(ProfileRuntime.load_profile(PATH), "invalid resume did not overwrite the save")
	check(SupplyService.transact("buy", "weapon.pistol_01", 1, PATH).error == ERR_BUSY, "trade also locked before resume")
	check(SortieRuntime.resume_saved(PATH) == OK, "resume saved session without reloading magazines")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	var restored := SortieCheckpoint.capture_world(battle)
	check(not FlowMenu.is_open(), "world restore does not open recovery error")
	check(_same(restored, expected.world), "whole gameplay world restored, including live rocket and enemy telegraph")
	check(_same(SortieCheckpoint.session_data(battle.session), expected.session), "inventory IDs, objectives, magazines and threat restored")
	check(_same(ProfileRuntime.get_profile().inventory.to_dict(), warehouse), "base warehouse unchanged by suspend")
	check(battle.enemies_remaining == expected.world.enemies.size() and battle.session.enemies_defeated == 1, "dead enemy stays dead without duplicate kill credit")
	for enemy in battle.enemy_container.get_children():
		if not enemy is EnemyController: continue
		var previous: Array = muzzles[enemy.get_meta("spawn_key")]
		check(enemy.presentation.get_muzzle_position().distance_to(previous[0]) < 0.0001 and enemy.presentation.get_muzzle_direction().distance_to(previous[1]) < 0.0001, "enemy muzzle origin/direction survive hit/recoil/animation state")
	if not first:
		var invalid := restored.duplicate(true)
		invalid.enemies.values()[0].tactics.role = 99
		check(not SortieCheckpoint.restore_world(invalid, battle) and _same(SortieCheckpoint.capture_world(battle), restored), "invalid duty rejects entire restore before any world mutation")
		var older := restored.duplicate(true)
		for entry in older.enemies.values(): entry.erase("tactics")
		battle.free()
		SortieRuntime.clear_session()
		ProfileRuntime.get_profile().sortie_checkpoint.world = older
		check(SortieRuntime.resume_saved(PATH) == OK, "pre-role checkpoint still resumes real session")
		battle = load("res://scenes/battle/battle.tscn").instantiate()
		battle.result_transition_enabled = false
		add_child(battle)
		var correct := true
		for enemy in battle.enemy_container.get_children():
			if not enemy is EnemyController: continue
			var point: EnemySpawnPoint = battle.area_root.get_node(enemy.get_meta("spawn_key"))
			correct = correct and enemy.tactics.role == point.tactical_role and not enemy.tactics.has_plan
		check(correct, "old checkpoint retains authored duties without stale/fabricated flank plans")
		var compatible := SortieCheckpoint.capture_world(battle)
		for entry in compatible.enemies.values(): entry.erase("tactics")
		check(not FlowMenu.is_open() and _same(compatible, older), "pre-role load preserves complete old gameplay world including rocket and pending shot")
	if first:
		var director: Node = battle.get_node("FirstMissionDirector")
		check(director.stage == director.Stage.CHOICE and director.choice_buttons.visible, "tutorial choice and reinforcement timer resume")
		var terminal: Node = battle.area_root.find_child("PrototypeTerminal", true, false)
		check(terminal.actor == battle.player and terminal.active_session == battle.session, "timed interaction actor/session rebound")
	battle.free()
	SortieRuntime.clear_session()
	get_tree().paused = false
	await get_tree().create_timer(0.4).timeout

func _terminal_outcomes() -> void:
	for success in [true, false]:
		await _prepare_world(false)
		var session: SortieSession = battle.session
		check(session.complete_extraction() if success else session.fail(), "actual terminal state")
		check(SortieRuntime.save_checkpoint() == OK, "pending result durably saved")
		var outcome_id := SortieRuntime.get_outcome().outcome_id
		battle.free()
		SortieRuntime.clear_session()
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK, "result survives process boundary")
		check(SortieRuntime.get_outcome().outcome_id == outcome_id, "same outcome ID recovered")
		check(SortieRuntime.finalize_sortie(PATH) == OK, "result settlement saved atomically")
		var after := ProfileRuntime.get_profile().to_dict()
		check(after.sortie_checkpoint.is_empty() and outcome_id in after.settled_outcomes, "settled result clears journal in same save")
		check(SortieRuntime.finalize_sortie(PATH) == OK and ProfileRuntime.get_profile().to_dict() == after, "retry cannot duplicate loss/reward")
		get_tree().paused = false
		await get_tree().create_timer(0.4).timeout

func _read_cross_process() -> void:
	get_tree().paused = true
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH + ".expected"))
	check(ProfileRuntime.load_profile(PATH), "second process loads profile")
	check(_same(ProfileRuntime.get_profile().to_dict(), expected), "second process inventory/economy/checkpoint identical")
	check(SortieRuntime.resume_saved(PATH) == OK, "second process restores session")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	check(not FlowMenu.is_open() and _same(SortieCheckpoint.capture_world(battle), expected.sortie_checkpoint.world), "second process restores complete world")
	get_tree().paused = false
	await get_tree().create_timer(0.65).timeout
	check(is_instance_valid(battle.player) and battle.session.status == SortieSession.Status.ACTIVE, "restored simulation advances normally")
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController: check(not enemy._is_telegraphing, "restored enemy shot finishes, not frozen forever")

func _same(a: Variant, b: Variant) -> bool:
	if SaveService.is_number(a) and SaveService.is_number(b): return absf(float(a) - float(b)) < 0.00005
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not _same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _same(a[i], b[i]): return false
		return true
	return a == b

func check(condition: bool, message: String) -> void:
	checks += 1
	print("CHECKPOINT %s: %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failures.append(message)
