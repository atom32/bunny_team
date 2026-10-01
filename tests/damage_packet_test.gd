extends Node3D

const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_packet_data()
	await _test_enemy_receivers_and_death()
	await _test_hitscan_and_cover()
	await _test_player_receiver()
	await _test_player_armor_tradeoff()
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


func _test_player_armor_tradeoff() -> void:
	var floor := VisualFactory.static_box(self, Vector3(80,0.2,16), Vector3(100,-0.1,50), Color("27333d"), "ArmorTestFloor")
	var light := PlayerController.new()
	var heavy := PlayerController.new()
	add_child(light)
	add_child(heavy)
	light.set_physics_process(false)
	heavy.set_physics_process(false)
	light.global_position = Vector3(80,0.1,48)
	heavy.global_position = Vector3(80,0.1,53)
	light.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	heavy.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	light.equip_armor(ContentDB.get_item(&"armor.recon_shell_01"))
	heavy.equip_armor(ContentDB.get_item(&"armor.bulwark_plate_01"))
	var light_before := light.health
	var heavy_before := heavy.health
	var light_hit := light.receive_damage(DamagePacket.new(25.0))
	var heavy_hit := heavy.receive_damage(DamagePacket.new(25.0))
	check(is_equal_approx(light_hit, 22.5) and is_equal_approx(light_before-light.health,22.5), "Light Armor reduces actual 25 damage to 22.5 (10% protection)")
	check(is_equal_approx(heavy_hit, 15.0) and is_equal_approx(heavy_before-heavy.health,15.0), "Heavy Armor reduces actual 25 damage to 15 (40% protection)")
	check(is_equal_approx(light.get_movement_speed(),8.2) and is_equal_approx(heavy.get_movement_speed(),6.2), "Same AR loadout has 8.2 vs 6.2 m/s mobility")
	check(light.armor_data.weight == 3.0 and heavy.armor_data.weight == 8.0, "Armor carry weight is 3 vs 8 kg")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press("move_right")
	var light_start := light.global_position
	var heavy_start := heavy.global_position
	for _frame in 60:
		await get_tree().physics_frame
		light._update_movement(1.0/60.0)
		heavy._update_movement(1.0/60.0)
	Input.action_release("move_right")
	var light_distance := ((light.global_position-light_start) * Vector3(1, 0, 1)).length()
	var heavy_distance := ((heavy.global_position-heavy_start) * Vector3(1, 0, 1)).length()
	print("ARMOR TRADEOFF / 25 damage: light %.1f HP, heavy %.1f HP / travel: light %.2fm, heavy %.2fm" % [light_hit,heavy_hit,light_distance,heavy_distance])
	check(light_distance > heavy_distance + 1.5 and heavy_distance > 5.0, "Actual one-second traversal differs: light %.2fm, heavy %.2fm" % [light_distance,heavy_distance])
	var profile := ProfileState.create_new()
	profile._equip_first_definition(LoadoutState.SLOT_ARMOR, &"armor.bulwark_plate_01")
	var save_path := "user://armor_tradeoff_%s.json" % OS.get_process_id()
	check(SaveService.save_profile(profile,save_path) == OK, "Heavy Armor loadout saves")
	var restored := SaveService.load_profile(save_path,false)
	var session := SortieSession.create_from_profile(restored.create_sortie_request(),restored)
	check(session.activate(), "Saved Heavy Armor sortie activates")
	var deployed := PlayerController.new()
	deployed.configure_sortie(session)
	add_child(deployed)
	deployed.set_physics_process(false)
	check(is_equal_approx(deployed.get_protection(),0.4) and is_equal_approx(deployed.get_movement_speed(),6.2), "Saved Heavy Armor selection applies protection and mobility after deployment")
	check(deployed.receive_damage(DamagePacket.new(25.0)) == 15.0, "Deployed Heavy Armor mitigates real incoming damage")
	var hud := BattleHUD.new()
	add_child(hud)
	hud.set_armor_stats(heavy.get_movement_speed(),heavy.get_protection(),heavy.armor_data.weight)
	check(hud.armor_label.text.contains("6.2 m/s") and hud.armor_label.text.contains("40%") and hud.armor_label.text.contains("8.0 kg"), "HUD exposes actual mobility, protection and carry weight")
	var hanger_ui := HangerUI.new()
	hanger_ui.configure(restored.inventory,restored.loadout)
	add_child(hanger_ui)
	check(hanger_ui.armor_detail.text.contains("6.2 m/s") and hanger_ui.armor_detail.text.contains("40%") and hanger_ui.armor_detail.text.contains("8.0 kg"), "Loadout screen exposes Heavy Armor tradeoff")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	for node in [light,heavy,deployed,hud,hanger_ui,floor]: node.queue_free()
	await get_tree().process_frame
