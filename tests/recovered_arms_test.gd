extends Node3D
## Controlled fixtures, NOT earned combat or a human loot/fun acceptance test.
const TABLE := &"campus_recovered_arms"
const PATH := "user://recovered_arms.json"
const FIELD_WORLD_PATH := "user://field_weapon_world.json"
const FIELD_EXPECTED_PATH := "user://field_weapon_world_expected.json"
var failures: Array[String] = []
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		var saved := SaveService.load_profile(PATH, false)
		check(saved != null and saved.validate(), "independent process reads the settled fixture")
		if saved:
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://recovered_arms_expected.json"))
			check(saved.to_dict() == ProfileState.from_dict(expected).to_dict(), "exact identity, wallet, loadout and conversion survive process termination")
	elif "--field-write" in OS.get_cmdline_user_args() or "--field-read" in OS.get_cmdline_user_args():
		await _field_world("--field-read" in OS.get_cmdline_user_args())
	elif "--field" in OS.get_cmdline_user_args():
		await _field()
	else:
		_rolls()
		_archive_support()
		await _lifecycle()
		await _world_and_ui()
		await _stash_visibility()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("RECOVERED_ARMS: " + failure)
	print("RECOVERED_ARMS_TEST: %s (%d checks; controlled fixtures, not earned play)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _rolls() -> void:
	var table := ContentDB.get_loot_table(TABLE)
	check(table != null and table.validate_definition() and table.entries.size() == 3, "three authored, registered weapon/conversion combinations")
	var seen := {}
	var hit_count := 0
	var consistent := true
	var same_ordinary_rng := true
	for value in range(1, 501):
		var a := RandomNumberGenerator.new(); a.seed = value
		var b := RandomNumberGenerator.new(); b.seed = value
		var baseline := LootSpawnPoint.new(); baseline.setup(&"prototype_high_value_loot")
		var point := LootSpawnPoint.new(); point.setup(&"prototype_high_value_loot")
		point.bonus_loot_table_id = TABLE; point.bonus_chance = .35
		var old := baseline.spawn(a)
		var current := point.spawn(b)
		same_ordinary_rng = same_ordinary_rng and a.state == b.state
		consistent = consistent and current.size() in [1,2] and current[0].item_instance.definition_id == old[0].item_instance.definition_id and current[0].item_instance.quantity == 1
		if current.size() == 2:
			hit_count += 1
			var item := current[1].item_instance
			seen[item.fitting] = true
			consistent = consistent and WeaponFitting.eligible(item) and WeaponFitting.valid(item) and item.quantity == 1 and current[0].item_instance.instance_id != item.instance_id
		check(point.spawn(b).is_empty(), "already rolled point cannot refill")
		baseline.free(); point.free()
	check(consistent and seen.size() == 3 and hit_count > 120 and hit_count < 225, "optional real weapons, all three conversions; core remains guaranteed, not every case holds a gun")
	check(same_ordinary_rng, "bonus stream leaves every later ordinary RNG draw unchanged")
	var a := RandomNumberGenerator.new(); a.seed = 441
	var b := RandomNumberGenerator.new(); b.seed = 441
	var x := LootRollService.roll(table,a,90)
	var y := LootRollService.roll(table,b,90)
	var exact := true
	for index in x.size():
		exact = exact and x[index].definition_id == y[index].definition_id and x[index].fitting == y[index].fitting and x[index].instance_id != y[index].instance_id
	check(exact, "same seed repeats authored combination, never item identity")
	var bad := LootTableEntry.new(); bad.definition_id = &"medical.medkit"; bad.fitting = "suppressor"
	var invalid := LootTableDefinition.new(); invalid.table_id = &"fixture"; invalid.entries = [bad]
	var state := a.state
	check(LootRollService.roll(invalid,a).is_empty() and a.state == state, "incompatible conversion rejected before RNG consumption")
	bad.definition_id = &"weapon.assault_rifle_01"; bad.max_quantity = 2
	check(not invalid.validate_definition(), "modified weapons cannot become stacks")
	bad.max_quantity = 1; bad.fitting = "unreviewed"
	check(not invalid.validate_definition(), "unknown modifier rejected")
	check(LootRollService.roll(ContentDB.get_loot_table(&"prototype_high_value_loot"),a)[0].fitting.is_empty(), "old tables still roll unmodified core")
	print("RECOVERED_ARMS_DISTRIBUTION: ", hit_count, "/500; ordinary RNG preserved")

func _archive_support() -> void:
	var campus:=preload("res://scripts/world/streets/street_district.gd")
	var profile:=ProfileRuntime.new_profile()
	var before:=profile.to_dict()
	check(campus.archive_bonus_chance(profile)==1.0 and profile.to_dict()==before,"no owned converted gun receives archive support without writing a progress flag")
	var kit:=ItemInstance.new(&"material.quickloader_kit")
	check(profile.inventory.add_item(kit) and campus.archive_bonus_chance(profile)==1.0,"an unused material kit is not falsely treated as an already owned modified gun")
	var owned:=ItemInstance.new(&"weapon.assault_rifle_01");owned.fitting="suppressor"
	check(profile.inventory.add_item(owned) and campus.archive_bonus_chance(profile)==.35,"existing actual modified gun retains ordinary 35 percent optional finds")
	profile.inventory.remove_item(owned.instance_id)
	check(campus.archive_bonus_chance(profile)==1.0,"losing or selling the last conversion restores support without an invisible permanent unlock")
	var consistent:=true;var normal_rng_unchanged:=true;var seen:={}
	for seed_value in range(1,501):
		var a:=RandomNumberGenerator.new();a.seed=seed_value
		var b:=RandomNumberGenerator.new();b.seed=seed_value
		var baseline:=LootSpawnPoint.new();baseline.setup(&"prototype_high_value_loot")
		var cache:=LootSpawnPoint.new();cache.setup(&"prototype_high_value_loot");cache.bonus_loot_table_id=TABLE;cache.bonus_chance=campus.archive_bonus_chance(profile)
		var ordinary:=baseline.spawn(a);var actual:=cache.spawn(b)
		normal_rng_unchanged=normal_rng_unchanged and a.state==b.state
		consistent=consistent and actual.size()==2 and actual[0].item_instance.definition_id==ordinary[0].item_instance.definition_id and actual[0].item_instance.quantity==ordinary[0].item_instance.quantity
		if actual.size()==2:
			seen[actual[1].item_instance.fitting]=true
			consistent=consistent and WeaponFitting.eligible(actual[1].item_instance) and WeaponFitting.valid(actual[1].item_instance)
		check(cache.spawn(b).is_empty(),"supported cache cannot reroll or refill")
		baseline.free();cache.free()
	check(consistent and seen.size()==3 and normal_rng_unchanged,"500 supported cache rolls each include one real conversion, preserve the core and later ordinary RNG, and vary across all three sidegrades")

func _lifecycle() -> void:
	var table := ContentDB.get_loot_table(TABLE)
	for entry in table.entries:
		for success in [false,true]:
			SortieRuntime.clear_session()
			var profile := ProfileRuntime.new_profile()
			profile.first_mission_completed = true
			var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
			check(session != null and session.activate(), "valid active fixture")
			var one := LootTableDefinition.new(); one.table_id = &"fixture"; one.entries = [entry]
			var rng := RandomNumberGenerator.new(); rng.seed = 71
			var item := LootRollService.roll(one,rng)[0]
			var pickup := LootPickup.new(); pickup.setup(item)
			var base_before := profile.to_dict()
			var tight := SortieSession.new(InventoryState.new(item.total_weight()-.01),LoadoutState.new(),&"prototype_arena",&"prototype_combat")
			tight.activate()
			check(pickup.try_pickup(tight) == LootPickup.PickupResult.CAPACITY_FULL and not pickup.consumed, "fitting mass can prevent whole-weapon pickup")
			check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS and profile.to_dict() == base_before, "physical pickup does not bank a permanent unlock")
			check(SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session)).inventory.get_item(item.instance_id).to_dict() == item.to_dict(), "carried snapshot preserves exact modified instance")
			check(session.complete_extraction() if success else session.fail(), "fixture reaches real terminal method")
			var outcome := SortieOutcomeService.create_outcome(session)
			check(outcome != null and SortieOutcomeService.commit_outcome(profile,outcome) == OK, "normal outcome commit handles modified loot")
			if not success:
				check(not profile.inventory.contains(item.instance_id) and outcome.inventory.get_items().is_empty(), "death loses the entire find with no permanent fitting bonus")
				pickup.free(); continue
			check(profile.inventory.get_item(item.instance_id).to_dict() == item.to_dict(), "safe return retains exact find, not a template grant")
			var after := profile.to_dict()
			check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and profile.to_dict() == after, "repeated settlement cannot duplicate recovered weapon")
			var definition := ContentDB.get_weapon(item.definition_id)
			var ammo_id := StringName(definition.compatible_ammo_ids[0])
			check(SupplyService.count(profile,ammo_id) == SupplyService.count(ProfileState.from_dict(base_before),ammo_id), "recovered weapon never grants ammunition")
			# Explicit ammunition fixture, separate from loot; sniper has no starter ammo.
			profile.inventory.add_item(ItemInstance.new(ammo_id,30))
			var model := StashLayout.new(profile)
			check(model.equip_item(item.instance_id,LoadoutState.SLOT_WEAPON_PRIMARY), "normal warehouse model can equip recovered gun")
			check(SaveService.save_profile(profile,PATH) == OK, "settled concrete conversion saves to isolated disk")
			var ammo_ids: Array[String] = []
			for stack in profile.inventory.get_items():
				if stack.definition_id == ammo_id: ammo_ids.append(stack.instance_id)
			var next := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena",&"prototype_combat",ammo_ids),profile)
			check(next != null and next.activate(), "next sortie accepts actual recovered configuration")
			var player := PlayerController.new(); player.configure_sortie(next); add_child(player); player.set_physics_process(false)
			await get_tree().physics_frame
			check(player.weapon_instance.instance_id == item.instance_id and player.weapon_instance.fitting == entry.fitting, "next player uses recovered identity and conversion")
			check(player.debug_fire_once() and player.reload_weapon(), "recovered gun fires and reloads with finite fixture ammunition")
			check(is_equal_approx(player.get_reload_remaining(),definition.reload_seconds*WeaponFitting.reload_factor(item)), "actual runtime uses conversion tradeoff on next sortie")
			player.free(); pickup.free()
			var file := FileAccess.open("user://recovered_arms_expected.json",FileAccess.WRITE); file.store_string(JSON.stringify(profile.to_dict())); file.close()

