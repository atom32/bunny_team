extends Node3D

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_full_mission_flow()
	await _test_early_extraction()
	await _test_failed_mission_flow()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("MISSION_FLOW_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("MISSION_FLOW_TEST: %s" % failure)
		print("MISSION_FLOW_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_full_mission_flow() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null, "full mission fixture starts an active Sortie")
	if not session:
		return
	var battle := BATTLE_SCENE.instantiate()
	battle.loot_seed = 41
	add_child(battle)
	await _wait_for_battle(battle)
	battle.result_transition_enabled = false

	var player := battle.player as PlayerController
	var terminal := battle.area_root.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var threat_event := battle.area_root.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var reach_zone := battle.area_root.find_child("PrototypeSurveyZone", true, false) as ObjectiveReachZone
	var high_value_spawn := battle.area_root.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	var extraction := battle.area_root.find_child("ExtractionPoint", true, false) as ExtractionPoint
	var initial_enemies := _get_battle_enemies(battle)
	_disable_enemies(initial_enemies)
	check(
		player != null and terminal != null and threat_event != null and reach_zone != null
		and high_value_spawn != null and extraction != null,
		"authored Arena exposes terminal, alert, reinforcement objective, target loot, and extraction"
	)
	check(session.status == SortieSession.Status.ACTIVE and not session.is_mission_completed(), "mission starts ACTIVE and incomplete")
	check(session.threat_level == SortieSession.ThreatLevel.NORMAL, "mission starts at NORMAL threat")
	check(threat_event != null and not threat_event.trigger_on_body_entered, "mission alert is terminal-bound instead of proximity-triggered")
	if not player or not terminal or not threat_event or not reach_zone or not high_value_spawn or not extraction:
		await _free_battle(battle)
		return

	threat_event._on_body_entered(player)
	check(session.threat_level == SortieSession.ThreatLevel.NORMAL and not threat_event.triggered, "walking through the disabled alert zone does not bypass the terminal")
	player.global_position = terminal.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	var terminal_response := player.interaction_component.interact_with_current()
	var interact_state := session.get_objective_state(&"interact_prototype_terminal")
	check(bool(terminal_response.get("success", false)), "player can access the authored interior terminal through the shared interaction protocol")
	check(interact_state != null and interact_state.progress == 1 and interact_state.status == ObjectiveState.Status.COMPLETED, "terminal completes the INTERACT objective")
	check(threat_event.triggered and threat_event.reinforcement_spawned, "successful terminal interaction triggers the local alert and reinforcement")
	check(session.threat_level == SortieSession.ThreatLevel.ALERT, "terminal-caused ThreatEvent raises SortieSession to ALERT")

	var enemies_after_alert := _get_battle_enemies(battle)
	var reinforcements := _new_enemies(initial_enemies, enemies_after_alert)
	_disable_enemies(reinforcements)
	check(reinforcements.size() == 3 and battle.enemies_remaining == 15, "terminal alert spawns exactly one authored reinforcement batch")
	check(_count_enemies(reinforcements, &"prototype_basic_enemy") == 2, "reinforcement batch resolves two Basic definitions")
	check(_count_enemies(reinforcements, &"prototype_heavy_enemy") == 1, "reinforcement batch resolves one Heavy definition")
	check(not threat_event.trigger() and _get_battle_enemies(battle).size() == 15, "repeated alert trigger never creates a second batch")

	for enemy in reinforcements:
		enemy.take_damage(enemy.health + enemy.armor + 1.0)
	await get_tree().process_frame
	var eliminate_state := session.get_objective_state(&"eliminate_prototype_enemies")
	check(eliminate_state != null and eliminate_state.progress == 3 and eliminate_state.status == ObjectiveState.Status.COMPLETED, "reinforcement deaths use the existing ELIMINATE objective path")
	check(not session.is_mission_completed(), "INTERACT and ELIMINATE do not bypass the required REACH objective")
	check(reach_zone.try_reach(player), "player can complete the authored survey REACH objective")
	check(session.is_mission_completed(), "all required ObjectiveStates complete the mission")

	var high_value_pickups := high_value_spawn.find_children("*", "LootPickup", true, false)
	var recovered_ids: Array[String] = []
	check(high_value_pickups.size() == 2, "target area exposes two authored high-value loot instances")
	for pickup_node in high_value_pickups:
		var pickup := pickup_node as LootPickup
		recovered_ids.append(pickup.item_instance.instance_id)
		check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "target loot enters carried inventory through LootPickup")
	check(profile.to_dict() == profile_before, "terminal, alert, combat, objectives, and loot do not mutate Warehouse mid-Sortie")

	check(extraction.extract(session), "mission-complete ALERT Sortie can extract")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.mission_completed, "Outcome records mission completion independently from extraction status")
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "mission recovery commits through the existing Outcome boundary")
	for instance_id in recovered_ids:
		check(profile.inventory.contains(instance_id), "successful mission recovers target loot %s" % instance_id)
	check(profile.validate(), "mission recovery leaves Warehouse loadout references valid")
	await _free_battle(battle)


