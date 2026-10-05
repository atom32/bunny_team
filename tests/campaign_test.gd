extends Node
const PATH := "user://campaign_test.json"
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--read" in args:
		_read_cross_process()
	else:
		_schema()
		await _chain()
		_atomic()
		await _ui()
		if "--write" in args: _write_cross_process()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("CAMPAIGN: " + failure)
	print("CAMPAIGN_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _schema() -> void:
	var profile := ProfileState.create_new()
	check(profile.validate() and profile.campaign == {"version":1,"stage":0,"progress":0}, "new profile has no fabricated contracts/rewards")
	check(not CampaignService.ready(profile), "first mission prerequisite is real")
	var impossible := ProfileState.from_dict(profile.to_dict())
	impossible.campaign.stage = 2
	check(not impossible.validate(), "claimed facilities without completed prerequisite rejected")
	check(not CampaignService.unlocked(profile, "clinic") and not SupplyService.recipes(profile).has("clinic_medkit"), "clinic recipe initially locked")
	check(SupplyService.prepare(profile,"barter","bench_ap").error != OK, "unearned facility recipe rejected by transaction, not only UI")
	var legacy := profile.to_dict()
	legacy.erase("campaign")
	legacy.first_mission_completed = true
	legacy.ar_damage_upgraded = true
	for version in [1,2,3]:
		var file := FileAccess.open(PATH,FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema_version":version,"profile":legacy})); file.close()
		var restored := SaveService.load_profile(PATH,false)
		check(restored != null and restored.campaign.stage == 0 and restored.inventory.to_dict() == profile.inventory.to_dict() and restored.ar_damage_upgraded, "legacy schema %d preserves actual equipment and old upgrade, no free campaign completion" % version)
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":4,"profile":legacy}));file.close()
	check(SaveService.load_profile(PATH,false) == null, "schema 4 missing campaign rejected instead of resetting progression")
	for bad in [{},[],{"version":1,"stage":0}, {"version":2,"stage":0,"progress":0}, {"version":1,"stage":6,"progress":0}, {"version":1,"stage":1.5,"progress":0}, {"version":1,"stage":0,"progress":3}, {"version":1,"stage":1,"progress":1}, {"version":1,"stage":5,"progress":1}, {"version":1,"stage":0,"progress":-1}, {"version":1,"stage":0,"progress":INF}, {"version":1,"stage":0,"progress":0,"unlocked":true}]:
		var data := profile.to_dict()
		data.campaign = bad
		check(ProfileState.from_dict(data) == null, "malformed/out-of-range/incompatible contract state rejected")
	check(SaveService.save_profile(profile,PATH) == OK and SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "integer state normalizes through real JSON file")

func _new() -> ProfileState:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	return profile

func _start(profile: ProfileState, kills := 0, complete := true, mission := &"streets_recon") -> SortieSession:
	var area := &"street_district" if mission == &"streets_recon" else &"prototype_arena"
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(area,mission), profile)
	check(session != null, "normal sortie starts with current profile")
	for index in kills: session.record_enemy_defeat()
	if complete:
		for objective in ContentDB.get_mission(mission).objective_definitions:
			match objective.objective_type:
				ObjectiveDefinition.Type.INTERACT: session.record_objective_interaction(objective.objective_id)
				ObjectiveDefinition.Type.REACH: session.record_objective_reached(objective.objective_id)
	return session

func _win(profile: ProfileState, kills := 0, complete := true) -> SortieOutcome:
	var session := _start(profile,kills,complete)
	check(session.complete_extraction(), "real extraction completion")
	var outcome := SortieRuntime.get_outcome()
	check(SortieRuntime.finalize_sortie(PATH) == OK, "normal atomic result settlement")
	return outcome

func _chain() -> void:
	var profile := _new()
	var before := profile.to_dict()
	check(CampaignService.claim("routes",PATH).error != OK and profile.to_dict() == before, "cannot claim incomplete contract")
	_win(profile,0,false)
	check(profile.campaign.progress == 0, "early extraction without required recon objectives does not count")
	var first_outcome := _win(profile)
	check(profile.campaign.progress == 1 and profile.campaign.stage == 0, "first successful recon advances but does not auto-claim")
	var once := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, first_outcome) == OK and profile.to_dict() == once, "same real outcome ID cannot increment contract twice")
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.to_dict() == once, "repeated return cannot duplicate contract progress")
	_win(profile)
	check(profile.campaign.progress == 2 and CampaignService.ready(profile), "two separately settled sorties satisfy first contract")
	var credits := profile.credits
	check(CampaignService.claim("routes",PATH).error == OK and profile.credits == credits+300 and profile.campaign.stage == 1 and profile.campaign.progress == 0, "claim grants exact reward and activates next contract")
	before = profile.to_dict()
	check(CampaignService.claim("routes",PATH).error != OK and profile.to_dict() == before, "stale/double-clicked claim cannot redeem another contract")
	profile.inventory.add_item(ItemInstance.new(&"material.fabric",3))
	profile.inventory.add_item(ItemInstance.new(&"material.parts",2))
	before = profile.to_dict()
	check(CampaignService.claim("clinic",PATH).error != OK and profile.to_dict() == before, "partial requirements do not consume anything")
	profile.inventory.add_item(ItemInstance.new(&"material.fabric",3))
	var equipped := profile.loadout.to_dict()
	check(CampaignService.claim("clinic",PATH).error == OK, "actual warehouse material delivery succeeds")
	check(SupplyService.count(profile,&"material.fabric") == 2 and SupplyService.count(profile,&"material.parts") == 0 and profile.loadout.to_dict() == equipped, "only exact delivery quantities consumed, equipment IDs untouched")
	check(CampaignService.unlocked(profile,"clinic") and SupplyService.recipes(profile).has("clinic_medkit"), "claimed clinic unlocks useful supply recipe")
	for index in 2: check(profile.inventory.add_item(ItemInstance.new(&"medical.field_dressing")), "clinic ingredient is an actual non-stackable dose")
	check(SupplyService.transact("barter","clinic_medkit",1,PATH).error == OK and SupplyService.count(profile,&"medical.medkit") == 1, "clinic produces a real usable carried medical item")
	check(not SupplyService.recipes(profile).has("bench_ap"), "clinic cannot unlock unrelated ammunition bench")
	for id in CampaignService.current(profile).inputs: profile.inventory.add_item(ItemInstance.new(id,CampaignService.current(profile).inputs[id]))
	check(CampaignService.claim("workbench",PATH).error == OK and CampaignService.unlocked(profile,"workbench"), "workbench delivery unlocks next permanent facility")
	for id in SupplyService.FACILITY_RECIPES.bench_ap.inputs: profile.inventory.add_item(ItemInstance.new(id,SupplyService.FACILITY_RECIPES.bench_ap.inputs[id]))
	check(SupplyService.transact("barter","bench_ap",1,PATH).error == OK and SupplyService.count(profile,&"ammo.556_ap") == 30, "bench creates actual existing AP ammunition without changing WeaponDefinition")
	var unrelated := _start(profile,5,false,&"prototype_combat")
	unrelated.complete_extraction()
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.campaign.progress == 0, "kills in another mission area cannot satisfy Streets security contract")
	_win(profile,3,false)
	check(profile.campaign.progress == 3, "security kills count on survival even without recon completion")
	var session := _start(profile,5)
	session.fail()
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.campaign.progress == 3, "failed sortie neither advances nor erases settled contract progress")
	check(CampaignService.unlocked(profile,"clinic") and CampaignService.unlocked(profile,"workbench"), "death retains earned facilities")
	# Use actual supply transactions to recover an equipped weapon after the loss.
	check(SupplyService.transact("buy","weapon.pistol_01",1,PATH).error == OK, "resupply after genuine carried loss")
	for item in profile.inventory.get_items():
		if item.definition_id == &"weapon.pistol_01": profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,item.instance_id,profile.inventory);break
	_win(profile,12)
	check(profile.campaign.progress == 8, "security requirement caps at eight rather than banking kills for later contracts")
	check(CampaignService.claim("security",PATH).error == OK and CampaignService.unlocked(profile,"supplier"), "security unlocks trusted supplier")
	var pistol := ContentDB.get_item(&"weapon.pistol_01")
	credits = profile.credits
	check(SupplyService.transact("buy","weapon.pistol_01",1,PATH).error == OK and profile.credits == credits-225, "equipment discount is actual 250 to 225 price")
	check(SupplyService.buy_price(ContentDB.get_item(&"ammo.9mm_standard"),profile) == ContentDB.get_item(&"ammo.9mm_standard").base_value, "supplier does not silently discount unrelated ammunition")
	var sale := SupplyService.sell_price(ItemInstance.new(pistol.id))
	check(sale < SupplyService.buy_price(pistol,profile), "discount cannot create buy/sell credit loop")
	for index in 3: _win(profile)
	check(CampaignService.claim("bastion",PATH).error == OK and profile.campaign.stage == 5, "three later recon extractions reach explicit campaign endpoint")
	check(CampaignService.current(profile).is_empty() and not CampaignService.ready(profile), "completed chain has no phantom repeat reward")
	before = profile.to_dict()
	check(CampaignService.claim("bastion",PATH).error != OK and profile.to_dict() == before, "final reward cannot duplicate")
	_win(profile)
	check(profile.campaign.stage == 5 and profile.campaign.progress == 0, "free sorties still playable after campaign endpoint")
	check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "end-of-chain state, IDs, facilities and economy persist together")
	await get_tree().process_frame

