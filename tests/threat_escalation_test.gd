extends Node3D

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_session_threat_rules()
	await _test_authored_threat_success_path()
	await _test_alert_failure_path()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("THREAT_ESCALATION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("THREAT_ESCALATION_TEST: %s" % failure)
		print("THREAT_ESCALATION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_session_threat_rules() -> void:
	var profile := ProfileState.create_new()
	var active := _create_session(profile, true)
	check(active != null and active.threat_level == SortieSession.ThreatLevel.NORMAL, "active Sortie starts at NORMAL threat")
	if active:
		check(active.raise_threat(), "active Sortie raises threat from NORMAL to ALERT")
		check(active.threat_level == SortieSession.ThreatLevel.ALERT, "raised threat is stored by SortieSession")
		check(not active.raise_threat() and active.threat_level == SortieSession.ThreatLevel.ALERT, "repeated threat raise is a stable no-op")
		check(active.complete_extraction(), "ALERT does not block successful extraction")
		check(not active.raise_threat(), "completed Sortie rejects threat changes")

	var preparing := _create_session(profile, false)
	check(preparing != null and not preparing.raise_threat(), "preparing Sortie rejects threat changes")
	var failed := _create_session(profile, true)
	check(failed != null and failed.fail() and not failed.raise_threat(), "failed Sortie rejects threat changes")
	var abandoned := _create_session(profile, true)
	check(abandoned != null and abandoned.abandon() and not abandoned.raise_threat(), "abandoned Sortie rejects threat changes")
	var player_actor := Node3D.new()
	player_actor.add_to_group("player")
	var inactive_event := ThreatEvent.new()
	inactive_event.setup(preparing)
	check(not inactive_event.try_trigger(player_actor), "ThreatEvent itself rejects a non-active Sortie")
	inactive_event.free()
	player_actor.free()


func _test_authored_threat_success_path() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var warehouse_count_before := profile.inventory.get_items().size()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null, "success fixture starts an active Sortie")
	if not session:
		return
	var battle := BATTLE_SCENE.instantiate()
	battle.loot_seed = 41
	add_child(battle)
	await _wait_for_battle(battle)
	battle.result_transition_enabled = false

	var player := battle.player as PlayerController
	var threat_event := battle.area_root.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var high_value_spawn := battle.area_root.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	var extraction := battle.area_root.find_child("ExtractionPoint", true, false) as ExtractionPoint
	var reinforcement_points := _get_reinforcement_points(battle)
	var initial_enemies := _get_battle_enemies(battle)
	_disable_enemies(initial_enemies)
	check(threat_event != null and high_value_spawn != null and extraction != null, "Arena authors threat, high-value loot, and extraction objects")
	check(initial_enemies.size() == 12 and battle.enemies_remaining == 12, "Battle starts with only the twelve initial enemies")
	check(reinforcement_points.size() == 3 and reinforcement_points.all(func(point: EnemySpawnPoint) -> bool: return not point.has_spawned), "three authored reinforcement points begin inactive")
	check(battle.hud.threat_label.text == "THREAT  NORMAL", "HUD reads NORMAL threat from SortieSession")
	if not player or not threat_event or not high_value_spawn or not extraction:
		battle.queue_free()
		await get_tree().process_frame
		return

	check(threat_event.try_trigger(player), "player entering the authored alert zone triggers the local threat event")
	var enemies_after_alert := _get_battle_enemies(battle)
	var reinforcement_enemies := _new_enemies(initial_enemies, enemies_after_alert)
	_disable_enemies(reinforcement_enemies)
	check(session.threat_level == SortieSession.ThreatLevel.ALERT, "ThreatEvent raises the current Sortie to ALERT")
	check(threat_event.triggered and threat_event.reinforcement_spawned, "ThreatEvent records its one-shot runtime state")
	check(reinforcement_enemies.size() == 3 and battle.enemies_remaining == 15, "alert activates exactly one batch of three reinforcements")
	check(_count_enemies(reinforcement_enemies, &"prototype_basic_enemy") == 2 and _count_enemies(reinforcement_enemies, &"prototype_heavy_enemy") == 1, "reinforcements resolve two Basic and one Heavy through EnemyDefinition")
	check(reinforcement_enemies.all(func(enemy: EnemyController) -> bool: return enemy.get_script() == initial_enemies[0].get_script()), "reinforcement uses the existing EnemySpawnService runtime scene")
	check(battle.hud.threat_label.text == "THREAT  ALERT" and battle.hud.banner.text.contains("REINFORCEMENTS"), "HUD reports ALERT and one-shot reinforcement feedback")
	check(profile.to_dict() == profile_before, "raising threat and spawning reinforcements do not mutate Profile")
	check(not threat_event.try_trigger(player) and _get_battle_enemies(battle).size() == 15, "repeated event trigger never spawns a second batch")

	var objective_before := session.get_objective_state(&"eliminate_prototype_enemies").progress
	var reinforcement := reinforcement_enemies[0]
	reinforcement.take_damage(reinforcement.health + reinforcement.armor + 1.0)
	await get_tree().process_frame
	var objective_after := session.get_objective_state(&"eliminate_prototype_enemies").progress
	check(objective_after == objective_before + 1, "reinforcement death uses the existing enemy-defeat objective path")

	var high_value_pickups := high_value_spawn.find_children("*", "LootPickup", true, false)
	check(high_value_pickups.size() == 2, "high-value authored point produces two real Salvage Core pickups")
	var recovered_ids: Array[String] = []
	if high_value_pickups.size() == 2:
		var capacity_before := session.inventory.capacity
		session.inventory.capacity = session.inventory.get_used_capacity()
		var inventory_before_rejection := session.inventory.to_dict()
		check((high_value_pickups[0] as LootPickup).try_pickup(session) == LootPickup.PickupResult.CAPACITY_FULL, "high-value loot still obeys carried capacity")
		check(session.inventory.to_dict() == inventory_before_rejection and not (high_value_pickups[0] as LootPickup).consumed, "capacity failure leaves both loot and carried inventory unchanged")
		session.inventory.capacity = capacity_before
		for pickup_node in high_value_pickups:
			var pickup := pickup_node as LootPickup
			recovered_ids.append(pickup.item_instance.instance_id)
			check(pickup.item_instance.definition_id == &"loot.salvage_core_01" and pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "high-value loot enters Sortie inventory through LootPickup")
	check(profile.to_dict() == profile_before, "ALERT loot remains isolated from the Warehouse before extraction")

	check(extraction.extract(session), "ALERT Sortie can extract without clearing reinforcements")
	check(session.status == SortieSession.Status.COMPLETED, "ALERT extraction reaches the normal completed state")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "ALERT extraction commits through the existing Outcome boundary")
	check(profile.inventory.get_items().size() == warehouse_count_before + 2, "successful alert extraction merges two high-value loot instances")
	for instance_id in recovered_ids:
		check(profile.inventory.contains(instance_id), "successful alert extraction recovers high-value loot %s" % instance_id)

	battle.queue_free()
	await get_tree().process_frame