func _world_and_ui() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","",false).error == OK,"normal campus fixture deployment")
	var battle = load("res://scenes/battle/battle.tscn").instantiate(); battle.loot_seed = 907; add_child(battle)
	battle.result_transition_enabled = false
	# Controlled visual fixture, explicitly not live earned combat.
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().process_frame; await get_tree().process_frame
	var archive: LootSpawnPoint
	var bonus_sites := 0
	for point in battle.area_root.loot_points:
		if not point.bonus_loot_table_id.is_empty(): archive = point; bonus_sites += 1
	check(bonus_sites == 1 and archive.loot_table_id == &"prototype_high_value_loot" and archive.bonus_chance == 1.0,"only existing guarded archive cache supports the fixture with no owned conversion; no new loot sites")
	var actual_finds:=archive.get_children().filter(func(child):return child is LootPickup and not child.item_instance.fitting.is_empty())
	check(actual_finds.size()==1,"actual fresh campus world physically contains one supported gun, not a warehouse grant")
	var saved := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle) and SortieCheckpoint.restore_world(saved,battle),"world checkpoint accepts actual rolled archive contents")
	check(SortieCheckpoint.capture_world(battle).nodes == saved.nodes,"resume keeps exact IDs/conversions and does not refill cache")
	# Old/emptied world slots remain empty even though current authoring has a bonus.
	var empty := saved.duplicate(true); var key := String(battle.area_root.get_path_to(archive)); empty.nodes[key].items = []
	check(SortieCheckpoint.restore_world(empty,battle),"empty saved archive restores")
	check(archive.get_children().filter(func(child):return child is LootPickup).is_empty(),"restoring empty/legacy slot does not grant a new weapon")
	var ui: Node = battle.get_node("SlicePresentation")
	var core := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup; core.setup(ItemInstance.new(&"loot.salvage_core_01")); archive.add_child(core)
	var pickup := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup; archive.add_child(pickup)
	ui.container = ui.crates[archive.get_instance_id()]
	battle.player.global_position = archive.global_position + Vector3.RIGHT
	for entry in ContentDB.get_loot_table(TABLE).entries:
		var item := ItemInstance.new(entry.definition_id); item.fitting = entry.fitting; pickup.setup(item)
		for locale in ["en","zh_CN"]:
			GameLanguage.set_language(locale,false); ui._show_loot()
			await get_tree().process_frame; await get_tree().process_frame
			var note := ui.panel.find_child("ModifiedFind1",true,false) as Label
			check(note != null and note.text == WeaponFitting.discovery_text(item),"actual inspection explains discovered modifier and tradeoff")
			check(note.size.x < 550 and note.get_minimum_size().y <= note.size.y,"bilingual discovery text wraps inside real cache row")
			var field := ui.panel.find_child("FieldSwap1",true,false) as Button
			var field_hint := ui.panel.find_child("FieldSwapHint1",true,false) as Label
			check(field != null and field.visible and not field.disabled and field.text == tr("SWAP CURRENT GUN"), "all three real discovered guns expose the bilingual field-swap control")
			var expected_hint := tr("Replace current %s. Empty magazine / compatible rounds: %d.\nOld gun stays here; loaded rounds return to your bag.") % [tr("PRIMARY"),battle.player.compatible_field_ammo(item)]
			check(field_hint != null and field_hint.visible and field_hint.text == expected_hint, "visible bilingual field hint states the chosen slot, actual ammo, empty magazine and old-gun consequence")
			if field_hint:
				check(field_hint.size.x < 550 and field_hint.get_minimum_size().y <= field_hint.size.y and field_hint.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "bilingual field-swap explanation fits its real row without clipping")
			if "--capture" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("find_"+entry.fitting+"_"+locale+".png")) == OK,"native discovery capture")
	ui._close_loot(); battle.free(); SortieRuntime.clear_session()

