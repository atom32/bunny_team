extends Node3D

const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_packet_data()
	await _test_enemy_receivers_and_death()
	await _test_hitscan_and_cover()
	await _test_player_receiver()
	_test_weapon_boundary()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("DAMAGE_PACKET_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("DAMAGE_PACKET_TEST: %s" % failure)
		print("DAMAGE_PACKET_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_packet_data() -> void:
	var packet := DamagePacket.new(10.0, 0.0, 3.0, self, &"weapon.test", &"player", Vector3(1.0, 2.0, 3.0), Vector3.UP)
	check(packet.structure_damage == 3.0 and packet.source_actor == self and packet.source_weapon == &"weapon.test" and packet.source_faction == &"player", "packet carries source and structure context")
	check(packet.hit_position == Vector3(1.0, 2.0, 3.0) and packet.hit_normal == Vector3.UP, "packet carries hit context")
	var packet_b := DamagePacket.new(4.0, 1.0)
	packet.base_damage = 99.0
	check(packet_b.base_damage == 4.0 and packet_b.armor_penetration == 1.0, "DamagePacket instances do not share mutable state")


func _test_enemy_receivers_and_death() -> void:
	var container := Node3D.new()
	add_child(container)
	var basic := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_basic_enemy"), Transform3D.IDENTITY, container)
	var heavy := EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_heavy_enemy"), Transform3D(Basis.IDENTITY, Vector3(2.0, 0.0, 0.0)), container)
	check(basic != null and heavy != null, "basic and heavy packet receiver fixtures spawn")
	if not basic or not heavy:
		container.queue_free()
		return
	basic.set_physics_process(false)
	heavy.set_physics_process(false)
	var basic_before := basic.health
	var heavy_before := heavy.health
	var basic_applied := basic.receive_damage(DamagePacket.new(10.0))
	var heavy_applied := heavy.receive_damage(DamagePacket.new(10.0))
	check(is_equal_approx(basic_applied, 10.0) and is_equal_approx(basic_before - basic.health, 10.0), "basic receiver applies ten unarmored damage")
	check(is_equal_approx(heavy_applied, 2.0) and is_equal_approx(heavy_before - heavy.health, 2.0), "heavy receiver applies two damage through eight armor")
	var penetrated := heavy.receive_damage(DamagePacket.new(10.0, 6.0))
	check(is_equal_approx(penetrated, 8.0), "heavy receiver resolves penetration through the same packet boundary")
	var fully_penetrated := heavy.receive_damage(DamagePacket.new(10.0, 10.0))
	check(is_equal_approx(fully_penetrated, 10.0), "penetration equal to armor applies full base damage")
	var configured_armor := heavy.armor
	heavy.armor = 20.0
	var fully_blocked := heavy.receive_damage(DamagePacket.new(5.0))
	check(is_equal_approx(fully_blocked, 0.0), "target-side armor resolution cannot create negative health damage")
	heavy.armor = configured_armor

	var profile := ProfileState.create_new()
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "enemy death fixture starts an active Sortie")
	# Battle connects this same signal to the session objective boundary.
	var defeated := [0]
	basic.died.connect(func(_enemy: EnemyController) -> void:
		defeated[0] += 1
		session.record_enemy_defeat()
	)
	basic.receive_damage(DamagePacket.new(1000.0, 1000.0, 0.0, self, &"weapon.test", &"player", basic.global_position, Vector3.UP))
	await get_tree().process_frame
	var objective := session.get_objective_state(&"eliminate_prototype_enemies") if session else null
	check(defeated[0] == 1 and objective != null and objective.progress == 1, "lethal DamagePacket preserves enemy death to Sortie objective progress")
	container.queue_free()
	await get_tree().process_frame


func _test_hitscan_and_cover() -> void:
	var shooter := PlayerController.new()
	shooter.preview_mode = true
	add_child(shooter)
	shooter.global_position = Vector3.ZERO
	shooter.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	var heavy := EnemySpawnService.spawn(
		ContentDB.get_enemy_definition(&"prototype_heavy_enemy"),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -8.0)),
		self
	)
	heavy.set_physics_process(false)
	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var health_before := heavy.health
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(heavy.health, health_before), "Cover world collision prevents DamagePacket delivery")
	cover.position.x = 4.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	var clear_query := PhysicsRayQueryParameters3D.create(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, -34.0), 6)
	var clear_result := get_world_3d().direct_space_state.intersect_ray(clear_query)
	var clear_collider := clear_result.get("collider") as Node
	check(not clear_result.is_empty() and clear_collider == heavy, "clear hitscan ray reaches the heavy receiver (hit %s)" % (clear_collider.name if clear_collider else "nothing"))
	shooter._fire_hitscan(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	check(is_equal_approx(health_before - heavy.health, 12.0), "clear hitscan delivers rifle packet and heavy armor resolves twenty damage to twelve (actual %.2f)" % (health_before - heavy.health))
	cover.queue_free()
	heavy.queue_free()
	shooter.queue_free()
	await get_tree().process_frame


func _test_player_receiver() -> void:
	var player := PlayerController.new()
	add_child(player)
	player.set_physics_process(false)
	var health_before := player.health
	var enemy_source := Node3D.new()
	add_child(enemy_source)
	var applied := player.receive_damage(DamagePacket.new(7.0, 0.0, 0.0, enemy_source, &"enemy.prototype_rifle", &"enemy"))
	check(is_equal_approx(applied, 7.0) and is_equal_approx(health_before - player.health, 7.0), "player receives enemy damage through DamagePacket")
	player.receive_damage(DamagePacket.new(player.max_health * 2.0, 0.0, 0.0, enemy_source, &"enemy.prototype_rifle", &"enemy"))
	check(player.is_dead, "lethal DamagePacket preserves player death handling")
	enemy_source.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_weapon_boundary() -> void:
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player_controller.gd")
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	check(player_source.contains("target.receive_damage(packet)"), "hitscan delivers a DamagePacket through the receiver protocol")
	check(not player_source.contains("EnemyDefinition") and not player_source.contains("prototype_heavy_enemy") and not player_source.contains("target.definition_id"), "weapon firing does not inspect enemy type or EnemyDefinition")
	check(enemy_source.contains("target.receive_damage(packet)") and not enemy_source.contains("target.take_damage("), "enemy attack delivery uses the same DamagePacket receiver boundary")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
