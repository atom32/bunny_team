extends Node
var failures: Array[String] = []
var checks := 0
const PATH := "user://alpha_economy_test.json"

func _ready() -> void:
	await get_tree().process_frame
	_test_starter_and_legacy()
	_test_trading()
	_test_barter()
	_test_material_rolls()
	_test_risk_and_recovery()
	_test_atomic_save()
	_test_recovery_reward()
	await _test_owned_ui()
	await _test_supply_scroll()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	for failure in failures: push_error("ALPHA_ECONOMY: " + failure)
	print("ALPHA_ECONOMY_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_starter_and_legacy() -> void:
	var profile := ProfileState.create_new()
	check(profile.validate() and profile.credits == 1500 and profile.inventory.get_items().size() == 6, "finite starter supplies")
	check(SupplyService.count(profile, &"weapon.rocket_launcher_01") == 0, "no full arsenal grant")
	check(not SupplyService.can_claim_relief(profile), "new profile cannot claim emergency aid")
	var legacy := ArmoryFixture.create_profile().to_dict()
	for key in ["credits", "successful_sorties", "failed_sorties", "relief_claimed_after", "settled_outcomes"]: legacy.erase(key)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 1, "profile": legacy}))
	file.close()
	check(ProfileRuntime.load_profile(PATH), "schema-1 profile migrates through actual JSON file")
	profile = ProfileRuntime.get_profile()
	check(profile.inventory.to_dict() == legacy.inventory and profile.loadout.to_dict() == legacy.loadout and profile.credits == 1500, "legacy possessions retain IDs, quantities and equipped references")
	check(SaveService.save_profile(profile, PATH) == OK, "legacy upgrades to current schema")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(raw.schema_version == SaveService.SCHEMA_VERSION and SaveService.load_profile(PATH, false).to_dict() == profile.to_dict(), "current schema roundtrip keeps wallet and possessions")
	for invalid in [-1, 1.5, "1500", INF]:
		var data := profile.to_dict()
		data.credits = invalid
		check(ProfileState.from_dict(data) == null, "invalid wallet is rejected: %s" % invalid)
	var missing: Dictionary = raw.duplicate(true)
	missing.profile.erase("credits")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(missing)); file.close()
	check(SaveService.load_profile(PATH, false) == null, "schema-2 missing wallet is not silently refilled")

func _test_trading() -> void:
	var profile := ProfileState.create_new()
	var before := profile.to_dict()
	var result := SupplyService.prepare(profile, "buy", "weapon.pistol_01")
	check(result.error == OK and profile.to_dict() == before, "buy prepares without publishing")
	profile = result.candidate
	check(profile.credits == 1250 and SupplyService.count(profile, &"weapon.pistol_01") == 1, "purchase spends authored price")
	var pistol := _find(profile, &"weapon.pistol_01")
	check(SupplyService.prepare(profile, "sell", pistol.instance_id, 2).error != OK, "cannot oversell")
	var sell := SupplyService.prepare(profile, "sell", pistol.instance_id)
	check(sell.error == OK and sell.candidate.credits == 1337 and SupplyService.count(sell.candidate, &"weapon.pistol_01") == 0, "sale removes instance and returns 35 percent")
	check(SupplyService.prepare(profile, "sell", profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)).error != OK, "equipped gear cannot disappear through sale")
	check(SupplyService.prepare(profile, "buy", "weapon.pistol_01", 0).error != OK, "zero quantity rejected")
	check(SupplyService.prepare(profile, "buy", "weapon.pistol_01", 2).error != OK, "nonstackable bulk rejected")
	check(SupplyService.prepare(profile, "buy", "weapon.rocket_launcher_01").error != OK, "advanced stock stays locked before first mission")
	profile.first_mission_completed = true
	profile.credits = 10000
	check(SupplyService.prepare(profile, "buy", "weapon.rocket_launcher_01").error == OK, "mission completion unlocks advanced stock")
	profile.credits = 1
	check(SupplyService.prepare(profile, "buy", "weapon.pistol_01").error != OK and profile.credits == 1, "insufficient funds never debit")
	profile.credits = 1500
	profile.inventory.capacity = profile.inventory.current_weight
	check(SupplyService.prepare(profile, "buy", "weapon.pistol_01").error != OK, "warehouse capacity checked before purchase")

func _test_barter() -> void:
	for recipe_id in SupplyService.RECIPES:
		var recipe: Dictionary = SupplyService.RECIPES[recipe_id]
		var profile := ProfileState.create_new()
		var initial_output := SupplyService.count(profile, recipe.output)
		check(SupplyService.prepare(profile, "barter", recipe_id).error != OK, "recipe rejects missing inputs: " + recipe_id)
		for id in recipe.inputs: profile.inventory.add_item(ItemInstance.new(id, recipe.inputs[id]))
		var before := profile.to_dict()
		var result := SupplyService.prepare(profile, "barter", recipe_id)
		check(result.error == OK and profile.to_dict() == before, "recipe prepares atomically: " + recipe_id)
		check(SupplyService.count(result.candidate, recipe.output) == initial_output + recipe.quantity, "recipe yields exact quantity: " + recipe_id)
		for id in recipe.inputs: check(SupplyService.count(result.candidate, id) == 0, "recipe consumes exact material: %s" % id)

