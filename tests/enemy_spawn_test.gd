extends Node3D

const SPAWN_POINT_SCENE := preload("res://scenes/world/enemy_spawn_point.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_definition_resolution()
	_test_authored_spawn_points()
	await _test_spawn_and_instance_independence()
	await _test_enemy_death_progress()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("ENEMY_SPAWN_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("ENEMY_SPAWN_TEST: %s" % failure)
		print("ENEMY_SPAWN_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_definition_resolution() -> void:
	var definition := ContentDB.get_enemy_definition(&"prototype_basic_enemy", false)
	check(definition != null and definition.validate_definition(), "prototype enemy resolves through ContentDB")
	if definition:
		check(definition.id == &"prototype_basic_enemy", "enemy definition exposes a stable content ID")
		check(definition.display_name == "Prototype Basic Enemy", "enemy definition exposes authored display content")
		check(definition.scene != null and definition.scene.resource_path == "res://scenes/enemies/enemy.tscn", "enemy definition points to the existing enemy runtime scene")
	check(ContentDB.get_enemy_definition(&"does_not_exist", false) == null, "unknown enemy ID fails without fallback")
	check(not ContentDB.has_enemy(&"does_not_exist"), "unknown enemy ID is absent from the registry")


func _test_authored_spawn_points() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var spawn_points := area.find_children("*", "EnemySpawnPoint", true, false)
	var initial_spawns := spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.initial_spawn)
	var reinforcement_spawns := spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return not point.initial_spawn)
	check(initial_spawns.size() == 12 and reinforcement_spawns.size() == 3, "Prototype Arena authors separate initial and reinforcement EnemySpawnPoints")
	check(_count_spawn_points(initial_spawns, &"prototype_basic_enemy") == 9, "Prototype Arena declares nine initial basic enemy spawn points")
	check(_count_spawn_points(initial_spawns, &"prototype_heavy_enemy") == 3, "Prototype Arena declares three initial heavy enemy spawn points")
	check(_count_spawn_points(reinforcement_spawns, &"prototype_basic_enemy") == 2 and _count_spawn_points(reinforcement_spawns, &"prototype_heavy_enemy") == 1, "Prototype Arena authors two basic and one heavy reinforcement")
	area.free()


func _test_spawn_and_instance_independence() -> void:
	var definition := ContentDB.get_enemy_definition(&"prototype_basic_enemy")
	var container := Node3D.new()
	container.name = "SpawnFixture"
	add_child(container)
	var enemies: Array[EnemyController] = []
	for index in 3:
		var spawn_point := SPAWN_POINT_SCENE.instantiate() as EnemySpawnPoint
		spawn_point.enemy_definition_id = definition.id
		spawn_point.position = Vector3(float(index) * 3.0, 0.1, -5.0)
		add_child(spawn_point)
		var enemy := EnemySpawnService.spawn(definition, spawn_point.global_transform, container)
		check(enemy != null and enemy.global_transform.is_equal_approx(spawn_point.global_transform), "spawn service applies authored spawn transform")
		if enemy:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemies.append(enemy)
		spawn_point.queue_free()
	await get_tree().process_frame
	check(enemies.size() == 3 and enemies[0] != enemies[1] and enemies[1] != enemies[2], "three spawn points create three independent runtime nodes")
	if enemies.size() == 3:
		var second_health := enemies[1].health
		enemies[0].health -= 10.0
		check(enemies[0].health != enemies[1].health and enemies[1].health == second_health, "enemy runtime health is independent between instances")
	container.queue_free()
	await get_tree().process_frame


func _test_enemy_death_progress() -> void:
	var profile := ProfileState.create_new()
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "death fixture starts an active sortie")
	if not session:
		return
	var container := Node3D.new()
	add_child(container)
	var definition := ContentDB.get_enemy_definition(&"prototype_basic_enemy")
	var enemy := EnemySpawnService.spawn(definition, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, -4.0)), container)
	check(enemy != null, "enemy death fixture instantiates from EnemyDefinition")
	if not enemy:
		container.queue_free()
		return
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.died.connect(func(_dead: EnemyController) -> void: session.record_enemy_defeat())
	var objective_before := session.get_objective_state(&"eliminate_prototype_enemies").progress
	enemy.take_damage(enemy.health + 1.0)
	await get_tree().process_frame
	var objective_after := session.get_objective_state(&"eliminate_prototype_enemies").progress
	check(objective_after == objective_before + 1, "enemy death signal advances SortieSession eliminate progress")
	container.queue_free()
	await get_tree().process_frame


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)


func _count_spawn_points(spawn_points: Array[Node], definition_id: StringName) -> int:
	return spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == definition_id).size()
