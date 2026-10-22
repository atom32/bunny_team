extends "res://tests/campus_chapter_run.gd"
## Actual earned Q02 save, ordinary relay sortie. No seeded layout, placements,
## direct damage, free supplies, disabled AI or forced focus/pause recovery.
var diversion_used := false

func _capture(name: String) -> void:
	if name == "05_relay_debrief":
		var ui := tree.current_scene.result_ui as ResultUI
		var profile_before := ProfileRuntime.get_profile().to_dict()
		var outcome_before := ui.outcome.to_dict()
		var primary := SortieGuidance.debrief(ui.outcome)
		check(not ui.outcome.mission_completed and ui.outcome.campus.relays.size() == 2 and not ui.outcome.campus.recorder_instance.is_empty(), "actual outing has returned story work but not the selected optional records objective")
		check(not primary.is_empty() and ui.find_child("ReturnFacts", true, false).text.contains(primary[1]), "real debrief displays the actual story return separately")
		check(ui.find_child("ReturnFacts", true, false).size.x <= 361, "actual story facts wrap inside their left column rather than across the character")
		check(ui.mission_completion_label.text == tr("OPTIONAL OPERATION NOT COMPLETED") and ui.find_child("ObjectiveHeading", true, false).text == tr("OPTIONAL OBJECTIVES"), "real debrief does not mistake optional records for failed story work")
		check(not ProfileRuntime.get_profile().campus_chapter.relays_returned and not ProfileRuntime.get_profile().campus_chapter.recorder_returned, "actual story credit still waits for Return to Base")
		check(ProfileRuntime.get_profile().to_dict() == profile_before and ui.outcome.to_dict() == outcome_before, "viewing debrief does not complete optional objectives or mutate rewards")
		evidence["debrief"] = {"primary":primary, "optional_verdict":ui.mission_completion_label.text, "optional_completed":ui.outcome.mission_completed, "optional_rows":ui.objective_labels.size(), "progress_pending_return":true}
	await super._capture(name)

func _run() -> void:
	if "--resume-pa" in OS.get_cmdline_user_args():
		await _resume_pa(); _finish(); return
	if "--read-relay" not in OS.get_cmdline_user_args():
		await super._run(); return
	tree = get_tree(); tree.current_scene = null
	var profile := ProfileRuntime.get_profile()
	var before := profile.to_dict()
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn"); await _frames(10)
	if tree.current_scene.opening: await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): _finish(); return
	check(profile.successful_sorties == _expected_returns(4) and profile.campus_chapter.relays_returned and profile.campus_chapter.recorder_returned and not profile.campus_chapter.power_returned and profile.sortie_checkpoint.is_empty(), "independent ordinary BOOT retains actual fourth return and next power operation")
	for key in ["inventory", "credits", "successful_sorties", "campus_chapter"]:
		check(profile.to_dict()[key] == before[key], "read-only continuation adds no reward or progress: " + key)
	evidence["profile_before"] = before; evidence["profile_after"] = profile.to_dict()
	_finish()

