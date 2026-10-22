extends Node3D
## Execute in an isolated project and user:// directory, never against a player profile.
const STANDARD := &"ammo.556_standard"
const AP := &"ammo.556_ap"
const RIFLE := &"weapon.assault_rifle_01"
const PATH := "user://ap_ammo_test.json"
const CROSS := "user://ap_ammo_cross.json"
var checks := 0
var failures: Array[String] = []

class Target extends EnemyController:
	var packets: Array[DamagePacket] = []
	func _build_collision() -> void:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(12, 12, .5)
		shape.shape = box
		add_child(shape)
	func receive_damage(packet: DamagePacket) -> float:
		packets.append(packet)
		return super.receive_damage(packet)

func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		_read_cross_process()
	else:
		await _packing_defaults()
		_stock_cases()
		_shared_rifle_stock()
		_switch_and_conservation()
		_checkpoint_validation()
		await _actual_hits()
		await _settlements()
		_relief_and_crafting()
		_write_cross_process()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error("AP_AMMO: " + failure)
	print("AP_AMMO_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	checks += 1
	print("AP_AMMO %s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures.append(message)

func _fresh(standard: int, ap: int) -> ProfileState:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	for item in profile.inventory.get_items():
		if ContentDB.get_item(item.definition_id).has_tag(&"ammo"): profile.inventory.remove_item(item.instance_id)
	if standard > 0: profile.inventory.add_item(ItemInstance.new(STANDARD, standard))
	if ap > 0: profile.inventory.add_item(ItemInstance.new(AP, ap))
	profile.ammo_pack = {String(STANDARD): standard, String(AP): ap, "ammo.9mm_standard": 0}
	profile.medical_pack = {"medical.field_dressing": 0, "medical.medkit": 0}
	return profile

func _gun(profile: ProfileState) -> String:
	return profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)

func _session(profile: ProfileState) -> SortieSession:
	var ids: Array[String] = []
	for item in profile.inventory.get_items():
		if ContentDB.get_item(item.definition_id).has_tag(&"ammo"): ids.append(item.instance_id)
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", ids), profile)
	check(session != null and session.activate(), "fixture activates through the normal session boundary")
	return session

func _rounds(session: SortieSession, id: StringName) -> int:
	var count := 0
	for item in session.inventory.get_items():
		if item.definition_id == id: count += item.quantity
	for state in session._weapon_runtime_states.values():
		if state.ammo_definition_id == id: count += state.magazine_ammo
	return count

func _drain(session: SortieSession, gun: String) -> void:
	var state = session.get_weapon_runtime_state(gun)
	var count: int = state.magazine_ammo
	var fired := 0
	for index in count:
		if session.fire_weapon(gun): fired += 1
	check(fired == count and state.magazine_ammo == 0, "each successful shot consumes exactly one loaded round")

func _packing_defaults() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.inventory.add_item(ItemInstance.new(AP, 80))
	var before := profile.to_dict()
	var defaults := DeploymentPlan.default_ammo_counts(profile)
	check(defaults.get(String(STANDARD)) == 90 and defaults.get(String(AP)) == 0, "standard keeps three-magazine default; AP is explicitly zero")
	var plan := DeploymentPlan.build(profile)
	var packed_ap := 0
	for id in plan.ammo_ids:
		if profile.inventory.get_item(id).definition_id == AP: packed_ap += int(plan.ammo_quantities[id])
	check(packed_ap == 0 and profile.to_dict() == before, "preview neither packs AP by default nor mutates stock")
	FlowMenu.save_path = PATH
	var panel := MedicalPacking.new()
	add_child(panel)
	await get_tree().process_frame
	var controls := panel.find_children("PackAmmo_ammo_556_ap", "SpinBox", true, false)
	check(controls.size() == 1, "existing packing UI exposes AP without a new UI system")
	if controls.size() == 1:
		controls[0].value = 37
		check(profile.ammo_pack.get(String(AP)) == 37 and SupplyService.count(profile, AP) == 80, "existing quantity control saves preference without consuming stock")
	panel.queue_free()
	await get_tree().process_frame
	before = profile.to_dict()
	check(DeploymentPlan.set_ammo_count(String(AP), 50, "user://missing_ap_directory/profile.json") != OK and profile.to_dict() == before, "failed packing save leaves preference and warehouse unchanged")

func _stock_cases() -> void:
	for spec in [[40, 0, STANDARD, 30], [0, 40, AP, 30], [40, 40, STANDARD, 30], [0, 0, STANDARD, 0]]:
		var profile := _fresh(spec[0], spec[1])
		var before := profile.to_dict()
		var session := _session(profile)
		if not session: continue
		var state = session.get_weapon_runtime_state(_gun(profile))
		check(state.ammo_definition_id == spec[2] and state.magazine_ammo == spec[3], "initial type/count obey stock and standard-first policy: " + str(spec))
		check(_rounds(session, STANDARD) == spec[0] and _rounds(session, AP) == spec[1], "initial loading conserves both types separately")
		var ammo_weight: float = spec[0] * .012 + spec[1] * .014
		var gear_weight := 0.0
		for id in profile.loadout.get_equipped_instance_ids(): gear_weight += profile.inventory.get_item(id).total_weight()
		check(is_equal_approx(session.inventory.current_weight, gear_weight + ammo_weight), "loaded plus reserve weight uses each type's actual mass")
		check(profile.to_dict() == before and session.validate(), "loading preserves warehouse and creates valid runtime")
		if spec[3] == 0:
			check(not session.fire_weapon(_gun(profile)) and session.reload_weapon(_gun(profile)) == 0, "no stock cannot create ammunition")

func _switch_and_conservation() -> void:
	var profile := _fresh(30, 31)
	var session := _session(profile)
	if not session: return
	var gun := _gun(profile)
	var state = session.get_weapon_runtime_state(gun)
	session.fire_weapon(gun)
	var before := SortieCheckpoint.session_data(session)
	check(not session.can_reload_weapon(gun) and session.reload_weapon(gun) == 0, "nonempty standard magazine cannot convert AP stock into standard rounds")
	check(SortieCheckpoint.session_data(session) == before, "rejected type change preserves inventory and magazine")
	_drain(session, gun)
	check(session.get_reserve_ammo(gun) == 31 and session.can_reload_weapon(gun), "empty standard magazine recognizes actual AP reserve")
	var weight := session.inventory.current_weight
	var weapon_object := session.inventory.get_item(gun)
	check(session.reload_weapon(gun) == 30 and state.ammo_definition_id == AP, "empty magazine switches to AP without standard stock")
	check(_rounds(session, STANDARD) == 0 and _rounds(session, AP) == 31 and is_equal_approx(weight, session.inventory.current_weight), "switch preserves quantities and weight")
	check(session.inventory.get_item(gun) == weapon_object, "reload preserves equipped item object identity")
	var pickup = load("res://scenes/world/loot_pickup.tscn").instantiate()
	pickup.item_instance = ItemInstance.new(STANDARD, 9)
	add_child(pickup)
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "real pickup adds standard ammunition to the carried inventory")
	session.fire_weapon(gun)
	check(session.reload_weapon(gun) == 1 and state.ammo_definition_id == AP, "nonempty AP magazine tops up AP even when standard is available")
	check(_rounds(session, AP) == 30 and _rounds(session, STANDARD) == 9, "AP top-up never consumes standard stock")
	_drain(session, gun)
	check(session.reload_weapon(gun) == 9 and state.ammo_definition_id == STANDARD, "empty AP magazine switches back to available standard rounds")
	weight = session.inventory.current_weight
	check(session.fire_weapon(gun) and is_equal_approx(weight - session.inventory.current_weight, .012), "standard shot removes exactly one standard round's mass")
	check(_rounds(session, STANDARD) == 8 and _rounds(session, AP) == 0, "shot/pickup sequence conserves each type")
	# An invalid candidate cannot partially debit stock or change the selected type.
	_drain(session, gun)
	session.inventory.add_item(ItemInstance.new(AP, 4))
	session.inventory.capacity = session.inventory.current_weight - .001
	before = SortieCheckpoint.session_data(session)
	check(session.reload_weapon(gun) == 0 and SortieCheckpoint.session_data(session) == before, "invalid inventory rejects reload without any partial mutation")
	session.inventory.capacity += 1
	check(session.reload_weapon(gun) == 4 and state.ammo_definition_id == AP, "valid retry loads the same untouched AP rounds")

