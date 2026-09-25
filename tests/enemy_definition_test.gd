extends Node3D

const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_definition_resolution()
	await _test_runtime_configuration_and_combat()
	await _test_heavy_cover_collision()
	_test_authored_mixed_spawn_points()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("ENEMY_DEFINITION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("ENEMY_DEFINITION_TEST: %s" % failure)
		print("ENEMY_DEFINITION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_definition_resolution() -> void:
	var basic := ContentDB.get_enemy_definition(&"prototype_basic_enemy", false)
	var heavy := ContentDB.get_enemy_definition(&"prototype_heavy_enemy", false)
	check(basic != null and basic.validate_definition(), "basic EnemyDefinition resolves through ContentDB")
	check(heavy != null and heavy.validate_definition(), "heavy EnemyDefinition resolves through ContentDB")
	if not basic or not heavy:
		return
	check(basic.scene == heavy.scene, "basic and heavy definitions reuse the same Enemy runtime scene")
	check(basic.max_health != heavy.max_health and basic.armor != heavy.armor, "basic and heavy definitions have distinct durability")
	check(basic.move_speed != heavy.move_speed and basic.approach_speed != heavy.approach_speed, "basic and heavy definitions have distinct movement speeds")
	check(basic.attack_damage != heavy.attack_damage and basic.attack_cooldown_min != heavy.attack_cooldown_min, "basic and heavy definitions have distinct attack profiles")


func _test_runtime_configuration_and_combat() -> void:
	var basic_definition := ContentDB.get_enemy_definition(&"prototype_basic_enemy")
	var heavy_definition := ContentDB.get_enemy_definition(&"prototype_heavy_enemy")
	var definition_snapshot := _definition_snapshot(basic_definition, heavy_definition)
	var container := Node3D.new()
	add_child(container)
	var basic := EnemySpawnService.spawn(basic_definition, Transform3D(Basis.IDENTITY, Vector3(-2.0, 0.1, -5.0)), container)
	var heavy := EnemySpawnService.spawn(heavy_definition, Transform3D(Basis.IDENTITY, Vector3(2.0, 0.1, -5.0)), container)
	check(basic != null and heavy != null and basic != heavy, "basic and heavy spawn as independent runtime nodes")
	if not basic or not heavy:
		container.queue_free()
		return
	basic.process_mode = Node.PROCESS_MODE_DISABLED
	heavy.process_mode = Node.PROCESS_MODE_DISABLED
	check(basic.definition_id == basic_definition.id and heavy.definition_id == heavy_definition.id, "runtime enemies retain only their stable definition identity")
	check(basic.max_health == basic_definition.max_health and heavy.max_health == heavy_definition.max_health, "runtime health configuration comes from EnemyDefinition")
	check(basic.armor == basic_definition.armor and heavy.armor == heavy_definition.armor, "runtime armor configuration comes from EnemyDefinition")
	check(basic.movement_speed == basic_definition.move_speed and heavy.movement_speed == heavy_definition.move_speed and heavy.approach_speed == heavy_definition.approach_speed, "runtime movement configuration comes from EnemyDefinition")
	check(basic.attack_damage == basic_definition.attack_damage and heavy.attack_damage == heavy_definition.attack_damage and heavy.attack_range == heavy_definition.attack_range, "runtime attack damage and range come from EnemyDefinition")
	check(heavy.attack_cooldown_min == heavy_definition.attack_cooldown_min and heavy.attack_cooldown_max == heavy_definition.attack_cooldown_max, "runtime attack cooldown comes from EnemyDefinition")

	var basic_health_before := basic.health
	var heavy_health_before := heavy.health
	basic.take_damage(20.0)
	heavy.take_damage(20.0)
	var basic_damage := basic_health_before - basic.health
	var heavy_damage := heavy_health_before - heavy.health
	check(basic_damage == 20.0 and heavy_damage == 12.0, "the same incoming damage resolves differently through runtime armor without weapon type checks")
	basic.health -= 5.0
	check(heavy.health == heavy_health_before - heavy_damage, "mutating one runtime enemy does not affect the other")
	check(_definition_snapshot(basic_definition, heavy_definition) == definition_snapshot, "runtime combat never mutates either EnemyDefinition Resource")
	check(basic.get_script() == heavy.get_script(), "basic and heavy share the same EnemyController implementation")

	container.queue_free()
	await get_tree().process_frame


func _test_heavy_cover_collision() -> void:
	var container := Node3D.new()
	add_child(container)
	var heavy := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_heavy_enemy"), Transform3D.IDENTITY, container)
	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	container.add_child(cover)
	var target := StaticBody3D.new()
	target.collision_layer = 1
	target.collision_mask = 0
	target.position = Vector3(0.0, 0.0, -8.0)
	var target_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 2.0, 1.0)
	target_shape.position.y = 1.0
	target_shape.shape = box
	target.add_child(target_shape)
	container.add_child(target)
	if heavy:
		heavy.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().physics_frame
	await get_tree().physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, -10.0), 5)
	var blocked_result := get_world_3d().direct_space_state.intersect_ray(query)
	check(not blocked_result.is_empty() and blocked_result.collider == cover, "Cover blocks the shared enemy attack ray used by the heavy runtime")
	cover.position.x = 4.0
	await get_tree().physics_frame
	var clear_result := get_world_3d().direct_space_state.intersect_ray(query)
	check(not clear_result.is_empty() and clear_result.collider == target, "enemy attack ray reaches its target after Cover leaves line of sight")
	container.queue_free()
	await get_tree().process_frame


func _test_authored_mixed_spawn_points() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var spawn_points := area.find_children("*", "EnemySpawnPoint", true, false)
	var initial_spawns := spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.initial_spawn)
	var reinforcement_spawns := spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return not point.initial_spawn)
	var initial_basic_count := initial_spawns.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == &"prototype_basic_enemy").size()
	var initial_heavy_count := initial_spawns.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == &"prototype_heavy_enemy").size()
	var reinforcement_basic_count := reinforcement_spawns.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == &"prototype_basic_enemy").size()
	var reinforcement_heavy_count := reinforcement_spawns.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == &"prototype_heavy_enemy").size()
	check(initial_basic_count == 9 and initial_heavy_count == 3, "one authored Area preserves nine initial basic and three initial heavy definitions")
	check(reinforcement_basic_count == 2 and reinforcement_heavy_count == 1, "the same Area authors a separate mixed reinforcement group")
	area.free()


func _definition_snapshot(basic: EnemyDefinition, heavy: EnemyDefinition) -> Dictionary:
	return {
		"basic": [basic.max_health, basic.armor, basic.move_speed, basic.approach_speed, basic.attack_damage, basic.attack_range, basic.attack_cooldown_min, basic.attack_cooldown_max],
		"heavy": [heavy.max_health, heavy.armor, heavy.move_speed, heavy.approach_speed, heavy.attack_damage, heavy.attack_range, heavy.attack_cooldown_min, heavy.attack_cooldown_max],
	}


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