func _stash_visibility() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
	var finds: Array[ItemInstance] = []
	for entry in ContentDB.get_loot_table(TABLE).entries:
		var item := ItemInstance.new(entry.definition_id); item.fitting = entry.fitting
		check(profile.inventory.add_item(item), "explicit stash visibility fixture owns authored gun")
		finds.append(item)
	var ui := HangerUI.new(); ui.configure(profile.inventory,profile.loadout); add_child(ui)
	for locale in ["en","zh_CN"]:
		GameLanguage.set_language(locale,false); ui.sync_loadout_selection()
		await get_tree().process_frame; await get_tree().process_frame
		for item in finds:
			var index := -1
			for row in ui.weapon_option.item_count:
				if ui.weapon_option.get_item_metadata(row) == item.instance_id: index = row; break
			check(index >= 0 and ui.weapon_option.get_item_text(index).contains(tr(WeaponFitting.caption(item.fitting))), "identical base guns have distinguishable fitting names in real selector")
			var tile: StashTile
			for child in ui.stash_grid.get_children():
				if child is StashTile and child.instance_id == item.instance_id: tile = child; break
			check((tile != null and tile.tooltip_text.contains(WeaponFitting.discovery_text(item))) or profile.loadout.is_equipped(item.instance_id), "real stash tile preserves complete benefit and tradeoff")
			check(not WeaponFitting.badge(item.fitting).is_empty() and (locale != "zh_CN" or WeaponFitting.badge(item.fitting) not in ["FAST RELOAD","QUIET","OPTIC"]), "compact modified-item badge is present and localized")
		# Fixture equipment swap uses the same model; ordinary earned double-click
		# is separately exercised by recovered_arms_run, never claimed here.
		check(ui.stash_grid.model.equip_item(finds.back().instance_id,LoadoutState.SLOT_WEAPON_PRIMARY), "normal warehouse model equips concrete observed variant")
		ui.sync_loadout_selection()
		await get_tree().process_frame; await get_tree().process_frame
		check(ui.weapon_option.tooltip_text.contains(tr(WeaponFitting.caption(finds.back().fitting))), "selected equipment retains fitting identity")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("stash_finds_"+locale+".png")) == OK, "native real stash/equipment visibility capture")
	ui.free()


