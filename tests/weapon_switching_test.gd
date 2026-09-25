extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_switching_and_runtime_isolation()
	await _test_extraction_recovery()
	await _test_failure_isolation()
	await _test_smg_rocket_lifecycle()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("WEAPON_SWITCHING_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("WEAPON_SWITCHING_TEST: %s" % failure)
		print("WEAPON_SWITCHING_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_switching_and_runtime_isolation() -> void:
	var fixture := await _create_fixture()
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var primary_id: String = fixture.primary_id
	var secondary_id: String = fixture.secondary_id
	var profile_primary := profile.inventory.get_item(primary_id)
	var profile_secondary := profile.inventory.get_item(secondary_id)
	var sortie_primary := session.inventory.get_item(primary_id)
	var sortie_secondary := session.inventory.get_item(secondary_id)
	var primary_state: WeaponRuntimeState = session.get_weapon_runtime_state(primary_id)
	var secondary_state: WeaponRuntimeState = session.get_weapon_runtime_state(secondary_id)

	check(profile_primary != null and profile_secondary != null, "profile owns concrete primary and secondary weapon instances")
	check(primary_id != secondary_id and profile_primary != profile_secondary, "primary and secondary use distinct business instances")
	check(sortie_primary != profile_primary and sortie_secondary != profile_secondary, "sortie owns deep copies of both weapon instances")
	check(primary_state != null and secondary_state != null and primary_state != secondary_state, "primary and secondary own independent WeaponRuntimeState objects")
	check(primary_state.weapon_definition_id == &"weapon.assault_rifle_01" and secondary_state.weapon_definition_id == &"weapon.rocket_launcher_01", "each runtime state records its own WeaponDefinition ID")
	check(primary_state.magazine_ammo == 30 and secondary_state.magazine_ammo == 1, "both carried ammo types initialize their own magazines")
	check(player.active_weapon_slot == LoadoutState.SLOT_WEAPON_PRIMARY, "player starts with the primary slot active")
	check(InputMap.has_action("switch_weapon"), "prototype input exposes one weapon-switch action")

	check(player.debug_fire_once(), "active primary weapon fires")
	check(primary_state.magazine_ammo == 29 and secondary_state.magazine_ammo == 1, "primary fire changes only the primary magazine")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "player switches to the equipped secondary slot")
	check(player.active_weapon_slot == LoadoutState.SLOT_WEAPON_SECONDARY and player.weapon_instance.instance_id == secondary_id, "secondary slot resolves its concrete ItemInstance")
	check(player.debug_fire_once(), "active secondary weapon fires")
	check(secondary_state.magazine_ammo == 0 and primary_state.magazine_ammo == 29, "secondary fire changes only the secondary magazine")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY), "player switches back to primary")
	check(primary_state.magazine_ammo == 29, "primary magazine survives a round trip through the secondary slot")

	for _round in 9:
		check(player.debug_fire_once(), "primary runtime can continue firing after switch")
	check(primary_state.magazine_ammo == 20 and secondary_state.magazine_ammo == 0, "fixture reaches isolated partial magazines")
	check(player.reload_weapon(), "reload applies to the active primary only")
	check(primary_state.magazine_ammo == 30 and secondary_state.magazine_ammo == 0, "primary reload leaves secondary runtime untouched")

	var active_before := player.active_weapon_slot
	check(not player.switch_weapon(&"weapon_missing"), "unknown weapon slot is rejected")
	check(player.active_weapon_slot == active_before, "rejected switch keeps the active slot")
	check(player.switch_weapon(active_before), "switching to the already active slot is a stable no-op")
	check(session.fail(), "fixture can enter a terminal non-active state")
	check(not player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "FAILED sortie rejects weapon switching")
	check(not player.debug_fire_once() and not player.reload_weapon(), "FAILED sortie rejects fire and reload")
	_cleanup_fixture(player)