func _resume_pa() -> void:
	tree = get_tree(); tree.current_scene = null
	var profile := ProfileRuntime.get_profile()
	var saved: Dictionary = profile.sortie_checkpoint
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.successful_sorties == _expected_returns(3) and saved.get("phase") == "battle", "resume uses the actual failed third-return checkpoint, not a fresh layout")
	check(saved.get("world", {}).get("map_revision") == 7 and saved.get("session", {}).get("campus", {}).get("relays") == ["relay_office"], "saved outing already has office repair but still needs PA approach and west repair")
	if not failures.is_empty(): return
	starting_stage = "relay"
	evidence["method"] = "Unedited actual failed exported PA checkpoint; ordinary BOOT/RESUME, normal combat controls, actual E, work and extraction. No world relocation, grants, disabled AI, collision or forced focus/pause. Not human timing."
	evidence["stage_before"] = starting_stage; evidence["profile_before"] = profile.to_dict()
	evidence["input_sha256"] = FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn"); await _frames(10)
	if tree.current_scene.opening: await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("RESUME SORTIE"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"): return
	battle = tree.current_scene
	battle.player.weapon_fired.connect(func(_r: float): shots += 1)
	var blocker: EnemyController
	for enemy in battle.enemy_container.get_children():
		if enemy.get_meta("spawn_key", "") == "CampusInfected10": blocker = enemy; break
	check(blocker != null and not blocker.is_dead and is_equal_approx(blocker.health, 45.0), "real blocking infected is restored alive at its original health")
	if blocker == null: return
	evidence["resume_blocker_before"] = {"key":"CampusInfected10", "health":blocker.health, "enemy_position":str(blocker.position), "player_position":str(battle.player.position)}
	var blocker_death := []
	blocker.died.connect(func(_enemy: EnemyController): blocker_death.append(true))
	for tick in 120:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(battle.area_root.get_node("StreetNavigation").get_navigation_map()) > 0: break
	var repair := battle.area_root.get_node("CampusRelayRepair") as CampusAction
	if not await _walk(repair.global_position, 2.2) or not await _work(repair): return
	check(blocker_death == [true], "unchanged ordinary combat controls defeat the actual body-blocking infected during the approach")
	evidence["resume_blocker_defeated"] = blocker_death == [true]
	var recorder := battle.area_root.get_node("ExperimentRecorder") as CampusAction
	if not await _walk(recorder.global_position, 2.2): return
	_release(); await _frames(); await _tap("interact")
	check(not battle.session.campus.recorder_instance.is_empty() and battle.session.inventory.contains(battle.session.campus.recorder_instance), "resumed real E takes the recorder after both actual repairs")
	var retreat: ExtractionPoint
	for i in 4:
		var exit := battle.area_root.get_node("Exit%d" % i) as ExtractionPoint
		if exit.available and exit.required_objective_id.is_empty(): retreat = exit
	if not await _walk(retreat.global_position, .4): return
	_release(); await _frames(); await _tap("interact")
	check(battle.session.status == SortieSession.Status.COMPLETED, "resumed ordinary exit interaction safely ends the original outing")
	evidence["shots"] = shots; evidence["health"] = battle.player.health; evidence["kills"] = battle.session.enemies_defeated
	if not await _wait_scene("res://scenes/result/result.tscn"): return
	await _capture("05_relay_debrief")
	await _click(tree.current_scene.find_child("ReturnButton", true, false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): return
	check(profile.successful_sorties == _expected_returns(4) and profile.campus_chapter.relays_returned and profile.campus_chapter.recorder_returned and not profile.campus_chapter.power_returned and profile.sortie_checkpoint.is_empty(), "original failed outing now earns exactly one safe fourth return, not a duplicated payout")
	await _click(tree.current_scene.find_child("NavOperations", true, false))
	await _capture("06_relay_returned")
	evidence["stage_after"] = CampusChapter.stage(profile.campus_chapter); evidence["profile_after"] = profile.to_dict()

func _walk(at: Vector3, tolerance := .4) -> bool:
	var pa := battle.area_root.get_node_or_null("CampusRelayDiversion") as CampusRelayDiversion
	var repair := battle.area_root.get_node_or_null("CampusRelayRepair") as CampusAction
	if not diversion_used and pa and repair and at.distance_to(repair.global_position) < 1:
		if not await super._walk(pa.global_position + Vector3(0,0,1), .6): return false
		_release()
		battle.player.interaction_component._physics_process(0)
		check(battle.player.interaction_component._current_target == pa, "ordinary approach selects the west PA switch")
		if battle.player.interaction_component._current_target != pa: return false
		await _tap("interact")
		check(pa.phase==CampusRelayDiversion.Phase.PLAYING, "actual interact input starts optional remote sound during earned relay sortie")
		if pa.phase != CampusRelayDiversion.Phase.PLAYING: return false
		diversion_used = true
		var heard := []
		var origin:Vector3 = pa.get_node("Speaker").global_position
		for enemy in battle.enemy_container.get_children():
			if enemy is EnemyController and not enemy.is_dead and enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and enemy.awareness.last_known.distance_to(origin) < .1:
				heard.append(String(enemy.get_meta("spawn_key", "")))
		evidence["pa_activation"] = {"map":int(battle.area_root.get_meta("map_revision")),"position":str(battle.player.position),"sound_origin":str(origin),"ordinary_listeners":heard,"health":battle.player.health,"relays_before":battle.session.campus.relays.duplicate(),"no_new_reward":true}
		await _capture("03_west_pa_active")
	return await super._walk(at, tolerance)

func _finish() -> void:
	evidence["language"]=TranslationServer.get_locale()
	if "--english" in OS.get_cmdline_user_args():check(TranslationServer.get_locale()=="en","post-BOOT earned route actually uses English")
	if "--read-complete" not in OS.get_cmdline_user_args() and "--read-relay" not in OS.get_cmdline_user_args():
		check(diversion_used, "earned route must actually use PA, repair relays and return; no partial-run PASS")
		check(evidence.has("profile_after") and evidence.get("stage_after") == "power", "earned route must record its actual final safe return, including resumed runs")
	evidence["pa_route_scope"] = "Ordinary actual earned relay outing; PA is optional in production. Precise generated controls, not a human playtime or difficulty test."
	super._finish()
