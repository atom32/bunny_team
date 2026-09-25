extends Node3D

const DOOR_SCENE := preload("res://scenes/world/door.tscn")
const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")

class DamageTarget:
	extends StaticBody3D

	var health := 100.0

	func _init() -> void:
		collision_layer = 2
		collision_mask = 0
		var shape := CapsuleShape3D.new()
		shape.radius = 0.5
		shape.height = 2.0
		var collision := CollisionShape3D.new()
		collision.position.y = 0.9
		collision.shape = shape
		add_child(collision)

	func receive_damage(packet: DamagePacket) -> float:
		var applied_damage := packet.base_damage
		health = maxf(health - applied_damage, 0.0)
		return applied_damage


var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_door_interaction_and_collision()
	await _test_cover_blocks_hitscan()
	_test_authored_area_geometry()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("WORLD_INTERACTION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("WORLD_INTERACTION_TEST: %s" % failure)
		print("WORLD_INTERACTION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_door_interaction_and_collision() -> void:
	var profile := ProfileState.create_new()
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "door fixture starts an active sortie")
	if not session:
		return

	var door := DOOR_SCENE.instantiate() as Door
	add_child(door)
	var actor := Node3D.new()
	actor.position = Vector3(1.1, 0.0, 1.5)
	add_child(actor)
	var interaction := InteractionComponent.new()
	actor.add_child(interaction)
	interaction.setup(actor, session)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var collision := door.find_child("CollisionShape3D", true, false) as CollisionShape3D
	check(not door.is_open() and collision != null and not collision.disabled, "door starts CLOSED with collision enabled")
	check(_ray_hits_world(Vector3(1.1, 1.2, 3.0), Vector3(1.1, 1.2, -3.0), door), "closed door blocks world collision queries")
	var opened := interaction.interact_with_current()
	check(bool(opened.get("success", false)) and door.is_open(), "InteractionComponent opens the authored door through the shared protocol")
	await get_tree().physics_frame
	check(collision.disabled and not _ray_hits_world(Vector3(1.1, 1.2, 3.0), Vector3(1.1, 1.2, -3.0), door), "open door disables its gameplay collision")
	var closed := interaction.interact_with_current()
	check(bool(closed.get("success", false)) and not door.is_open(), "repeated interaction closes the door")
	await get_tree().physics_frame
	check(not collision.disabled and _ray_hits_world(Vector3(1.1, 1.2, 3.0), Vector3(1.1, 1.2, -3.0), door), "closed door restores its gameplay collision")

	check(session.fail(), "door fixture can enter a terminal Sortie state")
	var state_before := door.state
	var rejected := door.interact(actor, session)
	check(not bool(rejected.get("success", false)) and door.state == state_before, "non-ACTIVE Sortie cannot change door state")

	interaction.queue_free()
	actor.queue_free()
	door.queue_free()
	await get_tree().process_frame


func _test_cover_blocks_hitscan() -> void:
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.global_position = Vector3.ZERO
	shooter.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))

	var target := DamageTarget.new()
	target.position = Vector3(0.0, 0.0, -8.0)
	add_child(target)
	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var cover_collision := cover.find_child("CollisionShape3D", true, false) as CollisionShape3D
	check(cover.collision_layer == 4 and cover_collision != null and not cover_collision.disabled, "CoverObstacle owns enabled world collision")
	var health_before := target.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(target.health, health_before), "hitscan stops at cover and does not damage the target behind it")

	cover.position.x = 4.0
	await get_tree().physics_frame
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(target.health < health_before, "hitscan damages the target after the cover no longer blocks line of sight")

	cover.queue_free()
	target.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_authored_area_geometry() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var door := area.find_child("SouthAccessDoor", true, false) as Door
	var covers := area.find_children("*", "CoverObstacle", true, false)
	check(door != null and not door.is_open(), "Prototype Arena authors one initially closed tactical door")
	check(covers.size() == 3, "Prototype Arena authors three ballistic CoverObstacles")
	area.free()


func _ray_hits_world(from: Vector3, to: Vector3, expected_root: Node) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider := result.collider as Node
	return collider == expected_root or expected_root.is_ancestor_of(collider)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
