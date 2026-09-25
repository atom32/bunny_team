extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const DESTRUCTIBLE_SCENE := preload("res://scenes/world/destructible_world_object.tscn")

const LOADOUT_CASES := [
	{
		"label": "AR + SMG",
		"primary": &"weapon.assault_rifle_01",
		"secondary": &"weapon.smg_01",
		"shared_ammo": true,
	},
	{
		"label": "AR + Rocket",
		"primary": &"weapon.assault_rifle_01",
		"secondary": &"weapon.rocket_launcher_01",
		"shared_ammo": false,
	},
	{
		"label": "SMG + Rocket",
		"primary": &"weapon.smg_01",
		"secondary": &"weapon.rocket_launcher_01",
		"shared_ammo": false,
	},
]

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	var weapon_metrics := await _collect_weapon_metrics()
	for loadout_case in LOADOUT_CASES:
		await _run_completed_loadout(loadout_case, weapon_metrics)
	await _run_failed_loadout()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("LOADOUT_DECISION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("LOADOUT_DECISION_TEST: %s" % failure)
		print("LOADOUT_DECISION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _run_completed_loadout(loadout_case: Dictionary, weapon_metrics: Dictionary) -> void:
	var fixture := await _create_fixture(loadout_case.primary, loadout_case.secondary)
	if fixture.is_empty():
		return
	var label: String = loadout_case.label
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var primary_id: String = fixture.primary_id
	var secondary_id: String = fixture.secondary_id
	var primary_state: WeaponRuntimeState = session.get_weapon_runtime_state(primary_id)
	var secondary_state: WeaponRuntimeState = session.get_weapon_runtime_state(secondary_id)
	var primary_definition := ContentDB.get_weapon(loadout_case.primary)
	var secondary_definition := ContentDB.get_weapon(loadout_case.secondary)
	var profile_before := profile.to_dict()

	check(primary_id != secondary_id, "%s uses two distinct weapon instance IDs" % label)
	check(
		profile.inventory.get_item(primary_id) != session.inventory.get_item(primary_id)
		and profile.inventory.get_item(secondary_id) != session.inventory.get_item(secondary_id),
		"%s sortie weapon instances are deep snapshots" % label
	)
	check(primary_state != null and secondary_state != null and primary_state != secondary_state, "%s owns independent runtime states" % label)
	if not primary_state or not secondary_state:
		await _cleanup_fixture(player)
		return
	var shares_ammo := primary_state.ammo_definition_id == secondary_state.ammo_definition_id
	check(shares_ammo == bool(loadout_case.shared_ammo), "%s has the expected reserve-ammo relationship" % label)
	check(session.get_initial_carried_instance_ids().has(primary_id) and session.get_initial_carried_instance_ids().has(secondary_id), "%s snapshots both equipped weapons" % label)

	var primary_metrics: Dictionary = weapon_metrics[primary_definition.id]
	var secondary_metrics: Dictionary = weapon_metrics[secondary_definition.id]
	print(
		"LOADOUT_TRACE | %s | primary=%s | secondary=%s | ammo=%s" % [
			label,
			_format_weapon(primary_definition, primary_metrics),
			_format_weapon(secondary_definition, secondary_metrics),
			"SHARED %s" % primary_state.ammo_definition_id if shares_ammo else "%s + %s" % [primary_state.ammo_definition_id, secondary_state.ammo_definition_id],
		]
	)

	var initial_totals := _get_runtime_ammo_totals(session, [primary_state, secondary_state])
	var primary_mag_before := primary_state.magazine_ammo
	var secondary_mag_before := secondary_state.magazine_ammo
	check(player.debug_fire_once(), "%s primary fires through PlayerController" % label)
	check(primary_state.magazine_ammo == primary_mag_before - 1 and secondary_state.magazine_ammo == secondary_mag_before, "%s primary fire does not change secondary magazine" % label)
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "%s switches to secondary" % label)
	check(player.debug_fire_once(), "%s secondary fires through PlayerController" % label)
	check(secondary_state.magazine_ammo == secondary_mag_before - 1 and primary_state.magazine_ammo == primary_mag_before - 1, "%s secondary fire preserves primary magazine" % label)
	var after_fire_totals := _get_runtime_ammo_totals(session, [primary_state, secondary_state])
	var expected_spent_by_ammo := {
		primary_state.ammo_definition_id: 1,
	}
	expected_spent_by_ammo[secondary_state.ammo_definition_id] = int(expected_spent_by_ammo.get(secondary_state.ammo_definition_id, 0)) + 1
	for ammo_definition_id in expected_spent_by_ammo:
		check(
			int(after_fire_totals[ammo_definition_id]) == int(initial_totals[ammo_definition_id]) - int(expected_spent_by_ammo[ammo_definition_id]),
			"%s consumes the correct total for %s" % [label, ammo_definition_id]
		)

	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY), "%s switches back to primary" % label)
	check(player.reload_weapon(), "%s reloads primary" % label)
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "%s returns to secondary" % label)
	check(player.reload_weapon(), "%s reloads secondary" % label)
	var after_reload_totals := _get_runtime_ammo_totals(session, [primary_state, secondary_state])
	check(after_reload_totals == after_fire_totals, "%s reload moves ammo without creating or deleting rounds" % label)
	check(profile.to_dict() == profile_before, "%s runtime combat leaves Warehouse unchanged" % label)
	print(
		"LOADOUT_TRACE | %s | initial_ammo=%s | after_fire=%s | after_reload=%s" % [
			label,
			_format_ammo_totals(initial_totals),
			_format_ammo_totals(after_fire_totals),
			_format_ammo_totals(after_reload_totals),
		]
	)

	check(session.complete_extraction(), "%s completes extraction" % label)
	check(primary_state.magazine_ammo == 0 and secondary_state.magazine_ammo == 0, "%s materializes both magazines" % label)
	for ammo_definition_id in after_fire_totals:
		check(
			_total_quantity(session.inventory, ammo_definition_id) == int(after_fire_totals[ammo_definition_id]),
			"%s recovers the exact remaining %s total" % [label, ammo_definition_id]
		)
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "%s commits recovered loadout" % label)
	if outcome:
		for ammo_definition_id in after_fire_totals:
			check(
				_total_quantity(profile.inventory, ammo_definition_id) == int(after_fire_totals[ammo_definition_id]),
				"%s Warehouse receives exact %s total" % [label, ammo_definition_id]
			)
		check(_count_instance_id(profile.inventory, primary_id) == 1 and _count_instance_id(profile.inventory, secondary_id) == 1, "%s keeps both weapon IDs unique" % label)
		check(profile.validate(), "%s recovered Profile remains valid" % label)
		var committed := profile.to_dict()
		check(SortieOutcomeService.commit_outcome(profile, outcome) == OK and profile.to_dict() == committed, "%s repeated commit is idempotent" % label)
	print("LOADOUT_TRACE | %s | extraction=%s | warehouse_ammo=%s" % [label, session.status == SortieSession.Status.COMPLETED, _format_profile_ammo(profile)])
	await _cleanup_fixture(player)


