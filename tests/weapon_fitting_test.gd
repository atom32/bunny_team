extends Node3D
const PATH := "user://fittings_test.json"
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		var profile := SaveService.load_profile(PATH,false)
		check(profile != null, "second process loads real saved profile")
		if profile:
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://fittings_expected.json"))
			check(profile.to_dict() == ProfileState.from_dict(expected).to_dict(), "second process retains exact inventory IDs, materials, wallet, loadout and fitting")
			check(profile.inventory.get_item(primary(profile)).fitting == "quickloader", "installed fitting survives process termination")
	else:
		_schema()
		_transactions()
		await _runtime()
		await _ui()
		var file := FileAccess.open("user://fittings_expected.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(ProfileRuntime.get_profile().to_dict()));file.close()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("FITTINGS: " + failure)
	print("WEAPON_FITTING_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func fresh() -> ProfileState:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	profile.campaign.stage = 3
	for id in [&"material.parts", &"material.wiring", &"material.fabric"]:
		profile.inventory.add_item(ItemInstance.new(id, 12))
	return profile

func primary(profile: ProfileState) -> String:
	return profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)

func _schema() -> void:
	var gun := ItemInstance.new(&"weapon.assault_rifle_01")
	var old := gun.to_dict(); old.erase("fitting")
	check(ItemInstance.from_dict(old).fitting == "", "old save defaults to standard without granting equipment")
	for value in [null, 2, [], "unknown"]:
		var raw := gun.to_dict();raw.fitting = value
		check(ItemInstance.from_dict(raw) == null, "invalid serialized fitting rejected")
	for id in [&"ammo.556_standard", &"medical.medkit", &"weapon.rocket_launcher_01", &"weapon.shotgun_01"]:
		var wrong := ItemInstance.new(id);wrong.fitting = "suppressor"
		check(ItemInstance.from_dict(wrong.to_dict()) == null and not InventoryState.new(999).add_item(wrong), "incompatible fit rejected in load and inventory: " + String(id))
	for id in ["quickloader", "suppressor"]:
		gun.fitting = id
		check(ItemInstance.from_dict(gun.to_dict()).to_dict() == gun.to_dict(), "instance identity and fitting roundtrip")
		var tight := InventoryState.new(ContentDB.get_item(gun.definition_id).weight)
		check(not tight.add_item(gun), "extra fitting weight cannot bypass capacity")
	check(WeaponFitting.reload_factor(null) == 1 and WeaponFitting.noise_factor(null) == 1, "debug/legacy standard definition unchanged")

func _transactions() -> void:
	var profile := fresh()
	var id := primary(profile)
	profile.campaign.stage = 2
	check(WeaponFitting.prepare(profile,id,"quickloader").error != OK, "bench unlock enforced by service")
	profile.campaign.stage = 3
	var before := profile.to_dict()
	check(WeaponFitting.install(id,"quickloader","user://missing_fittings_dir/save.json").error != OK and profile.to_dict() == before, "failed save consumes nothing")
	var weight := profile.inventory.current_weight
	var cost_weight := ContentDB.get_item(&"material.parts").weight * 2 + ContentDB.get_item(&"material.wiring").weight
	check(WeaponFitting.install(id,"quickloader",PATH).error == OK, "paid installed fitting persisted")
	check(profile.inventory.get_item(id).fitting == "quickloader" and primary(profile) == id and profile.credits == int(before.credits)-120, "exact original weapon and loadout identity preserved, exact credits paid")
	check(SupplyService.count(profile,&"material.parts") == 10 and SupplyService.count(profile,&"material.wiring") == 11, "exact materials consumed")
	check(is_equal_approx(profile.inventory.current_weight,weight-cost_weight+.8), "warehouse includes fitting mass")
	check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "real disk save preserves fitting")
	before = profile.to_dict()
	check(WeaponFitting.install(id,"quickloader",PATH).error != OK and profile.to_dict() == before, "duplicate click cannot consume twice")
	check(WeaponFitting.install(id,"suppressor",PATH).error == OK and profile.inventory.get_item(id).fitting == "suppressor", "replacement actually swaps utility choice")
	var credits := profile.credits
	check(WeaponFitting.install(id,"",PATH).error == OK and profile.credits == credits, "removal no refund/material exploit")
	check(profile.inventory.get_item(id).fitting.is_empty(), "removal restores standard effects")
	WeaponFitting.install(id,"quickloader",PATH)
	var plan := DeploymentPlan.build(profile)
	var session: SortieSession = DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).get("session")
	check(session != null and session.inventory.get_item(id).fitting == "quickloader", "deployment carries modified instance")
	check(is_equal_approx(session.inventory.current_weight,plan.weight), "packing and actual carried inventory agree including loaded rounds")
	check(WeaponFitting.install(id,"",PATH).error == ERR_BUSY, "cannot remove fitting while deployed")
	var restored := SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session))
	check(restored != null and restored.inventory.get_item(id).fitting == "quickloader" and is_equal_approx(restored.inventory.current_weight,session.inventory.current_weight), "checkpoint session restores fitting, identity and loaded-round weight")
	check(session.complete_extraction() and SortieRuntime.finalize_sortie(PATH) == OK, "modified weapon returns through actual result commit")
	check(profile.inventory.get_item(id).fitting == "quickloader", "extraction retains fitting")
	session = SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon"),profile)
	check(session.fail() and SortieRuntime.finalize_sortie(PATH) == OK, "normal failed result commit")
	check(not profile.inventory.contains(id), "death loses fitting with weapon, no permanent profile bonus")