func _atomic() -> void:
	var profile := _new()
	profile.campaign.progress = 2
	var before := profile.to_dict()
	check(CampaignService.claim("routes","user://missing_campaign_directory/profile.json").error != OK and profile.to_dict() == before, "failed claim save never grants credits/unlock or consumes progress")
	profile.campaign.progress = 1
	var session := _start(profile)
	check(CampaignService.claim("routes",PATH).error == ERR_BUSY, "no base claim during active sortie")
	session.complete_extraction()
	before = profile.to_dict()
	check(SortieRuntime.finalize_sortie("user://missing_campaign_directory/profile.json") != OK and profile.to_dict() == before, "failed settlement does not publish contract progress")
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.campaign.progress == 2, "failed settlement retries same pending outcome and advances progress once")
	profile.sortie_checkpoint = {"pending":true}
	check(CampaignService.claim("routes",PATH).error == ERR_BUSY, "suspended sortie also locks contract claims")
	profile.sortie_checkpoint = {}
	ProfileRuntime.recovery_required = true
	check(CampaignService.claim("routes",PATH).error == ERR_BUSY, "corrupt-profile recovery locks claims")
	ProfileRuntime.recovery_required = false
	profile.campaign.stage = 1;profile.campaign.progress = 0
	for id in CampaignService.current(profile).inputs: profile.inventory.add_item(ItemInstance.new(id,CampaignService.current(profile).inputs[id]))
	before = profile.to_dict()
	check(CampaignService.claim("clinic","user://missing_campaign_directory/profile.json").error != OK and profile.to_dict() == before, "failed delivery save cannot eat materials or unlock clinic")

