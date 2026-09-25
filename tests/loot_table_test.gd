extends Node

const LOOT_PICKUP_SCENE := preload("res://scenes/world/loot_pickup.tscn")
const LOOT_SPAWN_POINT_SCENE := preload("res://scenes/world/loot_spawn_point.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_content_and_rolls()
	_test_inventory_integration()
	await _test_spawn_point_and_capacity()
	_test_failed_sortie_loses_generated_loot()
	_test_successful_extraction_recovers_generated_loot()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("LOOT_TABLE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("LOOT_TABLE_TEST: %s" % failure)
		print("LOOT_TABLE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_content_and_rolls() -> void:
	var table := ContentDB.get_loot_table(&"prototype_basic_loot", false)
	check(table != null and table.validate_definition(), "prototype loot table resolves through ContentDB")
	if not table:
		return
	check(table.entries.size() == 3, "prototype loot table contains three weighted entries")

	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 12345
	rng_b.seed = 12345
	var deterministic_a := LootRollService.roll(table, rng_a)
	var deterministic_b := LootRollService.roll(table, rng_b)
	check(deterministic_a.size() == 1 and deterministic_b.size() == 1, "one loot roll creates one runtime item")
	if deterministic_a.size() == 1 and deterministic_b.size() == 1:
		check(
			deterministic_a[0].definition_id == deterministic_b[0].definition_id
			and deterministic_a[0].quantity == deterministic_b[0].quantity,
			"same table and seed produce the same content result"
		)
		check(deterministic_a[0].instance_id != deterministic_b[0].instance_id, "deterministic content rolls still create unique item instances")

	var seen_definitions: Dictionary = {}
	var seen_instance_ids: Dictionary = {}
	for seed_value in range(1, 401):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var result := LootRollService.roll(table, rng)
		check(result.size() == 1, "weighted roll with seed %d returns one item" % seed_value)
		if result.size() != 1:
			continue
		var item := result[0]
		check(ContentDB.has_item(item.definition_id), "weighted roll resolves to a registered item definition")
		check(_quantity_is_valid(item), "rolled quantity stays inside its entry range")
		check(not seen_instance_ids.has(item.instance_id), "multiple rolls never reuse an item instance ID")
		seen_instance_ids[item.instance_id] = true
		seen_definitions[item.definition_id] = true
	check(seen_definitions.size() == 3, "seeded weighted rolls can reach every prototype entry")

	var different_seed_rng := RandomNumberGenerator.new()
	different_seed_rng.seed = 98765
	var different_seed_result := LootRollService.roll(table, different_seed_rng)
	check(different_seed_result.size() == 1 and _quantity_is_valid(different_seed_result[0]), "a different seed remains a valid independent RNG input")


func _test_inventory_integration() -> void:
	var table := ContentDB.get_loot_table(&"prototype_basic_loot")
	var ammo_seed := _find_seed_for_definition(table, &"ammo.556_standard")
	check(ammo_seed >= 0, "a deterministic seed can select standard ammunition")
	if ammo_seed < 0:
		return
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = ammo_seed
	rng_b.seed = ammo_seed
	var ammo_a := LootRollService.roll(table, rng_a)[0]
	var ammo_b := LootRollService.roll(table, rng_b)[0]
	var expected_quantity := ammo_a.quantity + ammo_b.quantity
	var inventory := InventoryState.new(100.0)
	check(inventory.add_item(ammo_a), "rolled ammunition enters InventoryState")
	check(inventory.add_item(ammo_b), "second rolled ammunition stack enters InventoryState")
	check(_total_quantity(inventory, &"ammo.556_standard") == expected_quantity, "rolled ammunition uses existing stack and quantity rules")
	check(is_equal_approx(inventory.get_used_capacity(), expected_quantity * 0.012), "rolled stack capacity uses definition weight times quantity")


func _test_spawn_point_and_capacity() -> void:
	var table := ContentDB.get_loot_table(&"prototype_basic_loot")
	var salvage_seed := _find_seed_for_definition(table, &"loot.salvage_core_01")
	var rng := RandomNumberGenerator.new()
	rng.seed = salvage_seed
	var spawn_point := LOOT_SPAWN_POINT_SCENE.instantiate() as LootSpawnPoint
	spawn_point.setup(&"prototype_basic_loot")
	add_child(spawn_point)
	var spawned := spawn_point.spawn(rng)
	check(spawned.size() == 1 and spawned[0].item_instance.definition_id == &"loot.salvage_core_01", "authored spawn point turns a table roll into a LootPickup")
	check(spawn_point.spawn(rng).is_empty(), "one spawn point rolls only once per sortie scene")

	var inventory := InventoryState.new(0.0)
	var session := SortieSession.new(inventory, LoadoutState.new(), &"prototype_arena", &"prototype_combat")
	check(session.activate(), "capacity fixture creates an active empty sortie")
	var pickup := spawned[0]
	var inventory_before := inventory.to_dict()
	check(pickup.try_pickup(session) == LootPickup.PickupResult.CAPACITY_FULL, "generated loot respects carried inventory capacity")
	check(is_instance_valid(pickup) and not pickup.consumed, "capacity rejection leaves generated loot in the world")
	check(inventory.to_dict() == inventory_before, "capacity rejection leaves carried inventory unchanged")
	spawn_point.queue_free()
	await get_tree().process_frame


func _test_failed_sortie_loses_generated_loot() -> void:
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var session := _create_session(profile)
	if not session:
		return
	var item := _roll_definition(&"loot.salvage_core_01")
	var pickup := LootPickup.new()
	pickup.setup(item)
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "generated loot enters active sortie inventory")
	check(profile.to_dict() == profile_before, "generated pickup leaves warehouse unchanged during sortie")
	check(session.fail(), "generated-loot sortie can end as FAILED")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "failed generated-loot sortie creates a failed outcome")
	check(outcome != null and outcome.inventory.get_items().is_empty(), "failed outcome recovers no generated loot")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "failed generated-loot outcome commits as a no-op")
	check(profile.to_dict() == profile_before and not profile.inventory.contains(item.instance_id), "failed sortie never adds generated loot to warehouse")
	pickup.free()