func _test_extraction_recovery() -> void:
	var fixture := await _create_fixture()
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var primary_id: String = fixture.primary_id
	var secondary_id: String = fixture.secondary_id
	var profile_before := profile.to_dict()
	var primary_state: WeaponRuntimeState = session.get_weapon_runtime_state(primary_id)
	var secondary_state: WeaponRuntimeState = session.get_weapon_runtime_state(secondary_id)

	check(player.debug_fire_once(), "extraction fixture consumes one primary round")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "extraction fixture activates secondary")
	check(player.debug_fire_once(), "extraction fixture consumes one secondary round")
	check(player.reload_weapon(), "secondary reload uses only rocket reserve")
	var expected_standard := session.get_reserve_ammo(primary_id) + primary_state.magazine_ammo
	var expected_rockets := session.get_reserve_ammo(secondary_id) + secondary_state.magazine_ammo
	check(profile.to_dict() == profile_before, "dual-weapon fire and reload leave the warehouse unchanged")
	check(session.complete_extraction(), "successful extraction materializes both runtime magazines")
	check(primary_state.magazine_ammo == 0 and secondary_state.magazine_ammo == 0, "both magazines are cleared after materialization")
	check(_total_quantity(session.inventory, &"ammo.556_standard") == expected_standard, "primary magazine materializes exactly once")
	check(_total_quantity(session.inventory, &"ammo.rocket_standard") == expected_rockets, "secondary magazine materializes exactly once")

	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "dual-weapon outcome commits through the existing recovery boundary")
	check(profile.inventory.contains(primary_id) and profile.inventory.contains(secondary_id), "both recovered weapon instances return to the warehouse")
	check(_count_instance_id(profile.inventory, primary_id) == 1 and _count_instance_id(profile.inventory, secondary_id) == 1, "weapon instance IDs remain unique after recovery")
	check(_total_quantity(profile.inventory, &"ammo.556_standard") == expected_standard, "warehouse receives final primary ammunition state")
	check(_total_quantity(profile.inventory, &"ammo.rocket_standard") == expected_rockets, "warehouse receives final secondary ammunition state")
	check(profile.validate(), "recovered dual-slot loadout still resolves through warehouse inventory")
	var committed := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK and profile.to_dict() == committed, "repeated dual-weapon commit is idempotent")
	_cleanup_fixture(player)


func _test_failure_isolation() -> void:
	var fixture := await _create_fixture()
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var profile_before := profile.to_dict()

	check(player.debug_fire_once(), "failure fixture consumes primary runtime ammo")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "failure fixture switches secondary")
	check(player.debug_fire_once(), "failure fixture consumes secondary runtime ammo")
	check(session.fail(), "failure fixture enters FAILED")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "FAILED sortie creates a failed outcome")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "failed dual-weapon outcome uses no-op commit")
	check(profile.to_dict() == profile_before, "failure preserves the exact pre-sortie warehouse and both weapons")
	_cleanup_fixture(player)


