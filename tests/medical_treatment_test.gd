extends Node
const PATH := "user://medical_test.json"
const DRESSING := "medical.field_dressing"
const MEDKIT := "medical.medkit"
var failures: Array[String] = []
var checks := 0
var battle: Node3D
var player: PlayerController

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--read" in args:
		await _read()
	else:
		_test_stock_and_packing()
		await _prepare()
		if "--write" in args:
			await _write()
		else:
			_test_actions()
			await _write()
			await _clear_battle()
			await _read()
			await _failure()
			await _packing_ui()
	await _clear_battle()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("MEDICAL: " + failure)
	print("MEDICAL_TREATMENT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_stock_and_packing() -> void:
	ProfileRuntime._profile = ProfileState.create_new()
	var profile := ProfileRuntime.get_profile()
	check(DeploymentPlan.build(profile).medical_ids.is_empty(), "no free medical supplies from packing preferences")
	for id in [DRESSING, MEDKIT]:
		var definition := ContentDB.get_item(StringName(id)) as MedicalDefinition
		check(definition and definition in SupplyService.stock(profile) and definition.use_seconds > 0 and definition.healing > 0 and definition.weight > 0, "priced medical definition available at start: " + id)
		check(SupplyService.transact("buy", id, 1, PATH).error == OK, "actual saved medical purchase: " + id)
	var credits := profile.credits
	check(SupplyService.transact("buy", MEDKIT, 1, "user://missing_medical_dir/profile.json").error != OK and profile.credits == credits and SupplyService.count(profile, MEDKIT) == 1, "failed medical purchase save cannot charge or grant")
	profile.inventory.add_item(ItemInstance.new(&"material.fabric"))
	check(SupplyService.transact("barter", "field_dressing", 1, PATH).error == OK and SupplyService.count(profile, DRESSING) == 3 and SupplyService.count(profile, &"material.fabric") == 0, "fabric becomes two real nonstacked dressings atomically")
	var plan := DeploymentPlan.build(profile)
	check(plan.medical_ids.size() == 3 and plan.carried_ids().size() == plan.ammo_ids.size() + 3, "packing carries requested two dressings and one medkit")
	var owned := profile.inventory
	check(DeploymentPlan.set_medical_count(DRESSING, 0, PATH) == OK and profile.inventory == owned, "packing saves without replacing referenced warehouse object")
	check(DeploymentPlan.build(profile).medical_ids.size() == 1, "zero dressing choice really leaves all dressings at base")
	check(DeploymentPlan.set_medical_count(MEDKIT, 4, PATH) == OK and DeploymentPlan.build(profile).medical_ids.size() == 1, "limited to owned supplies, not requested count")
	check(DeploymentPlan.set_medical_count(DRESSING, 2, PATH) == OK and DeploymentPlan.set_medical_count(MEDKIT, 1, PATH) == OK, "medical loadout reset through actual saved preference API")
	check(DeploymentPlan.set_medical_count(DRESSING, 5, PATH) != OK and DeploymentPlan.set_medical_count("missing", 1, PATH) != OK, "invalid packing counts and types rejected")
	check(DeploymentPlan.set_medical_count(DRESSING, 0, "user://missing_medical_dir/profile.json") != OK and profile.medical_pack[DRESSING] == 2, "failed packing save retains previous preference")
	var old := profile.to_dict()
	old.erase("medical_pack")
	check(ProfileState.from_dict(old).inventory.to_dict() == profile.inventory.to_dict(), "old profiles gain defaults, no extra inventory")
	for value in [-1, 5, 1.5, "2", INF]:
		var broken := profile.to_dict()
		broken.medical_pack[DRESSING] = value
		check(ProfileState.from_dict(broken) == null, "invalid serialized medical preference rejected")
	var rng := RandomNumberGenerator.new()
	rng.seed = 921
	var seen := {}
	for item in LootRollService.roll(ContentDB.get_loot_table(&"street_supply_loot"), rng, 150): seen[String(item.definition_id)] = true
	check(seen.has(DRESSING) and seen.has(MEDKIT), "both medical types occur through actual Streets loot rolls")

func _prepare() -> void:
	var profile := ProfileRuntime.get_profile()
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area", &"first_mission", plan.carried_ids()), profile)
	check(session != null and session.validate(), "production carried request supports medical IDs")
	check(SortieRuntime.begin_persistence(PATH) == OK, "medical deployment journal saved")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	player = battle.player
	player.set_physics_process(false) # Action-unit fixture; no elapsed movement or incoming AI damage.
	player.velocity = Vector3.ZERO
	await get_tree().process_frame
	check(player.medical.count(DRESSING) == 2 and player.medical.count(MEDKIT) == 1, "exact actual loadout, not warehouse inventory")
	check(DeploymentPlan.set_medical_count(DRESSING, 0, PATH) == ERR_BUSY, "cannot repack active sortie")

func _test_actions() -> void:
	var med := player.medical
	check(not med.begin(DRESSING) and med.count(DRESSING) == 2, "full-health use neither starts nor spends")
	player.health = 90
	check(med.begin(DRESSING), "dressing action starts")
	med.tick(1.0)
	check(player.health == 90 and med.count(DRESSING) == 2 and is_equal_approx(med.remaining, 1.5), "no instant heal or premature item consumption")
	get_tree().paused = true
	med.tick(10)
	check(is_equal_approx(med.remaining, 1.5), "pause does not advance treatment")
	get_tree().paused = false
	Input.action_press("move_right")
	med.tick(.1)
	Input.action_release("move_right")
	check(not med.is_active() and med.count(DRESSING) == 2 and player.health == 90, "movement interrupts without free healing or losing the item")
	check(med.begin(DRESSING), "can retry after movement")
	player.receive_damage(DamagePacket.new(10))
	var hurt_health := player.health
	check(not med.is_active() and hurt_health < 90 and med.count(DRESSING) == 2, "actual incoming damage interrupts treatment")
	check(med.begin(DRESSING) and not med.begin(DRESSING) and not med.is_active(), "second medical key cancels rather than stacking timers")
	check(med.begin(DRESSING) and player.debug_fire_once() and not med.is_active(), "firing cancels healing, ordinary weapon remains usable")
	check(med.begin(DRESSING) and player.reload_weapon() and not med.is_active(), "reload cancels treatment through production method")
	check(not med.begin(DRESSING), "cannot start treatment while reload timer active")
	player._reload_remaining_by_weapon.clear()
	player.combat_rig._update_reload(10.0)
	check(med.begin(DRESSING) and player.toggle_weapon() and not med.is_active(), "weapon switching cancels treatment")
	check(med.begin(DRESSING), "dressing ready for interaction interruption")
	player.interaction_component.interact_with_current()
	check(not med.is_active() and med.count(DRESSING) == 2, "world interaction cancels treatment")
	check(med.begin(DRESSING), "dressing ready for dodge interruption")
	player._dodge_time = .1
	med.tick(.05)
	check(not med.is_active(), "dodge cannot overlap healing")
	player._dodge_time = 0
	var weight := med.session.inventory.current_weight
	check(med.begin(DRESSING), "valid stationary treatment begins")
	med.tick(2.49)
	check(player.health == hurt_health, "healing does not occur before full use duration")
	med.tick(.02)
	check(is_equal_approx(player.health, hurt_health + 40) and med.count(DRESSING) == 1 and not med.is_active(), "completion heals exactly once and consumes one dose")
	check(is_equal_approx(med.session.inventory.current_weight, weight - .15), "consumed dressing releases actual carried weight")
	check(SupplyService.count(ProfileRuntime.get_profile(), DRESSING) == 3, "base inventory remains staged until settlement")
	player.health = player.max_health - 5
	check(med.begin(DRESSING), "partial-heal cap case starts")
	med.tick(3)
	check(player.health == player.max_health and med.count(DRESSING) == 0, "cannot overheal; one actual dose spent")
	player.health = 90
	check(not med.begin(DRESSING), "no phantom use after last carried dressing")
	check(not med.begin("weapon.assault_rifle_01"), "non-medical items cannot heal")
	check(med.valid_snapshot({}) and not med.valid_snapshot({"item": "missing", "remaining": 2}), "legacy idle checkpoint accepted, missing treatment item rejected")
	check(not med.valid_snapshot({"item": "", "remaining": 1}) and not med.valid_snapshot({"item": "", "remaining": INF}), "malformed treatment timer rejected")

func _write() -> void:
	player.health = 90
	player.velocity = Vector3.ZERO
	check(player.medical.begin(MEDKIT), "start long medkit action before suspend")
	player.medical.tick(1.25)
	check(player.health == 90 and is_equal_approx(player.medical.remaining, 3.75), "medkit still pending, no partial free healing")
	check(SortieRuntime.save_checkpoint() == OK, "save pending medical action with exact remaining time")
	var saved := ProfileRuntime.get_profile().sortie_checkpoint
	var corrupt: Dictionary = saved.world.duplicate(true)
	corrupt.medical.remaining = 99
	check(not SortieCheckpoint.validate_world(corrupt, battle), "world validator rejects impossible treatment duration before mutation")
	check(player.medical.is_active(), "validation failure leaves current treatment unchanged")
	print("MEDICAL_WRITER_READY")

func _read() -> void:
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK, "read actual durable medical sortie")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	player = battle.player
	player.set_physics_process(false)
	check(not FlowMenu.is_open() and player.health == 90 and is_equal_approx(player.medical.remaining, 3.75), "world restores remaining healing time, not a fresh or completed action")
	check(player.medical.count(MEDKIT) == 1, "pending item exists exactly once after reload")
	player.medical.tick(3.76)
	check(player.health == 190 and player.medical.count(MEDKIT) == 0, "resumed medkit completes with exact health and one consumption")
	check(battle.session.complete_extraction(), "medical inventory can extract")
	check(SortieRuntime.finalize_sortie(PATH) == OK, "medical consumption settlement saved")
	var count := SupplyService.count(ProfileRuntime.get_profile(), DRESSING)
	check(SupplyService.count(ProfileRuntime.get_profile(), MEDKIT) == 0 and count >= 1, "used medkit absent from base; unused base supplies retained")
	check(ProfileRuntime.load_profile(PATH) and SupplyService.count(ProfileRuntime.get_profile(), MEDKIT) == 0, "reload cannot reissue consumed medicine")

