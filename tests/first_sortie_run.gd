extends "res://tests/normal_start_test.gd"
## Real normal-start loop using synthetic controls, not human acceptance.
## No teleports, forced stages, direct damage, profile fixtures or ammo grants.
var extended := false
var reading := false
var salvage := false

var battle: Node3D
var shots := 0
var stage_frames := {}
const ACTIONS := ["move_left","move_right","move_forward","move_back","aim_left","aim_right","aim_up","aim_down","fire"]

func _ready() -> void:
	get_tree().create_timer(150,true).timeout.connect(func(): failures.append("First-sortie driver deadline"); extended = true; _finish())
	super._ready()

func _run() -> void:
	if "--read" in OS.get_cmdline_user_args():
		tree = get_tree(); reading = true; extended = true
		salvage = "--salvage" in OS.get_cmdline_user_args()
		var profile := ProfileRuntime.get_profile()
		check(SaveService.save_exists() and not ProfileRuntime.recovery_required, "Independent process loads actual completed profile")
		check(profile.first_mission_completed and profile.ar_damage_upgraded and profile.successful_sorties == 1 and profile.failed_sorties == 0, "Independent process retains earned first victory and upgrade")
		check(profile.credits == 2100 and FirstMissionPreparation.salvage_count(profile) == (2 if salvage else 0) and profile.sortie_checkpoint.is_empty(), "Independent process retains correct route cargo, cost and closed sortie")
		_finish(); return
	super._run()

func _finish() -> void:
	if reading:
		var file := FileAccess.open("user://first_sortie_read.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t")); file.close()
		AudioDirector.shutdown_for_test()
		print("FIRST_SORTIE_RUN: %s (%d checks; independent read)" % ["PASS" if failures.is_empty() else "FAIL", checks])
		tree.quit(0 if failures.is_empty() else 1); return
	if not extended and failures.is_empty():
		extended = true
		_continue.call_deferred()
		return
	_release()
	print("FIRST_SORTIE_RUN: %s (%d checks; shots=%d)" % ["PASS" if failures.is_empty() else "FAIL", checks, shots])
	super._finish()

func _release() -> void:
	for action in ACTIONS: Input.action_release(action)