func _test_smg_rocket_lifecycle() -> void:
	var fixture := await _create_fixture(&"weapon.smg_01")
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var smg_id: String = fixture.primary_id
	var rocket_id: String = fixture.secondary_id
	var smg_state: WeaponRuntimeState = session.get_weapon_runtime_state(smg_id)
	var rocket_state: WeaponRuntimeState = session.get_weapon_runtime_state(rocket_id)
	var profile_before := profile.to_dict()

	check(profile.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, profile.inventory).definition_id == &"weapon.smg_01", "Hanger-compatible LoadoutState equips the owned SMG instance as primary")
	check(smg_state != null and rocket_state != null and smg_state != rocket_state, "SMG and Rocket own independent runtime states")
	check(smg_state.magazine_capacity == 36 and smg_state.magazine_ammo == 36, "SMG initializes its authored thirty-six-round magazine")
	check(rocket_state.magazine_capacity == 1 and rocket_state.magazine_ammo == 1, "Rocket initializes its independent single-round magazine")

	for _shot in 5:
		check(player.debug_fire_once(), "SMG fires from the active primary slot")
	check(smg_state.magazine_ammo == 31 and rocket_state.magazine_ammo == 1, "SMG fire leaves Rocket magazine untouched")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "SMG fixture switches to Rocket")
	check(player.debug_fire_once() and rocket_state.magazine_ammo == 0, "Rocket fire consumes only Rocket magazine")
	check(player.reload_weapon(), "Rocket reload consumes compatible Rocket reserve")
	check(rocket_state.magazine_ammo == 1 and session.get_reserve_ammo(rocket_id) == 3, "Rocket reload does not consume 5.56 reserve")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY), "SMG fixture switches back to primary")
	check(smg_state.magazine_ammo == 31, "SMG magazine survives the Rocket round trip")
	check(player.reload_weapon(), "SMG reload consumes compatible 5.56 reserve")
	check(smg_state.magazine_ammo == 36 and session.get_reserve_ammo(smg_id) == 115, "SMG reload restores five rounds without consuming Rocket reserve")
	check(rocket_state.magazine_ammo == 1 and session.get_reserve_ammo(rocket_id) == 3, "SMG reload leaves Rocket runtime unchanged")
	check(profile.to_dict() == profile_before, "SMG and Rocket runtime use leaves Warehouse unchanged before extraction")

	var expected_standard := session.get_reserve_ammo(smg_id) + smg_state.magazine_ammo
	var expected_rockets := session.get_reserve_ammo(rocket_id) + rocket_state.magazine_ammo
	check(session.complete_extraction(), "SMG and Rocket fixture extracts successfully")
	check(_total_quantity(session.inventory, &"ammo.556_standard") == expected_standard, "extraction materializes remaining SMG magazine exactly once")
	check(_total_quantity(session.inventory, &"ammo.rocket_standard") == expected_rockets, "extraction materializes remaining Rocket magazine exactly once")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "SMG and Rocket recovery commits through SortieOutcome")
	check(_total_quantity(profile.inventory, &"ammo.556_standard") == expected_standard, "Warehouse receives final SMG ammunition without duplication")
	check(_total_quantity(profile.inventory, &"ammo.rocket_standard") == expected_rockets, "Warehouse receives final Rocket ammunition without duplication")
	check(_count_instance_id(profile.inventory, smg_id) == 1 and _count_instance_id(profile.inventory, rocket_id) == 1, "SMG and Rocket business instance IDs remain unique")
	var committed := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK and profile.to_dict() == committed, "repeated SMG and Rocket commit is idempotent")
	_cleanup_fixture(player)

	var failure_fixture := await _create_fixture(&"weapon.smg_01")
	var failure_profile: ProfileState = failure_fixture.profile
	var failure_session: SortieSession = failure_fixture.session
	var failure_player: PlayerController = failure_fixture.player
	var failure_before := failure_profile.to_dict()
	check(failure_player.debug_fire_once(), "failed SMG fixture consumes runtime ammunition")
	check(failure_player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "failed SMG fixture switches to Rocket")
	check(failure_player.debug_fire_once(), "failed SMG fixture consumes Rocket runtime ammunition")
	var lost_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "smg_failure_loot")
	var pickup := LootPickup.new()
	pickup.setup(lost_loot)
	check(pickup.try_pickup(failure_session) == LootPickup.PickupResult.SUCCESS, "failed SMG fixture carries temporary loot")
	pickup.free()
	check(failure_session.fail(), "SMG and Rocket fixture enters FAILED")
	var failed_outcome := SortieOutcomeService.create_outcome(failure_session)
	check(failed_outcome != null and SortieOutcomeService.commit_outcome(failure_profile, failed_outcome) == OK, "failed SMG and Rocket outcome uses no-op commit")
	check(failure_profile.to_dict() == failure_before, "FAILED SMG and Rocket sortie preserves Warehouse and Profile loadout")
	check(not failure_profile.inventory.contains(lost_loot.instance_id), "FAILED SMG and Rocket sortie loses temporary loot")
	_cleanup_fixture(failure_player)


func _create_fixture(primary_definition_id: StringName = &"weapon.assault_rifle_01") -> Dictionary:
	var profile := ProfileState.create_new()
	if primary_definition_id != &"weapon.assault_rifle_01":
		var requested_primary := _find_item(profile.inventory, primary_definition_id)
		check(requested_primary != null and profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, requested_primary.instance_id, profile.inventory), "fixture equips requested primary weapon")
	var primary_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var secondary_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
	var standard_ammo := _find_item(profile.inventory, &"ammo.556_standard")
	var rocket_ammo := _find_item(profile.inventory, &"ammo.rocket_standard")
	var carried_ids: Array[String] = [standard_ammo.instance_id, rocket_ammo.instance_id]
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		carried_ids
	)
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.activate(), "fixture creates an active dual-weapon sortie")
	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	await get_tree().process_frame
	return {
		"profile": profile,
		"session": session,
		"player": player,
		"primary_id": primary_id,
		"secondary_id": secondary_id,
	}


func _cleanup_fixture(player: PlayerController) -> void:
	if is_instance_valid(player):
		player.queue_free()
	for rocket in find_children("RocketProjectile", "Area3D", true, false):
		rocket.queue_free()
	await get_tree().process_frame


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _total_quantity(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func _count_instance_id(inventory: InventoryState, instance_id: String) -> int:
	var count := 0
	for item in inventory.get_items():
		if item.instance_id == instance_id:
			count += 1
	return count


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