func _field_fixture(with_sniper_ammo := true) -> Dictionary:
	# Explicit ammunition fixtures. These checks do not claim earned discovery.
	var profile := ProfileState.create_new()
	profile.first_mission_completed = true
	if with_sniper_ammo: check(profile.inventory.add_item(ItemInstance.new(&"ammo.762_standard",12)), "field fixture explicitly supplies sniper ammunition")
	var ammo_ids: Array[String] = []
	for item in profile.inventory.get_items():
		if ContentDB.get_ammo(item.definition_id,false): ammo_ids.append(item.instance_id)
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena",&"prototype_combat",ammo_ids),profile)
	check(session != null and session.activate(), "field fixture activates the normal session and finite magazines")
	return {"profile":profile,"session":session}


func _field_rounds(session: SortieSession) -> Dictionary:
	var counts := {}
	for item in session.inventory.get_items():
		if ContentDB.get_ammo(item.definition_id,false): counts[item.definition_id] = int(counts.get(item.definition_id,0))+item.quantity
	for state in session._weapon_runtime_states.values():
		counts[state.ammo_definition_id] = int(counts.get(state.ammo_definition_id,0))+state.magazine_ammo
	# Empty default magazines are not ammunition quantities.
	for id in counts.keys():
		if counts[id] == 0: counts.erase(id)
	return counts


func _field_snapshot(session: SortieSession) -> Dictionary:
	return {"session":SortieCheckpoint.session_data(session),"reserved":session.inventory.reserved_weight,"weight":session.inventory.current_weight}


func _field() -> void:
	SortieRuntime.clear_session()
	_field_transactions()
	_field_ap()
	_field_rejections()
	_field_settlement()
	await _field_player()


func _field_transactions() -> void:
	for entry in ContentDB.get_loot_table(TABLE).entries:
		for slot in LoadoutState.WEAPON_SLOT_IDS:
			var fixture := _field_fixture()
			var profile: ProfileState = fixture.profile
			var session: SortieSession = fixture.session
			var old := session.loadout.get_item(slot,session.inventory)
			old.durability = 47.0
			check(session.fire_weapon(old.instance_id), "field conservation fixture spends one real loaded round")
			var old_data := old.to_dict()
			var incoming := ItemInstance.new(entry.definition_id,1,63.0); incoming.fitting = entry.fitting
			var incoming_data := incoming.to_dict()
			var initial_ids := session.get_initial_carried_instance_ids()
			var ammo_before := _field_rounds(session)
			var weight_before := session.inventory.current_weight
			var base_before := profile.to_dict()
			var other_slot: StringName = LoadoutState.SLOT_WEAPON_SECONDARY if slot == LoadoutState.SLOT_WEAPON_PRIMARY else LoadoutState.SLOT_WEAPON_PRIMARY
			var other_id := session.loadout.get_equipped_instance_id(other_slot)
			var other_runtime: Dictionary = SortieCheckpoint.session_data(session).weapons[other_id].duplicate(true)
			var result: Dictionary = session.exchange_field_weapon(slot,incoming)
			check(result.get("success",false) and result.get("outgoing") is ItemInstance, "all three modified finds can replace either existing weapon slot")
			if not result.get("success",false): continue
			check(result.outgoing.to_dict() == old_data and incoming.to_dict() == incoming_data, "field exchange preserves both exact IDs, durability and conversion")
			check(not session.inventory.contains(old.instance_id) and session.inventory.get_item(incoming.instance_id).to_dict() == incoming_data, "field exchange removes old carried gun and owns the actual incoming gun")
			check(session.loadout.get_equipped_instance_id(slot) == incoming.instance_id and session.loadout.get_equipped_instance_id(other_slot) == other_id, "field exchange changes only the selected slot")
			var state: Variant = session.get_weapon_runtime_state(incoming.instance_id)
			check(session.get_weapon_runtime_state(old.instance_id) == null and state != null and state.magazine_ammo == 0, "old runtime disappears and recovered gun starts with an empty magazine")
			check(SortieCheckpoint.session_data(session).weapons[other_id] == other_runtime, "other weapon magazine and caliber are untouched")
			check(_field_rounds(session) == ammo_before, "per-caliber ammunition is conserved across unloading and exchange")
			check(is_equal_approx(session.inventory.current_weight,weight_before-old.total_weight()+incoming.total_weight()), "loaded-to-loose ammunition does not gain or lose carried mass")
			check(session.get_initial_carried_instance_ids() == initial_ids and profile.to_dict() == base_before, "deployed IDs and warehouse remain unchanged before settlement")
			var snapshot := SortieCheckpoint.session_data(session)
			var restored := SortieCheckpoint.restore_session(snapshot)
			check(session.validate() and restored != null and SortieCheckpoint.session_data(restored) == snapshot, "field-exchanged loadout and magazines round-trip through existing session dictionary")
			check(session.reload_weapon(incoming.instance_id) > 0 and _field_rounds(session) == ammo_before, "normal reload uses existing compatible stock without granting rounds")
			var returned: Dictionary = session.exchange_field_weapon(slot,result.outgoing)
			check(returned.get("success",false) and returned.outgoing.to_dict() == incoming_data and _field_rounds(session) == ammo_before, "swapping back unloads the new magazine and returns the same find without copying ammo")
			for repeat in 3:
				var forward: Dictionary = session.exchange_field_weapon(slot,incoming)
				var backward: Dictionary = session.exchange_field_weapon(slot,old)
				check(forward.get("success",false) and backward.get("success",false) and _field_rounds(session) == ammo_before and session.inventory.get_items().filter(func(item): return item.instance_id in [old.instance_id,incoming.instance_id]).size() == 1, "repeated exchanges keep exactly one carried gun and finite original rounds")


