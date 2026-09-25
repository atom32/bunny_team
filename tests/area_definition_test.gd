extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_content_resolution()
	_test_area_loading()
	_test_sortie_id_boundary()
	_test_mission_area_separation()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("AREA_DEFINITION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("AREA_DEFINITION_TEST: %s" % failure)
		print("AREA_DEFINITION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_content_resolution() -> void:
	var definition := ContentDB.get_area_definition(&"prototype_arena", false)
	check(definition != null and definition.validate_definition(), "prototype area resolves through ContentDB")
	if definition:
		check(definition.id == &"prototype_arena", "area exposes a stable content ID")
		check(definition.display_name == "Prototype Arena", "area exposes authored display content")
		check(definition.scene != null and definition.scene.resource_path == "res://scenes/areas/prototype_arena.tscn", "area definition points to the authored area scene")
	check(ContentDB.get_area_definition(&"does_not_exist", false) == null, "unknown area ID fails without fallback")
	check(not ContentDB.has_area(&"does_not_exist"), "unknown area ID is absent from the registry")


func _test_area_loading() -> void:
	var definition := ContentDB.get_area_definition(&"prototype_arena")
	var area := AreaLoader.instantiate_area(definition)
	check(area != null and area is PrototypeArena, "AreaLoader instantiates the definition PackedScene")
	if not area:
		return
	check(area.find_child("Environment", true, false) != null, "authored area owns terrain and environment content")
	check(area.find_children("*", "LootSpawnPoint", true, false).size() == 4, "authored area owns standard and high-value loot spawn locations")
	check(area.find_children("*", "ThreatEvent", true, false).size() == 1, "authored area owns one local threat event")
	check(area.find_children("*", "ObjectiveInteractable", true, false).size() == 1, "authored area owns interaction locations")
	check(area.find_children("*", "ObjectiveReachZone", true, false).size() == 1, "authored area owns reach locations")
	check(area.find_children("*", "ExtractionPoint", true, false).size() == 1, "authored area owns extraction locations")
	check(area.find_children("*", "Door", true, false).size() == 1, "authored area owns one interactive door")
	check(area.find_children("*", "CoverObstacle", true, false).size() == 3, "authored area owns three ballistic cover obstacles")
	var player_spawns := 0
	var enemy_spawns := area.find_children("*", "EnemySpawnPoint", true, false)
	for marker in area.find_children("*", "Marker3D", true, false):
		player_spawns += 1 if marker.is_in_group("player_spawn_point") else 0
	var initial_spawns := enemy_spawns.filter(func(point: EnemySpawnPoint) -> bool: return point.initial_spawn)
	var reinforcement_spawns := enemy_spawns.filter(func(point: EnemySpawnPoint) -> bool: return not point.initial_spawn)
	check(player_spawns == 1 and initial_spawns.size() == 12 and reinforcement_spawns.size() == 3, "authored area separates twelve initial and three reinforcement spawn locations")
	check(_count_enemy_spawns(initial_spawns, &"prototype_basic_enemy") == 9, "authored area assigns nine initial spawn points to the basic enemy definition")
	check(_count_enemy_spawns(initial_spawns, &"prototype_heavy_enemy") == 3, "authored area assigns three initial spawn points to the heavy enemy definition")
	area.free()
	check(AreaLoader.instantiate_area(null) == null, "AreaLoader rejects an invalid definition instead of falling back")


func _test_sortie_id_boundary() -> void:
	var profile := ProfileState.create_new()
	check(profile.create_sortie_request(&"does_not_exist", &"prototype_combat") == null, "SortieRequest rejects an unregistered area ID")
	var request := profile.create_sortie_request(&"prototype_arena", &"prototype_combat")
	check(request != null and typeof(request.area_id) == TYPE_STRING_NAME, "SortieRequest stores only the stable area ID")
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.area_id == &"prototype_arena", "SortieSession carries the stable area ID into runtime")
	check(not _has_property(session, &"area_scene") and not _has_property(session, &"area_definition"), "SortieSession does not retain scene or AreaDefinition references")


func _test_mission_area_separation() -> void:
	var mission := ContentDB.get_mission(&"prototype_combat")
	var area := ContentDB.get_area_definition(&"prototype_arena")
	check(not _has_property(mission, &"scene") and not _has_property(mission, &"area_id"), "MissionDefinition contains WHAT without an area scene reference")
	check(not _has_property(area, &"mission_id") and not _has_property(area, &"objective_definitions"), "AreaDefinition contains WHERE without mission runtime or objectives")


func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _count_enemy_spawns(spawn_points: Array[Node], definition_id: StringName) -> int:
	return spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == definition_id).size()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