func _run_failed_loadout() -> void:
	var fixture := await _create_fixture(&"weapon.smg_01", &"weapon.rocket_launcher_01")
	if fixture.is_empty():
		return
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var player: PlayerController = fixture.player
	var profile_before := profile.to_dict()

	check(player.debug_fire_once(), "FAILED path fires SMG")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "FAILED path switches to Rocket")
	check(player.debug_fire_once(), "FAILED path fires Rocket")
	var lost_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "loadout_decision_failed_loot")
	var pickup := LootPickup.new()
	pickup.setup(lost_loot)
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "FAILED path picks up sortie loot")
	pickup.free()
	check(session.fail(), "FAILED path enters terminal failure state")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "FAILED path creates no-recovery outcome")
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "FAILED path uses no-op commit")
	check(profile.to_dict() == profile_before, "FAILED path preserves Warehouse and Loadout exactly")
	check(not profile.inventory.contains(lost_loot.instance_id), "FAILED path loses sortie loot")
	var retry_request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		_get_carried_ammo_ids(profile)
	)
	var retry_session := SortieSession.create_from_profile(retry_request, profile) if retry_request else null
	check(retry_session != null and retry_session.activate(), "unchanged Warehouse can start the next SMG + Rocket sortie")
	print("LOADOUT_TRACE | SMG + Rocket | failed=true | warehouse_unchanged=%s | loot_recovered=%s | retry_ready=%s" % [profile.to_dict() == profile_before, profile.inventory.contains(lost_loot.instance_id), retry_session != null and retry_session.status == SortieSession.Status.ACTIVE])
	await _cleanup_fixture(player)


func _create_fixture(primary_definition_id: StringName, secondary_definition_id: StringName) -> Dictionary:
	var profile := ProfileState.create_new()
	var primary_item := _find_item(profile.inventory, primary_definition_id)
	var secondary_item := _find_item(profile.inventory, secondary_definition_id)
	check(primary_item != null and secondary_item != null, "Profile owns requested %s + %s weapons" % [primary_definition_id, secondary_definition_id])
	if not primary_item or not secondary_item:
		return {}
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, primary_item.instance_id, profile.inventory), "Profile equips requested primary %s" % primary_definition_id)
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, secondary_item.instance_id, profile.inventory), "Profile equips requested secondary %s" % secondary_definition_id)
	var carried_ammo_ids := _get_carried_ammo_ids(profile)
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		carried_ammo_ids
	)
	var session := SortieSession.create_from_profile(request, profile) if request else null
	check(request != null and session != null and session.activate(), "Sortie starts with %s + %s" % [primary_definition_id, secondary_definition_id])
	if not session or session.status != SortieSession.Status.ACTIVE:
		return {}
	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	await get_tree().process_frame
	return {
		"profile": profile,
		"session": session,
		"player": player,
		"primary_id": primary_item.instance_id,
		"secondary_id": secondary_item.instance_id,
	}


