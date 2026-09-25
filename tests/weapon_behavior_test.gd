extends Node3D

const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")
const DESTRUCTIBLE_SCENE := preload("res://scenes/world/destructible_world_object.tscn")
const ROCKET_SCENE := preload("res://scenes/weapons/rocket_projectile.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_weapon_enemy_tradeoffs()
	await _test_smg_close_range_behavior()
	await _test_cover_changes_weapon_behavior()
	await _test_barrier_changes_weapon_behavior()
	await _test_ammo_lifecycle_isolation()
	_test_authored_tactical_layout()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("WEAPON_BEHAVIOR_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("WEAPON_BEHAVIOR_TEST: %s" % failure)
		print("WEAPON_BEHAVIOR_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_weapon_enemy_tradeoffs() -> void:
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01")
	var launcher := ContentDB.get_weapon(&"weapon.rocket_launcher_01")
	var basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(-5.0, 0.0, -8.0))
	var heavy := _spawn_enemy(&"prototype_heavy_enemy", Vector3(5.0, 0.0, -8.0))
	await _settle_physics()

	var rifle_basic_damage := basic.receive_damage(_packet_from_weapon(rifle))
	var rifle_heavy_damage := heavy.receive_damage(_packet_from_weapon(rifle))
	check(is_equal_approx(rifle_basic_damage, 20.0), "assault rifle applies full twenty damage to Basic")
	check(is_equal_approx(rifle_heavy_damage, 12.0), "assault rifle remains viable against Heavy while armor reduces each hit")
	check(not basic.is_dead and not heavy.is_dead, "one rifle round does not turn either enemy into a weapon-specific hard gate")
	basic.queue_free()
	heavy.queue_free()
	await get_tree().process_frame

	var rocket_basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(-5.0, 0.0, -8.0))
	var rocket_heavy := _spawn_enemy(&"prototype_heavy_enemy", Vector3(5.0, 0.0, -8.0))
	await _settle_physics()
	var basic_death := [false]
	rocket_basic.died.connect(func(_enemy: EnemyController) -> void: basic_death[0] = true)
	_explode_at(rocket_basic.global_position, launcher)
	check(basic_death[0], "rocket explosion defeats a Basic caught at the blast center")
	var heavy_health_before := rocket_heavy.health
	_explode_at(rocket_heavy.global_position, launcher)
	check(is_equal_approx(heavy_health_before - rocket_heavy.health, 84.0), "rocket uses the same armor formula and deals eighty-four damage to Heavy")
	check(not rocket_heavy.is_dead, "Heavy survives one rocket, keeping rifle follow-up and continued fire valid")
	rocket_heavy.queue_free()
	await get_tree().process_frame


func _test_smg_close_range_behavior() -> void:
	var smg := ContentDB.get_weapon(&"weapon.smg_01")
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.equip_weapon(smg)
	var basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(0.0, 0.0, -8.0))
	await _settle_physics()

	var basic_health_before := basic.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(basic_health_before - basic.health, 10.0), "SMG deals its full per-round damage to a close Basic")
	basic.queue_free()
	await get_tree().process_frame

	var heavy := _spawn_enemy(&"prototype_heavy_enemy", Vector3(0.0, 0.0, -8.0))
	await _settle_physics()
	var heavy_health_before := heavy.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(heavy_health_before - heavy.health, 2.0), "Heavy armor reduces an SMG round from ten damage to two")
	heavy.queue_free()
	await get_tree().process_frame

	var distant_basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(0.0, 0.0, -22.0))
	await _settle_physics()
	var distant_health_before := distant_basic.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(distant_basic.health, distant_health_before), "SMG hitscan respects its authored eighteen-meter range")
	distant_basic.queue_free()
	await get_tree().process_frame

	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	var covered_basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(0.0, 0.0, -8.0))
	await _settle_physics()
	var covered_health_before := covered_basic.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(covered_basic.health, covered_health_before), "permanent Cover blocks SMG hitscan exactly like rifle hitscan")
	covered_basic.queue_free()
	cover.queue_free()
	await get_tree().process_frame

	var barrier := _spawn_barrier(Vector3(0.0, 0.0, -4.0))
	await _settle_physics()
	var structure_health_before := barrier.current_structure_health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(barrier.current_structure_health, structure_health_before) and not barrier.destroyed, "SMG's authored zero structure damage leaves the Barrier intact")
	barrier.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_cover_changes_weapon_behavior() -> void:
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01")
	var launcher := ContentDB.get_weapon(&"weapon.rocket_launcher_01")
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.equip_weapon(rifle)
	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	var basic := _spawn_enemy(&"prototype_basic_enemy", Vector3(0.0, 0.0, -8.0))
	await _settle_physics()

	var health_before := basic.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(basic.health, health_before), "cover stops assault-rifle hitscan before it reaches Basic")
	var flank_origin := Vector3(4.0, 1.0, 0.0)
	var flank_direction := flank_origin.direction_to(basic.global_position + Vector3.UP)
	shooter._fire_hitscan(flank_origin, flank_direction)
	check(is_equal_approx(health_before - basic.health, 20.0), "repositioning around cover lets the same rifle damage Basic")

	basic.health = basic.max_health
	var blast_position := Vector3(0.0, 0.0, -3.5)
	_explode_at(blast_position, launcher)
	check(basic.health < basic.max_health, "rocket area query damages Basic behind intact cover without target-type branches")
	var cover_collision := cover.find_child("CollisionShape3D", true, false) as CollisionShape3D
	check(cover_collision != null and not cover_collision.disabled and not cover.has_method("receive_damage"), "rocket blast does not make permanent Cover destructible")

	basic.queue_free()
	cover.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_barrier_changes_weapon_behavior() -> void:
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01")
	var launcher := ContentDB.get_weapon(&"weapon.rocket_launcher_01")
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.equip_weapon(rifle)
	var rifle_barrier := _spawn_barrier(Vector3(0.0, 0.0, -4.0))
	await _settle_physics()

	for shot_index in 4:
		shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
		if shot_index == 0:
			check(is_equal_approx(rifle_barrier.current_structure_health, 15.0) and not rifle_barrier.destroyed, "one rifle hit chips Barrier but does not make it rocket-only")
	await get_tree().physics_frame
	check(rifle_barrier.destroyed, "four rifle hits can destroy Barrier through sustained low structure damage")
	rifle_barrier.queue_free()
	await get_tree().process_frame

	var rocket_barrier := _spawn_barrier(Vector3(0.0, 0.0, -4.0))
	var heavy := _spawn_enemy(&"prototype_heavy_enemy", Vector3(0.0, 0.0, -6.5))
	await _settle_physics()
	var heavy_health_before := heavy.health
	_explode_at(rocket_barrier.global_position, launcher)
	await get_tree().physics_frame
	check(rocket_barrier.destroyed and rocket_barrier.collision_shape.disabled, "one rocket destroys Barrier and removes its collision")
	check(heavy.health < heavy_health_before, "the same rocket explosion also delivers DamagePacket to Heavy behind Barrier")

	heavy.queue_free()
	rocket_barrier.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_ammo_lifecycle_isolation() -> void:
	var extraction_fixture := _create_sortie_fixture()
	var profile: ProfileState = extraction_fixture.profile
	var session: SortieSession = extraction_fixture.session
	var primary_id: String = extraction_fixture.primary_id
	var secondary_id: String = extraction_fixture.secondary_id
	var primary_state: WeaponRuntimeState = session.get_weapon_runtime_state(primary_id)
	var secondary_state: WeaponRuntimeState = session.get_weapon_runtime_state(secondary_id)
	var standard_reserve_before := session.get_reserve_ammo(primary_id)
	var rocket_reserve_before := session.get_reserve_ammo(secondary_id)

	check(session.fire_weapon(primary_id), "primary rifle consumes its runtime magazine")
	check(primary_state.magazine_ammo == 29 and secondary_state.magazine_ammo == 1, "rifle fire leaves rocket magazine unchanged")
	check(session.fire_weapon(secondary_id), "secondary launcher consumes its runtime magazine")
	check(primary_state.magazine_ammo == 29 and secondary_state.magazine_ammo == 0, "rocket fire leaves rifle magazine unchanged")
	check(session.get_reserve_ammo(primary_id) == standard_reserve_before and session.get_reserve_ammo(secondary_id) == rocket_reserve_before, "firing consumes neither reserve stack and never crosses ammunition definitions")

	var expected_standard := standard_reserve_before + primary_state.magazine_ammo
	var expected_rockets := rocket_reserve_before + secondary_state.magazine_ammo
	check(session.complete_extraction(), "dual-weapon behavior fixture extracts successfully")
	check(_total_quantity(session.inventory, &"ammo.556_standard") == expected_standard, "extraction materializes remaining rifle magazine exactly once")
	check(_total_quantity(session.inventory, &"ammo.rocket_standard") == expected_rockets, "extraction materializes remaining rocket magazine exactly once")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "dual-weapon ammunition commits through the existing recovery boundary")
	check(_total_quantity(profile.inventory, &"ammo.556_standard") == expected_standard and _total_quantity(profile.inventory, &"ammo.rocket_standard") == expected_rockets, "warehouse receives independent final ammunition totals")

	var failure_fixture := _create_sortie_fixture()
	var failure_profile: ProfileState = failure_fixture.profile
	var failure_session: SortieSession = failure_fixture.session
	var failure_before := failure_profile.to_dict()
	check(failure_session.fire_weapon(failure_fixture.primary_id) and failure_session.fire_weapon(failure_fixture.secondary_id), "failure fixture consumes both runtime magazines")
	check(failure_session.fail(), "dual-weapon behavior fixture can fail")
	var failure_outcome := SortieOutcomeService.create_outcome(failure_session)
	check(failure_outcome != null and SortieOutcomeService.commit_outcome(failure_profile, failure_outcome) == OK, "failed dual-weapon outcome uses the existing no-op commit")
	check(failure_profile.to_dict() == failure_before, "death recovers neither magazine and leaves warehouse byte-for-byte unchanged")