func _test_material_rolls() -> void:
	var table := ContentDB.get_loot_table(&"street_supply_loot",false)
	check(table != null and table.validate_definition(), "Streets supply table resolves all material references")
	var rng := RandomNumberGenerator.new()
	rng.seed = 907
	var rolls := LootRollService.roll(table,rng,500)
	var seen := {}
	for item in rolls: seen[item.definition_id] = true
	for id in [&"material.scrap", &"material.propellant", &"material.electronics", &"material.fabric", &"material.parts", &"material.wiring", &"material.data_drive"]:
		check(seen.has(id) and ContentDB.get_item(id).icon != null, "material is lootable and has readable UI artwork: %s" % id)
	var profile := ProfileState.create_new()
	profile.inventory.add_item(ItemInstance.new(&"material.electronics",2))
	profile.inventory.add_item(ItemInstance.new(&"material.scrap",4))
	profile.inventory.capacity = profile.inventory.current_weight
	var before := profile.to_dict()
	check(SupplyService.prepare(profile,"barter","field_smg").error != OK and profile.to_dict() == before, "barter output too heavy never consumes input materials")

func _test_risk_and_recovery() -> void:
	for failed in [true, false]:
		var profile := ProfileState.create_new()
		profile.ar_damage_upgraded = true
		var stored := ItemInstance.new(&"material.data_drive", 1)
		profile.inventory.add_item(stored)
		var before := profile.to_dict()
		var plan := DeploymentPlan.build(profile)
		var session := SortieSession.create_from_profile(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, plan.ammo_ids), profile)
		check(session.activate(), "sortie activates")
		var loot := ItemInstance.new(&"material.electronics", 1)
		session.inventory.add_item(loot)
		check(session.fail() if failed else session.abandon(), "death/abandon is terminal")
		var outcome := SortieOutcomeService.create_outcome(session)
		check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "loss commit succeeds")
		check(ArmoryFixture.loss_matches(profile,before,outcome.initial_carried_instance_ids), "loss affects only actual deployed inventory")
		check(profile.inventory.contains(stored.instance_id) and not profile.inventory.contains(loot.instance_id) and profile.ar_damage_upgraded, "safe storage and permanent upgrade survive")
		var once := profile.to_dict()
		check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and profile.to_dict() == once, "repeated loss never increments twice")
		check(not SupplyService.can_claim_relief(profile), "healthy wallet uses normal resupply")
		profile.credits = 0
		check(SupplyService.can_claim_relief(profile), "bankrupt failed operator can recover")
		var relief := SupplyService.prepare(profile,"relief","")
		check(relief.error == OK, "emergency pistol and ammo granted")
		profile = relief.candidate
		check(SupplyService.count(profile,&"ammo.9mm_standard") == 45 and not SupplyService.can_claim_relief(profile), "kit has 45 rounds and cannot be claimed twice")
		plan = DeploymentPlan.build(profile)
		var retry := SortieSession.create_from_profile(profile.create_sortie_request(&"first_mission_area", &"first_mission",plan.ammo_ids),profile)
		check(retry != null and retry.activate() and retry.fire_weapon(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)), "emergency loadout can deploy and fire")
		check(SaveService.save_profile(profile,PATH) == OK and ProfileRuntime.load_profile(PATH), "settled loss and relief persist")
		check(ProfileRuntime.get_profile().to_dict() == profile.to_dict(), "load does not resurrect lost starter equipment")
	var dry := ProfileState.create_new()
	dry.failed_sorties = 1
	dry.credits = 0
	for item in dry.inventory.get_items():
		if ContentDB.get_item(item.definition_id).has_tag(&"ammo"): dry.inventory.remove_item(item.instance_id)
	check(SupplyService.can_claim_relief(dry), "owning only dry weapons cannot softlock relief")

func _test_atomic_save() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var before := profile.to_dict()
	var bad := "user://missing_alpha_economy_directory/profile.json"
	check(SupplyService.transact("buy","weapon.pistol_01",1,bad).error != OK and profile.to_dict() == before, "failed save never spends wallet or publishes purchased item")
	check(SupplyService.transact("buy","weapon.pistol_01",1,PATH).error == OK, "real transaction persists")
	check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "disk and memory agree after transaction")
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID,SortieRequest.PROTOTYPE_MISSION_ID,plan.ammo_ids),profile)
	check(SupplyService.transact("buy","ammo.556_standard",30,PATH).error == ERR_BUSY, "cannot trade while deployed")
	session.fail()
	before = profile.to_dict()
	check(SortieRuntime.finalize_sortie(bad) != OK and profile.to_dict() == before, "failed settlement save preserves both pending outcome and warehouse")
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.failed_sorties == 1, "retry settles loss once")
	var settled := profile.to_dict()
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.to_dict() == settled, "repeated return cannot double debit")
	profile = ProfileRuntime.new_profile()
	session = SortieRuntime.start_sortie(profile.create_sortie_request(),profile)
	session.complete_extraction()
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.credits == 1500 and profile.successful_sorties == 1, "empty early extraction preserves possessions without creating credits")
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.credits == 1500, "reward cannot duplicate")

