extends Node
var failures: Array[String] = []
var save_path := "user://first_mission_test_%s.json" % OS.get_process_id()

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	ProfileRuntime.new_profile()
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	get_tree().root.add_child(hideout)
	get_tree().current_scene = hideout
	await _capture("base")
	_button(hideout.screen, "SELECT BUNNY").pressed.emit()
	check(ProfileRuntime.get_profile().bunny_selected, "Base button selects Bunny")
	_button(hideout.screen, "SELECT AR + SMG").pressed.emit()
	check(FirstMissionPreparation.has_starter_kit(ProfileRuntime.get_profile()), "Base button selects starter kit")
	hideout.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	var legacy := ProfileState.create_new().to_dict()
	for key in ["bunny_selected", "first_mission_completed", "ar_damage_upgraded"]: legacy.erase(key)
	check(not ProfileState.from_dict(legacy).first_mission_completed, "Old saves receive First Mission without losing inventory")
	legacy["field_pack_upgraded"] = true
	check(ProfileState.from_dict(legacy).ar_damage_upgraded, "Previously purchased pack upgrade migrates to AR upgrade without a second charge")
	for bonus in [false, true]:
		var profile := ProfileRuntime.new_profile()
		profile.bunny_selected = true
		FirstMissionPreparation.equip_starter_kit(profile)
		check(FirstMissionPreparation.has_starter_kit(profile), "Starter kit equips AR and SMG")
		var plan := DeploymentPlan.build(profile)
		var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area", &"first_mission", plan.ammo_ids), profile)
		check(session != null, "First Mission is registered and deployable")
		var battle = load("res://scenes/battle/battle.tscn").instantiate()
		get_tree().root.add_child(battle)
		get_tree().current_scene = battle
		battle.result_transition_enabled = false
		battle.player.set_physics_process(false)
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("training")
		var director = battle.get_node("FirstMissionDirector")
		var terminal = battle.area_root.find_child("PrototypeTerminal", true, false)
		var extraction = battle.area_root.find_child("ExtractionPoint", true, false)
		var patrol_case = battle.area_root.find_child("PatrolSalvage", true, false)
		var high_case = battle.area_root.find_child("HighValueLootSpawn", true, false)
		check(not director.patrol.is_physics_processing() and not patrol_case.visible and not high_case.visible, "Training starts safely with no visible supplies or active PMC")
		check(not extraction.can_extract(session), "Cannot skip mission from the spawn beacon")
		check(not terminal.interact(battle.player, session).success, "Cannot investigate before training")
		director.set_process(false)
		battle.player.global_position += Vector3(4,0,0)
		director._process(0.1)
		check(director.stage == director.Stage.AIM, "Actual travel advances movement training")
		battle.player.aim_direction = -director.start_aim
		director._process(0.1)
		check(director.stage == director.Stage.FIRE, "Aim change advances aiming training")
		check(session.fire_weapon(battle.player.weapon_instance.instance_id), "Training shot consumes real ammo")
		battle.player.weapon_fired.emit(0.1)
		director._process(0.1)
		check(director.stage == director.Stage.PMC and director.patrol.is_physics_processing(), "Real shot activates first PMC")
		director.patrol._die(Vector3.ZERO)
		check(director.stage == director.Stage.RELOAD and patrol_case.visible, "PMC death reveals guaranteed upgrade material")
		check(battle.player.reload_weapon(), "Reload uses real reserve ammunition")
		director._process(0.1)
		battle.player._reload_remaining_by_weapon[battle.player.weapon_instance.instance_id] = 0.0
		director._process(0.1)
		check(director.stage == director.Stage.LOOT, "Finished reload advances to search tutorial")
		for pickup in patrol_case.get_children():
			if pickup is LootPickup: check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "Patrol material enters carried inventory")
		director._process(0.1)
		check(director.stage == director.Stage.TERMINAL, "Taking salvage unlocks investigation")
		battle.player.global_position = terminal.global_position
		check(terminal.interact(battle.player, session).success, "Investigation starts at terminal")
		battle.player.global_position += Vector3(4,0,0)
		terminal._process(0.1)
		check(terminal.investigation_remaining == 0.0 and not session.is_mission_completed(), "Walking away cancels investigation")
		battle.player.global_position = terminal.global_position
		terminal.interact(battle.player, session)
		terminal._process(8.1)
		check(session.is_mission_completed() and director.stage == director.Stage.CHOICE, "Investigation completes and exposes risk choice")
		check(high_case.visible and extraction.can_extract(session), "Both routes are available after the alarm")
		await _capture("choice")
		director.choose_route(bonus)
		director._process(12.1)
		check(session.threat_level == SortieSession.ThreatLevel.ALERT and battle.enemies_remaining == 3, "Alarm activates exactly one PMC response group")
		director._process(20.0)
		check(battle.enemies_remaining == 3, "Alarm never duplicates the wave")
		if bonus:
			for pickup in high_case.get_children():
				if pickup is LootPickup: pickup.try_pickup(session)
			director._process(0.1)
			check(director.stage == director.Stage.EXTRACT, "Optional salvage redirects player home")
		battle.player.global_position = extraction.global_position
		extraction.interact(battle.player, session)
		battle.player.global_position += Vector3(4,0,0)
		extraction._process(0.1)
		check(session.status == SortieSession.Status.ACTIVE and extraction.extraction_remaining == 0, "Leaving beacon cancels extraction")
		battle.player.global_position = extraction.global_position
		extraction.interact(battle.player, session)
		extraction._process(8.1)
		check(session.status == SortieSession.Status.COMPLETED, "Defending beacon completes extraction")
		check(SortieRuntime.finalize_sortie("user://missing_first_mission_dir/save.json") != OK and not profile.first_mission_completed, "Failed settlement save does not publish first completion")
		battle.queue_free()
		get_tree().current_scene = null
		await get_tree().process_frame
		var result = load("res://scenes/result/result.tscn").instantiate()
		result.finalize_save_path = save_path
		get_tree().root.add_child(result)
		get_tree().current_scene = result
		await _capture("debrief")
		result.result_ui.return_button.pressed.emit()
		await get_tree().create_timer(1.5).timeout
		var workshop = get_tree().current_scene
		check(workshop.scene_file_path == "res://scenes/presentation/slice/hideout.tscn" and workshop.section == "Workshop", "Real debrief return saves and opens Workshop")
		check(SortieRuntime.get_current_session() == null, "Extraction persists settlement")
		var expected := 3 if bonus else 1
		check(profile.first_mission_completed and FirstMissionPreparation.salvage_count(profile) == expected, "Chosen route transfers exact material count to warehouse")
		check(SortieRuntime.finalize_sortie(save_path) == OK and FirstMissionPreparation.salvage_count(profile) == expected, "Retry does not duplicate recovered material")
		check(FirstMissionPreparation.upgrade_weapon("user://missing_first_mission_dir/save.json") != OK and not profile.ar_damage_upgraded and FirstMissionPreparation.salvage_count(profile) == expected, "Failed upgrade save preserves materials")
		check(FirstMissionPreparation.upgrade_weapon(save_path) == OK, "Workshop consumes one core and saves upgrade")
		check(profile.ar_damage_upgraded and FirstMissionPreparation.salvage_count(profile) == expected-1, "Upgrade has exact cost")
		check(FirstMissionPreparation.upgrade_weapon(save_path) == ERR_UNAVAILABLE, "Upgrade cannot charge twice")
		var restored := SaveService.load_profile(save_path, false)
		check(restored.ar_damage_upgraded and restored.first_mission_completed and restored.bunny_selected, "Progress survives profile reload")
		workshop.show_section("Workshop")
		check(_button(workshop.screen, "SECOND SORTIE / LOADOUT") != null, "Workshop exposes second sortie after upgrade")
		await _capture("workshop")
		for armor in profile.inventory.get_items():
			if armor.definition_id == &"armor.bulwark_plate_01":
				workshop.hanger._on_armor_selected(armor.instance_id)
		workshop.show_section("Hanger")
		check(workshop.hanger.hanger_ui.armor_detail.text.contains("40%"), "Selecting Heavy Armor refreshes real loadout protection")
		await _capture("loadout")
		for button in workshop.hanger.hanger_ui.find_children("*", "Button", true, false):
			if button.text == "MISSION TERMINAL":
				check(button.get_global_rect().end.y < 644.0, "Equipment details keep mission button above hub navigation")
		var next := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
		check(next.inventory.capacity == 100.0, "Single weapon upgrade leaves carried capacity at 100kg")
		check(is_equal_approx(next.get_weapon_damage(ContentDB.get_weapon(&"weapon.assault_rifle_01")), 22.0), "Next sortie AR damage increases from 20 to 22")
		check(is_equal_approx(next.get_weapon_damage(ContentDB.get_weapon(&"weapon.smg_01")), ContentDB.get_weapon(&"weapon.smg_01").damage), "SMG damage remains unchanged")
		check(ContentDB.get_weapon(&"weapon.assault_rifle_01").damage == 20.0, "Shared weapon definition remains at base damage")
		await _test_upgraded_hit(next)
		workshop.queue_free()
		get_tree().current_scene = null
		await get_tree().process_frame
	# Failure must leave the first mission available.
	var retry_profile := ProfileRuntime.new_profile()
	var retry_session := SortieRuntime.start_sortie(retry_profile.create_sortie_request(&"first_mission_area", &"first_mission"), retry_profile)
	retry_session.fail()
	check(SortieRuntime.finalize_sortie(save_path) == OK and not retry_profile.first_mission_completed, "Death does not skip first mission")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.15).timeout
	print("FIRST_MISSION_TEST %s" % ("PASS" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
	else: print("PASS / ", message)

func _button(root: Node, text: String) -> Button:
	for candidate in root.find_children("*", "Button", true, false):
		if candidate.text == text: return candidate
	return null

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().create_timer(0.75).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/first_mission_%s.png" % label)

func _test_upgraded_hit(session: SortieSession) -> void:
	check(session.activate(), "Upgraded next sortie activates")
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	shooter.configure_sortie(session)
	add_child(shooter)
	var enemy := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_basic_enemy"), Transform3D(Basis.IDENTITY, Vector3(100,0,-8)), self)
	enemy.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var before := enemy.health
	shooter._fire_hitscan(Vector3(100,1,0), Vector3.FORWARD)
	check(is_equal_approx(before - enemy.health, 22.0), "Actual AR hitscan delivers 22 damage after upgrade")
	check(shooter.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY).display_name.contains("+10% DMG"), "Battle HUD marks upgraded AR")
	shooter.preview_mode = false
	check(shooter.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "Upgraded player switches to SMG")
	before = enemy.health
	shooter._fire_hitscan(Vector3(100,1,0), Vector3.FORWARD)
	check(is_equal_approx(before - enemy.health, ContentDB.get_weapon(&"weapon.smg_01").damage), "Switching to SMG does not inherit AR damage bonus")
	enemy.queue_free()
	shooter.queue_free()
	await get_tree().process_frame