func _field_rejections() -> void:
	var fixture := _field_fixture()
	var session: SortieSession = fixture.session
	var old := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY,session.inventory)
	var incoming := ItemInstance.new(&"weapon.sniper_01"); incoming.fitting = "observation_optic"
	var invalid := ItemInstance.new(&"weapon.assault_rifle_01"); invalid.fitting = "unknown_fixture"
	for pair in [[&"unknown",incoming],[LoadoutState.SLOT_ARMOR,incoming],[LoadoutState.SLOT_WEAPON_PRIMARY,old],[LoadoutState.SLOT_WEAPON_PRIMARY,ItemInstance.new(&"medical.medkit")],[LoadoutState.SLOT_WEAPON_PRIMARY,invalid],[LoadoutState.SLOT_WEAPON_PRIMARY,null]]:
		var before := _field_snapshot(session)
		var item_before: Dictionary = pair[1].to_dict() if pair[1] else {}
		var result: Dictionary = session.exchange_field_weapon(pair[0],pair[1])
		check(not result.get("success",false) and _field_snapshot(session) == before and (pair[1].to_dict() if pair[1] else {}) == item_before, "invalid field source or slot rejects atomically with no item or ammo changes")
	session.inventory.capacity = session.inventory.current_weight
	var full_before := _field_snapshot(session)
	var overweight: Dictionary = session.exchange_field_weapon(LoadoutState.SLOT_WEAPON_PRIMARY,incoming)
	check(not overweight.get("success",false) and _field_snapshot(session) == full_before, "heavier incoming weapon fails at exact full capacity without partial unloading")
	# Same weapon mass, including its existing physical conversion. The loose
	# rounds replace reserved weight, not a second copy of the loaded mass.
	old.fitting = "suppressor"
	session.inventory.capacity = session.inventory.current_weight
	var equal_mass := ItemInstance.new(old.definition_id); equal_mass.fitting = old.fitting
	var full_rounds := _field_rounds(session)
	var full_weight := session.inventory.current_weight
	var equal_result: Dictionary = session.exchange_field_weapon(LoadoutState.SLOT_WEAPON_PRIMARY,equal_mass)
	check(equal_result.get("success",false) and is_equal_approx(session.inventory.current_weight,full_weight) and _field_rounds(session) == full_rounds, "exact-full equal-mass swap succeeds without double-counting unloaded rounds")
	for status in [SortieSession.Status.PREPARING,SortieSession.Status.FAILED,SortieSession.Status.COMPLETED,SortieSession.Status.ABANDONED]:
		session.status = status
		var before := _field_snapshot(session)
		var inactive: Dictionary = session.exchange_field_weapon(LoadoutState.SLOT_WEAPON_PRIMARY,incoming)
		check(not inactive.get("success",false) and _field_snapshot(session) == before, "field swap is unavailable outside active combat")


func _field_settlement() -> void:
	for terminal in ["complete","fail","abandon"]:
		var fixture := _field_fixture()
		var profile: ProfileState = fixture.profile
		var session: SortieSession = fixture.session
		var old_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
		var incoming := ItemInstance.new(&"weapon.assault_rifle_01",1,56.0); incoming.fitting = "suppressor"
		var warehouse_only := ItemInstance.new(&"material.parts",2)
		check(profile.inventory.add_item(warehouse_only), "field settlement fixture includes warehouse-only property")
		var initial_ids := session.get_initial_carried_instance_ids()
		var swapped: Dictionary = session.exchange_field_weapon(LoadoutState.SLOT_WEAPON_PRIMARY,incoming)
		check(swapped.get("success",false), "field settlement fixture exchanges the real gun")
		if not swapped.get("success",false): continue
		check(session.complete_extraction() if terminal == "complete" else (session.fail() if terminal == "fail" else session.abandon()), "field fixture reaches the normal terminal method")
		var outcome := SortieOutcomeService.create_outcome(session)
		check(outcome != null and SortieOutcomeService.commit_outcome(profile,outcome) == OK, "normal field-exchanged outcome commits")
		check(not profile.inventory.contains(old_id) and profile.inventory.contains(warehouse_only.instance_id), "leaving original gun in cache removes it at settlement but never removes warehouse-only property")
		check(profile.inventory.contains(incoming.instance_id) == (terminal == "complete") and outcome.initial_carried_instance_ids == initial_ids, "only safe return recovers the find; death and abandonment lose it with immutable deployed IDs")
		if terminal == "complete":
			check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == incoming.instance_id and profile.inventory.get_item(incoming.instance_id).to_dict() == incoming.to_dict(), "safe return retains the actually worn find and exact conversion")
		var after := profile.to_dict()
		check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and profile.to_dict() == after, "repeated field settlement cannot duplicate either gun, ammunition or money")


