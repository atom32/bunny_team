extends Node3D
## Controlled fixtures, NOT earned combat or a human loot/fun acceptance test.
const TABLE := &"campus_recovered_arms"
const PATH := "user://recovered_arms.json"
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