func _ui() -> void:
	var profile := _new()
	profile.campaign.progress = 2
	var hub: Node3D = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	hub.show_section("Overview")
	var panel: CampaignPanel = hub.screen.get_node("CampaignPanel")
	panel.save_path = PATH
	var button := panel.find_child("ClaimContract",true,false) as Button
	check(button != null and not button.disabled, "normal Hideout exposes ready campaign claim")
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(profile.campaign.stage == 1 and SaveService.load_profile(PATH,false).campaign.stage == 1, "real base button claims and durably advances contract")
	check((panel.find_child("ClaimContract",true,false) as Button).disabled, "next delivery UI is not spuriously claimable")
	hub.free()

func _write_cross_process() -> void:
	var profile := _new()
	profile.campaign = {"version":1,"stage":3,"progress":4}
	profile.inventory.add_item(ItemInstance.new(&"material.data_drive",2))
	check(SaveService.save_profile(profile,PATH) == OK, "cross-process partial campaign saved")
	FileAccess.open(PATH+".expected",FileAccess.WRITE).store_string(JSON.stringify(profile.to_dict()))

func _read_cross_process() -> void:
	check(ProfileRuntime.load_profile(PATH), "second process loads campaign save")
	var profile := ProfileRuntime.get_profile()
	var expected := ProfileState.from_dict(JSON.parse_string(FileAccess.get_file_as_string(PATH+".expected")))
	check(profile.to_dict() == expected.to_dict(), "cross-process partial progress, credits and instance IDs unchanged")
	check(profile.campaign.stage == 3 and profile.campaign.progress == 4 and SupplyService.recipes(profile).has("clinic_medkit") and SupplyService.recipes(profile).has("bench_ap"), "earned facilities remain usable after process restart")
	check(not CampaignService.unlocked(profile,"supplier"), "next reward remains locked after restart")
	_win(profile,4)
	check(CampaignService.claim("security",PATH).error == OK and CampaignService.unlocked(profile,"supplier"), "second process continues partial objective and claims exactly once")
	var before := profile.to_dict()
	check(CampaignService.claim("security",PATH).error != OK and profile.to_dict() == before, "cross-process reward idempotence")

func check(condition: bool, message: String) -> void:
	checks += 1
	print("CAMPAIGN %s: %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failures.append(message)