func _field_player() -> void:
	# Actual default player and pickup API, no enemies, no earned-play claim.
	for entry in ContentDB.get_loot_table(TABLE).entries:
		var fixture := _field_fixture(false)
		var session: SortieSession = fixture.session
		var player := preload("res://scenes/player/player.tscn").instantiate() as PlayerController
		player.configure_sortie(session); add_child(player); player.set_physics_process(false)
		var incoming := ItemInstance.new(entry.definition_id,1,61.0); incoming.fitting = entry.fitting
		var pickup := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
		pickup.setup(incoming); add_child(pickup); pickup.position = Vector3.RIGHT
		await get_tree().physics_frame
		var old := player.weapon_instance
		var old_data := old.to_dict()
		var initial_ids := session.get_initial_carried_instance_ids()
		var events: Array[String] = []
		var switched: Array[StringName] = []
		pickup.picked_up.connect(func(item: ItemInstance): events.append(item.instance_id))
		player.weapon_switched.connect(func(slot: StringName): switched.append(slot))
		var incoming_definition := ContentDB.get_weapon(incoming.definition_id)
		var expected_ammo := 0
		for id in incoming_definition.compatible_ammo_ids:
			expected_ammo += int(_field_rounds(session).get(StringName(id),0))
		# Only the active gun is unloaded; the other equipped magazine is not
		# available stock for the replacement gun.
		var inactive_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
		var inactive_state: Variant = session.get_weapon_runtime_state(inactive_id)
		if String(inactive_state.ammo_definition_id) in incoming_definition.compatible_ammo_ids: expected_ammo -= inactive_state.magazine_ammo
		check(player.compatible_field_ammo(incoming) == expected_ammo, "field preview counts compatible carried rounds plus the current magazine only")
		for blocked in ["distance","reload","dead","preview","consumed"]:
			if blocked == "distance": pickup.position = Vector3.RIGHT*10
			elif blocked == "reload": player._reload_remaining_by_weapon[old.instance_id] = .75
			elif blocked == "dead": player.is_dead = true
			elif blocked == "preview": player.preview_mode = true
			else: pickup.consumed = true
			var before := _field_snapshot(session)
			var refused: Dictionary = player.equip_cached_weapon(pickup)
			check(not refused.get("success",false) and _field_snapshot(session) == before and pickup.item_instance.to_dict() == incoming.to_dict() and events.is_empty(), "player field swap rejects distance, active reload, death, preview and consumed source without touching the cache")
			pickup.position = Vector3.RIGHT; player._reload_remaining_by_weapon.erase(old.instance_id); player.is_dead = false; player.preview_mode = false; pickup.consumed = false
		var other_view := SubViewport.new(); other_view.own_world_3d = true; other_view.render_target_update_mode = SubViewport.UPDATE_DISABLED; add_child(other_view)
		var remote := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
		remote.setup(ItemInstance.from_dict(incoming.to_dict())); other_view.add_child(remote)
		var before_remote := _field_snapshot(session)
		var refused_world: Dictionary = player.equip_cached_weapon(remote)
		check(not refused_world.get("success",false) and _field_snapshot(session) == before_remote and remote.item_instance.to_dict() == incoming.to_dict(), "same-position source in another World3D cannot be exchanged")
		other_view.free()
		var before_rounds := _field_rounds(session)
		var takes_before := int(player.get("local_motion_events").get("take",0))
		var result: Dictionary = player.equip_cached_weapon(pickup)
		check(result.get("success",false), "default player can equip the actual nearby field find")
		if result.get("success",false):
			check(player.weapon_instance.instance_id == incoming.instance_id and player.weapon_instance.fitting == entry.fitting and is_instance_valid(player.equipped_weapon_visual), "real hand-held item changes to the find with its physical presentation")
			check(pickup.item_instance.to_dict() == old_data and not pickup.consumed and events == [incoming.instance_id], "existing cache slot now holds the old gun and emits exactly one acquisition event")
			check(switched == [LoadoutState.SLOT_WEAPON_PRIMARY] and int(player.get("local_motion_events").get("take",0)) > takes_before, "field swap updates weapon observers and requests the actual TakeGun motion")
			check(player.get_magazine_ammo() == 0 and _field_rounds(session) == before_rounds and session.get_initial_carried_instance_ids() == initial_ids, "player API grants no magazine, ammunition or new deployed ID")
			if expected_ammo == 0:
				check(not player.reload_weapon() and not player.debug_fire_once(), "no compatible ammunition remains a genuine empty, unusable gun rather than a free round")
			else:
				check(player.reload_weapon() and player.get_magazine_ammo() > 0 and _field_rounds(session) == before_rounds, "normal R path reloads the actual find using finite existing compatible ammo")
				# Finish the controlled reload before checking a second legal swap.
				player._reload_remaining_by_weapon[incoming.instance_id] = 0.0
				if player.combat_rig: player.combat_rig._update_reload(5.0)
			check(not player._reload_remaining_by_weapon.has(old.instance_id), "field player removes obsolete old-gun reload state")
			var back: Dictionary = player.equip_cached_weapon(pickup)
			check(back.get("success",false) and pickup.item_instance.instance_id == incoming.instance_id and player.weapon_instance.instance_id == old.instance_id and _field_rounds(session) == before_rounds, "real player can exchange back without consuming or rerolling the cache slot")
			if entry.fitting == "suppressor" and back.get("success",false):
				check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "field fixture selects the existing secondary weapon normally")
				var primary_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
				var secondary_id := player.weapon_instance.instance_id
				var secondary: Dictionary = player.equip_cached_weapon(pickup)
				check(secondary.get("success",false) and player.active_weapon_slot == LoadoutState.SLOT_WEAPON_SECONDARY and player.weapon_instance.instance_id == incoming.instance_id and session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == primary_id and pickup.item_instance.instance_id == secondary_id, "actual player replaces the currently selected secondary slot without resetting to primary")
				check(_field_rounds(session) == before_rounds and not player._reload_remaining_by_weapon.has(secondary_id), "secondary swap keeps all rounds and removes only its old reload record")
		player.free(); pickup.free()