func _test_successful_extraction_recovers_generated_loot() -> void:
	var profile := ProfileState.create_new()
	var session := _create_session(profile)
	if not session:
		return
	var item := _roll_definition(&"loot.salvage_core_01")
	var pickup := LootPickup.new()
	pickup.setup(item)
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "successful fixture picks up generated loot")
	check(not profile.inventory.contains(item.instance_id), "generated loot remains sortie-only before extraction")
	check(session.complete_extraction(), "generated-loot sortie completes through extraction")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.inventory.contains(item.instance_id), "completed outcome snapshots generated loot")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "completed generated-loot outcome commits")
	check(profile.inventory.contains(item.instance_id) and profile.validate(), "successful extraction adds generated loot to valid warehouse state")
	pickup.free()


func _create_session(profile: ProfileState) -> SortieSession:
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "loot test fixture creates an active sortie session")
	return session


func _roll_definition(definition_id: StringName) -> ItemInstance:
	var table := ContentDB.get_loot_table(&"prototype_basic_loot")
	var seed_value := _find_seed_for_definition(table, definition_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return LootRollService.roll(table, rng)[0]


func _find_seed_for_definition(table: LootTableDefinition, definition_id: StringName) -> int:
	for seed_value in range(1, 1001):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var result := LootRollService.roll(table, rng)
		if result.size() == 1 and result[0].definition_id == definition_id:
			return seed_value
	return -1


func _quantity_is_valid(item: ItemInstance) -> bool:
	match item.definition_id:
		&"loot.salvage_core_01":
			return item.quantity == 1
		&"ammo.556_standard":
			return item.quantity >= 30 and item.quantity <= 60
		&"ammo.rocket_standard":
			return item.quantity >= 1 and item.quantity <= 2
	return false


func _total_quantity(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