func _shared_rifle_stock() -> void:
	var profile := _fresh(0, 37)
	var spare := ItemInstance.new(RIFLE)
	profile.inventory.add_item(spare)
	profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, spare.instance_id, profile.inventory)
	var defaults := DeploymentPlan.default_ammo_counts(profile)
	check(defaults.get(String(STANDARD)) == 180 and defaults.get(String(AP)) == 0, "two rifles share one standard target and keep AP default zero")
	var session := _session(profile)
	if not session: return
	var total_loaded := 0
	for state in session._weapon_runtime_states.values():
		check(state.ammo_definition_id == AP, "each rifle falls back to actual AP stock")
		total_loaded += state.magazine_ammo
	check(total_loaded == 37 and _rounds(session, AP) == 37, "two magazines consume one shared reserve without duplication")
	profile = _fresh(0, 130)
	session = _session(profile)
	if not session: return
	var gun := _gun(profile)
	for index in 4:
		_drain(session, gun)
		session.reload_weapon(gun)
	check(_rounds(session, AP) == 10 and session.get_weapon_runtime_state(gun).magazine_ammo == 10, "multi-stack AP loading preserves the last ten of one hundred thirty rounds")

func _checkpoint_validation() -> void:
	var profile := _fresh(0, 37)
	var session := _session(profile)
	if not session: return
	var gun := _gun(profile)
	for index in 5: session.fire_weapon(gun)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(SortieCheckpoint.session_data(session)))
	var restored := SortieCheckpoint.restore_session(raw)
	check(restored != null, "AP session restores through JSON checkpoint")
	if restored:
		var state = restored.get_weapon_runtime_state(gun)
		check(state.ammo_definition_id == AP and state.magazine_ammo == 25 and _rounds(restored, AP) == 32, "restore retains saved type/count without reloading free rounds")
		check(is_equal_approx(restored.inventory.current_weight, session.inventory.current_weight), "restore recomputes AP magazine weight")
	var before := session.inventory.to_dict()
	for corrupt in [{"ammo":"ammo.9mm_standard"}, {"ammo":"unknown"}, {"ammo":12}, {"capacity":31}, {"capacity":true}, {"rounds":31}, {"rounds":-1}, {"rounds":.5}]:
		var bad := raw.duplicate(true)
		bad.weapons[gun].merge(corrupt, true)
		check(SortieCheckpoint.restore_session(bad) == null, "illegal checkpoint rejects safely: " + str(corrupt))
	check(session.inventory.to_dict() == before and _rounds(session, AP) == 32, "rejected restore leaves live session untouched")
	profile = _fresh(37, 0)
	session = _session(profile)
	var legacy := SortieCheckpoint.restore_session(JSON.parse_string(JSON.stringify(SortieCheckpoint.session_data(session))))
	check(legacy != null and legacy.get_weapon_runtime_state(_gun(profile)).ammo_definition_id == STANDARD, "unchanged old standard-magazine payload still restores")