func _test_early_extraction() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileState.create_new()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null, "early-extraction fixture starts an active Sortie")
	if not session:
		return
	var battle := BATTLE_SCENE.instantiate()
	battle.loot_seed = 41
	add_child(battle)
	await _wait_for_battle(battle)
	battle.result_transition_enabled = false
	_disable_enemies(_get_battle_enemies(battle))
	var extraction := battle.area_root.find_child("ExtractionPoint", true, false) as ExtractionPoint
	var threat_event := battle.area_root.find_child("LocalAlertEvent", true, false) as ThreatEvent
	check(not session.is_mission_completed() and session.threat_level == SortieSession.ThreatLevel.NORMAL, "conservative path leaves mission incomplete and threat NORMAL")
	check(extraction != null and extraction.extract(session), "mission-incomplete NORMAL Sortie may extract early")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.COMPLETED, "early extraction still creates a completed Sortie outcome")
	check(outcome != null and not outcome.mission_completed, "early extraction does not auto-complete Mission")
	check(threat_event != null and not threat_event.triggered, "early extraction never triggers the interior alert")
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "early extraction preserves the normal recovery boundary")
	await _free_battle(battle)


func _test_failed_mission_flow() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null, "failed mission fixture starts an active Sortie")
	if not session:
		return
	var battle := BATTLE_SCENE.instantiate()
	battle.loot_seed = 73
	add_child(battle)
	await _wait_for_battle(battle)
	battle.result_transition_enabled = false
	_disable_enemies(_get_battle_enemies(battle))

	var terminal := battle.area_root.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var threat_event := battle.area_root.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var high_value_spawn := battle.area_root.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	check(terminal != null and threat_event != null and high_value_spawn != null, "failure path resolves authored mission objects")
	if not terminal or not threat_event or not high_value_spawn:
		await _free_battle(battle)
		return
	check(bool(terminal.interact(battle.player, session).get("success", false)), "failure path accesses the terminal")
	_disable_enemies(_get_battle_enemies(battle))
	check(threat_event.triggered and session.threat_level == SortieSession.ThreatLevel.ALERT, "terminal raises ALERT before failure")

	var pickups := high_value_spawn.find_children("*", "LootPickup", true, false)
	var lost_loot_id := ""
	if not pickups.is_empty():
		var pickup := pickups[0] as LootPickup
		lost_loot_id = pickup.item_instance.instance_id
		check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "failed mission can carry target loot temporarily")
	battle.player.take_damage(battle.player.health + battle.player.max_health)
	await get_tree().process_frame
	check(session.status == SortieSession.Status.FAILED, "player death ends terminal-triggered mission as FAILED")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "failed mission produces a FAILED outcome")
	check(outcome != null and not outcome.mission_completed, "failed mission outcome cannot report mission completed")
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "FAILED outcome follows the existing no-op commit policy")
	check(profile.to_dict() == profile_before, "failed mission leaves Warehouse inventory and loadout unchanged")
	check(lost_loot_id.is_empty() or not profile.inventory.contains(lost_loot_id), "failed mission loses target loot carried only by the Sortie")
	await _free_battle(battle)


func _wait_for_battle(battle: Node) -> void:
	for _frame in 6:
		await get_tree().process_frame
	for _frame in 2:
		await get_tree().physics_frame
	check(battle.session != null and battle.area_root != null and battle.player != null, "Battle finishes runtime setup")


func _get_battle_enemies(battle: Node) -> Array[EnemyController]:
	var result: Array[EnemyController] = []
	if not battle.enemy_container:
		return result
	for child in battle.enemy_container.get_children():
		if child is EnemyController:
			result.append(child as EnemyController)
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


func _free_battle(battle: Node) -> void:
	battle.queue_free()
	await get_tree().process_frame


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