func _continue() -> void:
	salvage = "--salvage" in OS.get_cmdline_user_args()
	battle = tree.current_scene
	battle.player.weapon_fired.connect(func(_recoil: float): shots += 1)
	var director = battle.get_node("FirstMissionDirector")
	Input.action_press("aim_right")
	for tick in 12: await tree.physics_frame
	Input.action_press("fire")
	for tick in 15: await tree.physics_frame
	Input.action_release("fire")
	var before_move := shots
	check(director.stage == director.Stage.MOVE and before_move > 0, "Pre-lesson aim and real shots occurred during MOVE")
	await _tap("reload")
	check(battle.player.get_reload_remaining() > 0, "Exploration reload really starts before its lesson")
	for tick in 300:
		await tree.physics_frame
		if battle.player.get_reload_remaining() <= 0: break
	Input.action_press("move_right")
	for tick in 30: await tree.physics_frame
	Input.action_release("move_right")
	for tick in 90:
		await tree.physics_frame
		var key := str(director.stage)
		stage_frames[key] = int(stage_frames.get(key,0))+1
	evidence["stage_frames_without_new_aim_or_fire"] = stage_frames
	evidence["shots_before_move"] = before_move
	evidence["shots_after_wait"] = shots
	evidence["stage_after_wait"] = director.stage
	await _capture("08_held_aim_no_new_fire")
	check(shots == before_move, "No shot or turn was performed after entering the aiming lesson")
	check(director.stage == director.Stage.AIM, "Aiming lesson waits for a fresh turn rather than a pre-lesson direction")
	if not failures.is_empty(): _finish(); return
	Input.action_release("aim_right"); Input.action_press("aim_up")
	for tick in 30: await tree.physics_frame
	check(director.stage == director.Stage.FIRE and shots == before_move and not director.patrol.is_physics_processing(), "Fresh turn reaches FIRE, but old shots cannot activate patrol")
	await _capture("09_wait_for_fresh_shot")
	Input.action_press("fire")
	for tick in 8: await tree.physics_frame
	Input.action_release("fire")
	check(director.stage == director.Stage.PMC and shots > before_move, "New real shot activates ordinary patrol")
	for tick in 1800:
		await tree.physics_frame
		if battle.player.is_dead or battle.session.enemies_defeated >= 1: break
		_controls(battle.player.global_position)
	_release()
	check(battle.session.enemies_defeated >= 1 and not battle.player.is_dead, "Patrol defeated by actual weapon/AI combat")
	check(director.stage == director.Stage.RELOAD and not director.reload_seen, "Earlier completed reload does not skip fresh-magazine step")
	await _capture("10_patrol_defeated")
	if not failures.is_empty(): _finish(); return
	await _tap("reload")
	for tick in 300:
		await tree.physics_frame
		if director.stage == director.Stage.LOOT: break
	check(director.stage == director.Stage.LOOT, "Post-fight reload completes through normal input and timer")
	var supplies: Node3D = battle.area_root.find_child("PatrolSalvage",true,false)
	# The corpse location varies with normal AI. Cross north of the parked car
	# before heading west; a direct diagonal from spawn can hit its real collider.
	for at in [Vector3(4,0,26),Vector3(supplies.global_position.x,0,26)]:
		if not await _walk(at): _finish(); return
	if not await _walk(supplies.global_position,1.2): _finish(); return
	_release(); await _tap("interact"); await _frames()
	var presentation = battle.get_node("SlicePresentation")
	check(is_instance_valid(presentation.panel), "Real interaction opens patrol cache UI")
	await _capture("11_patrol_cache")
	if not is_instance_valid(presentation.panel): _finish(); return
	var core_id := ""
	for row in presentation._cache_rows:
		if row.pickup.item_instance.definition_id == &"loot.salvage_core_01":
			core_id = row.pickup.item_instance.instance_id
			await _click(row.take)
			break
	check(not core_id.is_empty() and battle.session.inventory.contains(core_id), "Actual TAKE button puts the same physical core in carried inventory")
	await _click(presentation.panel.find_child("CloseCache",true,false))
	check(director.stage == director.Stage.TERMINAL, "Recovered salvage unlocks terminal lesson")
	for at in [Vector3(-16,0,26),Vector3(-16,0,24.7)]:
		if not await _walk(at): _finish(); return
	_release(); await _tap("interact")
	var door = battle.area_root.find_child("SouthAccessDoor",true,false)
	check(door.is_open(), "Authored south office door opened through ordinary interaction")
	for at in [Vector3(-16,0,21.5),Vector3(-19.5,0,21),Vector3(-19.5,0,13.1)]:
		if not await _walk(at): _finish(); return
	_release(); await _tap("interact")
	for tick in 720:
		await tree.physics_frame
		if director.stage == director.Stage.CHOICE or battle.player.is_dead: break
	check(director.stage == director.Stage.CHOICE and battle.session.is_mission_completed(), "Actual uninterrupted 8-second investigation creates route choice")
	await _capture("12_real_choice")
	if not failures.is_empty(): _finish(); return
	await _click(_button("CONTINUE / SALVAGE" if salvage else "EXTRACT / KEEP CARGO"))
	check(director.stage == (director.Stage.SALVAGE if salvage else director.Stage.EXTRACT), "Real route button selects the requested risk")
	for at in [Vector3(-19.5,0,21),Vector3(-16,0,21.5),Vector3(-16,0,26)]:
		if not await _walk(at): _finish(); return
	if salvage:
		for at in [Vector3(4,0,26),Vector3(4,0,-2),Vector3(7,0,-2)]:
			if not await _walk(at): _finish(); return
		_release(); await _tap("interact"); await _frames()
		check(is_instance_valid(presentation.panel), "Risk branch actually reaches and opens north cache")
		if not is_instance_valid(presentation.panel): _finish(); return
		var extra_ids: Array[String] = []
		for index in 2:
			if presentation._cache_rows.is_empty(): break
			var row: Dictionary = presentation._cache_rows[0]
			extra_ids.append(row.pickup.item_instance.instance_id)
			await _click(row.take)
		check(extra_ids.size() == 2 and extra_ids.all(func(id): return battle.session.inventory.contains(id)), "Risk branch recovers two physical extra cores through actual TAKE buttons")
		evidence["extra_core_ids"] = extra_ids
		await _capture("12b_risk_cache")
		await _click(presentation.panel.find_child("CloseCache",true,false))
		check(director.stage == director.Stage.EXTRACT, "North salvage genuinely redirects the tutorial home")
		for at in [Vector3(4,0,-2),Vector3(4,0,26)]:
			if not await _walk(at): _finish(); return
	for at in [Vector3(2.5,0,32)]:
		if not await _walk(at): _finish(); return
	_release(); await _tap("interact")
	var beacon = battle.area_root.find_child("ExtractionPoint",true,false)
	check(beacon.extraction_remaining > 0, "Real interact input starts 8-second defended extraction")
	await _capture("13_defend_return")
	for tick in 720:
		await tree.physics_frame
		if battle.ending: break
		_controls(battle.player.global_position)
	_release()
	evidence["completed_health"] = battle.player.health
	evidence["defeated"] = battle.session.enemies_defeated
	evidence["real_shots"] = shots
	check(battle.session.status == SortieSession.Status.COMPLETED and battle.session.is_mission_completed(), "Actual mission and defended extraction completed with normal losses")
	if not await _wait_scene("res://scenes/result/result.tscn"): failures.append("No normal debrief"); _finish(); return
	await _capture("14_debrief")
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): failures.append("Return did not reach base"); _finish(); return
	var profile := ProfileRuntime.get_profile()
	check(profile.first_mission_completed and profile.successful_sorties == 1 and profile.inventory.contains(core_id), "Normal debrief commits first mission, survival count and recovered core")
	await _click(tree.current_scene.find_child("NavWorkshop",true,false))
	await _capture("15_first_upgrade_offer")
	var before_cost := FirstMissionPreparation.salvage_count(profile)
	check(before_cost == (3 if salvage else 1), "Returned warehouse contains exactly the selected route's physical cores")
	await _click(_button("UPGRADE AR / 1 SALVAGE CORE"))
	check(profile.ar_damage_upgraded and FirstMissionPreparation.salvage_count(profile) == before_cost - 1, "Real workshop button saves upgrade and consumes exactly one recovered core")
	if not await _wait_scene("res://scenes/presentation/slice/workshop_moment.tscn"): failures.append("Saved upgrade did not reach homecoming fitting"); _finish(); return
	var fitting = tree.current_scene
	var after_upgrade := JSON.stringify(profile.to_dict())
	for tick in 1800:
		await tree.physics_frame
		if fitting.phase == "choice": break
	check(fitting.phase == "choice", "Actual approach and radio exchange reach spare-screw choice")
	await _capture("15b_spare_screw_choice")
	if fitting.phase != "choice": _finish(); return
	await _click(fitting.choices.get_node("ChoiceTidy" if salvage else "ChoiceTap"))
	for tick in 1200:
		await tree.physics_frame
		if fitting.phase == "done": break
	check(fitting.phase == "done" and fitting.branch == ("tidy" if salvage else "tap"), "Selected gesture and real workbench fitting reach homecoming ending")
	check(JSON.stringify(profile.to_dict()) == after_upgrade, "Homecoming choice grants no inventory, flags or rewards")
	evidence["fitting_branch"] = fitting.branch
	evidence["profile_unchanged_by_fitting"] = JSON.stringify(profile.to_dict()) == after_upgrade
	await _capture("15c_fitting_complete")
	await _click(fitting.exits.get_node("NextRequest"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): failures.append("Fitting did not return to normal base"); _finish(); return
	check(tree.current_scene.section == "Operations", "Next-request exit opens ordinary operations without accepting a contract")
	evidence["fitting_exit_section"] = tree.current_scene.section
	evidence["route"] = "salvage" if salvage else "return"
	evidence["final_profile"] = {"credits":profile.credits,"successful_sorties":profile.successful_sorties,"first_mission_completed":profile.first_mission_completed,"ar_damage_upgraded":profile.ar_damage_upgraded}
	await _capture("16_loop_complete")
	_finish()

func _tap(action: String) -> void:
	for pressed in [true,false]:
		var event := InputEventAction.new(); event.action = action; event.pressed = pressed
		Input.parse_input_event(event)
		await tree.physics_frame
	await _frames()

func _axis(negative: String, positive: String, value: float) -> void:
	if value < -.01: Input.action_press(negative,-value)
	elif value > .01: Input.action_press(positive,value)

func _controls(destination: Vector3) -> void:
	_release()
	var player: PlayerController = battle.player
	var gap := destination-player.global_position; gap.y = 0
	var motion := gap.normalized() if gap.length()>.25 else Vector3.ZERO
	_axis("move_left","move_right",motion.x); _axis("move_forward","move_back",motion.z)
	var aim := motion if motion != Vector3.ZERO else player.aim_direction
	if battle.player_visibility.heard_remaining > 0: aim = battle.player_visibility.heard_direction
	var nearest: EnemyController
	var distance := 28.0
	for candidate in battle.enemy_container.get_children():
		if not candidate is EnemyController or candidate.is_dead or not battle.player_visibility.can_see_enemy(candidate): continue
		var separation := player.global_position.distance_to(candidate.global_position)
		if separation >= distance: continue
		var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.25,candidate.global_position+Vector3.UP*1.25,6)
		query.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider == candidate: nearest = candidate; distance = separation
	if nearest:
		aim = player.global_position.direction_to(nearest.global_position); aim.y = 0; aim = aim.normalized()
		Input.action_press("fire")
	_axis("aim_left","aim_right",aim.x); _axis("aim_up","aim_down",aim.z)
	if int(player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY).get("magazine",0)) == 0 and player.can_reload():
		# Dispatch the normal action, never refill inventory or call session reload.
		var event := InputEventAction.new(); event.action = "reload"; event.pressed = true
		Input.parse_input_event(event)
		event = InputEventAction.new(); event.action = "reload"; event.pressed = false
		Input.parse_input_event(event)

func _walk(at: Vector3, tolerance := .4) -> bool:
	for tick in 1800:
		await tree.physics_frame
		if battle.player.is_dead: failures.append("Died walking to " + str(at)); return false
		var gap: Vector3 = at-battle.player.global_position; gap.y = 0
		if gap.length() < tolerance: _release(); return true
		_controls(at)
	failures.append("Walking stuck at %s toward %s" % [battle.player.global_position,at])
	return false

func _capture(name: String) -> void:
	await super._capture(name)
	var progress := ""
	if is_instance_valid(battle): progress = " health=%s shots=%d kills=%d" % [battle.player.health,shots,battle.session.enemies_defeated]
	print("FIRST_SORTIE_RUN reached ",name,progress)