func _actual_hits() -> void:
	for spec in [[STANDARD, false, 0.0, 20.0, 0.0], [STANDARD, true, 3.0, 25.0, 0.0], [AP, false, 0.0, 18.0, 22.0], [AP, true, 3.0, 22.8, 22.0]]:
		var profile := _fresh(1 if spec[0] == STANDARD else 0, 1 if spec[0] == AP else 0)
		profile.ar_damage_upgraded = spec[1]
		var session := _session(profile)
		if not session: continue
		var player := PlayerController.new()
		player.configure_sortie(session)
		add_child(player)
		player.set_physics_process(false)
		player.armor_data = player.armor_data.duplicate()
		player.armor_data.damage_modifier = spec[2]
		player.aim_direction = Vector3.FORWARD
		player.aim_world_point = Vector3(0, 1.15, -10)
		var target := Target.new()
		add_child(target)
		target.position = Vector3(0, 1, -6)
		target.set_physics_process(false)
		target.health = 1000
		target.armor = 8
		await get_tree().physics_frame
		await get_tree().physics_frame
		var weight := session.inventory.current_weight
		check(player.debug_fire_once() and target.packets.size() == 1, "actual player shot reaches real enemy receiver: " + str(spec))
		if target.packets.size() == 1:
			var packet: DamagePacket = target.packets[0]
			check(is_equal_approx(packet.base_damage, spec[3]) and packet.armor_penetration == spec[4], "packet uses approved base, upgrade then armor modifier, and correct penetration")
			check(is_equal_approx(1000 - target.health, spec[3] - maxf(8 - spec[4], 0)), "real enemy armor calculation matches expected damage")
		check(player.get_magazine_ammo() == 0 and is_equal_approx(weight - session.inventory.current_weight, ContentDB.get_ammo(spec[0]).weight), "last shot keeps its original type for damage while consuming its exact weight")
		var total := _rounds(session, spec[0])
		check(not player.debug_fire_once() and _rounds(session, spec[0]) == total, "rejected fire does not consume ammunition")
		player.free()
		target.free()
		await get_tree().process_frame
	check(ContentDB.get_weapon(RIFLE).damage == 20 and ContentDB.get_weapon(RIFLE).armor_penetration == 0 and ContentDB.get_ammo(STANDARD).armor_penetration == 8, "compatibility rule never mutates shared balance resources")