func _field_ap() -> void:
	var profile := ProfileState.create_new()
	for item in profile.inventory.get_items():
		if item.definition_id == &"ammo.556_standard": profile.inventory.remove_item(item.instance_id)
	check(profile.inventory.add_item(ItemInstance.new(&"ammo.556_ap",36)), "explicit AP-only field fixture provides finite rounds rather than relabeling a standard magazine")
	var ammo_ids: Array[String] = []
	for item in profile.inventory.get_items():
		if ContentDB.get_ammo(item.definition_id,false): ammo_ids.append(item.instance_id)
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena",&"prototype_combat",ammo_ids),profile)
	check(session != null and session.activate(), "AP field fixture activates through existing compatibility selection")
	var old_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var state: Variant = session.get_weapon_runtime_state(old_id)
	check(state.ammo_definition_id == &"ammo.556_ap" and state.magazine_ammo > 0 and session.fire_weapon(old_id) and session.reload_weapon(old_id) == 1, "normal finite AP reload retains the loaded ammunition type")
	var before := _field_rounds(session)
	var incoming := ItemInstance.new(&"weapon.assault_rifle_01"); incoming.fitting = "suppressor"
	var swapped: Dictionary = session.exchange_field_weapon(LoadoutState.SLOT_WEAPON_PRIMARY,incoming)
	check(swapped.get("success",false) and _field_rounds(session) == before and not _field_rounds(session).has(&"ammo.556_standard"), "field unloading returns AP as AP, never converts it to standard ammunition")
	var loose_ap := 0
	for item in session.inventory.get_items():
		if item.definition_id == &"ammo.556_ap": loose_ap += item.quantity
	check(loose_ap == int(before.get(&"ammo.556_ap",0)), "all old AP magazine rounds become actual loose AP stock")


func _field_world_battle() -> Node3D:
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	return battle


