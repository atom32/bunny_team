extends Node3D

const DESTRUCTIBLE_SCENE := preload("res://scenes/world/destructible_world_object.tscn")
const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")
const ROCKET_SCENE := preload("res://scenes/weapons/rocket_projectile.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_structure_damage_semantics()
	await _test_weapon_definitions_and_cover_boundary()
	await _test_hitscan_before_and_after_destruction()
	await _test_rocket_packet_path()
	_test_authored_area()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("DESTRUCTIBLE_WORLD_OBJECT_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("DESTRUCTIBLE_WORLD_OBJECT_TEST: %s" % failure)
		print("DESTRUCTIBLE_WORLD_OBJECT_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_structure_damage_semantics() -> void:
	var barrier := _spawn_barrier(Vector3.ZERO)
	var collision := barrier.collision_shape
	check(barrier.max_structure_health > 0.0 and barrier.current_structure_health == barrier.max_structure_health, "barrier starts with full runtime structure health")
	check(not barrier.destroyed and collision != null and not collision.disabled and barrier.visual.visible, "barrier starts visible with collision enabled")

	var applied := barrier.receive_damage(DamagePacket.new(999.0, 0.0, 10.0))
	check(applied == 10.0 and barrier.current_structure_health == barrier.max_structure_health - 10.0, "world structure consumes structure_damage instead of base_damage")
	var health_before_zero := barrier.current_structure_health
	check(barrier.receive_damage(DamagePacket.new(999.0, 999.0, 0.0)) == 0.0 and barrier.current_structure_health == health_before_zero, "zero structure damage leaves world structure unchanged")
	check(barrier.receive_damage(DamagePacket.new(10.0, 0.0, 5.0)) == 5.0 and barrier.current_structure_health == 5.0, "armor penetration does not alter structure damage")
	check(barrier.receive_damage(DamagePacket.new(0.0, 0.0, 5.0)) == 5.0 and barrier.destroyed, "lethal structure damage destroys the barrier")
	await get_tree().physics_frame
	check(barrier.current_structure_health == 0.0 and collision.disabled and not barrier.visual.visible, "destroyed barrier hides its visual and disables collision")
	check(barrier.receive_damage(DamagePacket.new(0.0, 0.0, 100.0)) == 0.0 and barrier.current_structure_health == 0.0, "destroyed barrier rejects subsequent packets")
	barrier.queue_free()
	await get_tree().process_frame


func _test_weapon_definitions_and_cover_boundary() -> void:
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01")
	var rocket := ContentDB.get_weapon(&"weapon.rocket_launcher_01")
	check(rifle.structure_damage == 5.0 and rocket.structure_damage == 50.0, "rifle and rocket expose distinct authored structure damage")
	var rifle_target := _spawn_barrier(Vector3(-3.0, 0.0, 0.0))
	var rocket_target := _spawn_barrier(Vector3(3.0, 0.0, 0.0))
	rifle_target.receive_damage(_packet_from_weapon(rifle))
	rocket_target.receive_damage(_packet_from_weapon(rocket))
	check(rifle_target.current_structure_health == 15.0 and not rifle_target.destroyed, "rifle packet damages the structure through the shared receiver")
	check(rocket_target.destroyed, "rocket packet destroys the same structure without weapon-ID branches")

	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	await get_tree().physics_frame
	var cover_collision := cover.find_child("CollisionShape3D", true, false) as CollisionShape3D
	check(not cover.has_method("receive_damage") and cover_collision != null and not cover_collision.disabled, "Cover remains outside the destructible receiver boundary")
	check(_ray_collider(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, -8.0)) == cover, "indestructible Cover continues to block world collision")

	cover.queue_free()
	rifle_target.queue_free()
	rocket_target.queue_free()
	await get_tree().process_frame


func _test_hitscan_before_and_after_destruction() -> void:
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	var barrier := _spawn_barrier(Vector3(0.0, 0.0, -4.0))
	var heavy := EnemySpawnService.spawn(
		ContentDB.get_enemy_definition(&"prototype_heavy_enemy"),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -8.0)),
		self
	)
	heavy.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var heavy_health_before := heavy.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(barrier.current_structure_health == 15.0 and heavy.health == heavy_health_before, "barrier consumes rifle structure damage and shields the Heavy behind it")
	for _shot in 3:
		shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(barrier.destroyed and barrier.collision_shape.disabled, "four rifle hits remove the barrier collision")
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(heavy_health_before - heavy.health, 12.0), "after destruction the rifle packet reaches Heavy and resolves twenty damage through eight armor")

	barrier.queue_free()
	heavy.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_rocket_packet_path() -> void:
	var barrier := _spawn_barrier(Vector3.ZERO)
	var shooter := StaticBody3D.new()
	add_child(shooter)
	var rocket: Variant = ROCKET_SCENE.instantiate()
	add_child(rocket)
	rocket.global_position = barrier.global_position
	rocket.setup(shooter, Vector3.FORWARD, ContentDB.get_weapon(&"weapon.rocket_launcher_01"))
	await get_tree().physics_frame
	rocket._explode()
	await get_tree().physics_frame
	check(barrier.destroyed, "rocket explosion finds world-layer receivers and delivers the same DamagePacket")
	barrier.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_authored_area() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var barrier := area.find_child("DestructibleBarrier", true, false) as DestructibleWorldObject
	var covers := area.find_children("*", "CoverObstacle", true, false)
	check(barrier != null and not barrier.destroyed, "Prototype Arena authors one fresh destructible barrier")
	check(covers.size() == 3, "authored destructible barrier does not replace the three permanent covers")
	area.free()


func _spawn_barrier(position_value: Vector3) -> DestructibleWorldObject:
	var barrier := DESTRUCTIBLE_SCENE.instantiate() as DestructibleWorldObject
	barrier.position = position_value
	add_child(barrier)
	return barrier


func _packet_from_weapon(weapon: WeaponDefinition) -> DamagePacket:
	return DamagePacket.new(weapon.damage, weapon.armor_penetration, weapon.structure_damage, self, weapon.id, &"player")


func _ray_collider(from: Vector3, to: Vector3) -> Node:
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result.get("collider") as Node


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