func _failure() -> void:
	await _clear_battle()
	ProfileRuntime._profile = ProfileState.create_new()
	var profile := ProfileRuntime.get_profile()
	for index in 3: profile.inventory.add_item(ItemInstance.new(StringName(DRESSING)))
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", plan.carried_ids()), profile)
	check(session.fail() and SortieRuntime.finalize_sortie(PATH) == OK, "death settlement accepts medical loadout")
	check(SupplyService.count(profile, DRESSING) == 1, "death loses two packed dressings, not the one left at base")

func _packing_ui() -> void:
	var original_path := FlowMenu.save_path
	FlowMenu.save_path = PATH
	var panel := MedicalPacking.new()
	add_child(panel)
	var quantity: SpinBox = panel.find_child("PackDressing", true, false)
	quantity.value = 0
	await get_tree().process_frame
	check(ProfileRuntime.get_profile().medical_pack[DRESSING] == 0 and SaveService.load_profile(PATH, false).medical_pack[DRESSING] == 0, "real packing UI updates and saves chosen quantity")
	panel.free()
	FlowMenu.save_path = original_path

func _clear_battle() -> void:
	FlowMenu.close()
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session()
	await get_tree().process_frame

func check(value: bool, message: String) -> void:
	checks += 1
	print("MEDICAL %s: %s" % ["PASS" if value else "FAIL", message])
	if not value: failures.append(message)
