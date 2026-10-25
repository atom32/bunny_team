extends Node
## Controlled admission/return fixtures, not a fresh-player playthrough.
const PATH := "user://first_sortie_readiness_test.json"
const AREA := &"first_mission_area"
const MISSION := &"first_mission"
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func fresh() -> ProfileState:
	SortieRuntime.clear_session()
	ProfileRuntime.recovery_required = false
	return ProfileRuntime.new_profile()

func frames() -> void:
	for tick in 3: await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	var previous_path := FlowMenu.save_path
	var previous_presentation := GameState.presentation_enabled
	FlowMenu.save_path = PATH
	GameLanguage.set_language("en", false)
	_admission()
	await _secondary_can_fire()
	_capacity()
	_legacy_pending()
	await _rebuild_navigation()
	SortieRuntime.clear_session()
	FlowMenu.save_path = previous_path
	GameState.presentation_enabled = previous_presentation
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("FIRST_SORTIE_READINESS: " + failure)
	print("FIRST_SORTIE_READINESS_TEST: %s (%d checks; controlled fixtures)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _admission() -> void:
	var profile := fresh()
	var before := profile.to_dict()
	var plan := DeploymentPlan.build(profile, MISSION)
	check(plan.error.is_empty() and not plan.ammo_quantities.is_empty(), "normal owned starter rounds allow the first sortie")
	check(DeploymentPlan.prepare(profile, AREA, MISSION).error == OK and profile.to_dict() == before, "normal first-sortie preparation is nonmutating")
	profile.ammo_pack = {"ammo.556_standard":0, "ammo.9mm_standard":0}
	before = profile.to_dict()
	check(SaveService.save_profile(profile, PATH) == OK, "isolated dry request saves before admission check")
	var disk := FileAccess.get_file_as_string(PATH)
	plan = DeploymentPlan.build(profile, MISSION)
	check(not plan.error.is_empty() and plan.ammo_quantities.is_empty(), "owned warehouse stock cannot conceal a zero-round requested first load")
	var rejected := DeploymentPlan.deploy(profile, AREA, MISSION, PATH)
	check(rejected.error != OK and not SortieRuntime.get_current_session() and profile.to_dict() == before and FileAccess.get_file_as_string(PATH) == disk, "dry first-sortie rejection publishes no session, checkpoint, items or disk changes")
	check(DeploymentPlan.prepare(profile, &"street_district", &"streets_recon").error == OK, "later field sortie remains allowed to carry empty guns and retreat")
	profile = fresh()
	for item in profile.inventory.get_items():
		if item.definition_id in [&"ammo.556_standard", &"ammo.9mm_standard"]: profile.inventory.remove_item(item.instance_id)
	check(profile.inventory.add_item(ItemInstance.new(&"ammo.762_standard",30)), "wrong-caliber fixture explicitly owns finite unrelated rounds")
	profile.ammo_pack = {"ammo.556_standard":90, "ammo.9mm_standard":108}
	before = profile.to_dict()
	plan = DeploymentPlan.build(profile, MISSION)
	check(not plan.error.is_empty() and plan.ammo_quantities.is_empty() and DeploymentPlan.prepare(profile, AREA, MISSION).error != OK and profile.to_dict() == before, "positive requests and unrelated ammunition cannot satisfy the first live-fire gate")

func _secondary_can_fire() -> void:
	var profile := fresh()
	profile.ammo_pack = {"ammo.556_standard":0, "ammo.9mm_standard":1}
	var deployed := DeploymentPlan.deploy(profile, AREA, MISSION, PATH, false)
	check(deployed.error == OK, "one actual secondary-compatible round allows first-sortie admission")
	if deployed.error != OK: return
	var session: SortieSession = deployed.session
	var primary_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var secondary_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
	check(session.get_weapon_runtime_state(primary_id).magazine_ammo == 0 and session.get_weapon_runtime_state(secondary_id).magazine_ammo == 1, "actual activated magazines match the sparse packed load")
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().physics_frame
	var director = battle.get_node("FirstMissionDirector")
	director.set_process(false)
	battle.player.set_physics_process(false)
	director._advance(director.Stage.FIRE) # Explicit lesson fixture, not earned progress.
	check(not battle.player._try_fire(), "the dry active primary cannot manufacture the required shot")
	check(battle.player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY) and battle.player._try_fire(), "normal switching fires the actually loaded secondary round")
	director._process(0.0)
	check(director.stage == director.Stage.PMC and director.patrol.is_physics_processing(), "the real weapon_fired event satisfies the existing director gate from the secondary slot")
	battle.free()
	await frames()
	SortieRuntime.clear_session()