func _field_json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _field_world(read_saved: bool) -> void:
	# Controlled real battle/checkpoint fixture. The player's archive position
	# is assigned here and enemies are paused, not represented as earned play.
	SortieRuntime.clear_session()
	var expected: Dictionary = {}
	if read_saved:
		expected = JSON.parse_string(FileAccess.get_file_as_string(FIELD_EXPECTED_PATH))
		var loaded := ProfileRuntime.load_profile(FIELD_WORLD_PATH)
		check(loaded, "independent field process loads the isolated durable profile")
		var resumed := SortieRuntime.resume_saved(FIELD_WORLD_PATH) if loaded else ERR_INVALID_DATA
		check(resumed == OK, "independent field process resumes the exact signed weapon-swap checkpoint")
		if resumed != OK: return
	else:
		var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
		check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",FIELD_WORLD_PATH).error == OK, "field-world fixture deploys through the real persisted campus transaction")
	get_tree().paused = true # Inspect/save the exact instant, without live AI drift.
	var battle: Node3D = await _field_world_battle()
	check(not FlowMenu.is_open() and battle.session != null, "real field fixture attaches and validates its authored world")
	if FlowMenu.is_open() or not battle.session:
		battle.free(); SortieRuntime.clear_session(); get_tree().paused = false; return
	var session: SortieSession = battle.session
	if not read_saved:
		var archive: LootSpawnPoint
		for point in battle.area_root.loot_points:
			if not point.bonus_loot_table_id.is_empty(): archive = point
		check(archive != null, "field-world fixture uses the existing guarded archive, not a new loot site")
		if not archive:
			battle.free(); SortieRuntime.clear_session(); get_tree().paused = false; return
		var pickup: LootPickup
		for child in archive.get_children():
			if child is LootPickup and not child.item_instance.fitting.is_empty(): pickup = child
		check(pickup != null, "current unmodified profile has one actual normally rolled field weapon")
		if not pickup:
			battle.free(); SortieRuntime.clear_session(); get_tree().paused = false; return
		battle.player.global_position = archive.global_position + Vector3.RIGHT
		var old: ItemInstance = battle.player.weapon_instance
		var old_data := old.to_dict()
		var incoming_data := pickup.item_instance.to_dict()
		var initial_ids := session.get_initial_carried_instance_ids()
		var rounds_before := _field_rounds(session)
		# A completed old reload's zero entry is legal, but must not become an
		# orphan reference after replacing the gun and saving the world.
		battle.player._reload_remaining_by_weapon[old.instance_id] = 0.0
		var swap: Dictionary = battle.player.equip_cached_weapon(pickup)
		check(swap.get("success",false) and pickup.item_instance.to_dict() == old_data, "actual field swap places the original gun in the same authored cache")
		if not swap.get("success",false):
			battle.free(); SortieRuntime.clear_session(); get_tree().paused = false; return
		var loaded_rounds := 0
		if "--field-empty" not in OS.get_cmdline_user_args() and battle.player.get_reserve_ammo() > 0:
			check(battle.player.reload_weapon(), "loaded checkpoint uses the actual player reload method and existing compatible ammunition")
			loaded_rounds = battle.player.get_magazine_ammo()
		check(_field_rounds(session) == rounds_before and session.get_initial_carried_instance_ids() == initial_ids, "checkpoint fixture has unchanged caliber totals and original deployed IDs")
		var world := SortieCheckpoint.capture_world(battle)
		check(SortieCheckpoint.validate_world(world,battle) and world.layout == SortieCheckpoint.layout_signature(battle.area_root), "swapped real world validates against its authored collision and node signature")
		check(not world.reloads.has(old.instance_id), "swapped world contains no orphan old-weapon reload key")
		check(SortieRuntime.save_checkpoint() == OK, "field swap and original cache slot commit through the normal atomic checkpoint service")
		expected = {"archive":String(battle.area_root.get_path_to(archive)),"old":old_data,"incoming":incoming_data,"initial_ids":initial_ids,"rounds":rounds_before,"magazine":loaded_rounds,"session":SortieCheckpoint.session_data(session),"world":world}
		var file := FileAccess.open(FIELD_EXPECTED_PATH,FileAccess.WRITE)
		check(file != null, "isolated field expected-state record opens")
		if file: file.store_string(JSON.stringify(expected)); file.close()
		print("FIELD_WEAPON_WORLD_WRITE / magazine=",loaded_rounds," cache=",expected.archive," old=",old.instance_id," new=",incoming_data.instance_id)
	else:
		check(_field_json(SortieCheckpoint.session_data(session)) == _field_json(expected.session), "independent process retains exact current weapon IDs, magazine type/count and deployed IDs")
		check(_field_json(_field_rounds(session)) == _field_json(expected.rounds) and battle.player.get_magazine_ammo() == int(expected.magazine), "independent process neither grants nor drops loaded or loose ammunition")
		var archive := battle.area_root.get_node_or_null(NodePath(expected.archive)) as LootSpawnPoint
		var pickup: LootPickup
		if archive:
			for child in archive.get_children():
				if child is LootPickup and child.item_instance.instance_id == expected.old.instance_id: pickup = child
		check(pickup != null and pickup.item_instance.to_dict() == ItemInstance.from_dict(expected.old).to_dict(), "old gun restores to the exact original world-cache slot with its identity and durability")
		check(battle.player.weapon_instance.to_dict() == ItemInstance.from_dict(expected.incoming).to_dict() and battle.player.active_weapon_slot == LoadoutState.SLOT_WEAPON_PRIMARY, "actual resumed player wears the found gun rather than a stale initial loadout")
		var world := SortieCheckpoint.capture_world(battle)
		check(SortieCheckpoint.validate_world(world,battle) and world.layout == expected.world.layout and world.layout == SortieCheckpoint.layout_signature(battle.area_root), "independent field world validates its preserved authored layout signature")
		check(_field_json(world.nodes) == _field_json(expected.world.nodes) and not world.reloads.has(expected.old.instance_id), "world contents preserve the old-gun slot without duplicate pickup or orphan reload ID")
		check(_field_json(world.reloads) == _field_json(expected.world.reloads), "remaining new-weapon reload state survives independent process restoration exactly")
		if pickup:
			# Finish only the frozen fixture's reload before requesting another
			# legal exchange; active reload rejection is exercised in --field.
			battle.player._reload_remaining_by_weapon[battle.player.weapon_instance.instance_id] = 0.0
			if battle.player.combat_rig: battle.player.combat_rig._update_reload(5.0)
			var rounds_before := _field_rounds(session)
			var exchanged: Dictionary = battle.player.equip_cached_weapon(pickup)
			check(exchanged.get("success",false) and battle.player.weapon_instance.instance_id == expected.old.instance_id and pickup.item_instance.instance_id == expected.incoming.instance_id, "independent resumed player can exchange back with the same physical cache slot")
			var again: Dictionary = battle.player.equip_cached_weapon(pickup)
			check(again.get("success",false) and battle.player.weapon_instance.instance_id == expected.incoming.instance_id and pickup.item_instance.instance_id == expected.old.instance_id and _field_rounds(session) == rounds_before, "repeated post-resume exchanges do not copy either weapon or its magazine")
			var after_world := SortieCheckpoint.capture_world(battle)
			check(SortieCheckpoint.validate_world(after_world,battle) and not after_world.reloads.has(expected.old.instance_id), "post-resume exchange remains a valid world checkpoint with no stale reload references")
		print("FIELD_WEAPON_WORLD_READ / magazine=",expected.magazine," cache=",expected.archive)
	battle.free(); SortieRuntime.clear_session(); get_tree().paused = false