func _settlements() -> void:
	for result in ["success", "failure", "death"]:
		var profile := _fresh(80, 100)
		profile.ammo_pack[String(STANDARD)] = 37
		profile.ammo_pack[String(AP)] = 41
		var plan := DeploymentPlan.build(profile)
		var deployed := DeploymentPlan.deploy(profile, &"street_district", &"streets_recon", PATH)
		check(deployed.error == OK, "production partial-stack deployment succeeds: " + result)
		if deployed.error != OK: continue
		var session: SortieSession = deployed.session
		var gun := _gun(profile)
		check(_rounds(session, STANDARD) == 37 and _rounds(session, AP) == 41 and is_equal_approx(session.inventory.current_weight, plan.weight), "packed totals include magazines exactly once and match preview mass")
		_drain(session, gun)
		session.reload_weapon(gun)
		_drain(session, gun)
		check(session.reload_weapon(gun) == 30, "fallback loads AP after all carried standard rounds are spent")
		for index in 5: session.fire_weapon(gun)
		if result == "success": check(session.complete_extraction(), "success materializes remaining AP exactly once")
		elif result == "failure": check(session.fail(), "failure closes the sortie without recovering ammunition")
		else:
			var battle = load("res://scenes/battle/battle.tscn").instantiate()
			battle.result_transition_enabled = false
			add_child(battle)
			battle.player.set_physics_process(false)
			battle.player.receive_damage(DamagePacket.new(100000))
			check(battle.player.is_dead and session.status == SortieSession.Status.FAILED, "actual player death invokes production battle failure")
			battle.free()
			await get_tree().process_frame
		var before := profile.to_dict()
		check(SortieRuntime.finalize_sortie("user://missing_ap_directory/profile.json") != OK and profile.to_dict() == before, "failed settlement save preserves warehouse and pending outcome")
		check(SortieRuntime.finalize_sortie(PATH) == OK, "settlement retry succeeds")
		check(SupplyService.count(profile, STANDARD) == 43 and SupplyService.count(profile, AP) == (95 if result == "success" else 59), "success returns unspent AP; failure/death lose only deployed split stacks")
		before = profile.to_dict()
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.to_dict() == before, "repeat return cannot add ammunition")
		check(SaveService.load_profile(PATH, false).to_dict() == before, "settled warehouse survives real save/load")