func _capacity() -> void:
	var profile := fresh()
	for slot in LoadoutState.SLOT_IDS: profile.loadout.unequip(slot)
	for item in profile.inventory.get_items():
		if item.definition_id in [&"ammo.556_standard", &"ammo.9mm_standard"]: profile.inventory.remove_item(item.instance_id)
	# Real definitions: 8kg launcher + 1.8kg fitted pistol + 8kg armor, no pack.
	# The remaining .2kg cannot hold a single .8kg rocket; the pistol is dry.
	var launcher := ItemInstance.new(&"weapon.rocket_launcher_01")
	var pistol := ItemInstance.new(&"weapon.pistol_01"); pistol.fitting = "quickloader"
	var armor := ItemInstance.new(&"armor.bulwark_plate_01")
	for item in [launcher, pistol, armor, ItemInstance.new(&"ammo.rocket_standard",4)]:
		check(profile.inventory.add_item_preserving_instance(item), "capacity fixture owns each finite item without modifying shared definitions")
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, launcher.instance_id, profile.inventory) and profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, pistol.instance_id, profile.inventory) and profile.loadout.equip(LoadoutState.SLOT_ARMOR, armor.instance_id, profile.inventory), "real equipped fixture leaves less than one compatible round of free capacity")
	var before := profile.to_dict()
	var plan := DeploymentPlan.build(profile, MISSION)
	check(profile.validate() and is_equal_approx(plan.weight,17.8) and plan.capacity == 18.0 and plan.ammo_quantities.is_empty() and not plan.error.is_empty(), "capacity-clipped zero actual rounds are rejected even with owned and requested rockets")
	check(DeploymentPlan.prepare(profile, AREA, MISSION).error != OK and profile.to_dict() == before, "capacity rejection changes neither requested load nor owned instances")

func _legacy_pending() -> void:
	var profile := fresh()
	profile.ammo_pack = {"ammo.556_standard":0, "ammo.9mm_standard":0}
	# Simulate an already saved pre-guard deployment using the lower-level API.
	# Existing suspended dry sorties are not silently rearmed or advanced.
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(AREA, MISSION), profile)
	check(session != null and SortieRuntime.begin_persistence(PATH) == OK, "controlled old dry deployment fixture checkpoints without a world")
	if not session: return
	var saved := SortieCheckpoint.session_data(session)
	SortieRuntime.clear_session()
	check(SortieRuntime.resume_saved(PATH) == OK and SortieCheckpoint.session_data(SortieRuntime.get_current_session()) == saved, "existing dry suspended sortie resumes unchanged, with no free ammo, objectives or completion")
	SortieRuntime.clear_session()

func _rebuild_navigation() -> void:
	var profile := fresh()
	var deployed := DeploymentPlan.deploy(profile, AREA, MISSION, PATH, false)
	check(deployed.error == OK and deployed.session.fail() and SortieRuntime.finalize_sortie(PATH) == OK, "real failed-sortie settlement removes carried equipment before rebuilding")
	check(profile.failed_sorties == 1 and not profile.first_mission_completed and not FirstMissionPreparation.owns_starter_weapons(profile), "failed tutorial retains the need to rebuild rather than completing training")
	GameState.presentation_enabled = true
	var hideout: Node3D = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hideout)
	hideout.show_section("Overview")
	await frames()
	var rebuild: Button
	for button in hideout.screen.find_children("*", "Button", true, false):
		if button.text == "WORKSHOP / RESUPPLY": rebuild = button; break
	check(rebuild != null and rebuild.is_visible_in_tree(), "settled first failure exposes the actual rebuild button")
	if rebuild:
		var before := profile.to_dict()
		rebuild.pressed.emit() # Production navigation callback, not OS mouse acceptance.
		await frames()
		var contacts: ContactPanel = hideout.screen.get_node("ContactPanel")
		var shop: SupplyPanel = contacts.find_child("SupplyPanel", true, false)
		var relief: Button
		for button in shop.find_children("*", "Button", true, false):
			if button.text == "EMERGENCY KIT / PISTOL + 45 ROUNDS": relief = button; break
		check(contacts.contact_id == "shen_yanshuang" and contacts.selected_tab == "trade" and shop.contact_id == "shen_yanshuang", "rebuild opens Shen's real combat-supply trade page directly")
		check(shop.find_child("Supply_buy_weapon_pistol_01", true, false) != null and relief != null and relief.is_visible_in_tree(), "replacement pistol and conditional emergency kit are visible without finding another contact")
		check(relief != null and relief.disabled == not SupplyService.can_claim_relief(profile) and profile.to_dict() == before, "rebuild navigation preserves real aid eligibility, credits and ownership")
	hideout.free()
	await frames()