func _test_alert_failure_path() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null, "failure fixture starts an active Sortie")
	if not session:
		return
	var battle := BATTLE_SCENE.instantiate()
	battle.loot_seed = 73
	add_child(battle)
	await _wait_for_battle(battle)
	battle.result_transition_enabled = false
	_disable_enemies(_get_battle_enemies(battle))

	var event := battle.area_root.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var high_value_spawn := battle.area_root.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	check(event != null and event.try_trigger(battle.player), "failure path raises the authored local alert")
	_disable_enemies(_get_battle_enemies(battle))
	var pickups := high_value_spawn.find_children("*", "LootPickup", true, false) if high_value_spawn else []
	var lost_loot_id := ""
	if not pickups.is_empty():
		var pickup := pickups[0] as LootPickup
		lost_loot_id = pickup.item_instance.instance_id
		check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "failure path can take high-value loot into carried inventory")
	battle.player.take_damage(battle.player.health + battle.player.max_health)
	await get_tree().process_frame
	check(session.status == SortieSession.Status.FAILED and session.threat_level == SortieSession.ThreatLevel.ALERT, "player death ends an ALERT Sortie as FAILED")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "failed ALERT outcome remains a valid no-op commit")
	check(profile.to_dict() == profile_before, "failed ALERT leaves Warehouse inventory and loadout unchanged")
	check(lost_loot_id.is_empty() or not profile.inventory.contains(lost_loot_id), "high-value loot is lost on failed ALERT Sortie")

	battle.queue_free()
	await get_tree().process_frame


func _create_session(profile: ProfileState, activate: bool) -> SortieSession:
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	if activate and session and not session.activate():
		return null
	return session


func _wait_for_battle(battle: Node) -> void:
	for _frame in 6:
		await get_tree().process_frame
	for _frame in 2:
		await get_tree().physics_frame
	check(battle.session != null and battle.area_root != null and battle.player != null and battle.hud != null, "Battle finishes runtime setup")


func _get_battle_enemies(battle: Node) -> Array[EnemyController]:
	var result: Array[EnemyController] = []
	if not battle.enemy_container:
		return result
	for child in battle.enemy_container.get_children():
		if child is EnemyController:
			result.append(child as EnemyController)
	return result


func _get_reinforcement_points(battle: Node) -> Array[EnemySpawnPoint]:
	var result: Array[EnemySpawnPoint] = []
	for candidate in battle.area_root.find_children("*", "EnemySpawnPoint", true, false):
		var point := candidate as EnemySpawnPoint
		if not point.initial_spawn:
			result.append(point)
	return result


func _new_enemies(before: Array[EnemyController], after: Array[EnemyController]) -> Array[EnemyController]:
	var result: Array[EnemyController] = []
	for enemy in after:
		if not before.has(enemy):
			result.append(enemy)
	return result


func _disable_enemies(enemies: Array[EnemyController]) -> void:
	for enemy in enemies:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _count_enemies(enemies: Array[EnemyController], definition_id: StringName) -> int:
	return enemies.filter(func(enemy: EnemyController) -> bool: return enemy.definition_id == definition_id).size()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
