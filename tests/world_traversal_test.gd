extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_authored_field_office()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("WORLD_TRAVERSAL_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("WORLD_TRAVERSAL_TEST: %s" % failure)
		print("WORLD_TRAVERSAL_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_authored_field_office() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	check(area != null, "Prototype Arena instantiates through AreaLoader")
	if not area:
		return
	add_child(area)
	await get_tree().process_frame
	await get_tree().physics_frame
	var building := area.find_child("FieldOffice", true, false) as Node3D
	var door := area.find_child("SouthAccessDoor", true, false) as Door
	var floor := building.find_child("InteriorFloor", true, false) as StaticBody3D if building else null
	var ceiling := building.find_child("CeilingFrame", true, false) as Node3D if building else null
	var terminal := area.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var interior_cover := area.find_child("InteriorEntryCover", true, false) as CoverObstacle
	var barrier := area.find_child("DestructibleBarrier", true, false) as DestructibleWorldObject
	check(building != null and door != null, "authored Area contains a Field Office and interactive entrance Door")
	check(floor != null and floor.find_child("CollisionShape3D", true, false) != null, "Field Office owns a collidable interior floor")
	check(ceiling != null and ceiling.get_child_count() == 4, "Field Office has a visible ceiling frame without hiding the top-down interior")
	check(building.find_child("WestWall", true, false) != null and building.find_child("EastWall", true, false) != null, "Field Office owns collidable side walls")
	check(terminal != null and interior_cover != null and barrier != null, "existing Terminal, Cover, and Barrier are authored inside the building footprint")
	if not building or not door:
		area.queue_free()
		return

	var profile := ProfileState.create_new()
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "traversal fixture creates an ACTIVE Sortie")
	check(not door.is_open() and not door.door_collision.disabled, "building entrance starts closed and collidable")
	check(bool(door.interact(null, session).success), "existing interaction contract opens the building Door")
	await get_tree().physics_frame
	check(door.is_open() and door.door_collision.disabled, "open Door removes entrance collision")

	var player := PLAYER_SCENE.instantiate() as PlayerController
	add_child(player)
	await get_tree().process_frame
	player.set_process(false)
	player.set_physics_process(false)
	player.global_position = building.to_global(Vector3(0.0, 0.0, 8.5))
	await get_tree().physics_frame
	player.move_and_collide(Vector3(0.0, 0.0, -3.0))
	var entered_local := building.to_local(player.global_position)
	check(entered_local.z < 7.0 and entered_local.z > -7.0, "real Player collision body crosses the open front doorway into Interior")
	player.global_position = building.to_global(Vector3(0.0, 0.0, -5.5))
	await get_tree().physics_frame
	player.move_and_collide(Vector3(0.0, 0.0, -3.0))
	var exited_local := building.to_local(player.global_position)
	check(exited_local.z < -7.0, "real Player collision body leaves through the authored back exit")

	var floor_query := PhysicsRayQueryParameters3D.create(
		building.to_global(Vector3(0.0, 2.0, 0.0)),
		building.to_global(Vector3(0.0, -1.0, 0.0)),
		4
	)
	var floor_hit := get_world_3d().direct_space_state.intersect_ray(floor_query)
	check(not floor_hit.is_empty() and floor_hit.collider == floor, "interior floor participates in world collision")
	var wall_query := PhysicsRayQueryParameters3D.create(
		building.to_global(Vector3(0.0, 1.0, -4.0)),
		building.to_global(Vector3(7.0, 1.0, -4.0)),
		4
	)
	var wall_hit := get_world_3d().direct_space_state.intersect_ray(wall_query)
	var wall_collider_name := String(wall_hit.collider.name) if not wall_hit.is_empty() else "none"
	check(not wall_hit.is_empty() and wall_hit.collider.name == "EastWall", "interior wall bounds the combat space (hit %s)" % wall_collider_name)

	player.queue_free()
	area.queue_free()
	await get_tree().process_frame


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