func _collect_weapon_metrics() -> Dictionary:
	var metrics := {}
	for definition_id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		var definition := ContentDB.get_weapon(definition_id)
		metrics[definition_id] = await _measure_weapon(definition)
	return metrics


func _measure_weapon(definition: WeaponDefinition) -> Dictionary:
	var basic := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_basic_enemy"), Transform3D(Basis.IDENTITY, Vector3(-5.0, 0.0, -8.0)), self)
	var heavy := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_heavy_enemy"), Transform3D(Basis.IDENTITY, Vector3(5.0, 0.0, -8.0)), self)
	var barrier := DESTRUCTIBLE_SCENE.instantiate() as DestructibleWorldObject
	barrier.position = Vector3(0.0, 0.0, -4.0)
	add_child(barrier)
	if basic:
		basic.set_physics_process(false)
	if heavy:
		heavy.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var basic_damage := basic.receive_damage(_packet_from_weapon(definition)) if basic else -1.0
	var heavy_damage := heavy.receive_damage(_packet_from_weapon(definition)) if heavy else -1.0
	var structure_damage := barrier.receive_damage(_packet_from_weapon(definition)) if barrier else -1.0
	var expected_heavy_damage := maxf(definition.damage - maxf(8.0 - definition.armor_penetration, 0.0), 0.0)
	check(is_equal_approx(basic_damage, definition.damage), "%s uses full base damage against Basic" % definition.display_name)
	check(is_equal_approx(heavy_damage, expected_heavy_damage), "%s resolves through Heavy armor" % definition.display_name)
	check(is_equal_approx(structure_damage, minf(definition.structure_damage, barrier.max_structure_health)), "%s uses authored structure damage against Barrier" % definition.display_name)
	var result := {
		"basic_damage": basic_damage,
		"heavy_damage": heavy_damage,
		"structure_damage": structure_damage,
		"barrier_destroyed": barrier.destroyed,
	}
	if is_instance_valid(basic):
		basic.queue_free()
	if is_instance_valid(heavy):
		heavy.queue_free()
	if is_instance_valid(barrier):
		barrier.queue_free()
	await get_tree().process_frame
	return result


func _get_carried_ammo_ids(profile: ProfileState) -> Array[String]:
	var ammo_definition_ids: Dictionary = {}
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		var weapon_item := profile.loadout.get_item(slot_id, profile.inventory)
		var weapon_definition := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		var ammo_definition_id := weapon_definition.get_runtime_ammo_definition_id() if weapon_definition else &""
		if not ammo_definition_id.is_empty():
			ammo_definition_ids[ammo_definition_id] = true
	var instance_ids: Array[String] = []
	for item in profile.inventory.get_items():
		if ammo_definition_ids.has(item.definition_id):
			instance_ids.append(item.instance_id)
	return instance_ids


func _get_runtime_ammo_totals(session: SortieSession, states: Array) -> Dictionary:
	var totals := {}
	for state in states:
		if not totals.has(state.ammo_definition_id):
			totals[state.ammo_definition_id] = _total_quantity(session.inventory, state.ammo_definition_id)
		totals[state.ammo_definition_id] = int(totals[state.ammo_definition_id]) + state.magazine_ammo
	return totals


func _format_weapon(definition: WeaponDefinition, metrics: Dictionary) -> String:
	return "%s[basic=%.0f heavy=%.0f structure=%.0f mag=%d range=%.0f]" % [
		definition.display_name,
		metrics.basic_damage,
		metrics.heavy_damage,
		metrics.structure_damage,
		definition.magazine_capacity,
		definition.weapon_range,
	]


func _format_ammo_totals(totals: Dictionary) -> String:
	var parts: Array[String] = []
	for ammo_definition_id in [&"ammo.556_standard", &"ammo.rocket_standard"]:
		if totals.has(ammo_definition_id):
			parts.append("%s=%d" % [ammo_definition_id, totals[ammo_definition_id]])
	return ", ".join(parts)


func _format_profile_ammo(profile: ProfileState) -> String:
	return "ammo.556_standard=%d, ammo.rocket_standard=%d" % [
		_total_quantity(profile.inventory, &"ammo.556_standard"),
		_total_quantity(profile.inventory, &"ammo.rocket_standard"),
	]


func _packet_from_weapon(definition: WeaponDefinition) -> DamagePacket:
	return DamagePacket.new(
		definition.damage,
		definition.armor_penetration,
		definition.structure_damage,
		self,
		definition.id,
		&"player"
	)


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


func _cleanup_fixture(player: PlayerController) -> void:
	if is_instance_valid(player):
		player.queue_free()
	for rocket in find_children("RocketProjectile", "Area3D", true, false):
		rocket.queue_free()
	await get_tree().process_frame


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