func _runtime() -> void:
	var profile := fresh()
	var id := primary(profile)
	WeaponFitting.install(id,"quickloader",PATH)
	var plan := DeploymentPlan.build(profile)
	var session: SortieSession = DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).get("session")
	var player := PlayerController.new()
	player.configure_sortie(session)
	add_child(player)
	player.set_physics_process(false)
	await get_tree().physics_frame
	var gun := player.weapon_instance
	var definition := player.weapon_data
	var base_reload := definition.reload_seconds
	var base_spread := definition.spread_degrees
	gun.fitting = ""
	seed(722)
	var bare: Vector3 = player._spread_direction(Vector3.FORWARD,0)
	gun.fitting = "quickloader"
	seed(722)
	var stabilized: Vector3 = player._spread_direction(Vector3.FORWARD,0)
	check(stabilized == bare, "quickloader does not silently change ballistics")
	check(player.debug_fire_once(), "modified weapon fires through real player contract")
	check(player.reload_weapon(), "modified weapon can reload")
	check(is_equal_approx(player.get_reload_remaining(),base_reload*.8) and is_equal_approx(player.combat_rig.reload_duration,base_reload*.8), "runtime and animation use same shorter reload duration")
	check(definition.reload_seconds == base_reload and definition.spread_degrees == base_spread, "shared weapon resource never mutated")
	# Advance the real reload presentation; clearing only gameplay timer would
	# incorrectly leave the rig reloading and block every subsequent shot.
	for frame in 150: player._physics_process(1.0/60.0)
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	check(not player.combat_rig.is_reloading() and player.get_reload_remaining() == 0, "actual player ticks complete both reload timers")
	gun.fitting = "suppressor"
	seed(722)
	var suppressed: Vector3 = player._spread_direction(Vector3.FORWARD,0)
	check(suppressed == bare, "suppressor does not silently change ballistics")
	# Real hearing boundary, not just scalar comparison. Enemy receives sound only.
	var enemy := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_heavy_enemy"),Transform3D(Basis.IDENTITY,Vector3(30,0,0)),self)
	enemy.set_physics_process(false)
	await get_tree().physics_frame
	enemy.set_physics_process(true)
	enemy.awareness.state = EnemyAwareness.State.PATROL
	player._reload_remaining_by_weapon.clear()
	check(player.debug_fire_once(), "suppressed shot fires")
	check(player.reload_weapon() and is_equal_approx(player.get_reload_remaining(),base_reload*1.15), "suppressor has actual slower reload tradeoff")
	for frame in 150: player._physics_process(1.0/60.0)
	player.position = Vector3.ZERO;player.velocity = Vector3.ZERO
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "actual suppressed shot does not alert enemy outside reduced radius")
	gun.fitting = ""
	check(player.debug_fire_once(), "standard shot fires")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE, "same enemy hears standard shot at same distance")
	enemy.free()
	player.free()
	SortieRuntime.clear_session()

func _ui() -> void:
	var profile := fresh()
	var id := primary(profile)
	var panel := SupplyPanel.new()
	panel.save_path = PATH
	panel.position = Vector2(42,148)
	panel.size = Vector2(800,474)
	panel.selected_tab = 3
	add_child(panel)
	await get_tree().process_frame
	var button := panel.find_child("Fit_"+id,true,false) as Button
	check(button != null and button.disabled, "real workshop exposes eligible owned weapon, standard no-op disabled")
	if button:
		var choice := button.get_parent().get_child(0) as OptionButton
		choice.selected = 1
		choice.item_selected.emit(1)
		check(not button.disabled, "owned materials enable selected fitting")
		button.pressed.emit()
		await get_tree().process_frame
		check(profile.inventory.get_item(id).fitting == "quickloader" and SaveService.load_profile(PATH,false).inventory.get_item(id).fitting == "quickloader", "workshop button installs and persists actual instance")
	if "--capture" in OS.get_cmdline_user_args():
		var path := OS.get_environment("BUNNY_EVIDENCE")
		for locale in ["en", "zh_CN"]:
			GameLanguage.set_language(locale,false)
			panel._refresh()
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(path.path_join("fittings_"+locale+".png")) == OK, "rendered actual workshop UI at production panel size")
	panel.free()