func _test_owned_ui() -> void:
	var profile := ProfileRuntime.new_profile()
	var ui := HangerUI.new()
	ui.configure(profile.inventory,profile.loadout)
	add_child(ui)
	check(ui.weapon_option.item_count == 3, "loadout offers only owned starter weapons plus none")
	check(SupplyService.transact("buy","weapon.pistol_01",1,PATH).error == OK, "UI fixture purchases weapon")
	ui.configure(profile.inventory,profile.loadout)
	ui.refresh_owned_items()
	check(ui.weapon_option.item_count == 4, "new purchase appears in loadout without scene restart")
	var pistol := _find(profile,&"weapon.pistol_01")
	check(SupplyService.transact("sell",pistol.instance_id,1,PATH).error == OK, "UI fixture sells weapon")
	ui.configure(profile.inventory,profile.loadout)
	ui.refresh_owned_items()
	check(ui.weapon_option.item_count == 3, "sold weapon disappears from selectable equipment")
	ui.queue_free()
	await get_tree().process_frame

func _find(profile: ProfileState, id: StringName) -> ItemInstance:
	for item in profile.inventory.get_items():
		if item.definition_id == id: return item
	return null

func _test_supply_scroll() -> void:
	var profile := ProfileRuntime.new_profile()
	var panel := SupplyPanel.new()
	panel.save_path = PATH
	panel.size = Vector2(780, 470)
	add_child(panel)
	await get_tree().create_timer(.1).timeout
	var buy: ScrollContainer = panel._scrolls["BUY SUPPLIES"]
	buy.scroll_vertical = 210
	var position := buy.scroll_vertical
	check(position > 0, "Supply test scrolls a real overflowing list")
	await _capture_supply("before_purchase")
	panel._trade("buy", "ammo.556_standard", 30)
	await get_tree().create_timer(.1).timeout
	check(panel._scrolls["BUY SUPPLIES"].scroll_vertical == position, "Successful purchase preserves supply list position")
	check(profile.credits == 1410 and SupplyService.count(profile, &"ammo.556_standard") == 150, "Scroll preservation keeps exact purchase semantics")
	await _capture_supply("after_purchase")
	panel._trade("buy", "ammo.556_standard", 100000)
	await get_tree().create_timer(.1).timeout
	check(panel._scrolls["BUY SUPPLIES"].scroll_vertical == position and profile.credits == 1410, "Rejected purchase preserves list and wallet")
	var sell: ScrollContainer = panel._scrolls["SELL RECOVERED"]
	(sell.get_parent() as TabContainer).current_tab = 1
	await get_tree().create_timer(.1).timeout
	sell.scroll_vertical = 10000
	var old_sell := sell.scroll_vertical
	check(old_sell > 0, "Sell list has a genuine scroll range")
	var ammo := _find(profile, &"ammo.9mm_standard")
	panel._trade("sell", ammo.instance_id, ammo.quantity)
	await get_tree().create_timer(.1).timeout
	sell = panel._scrolls["SELL RECOVERED"]
	check(panel.selected_tab == 1 and sell.scroll_vertical <= old_sell and sell.scroll_vertical >= 0, "Shrinking sell list retains tab and clamps to remaining range")
	check(panel._scrolls["BUY SUPPLIES"].scroll_vertical == position, "Other tab retains its independent scroll position")
	panel.queue_free()
	await get_tree().process_frame

func _capture_supply(label: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	var directory := OS.get_environment("BUNNY_EVIDENCE")
	if directory.is_empty(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png")) == OK, "Supply screenshot saved: " + label)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _test_recovery_reward() -> void:
	for mode in ["unchanged", "spent", "recovered_material", "recovered_ammo"]:
		var profile := ProfileRuntime.new_profile()
		check(DeploymentPlan.set_ammo_count("ammo.556_standard",30,PATH) == OK,"minimal magazine-only pack saves")
		var deployment := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH)
		check(deployment.error == OK,"real exact deployment for reward: "+mode)
		var session: SortieSession = deployment.session
		if mode == "spent": session.fire_weapon(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY))
		if mode == "recovered_material": session.inventory.add_item_preserving_instance(ItemInstance.new(&"material.fabric",1))
		if mode == "recovered_ammo": session.inventory.add_item_preserving_instance(ItemInstance.new(&"ammo.556_standard",5))
		check(session.complete_extraction(),"early return remains permitted: "+mode)
		var outcome := SortieRuntime.get_outcome()
		var reward := 100 if mode.begins_with("recovered") else 0
		check(SortieOutcomeService.credit_reward(outcome,profile) == reward,"magazine IDs cannot fabricate recovered goods: "+mode)
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.credits == 1500+reward,"durable preview and payment agree: "+mode)
		var once := profile.to_dict()
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.to_dict() == once,"recovery reward cannot duplicate: "+mode)
		check(SaveService.load_profile(PATH,false).to_dict() == once,"saved wallet/inventory match: "+mode)
