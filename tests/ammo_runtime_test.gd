extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const WEAPON_RUNTIME_STATE_SCRIPT := preload("res://scripts/data/weapon_runtime_state.gd")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_initial_magazine_and_player_fire()
	_test_empty_magazine()
	_test_reload()
	_test_partial_reserve()
	_test_incompatible_and_full_reload()
	_test_multiple_stacks()
	_test_extraction_materialization_and_profile_isolation()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("AMMO_RUNTIME_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("AMMO_RUNTIME_TEST: %s" % failure)
		print("AMMO_RUNTIME_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_initial_magazine_and_player_fire() -> void:
	var fixture := _create_session_fixture(120)
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	var state: Variant = session.get_weapon_runtime_state(weapon_id)
	check(state != null and state.magazine_ammo == 30 and state.magazine_capacity == 30, "session initializes the rifle magazine to 30")
	check(session.get_reserve_ammo(weapon_id) == 120, "initial magazine does not consume reserve ammunition")
	var capacity_before := session.inventory.get_used_capacity()
	var profile_before := profile.to_dict()
	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	await get_tree().process_frame
	player.aim_world_point = player.global_position + Vector3.FORWARD * 20.0 + Vector3.UP
	check(player.debug_fire_once(), "player fire path accepts a shot with magazine ammunition")
	check(state.magazine_ammo == 29, "one successful player shot consumes one magazine round")
	check(session.get_reserve_ammo(weapon_id) == 120, "firing does not consume reserve ammunition")
	check(is_equal_approx(session.inventory.get_used_capacity(), capacity_before), "magazine consumption does not change inventory capacity")
	check(profile.to_dict() == profile_before, "player firing leaves the warehouse unchanged")
	player.queue_free()
	await get_tree().process_frame


func _test_empty_magazine() -> void:
	var fixture := _create_session_fixture(30)
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	for _round in 30:
		check(session.fire_weapon(weapon_id), "available magazine round fires")
	var before := session.inventory.to_dict()
	check(not session.fire_weapon(weapon_id), "empty magazine rejects firing")
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 0, "empty magazine remains at zero")
	check(session.inventory.to_dict() == before, "rejected fire leaves reserve ammunition unchanged")


func _test_reload() -> void:
	var fixture := _create_session_fixture(50)
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	for _round in 20:
		session.fire_weapon(weapon_id)
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 10, "reload fixture reaches 10 rounds")
	check(session.reload_weapon(weapon_id) == 20, "partial magazine reloads the required 20 rounds")
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 30, "reload fills the magazine")
	check(session.get_reserve_ammo(weapon_id) == 30, "reload consumes exactly 20 reserve rounds")


func _test_partial_reserve() -> void:
	var fixture := _create_session_fixture(12)
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	for _round in 20:
		session.fire_weapon(weapon_id)
	check(session.reload_weapon(weapon_id) == 12, "reload uses all available reserve when it cannot fill the magazine")
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 22, "partial reserve raises magazine from 10 to 22")
	check(session.get_reserve_ammo(weapon_id) == 0, "partial reload removes the exhausted reserve stack")


func _test_incompatible_and_full_reload() -> void:
	var incompatible_inventory := InventoryState.new(20.0)
	check(incompatible_inventory.add_item(ItemInstance.new(&"ammo.556_ap", 40, 100.0, "ap_only")), "incompatible fixture owns AP ammunition")
	var incompatible_state = WEAPON_RUNTIME_STATE_SCRIPT.new("rifle", &"ammo.556_standard", 30, 10)
	var incompatible_before := incompatible_inventory.to_dict()
	check(incompatible_state.reload(incompatible_inventory) == 0, "standard-ammo weapon rejects AP reserve")
	check(incompatible_state.magazine_ammo == 10 and incompatible_inventory.to_dict() == incompatible_before, "failed incompatible reload is atomic")

	var full_inventory := InventoryState.new(20.0)
	check(full_inventory.add_item(ItemInstance.new(&"ammo.556_standard", 40, 100.0, "full_reserve")), "full-magazine fixture owns reserve ammunition")
	var full_state = WEAPON_RUNTIME_STATE_SCRIPT.new("rifle", &"ammo.556_standard", 30, 30)
	var full_before := full_inventory.to_dict()
	check(full_state.reload(full_inventory) == 0, "full magazine cannot reload")
	check(full_state.magazine_ammo == 30 and full_inventory.to_dict() == full_before, "full-magazine reload leaves all state unchanged")


func _test_multiple_stacks() -> void:
	var inventory := InventoryState.new(20.0)
	check(inventory.add_item(ItemInstance.new(&"ammo.556_standard", 100, 100.0, "multi_stack_a")), "multiple-stack fixture accepts first stack")
	check(inventory.add_item(ItemInstance.new(&"ammo.556_standard", 50, 100.0, "multi_stack_b")), "multiple-stack fixture accepts overflow stack")
	check(_total_ammo(inventory, &"ammo.556_standard") == 150 and inventory.get_items().size() == 2, "fixture contains two standard-ammo stacks")
	var state = WEAPON_RUNTIME_STATE_SCRIPT.new("rifle", &"ammo.556_standard", 40, 0)
	check(state.reload(inventory) == 40, "reload consumes across multiple compatible stacks")
	check(state.magazine_ammo == 40 and _total_ammo(inventory, &"ammo.556_standard") == 110, "multi-stack reload transfers exactly 40 rounds")


func _test_extraction_materialization_and_profile_isolation() -> void:
	var fixture := _create_session_fixture(120)
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	var ammo_id: String = fixture.ammo_id
	var profile_before := profile.to_dict()
	for _round in 10:
		session.fire_weapon(weapon_id)
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 20, "extraction fixture has 20 rounds remaining in magazine")
	check(profile.to_dict() == profile_before, "sortie fire still leaves profile unchanged before extraction")
	check(session.complete_extraction(), "successful extraction materializes runtime ammunition")
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == 0, "materialized magazine is cleared exactly once")
	check(_total_ammo(session.inventory, &"ammo.556_standard") == 140, "reserve 120 plus remaining magazine 20 becomes recovered ammo 140")
	check(profile.to_dict() == profile_before, "extraction alone does not mutate profile")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and _total_ammo(outcome.inventory, &"ammo.556_standard") == 140, "outcome stores materialized ammo only in recovered inventory")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "ammo outcome commits through the existing boundary")
	check(_total_ammo(profile.inventory, &"ammo.556_standard") == 140, "commit replaces initial carried ammo with recovered ammo")
	check(profile.inventory.contains(ammo_id), "commit preserves the original carried stack identity when possible")
	var committed := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK and profile.to_dict() == committed, "repeated ammo outcome commit is idempotent")


func _create_session_fixture(reserve_quantity: int) -> Dictionary:
	var profile := ProfileState.create_new()
	var ammo := _find_item(profile.inventory, &"ammo.556_standard")
	ammo.quantity = reserve_quantity
	var weapon_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var carried_ids: Array[String] = [ammo.instance_id]
	var request := profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids)
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.activate(), "ammo runtime fixture creates an active sortie")
	return {
		"profile": profile,
		"session": session,
		"weapon_id": weapon_id,
		"ammo_id": ammo.instance_id,
	}


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _total_ammo(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