func _test_authored_tactical_layout() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var lane := area.find_child("InteriorCombatLane", true, false) as Node3D
	var cover := area.find_child("InteriorEntryCover", true, false) as CoverObstacle
	var barrier := area.find_child("DestructibleBarrier", true, false) as DestructibleWorldObject
	var basic_spawn := area.find_child("InteriorBasicSpawn", true, false) as EnemySpawnPoint
	var heavy_spawn := area.find_child("BarrierHeavySpawn", true, false) as EnemySpawnPoint
	check(lane != null and cover != null and barrier != null, "Prototype Arena groups its existing door, cover, and Barrier as one authored interior combat lane")
	check(basic_spawn != null and basic_spawn.enemy_definition_id == &"prototype_basic_enemy" and cover.position.z > basic_spawn.position.z, "authored Basic starts behind permanent cover from the southern approach")
	check(heavy_spawn != null and heavy_spawn.enemy_definition_id == &"prototype_heavy_enemy" and barrier.position.z > heavy_spawn.position.z, "authored Heavy starts behind the destructible Barrier from the player approach")
	area.free()


func _create_sortie_fixture() -> Dictionary:
	var profile := ProfileState.create_new()
	var standard_ammo := _find_item(profile.inventory, &"ammo.556_standard")
	var rocket_ammo := _find_item(profile.inventory, &"ammo.rocket_standard")
	var carried_ids: Array[String] = [standard_ammo.instance_id, rocket_ammo.instance_id]
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		carried_ids
	)
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.activate(), "weapon behavior fixture creates an active dual-weapon sortie")
	return {
		"profile": profile,
		"session": session,
		"primary_id": profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY),
		"secondary_id": profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY),
	}


func _spawn_enemy(definition_id: StringName, position_value: Vector3) -> EnemyController:
	var enemy := EnemySpawnService.spawn(
		ContentDB.get_enemy_definition(definition_id),
		Transform3D(Basis.IDENTITY, position_value),
		self
	)
	enemy.set_physics_process(false)
	return enemy


func _spawn_barrier(position_value: Vector3) -> DestructibleWorldObject:
	var barrier := DESTRUCTIBLE_SCENE.instantiate() as DestructibleWorldObject
	barrier.position = position_value
	add_child(barrier)
	return barrier


func _explode_at(position_value: Vector3, weapon: WeaponDefinition) -> void:
	var shooter := StaticBody3D.new()
	add_child(shooter)
	var rocket: Variant = ROCKET_SCENE.instantiate()
	add_child(rocket)
	rocket.global_position = position_value
	rocket.setup(shooter, Vector3.FORWARD, weapon)
	rocket._explode()
	shooter.queue_free()


func _packet_from_weapon(weapon: WeaponDefinition) -> DamagePacket:
	return DamagePacket.new(
		weapon.damage,
		weapon.armor_penetration,
		weapon.structure_damage,
		self,
		weapon.id,
		&"player"
	)


func _settle_physics() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


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


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