func _relief_and_crafting() -> void:
	var profile := _fresh(0, 10)
	profile.failed_sorties = 1
	profile.credits = 0
	check(not SupplyService.can_claim_relief(profile), "owned rifle plus AP stock is not falsely classified as unarmed")
	var gun := _gun(profile)
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.inventory.remove_item(gun)
	check(SupplyService.can_claim_relief(profile), "AP without any compatible owned weapon does not suppress legitimate relief")
	profile = _fresh(0, 10)
	profile.first_mission_completed = true
	profile.campaign.stage = 3
	profile.inventory.add_item(ItemInstance.new(&"material.scrap", 3))
	profile.inventory.add_item(ItemInstance.new(&"material.propellant", 2))
	var before := profile.to_dict()
	check(SupplyService.transact("barter", "bench_ap", 1, "user://missing_ap_directory/profile.json").error != OK and profile.to_dict() == before, "failed AP crafting save rolls back materials and product")
	check(SupplyService.transact("barter", "bench_ap", 1, PATH).error == OK and SupplyService.count(profile, AP) == 40, "existing recipe adds exactly thirty AP rounds")
	check(SupplyService.count(profile, &"material.scrap") == 0 and SupplyService.count(profile, &"material.propellant") == 0, "existing recipe consumes exactly three scrap and two propellant")

func _write_cross_process() -> void:
	var profile := _fresh(0, 80)
	profile.ammo_pack[String(AP)] = 37
	var deployed := DeploymentPlan.deploy(profile, &"street_district", &"streets_recon", CROSS)
	check(deployed.error == OK, "cross-process AP deployment is durable")
	if deployed.error != OK: return
	var session: SortieSession = deployed.session
	for index in 5: session.fire_weapon(_gun(profile))
	check(SortieRuntime.save_checkpoint() == OK, "AP magazine checkpoint saved after five shots")
	var file := FileAccess.open(CROSS + ".expected", FileAccess.WRITE)
	file.store_string(JSON.stringify(SortieCheckpoint.session_data(session)))
	file.close()

func _read_cross_process() -> void:
	check(ProfileRuntime.load_profile(CROSS), "second process reads actual AP profile")
	check(SortieRuntime.resume_saved(CROSS) == OK, "second process resumes saved AP magazine rather than default standard")
	var session := SortieRuntime.get_current_session()
	if not session: return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CROSS + ".expected"))
	check(JSON.parse_string(JSON.stringify(SortieCheckpoint.session_data(session))) == expected, "cross-process session fields roundtrip exactly")
	var profile := ProfileRuntime.get_profile()
	var state = session.get_weapon_runtime_state(_gun(profile))
	check(state.ammo_definition_id == AP and state.magazine_ammo == 25 and _rounds(session, AP) == 32, "second process retains twenty-five loaded plus seven loose AP rounds")
	check(SaveService.SCHEMA_VERSION == 11 and SortieCheckpoint.VERSION == 6, "schema 11 profile and unchanged schema 6 checkpoint")
	check(session.complete_extraction() and SortieRuntime.finalize_sortie(CROSS) == OK, "resumed AP sortie extracts through the normal transaction")
	check(SupplyService.count(profile, AP) == 75, "cross-process extraction conserves original eighty minus five fired rounds")
