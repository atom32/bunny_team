extends Node

var failures: Array[String] = []
var extracted_loot_id := ""
var high_value_loot_ids: Array[String] = []
var acceptance_save_path := ""
var early_extraction_save_path := ""
var failure_save_path := ""
var warehouse_count_before := 0
var uncarried_warehouse_id := ""
var explicit_ammo_id := ""
var explicit_rocket_ammo_id := ""
var expected_extracted_ammo_quantity := 0
var expected_extracted_rocket_quantity := 0
var generated_ammo_quantity := 0


func _ready() -> void:
	acceptance_save_path = "user://acceptance_extraction_%d.json" % OS.get_process_id()
	early_extraction_save_path = "user://acceptance_early_extraction_%d.json" % OS.get_process_id()
	failure_save_path = "user://acceptance_failure_%d.json" % OS.get_process_id()
	_cleanup_save(acceptance_save_path)
	_cleanup_save(early_extraction_save_path)
	_cleanup_save(failure_save_path)
	ProfileRuntime.new_profile()
	SortieRuntime.clear_session()
	await get_tree().process_frame
	_test_resources()
	await _test_hanger_and_equipment()
	await _test_battle()
	await _test_enemy_character_debug()
	await _test_ragdoll()
	await _test_result()
	await _test_early_extraction()
	await _test_failed_sortie()
	_cleanup_save(acceptance_save_path)
	_cleanup_save(early_extraction_save_path)
	_cleanup_save(failure_save_path)
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("ACCEPTANCE_SMOKE: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("ACCEPTANCE_SMOKE: %s" % failure)
		print("ACCEPTANCE_SMOKE: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_resources() -> void:
	var profile := ProfileRuntime.get_profile()
	check(profile != null and profile.validate(), "ProfileRuntime owns a valid current profile")
	check(ContentDB.get_items().size() == 11, "content manifest registers all prototype definitions")
	check(ContentDB.get_weapon(&"weapon.assault_rifle_01", false) != null, "stable rifle content ID resolves")
	check(ContentDB.get_ammo(&"ammo.556_ap", false) != null, "stable ammunition content ID resolves")
	check(ContentDB.get_ammo(&"ammo.rocket_standard", false) != null, "rocket ammunition content ID resolves")
	check(ContentDB.get_item(&"loot.salvage_core_01", false) != null, "prototype salvage loot content ID resolves")
	var mission := ContentDB.get_mission(&"prototype_combat", false)
	check(mission != null and mission.objective_definitions.size() == 3, "prototype mission resolves all three objective types through ContentDB")
	var area := ContentDB.get_area_definition(&"prototype_arena", false)
	check(area != null and area.scene != null, "prototype area resolves to an authored scene through ContentDB")
	var loot_table := ContentDB.get_loot_table(&"prototype_basic_loot", false)
	check(loot_table != null and loot_table.entries.size() == 3, "prototype loot table resolves through ContentDB")
	check(AudioServer.get_bus_index(&"Music") >= 0 and AudioServer.get_bus_index(&"SFX") >= 0, "music and sound effects use dedicated audio buses")
	check(AudioDirector.music_player != null and AudioDirector.music_player.stream is AudioStreamWAV, "the synthwave background loop is loaded")
	if AudioDirector.music_player and AudioDirector.music_player.stream is AudioStreamWAV:
		var music_stream := AudioDirector.music_player.stream as AudioStreamWAV
		check(music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and music_stream.get_length() >= 20.0, "background music loops without scene restarts")
	check(AudioDirector._sfx_players.size() >= 16, "rapid weapon fire uses a reusable sound-player pool")
	for cue in [&"ar_fire", &"smg_fire", &"rocket_fire", &"enemy_fire", &"impact", &"player_hurt", &"explosion", &"dodge", &"reload", &"ui_click", &"victory", &"defeat"]:
		check(AudioDirector.has_cue(cue), "%s sound cue is available" % cue)
	for weapon_audio in [[&"weapon.assault_rifle_01", &"ar_fire"], [&"weapon.smg_01", &"smg_fire"], [&"weapon.rocket_launcher_01", &"rocket_fire"]]:
		AudioDirector.play_weapon(weapon_audio[0])
		check(AudioDirector.last_cue == weapon_audio[1], "%s uses its distinct weapon sound" % weapon_audio[0])
	check((ContentDB.get_item(&"armor.recon_shell_01", false) as EquipmentDefinition) != null, "light armor definition is registered")
	check((ContentDB.get_item(&"equipment.field_pack_01", false) as EquipmentDefinition) != null, "backpack definition is registered")
	for weapon_id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		var weapon := ContentDB.get_weapon(weapon_id)
		check(weapon != null and weapon.scene != null, "%s has a visible PackedScene" % weapon_id)
		check(weapon.damage > 0.0 and weapon.fire_rate > 0.0, "%s has live combat stats" % weapon_id)
	var rocket := ContentDB.get_weapon(&"weapon.rocket_launcher_01")
	check(rocket.action_type == &"projectile" and rocket.blast_radius >= 4.0, "rocket launcher uses a radial projectile action")
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01")
	var smg := ContentDB.get_weapon(&"weapon.smg_01")
	check(smg.fire_rate > rifle.fire_rate and smg.weapon_range < rifle.weapon_range, "SMG is the fast close-range weapon")
	check(rifle.damage > smg.damage and rifle.weapon_range >= 30.0, "assault rifle is the stable medium-range weapon")
	check(rocket.damage > rifle.damage * 4.0 and rocket.recoil_strength > rifle.recoil_strength * 3.0, "rocket launcher has distinctly heavy damage and recoil")
	check(rifle.get_runtime_ammo_definition_id() == &"ammo.556_standard" and rifle.magazine_capacity == 30, "rifle has exact runtime ammunition and magazine configuration")


func _test_hanger_and_equipment() -> void:
	var hanger: Node = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := hanger.find_child("Player", true, false) as PlayerController
	var ui := hanger.find_child("HangerUI", true, false) as HangerUI
	check(player != null, "hanger contains a 3D character")
	check(ui != null and ui.weapon_option.item_count == 4, "hanger exposes all primary weapon choices plus unequip")
	check(ui != null and ui.secondary_weapon_option.item_count == 4, "hanger exposes all secondary weapon choices plus unequip")
	if player:
		var profile := ProfileRuntime.get_profile()
		check(player.weapon_instance == profile.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, profile.inventory), "hanger preview equips the selected owned weapon instance")
		var secondary := profile.loadout.get_item(LoadoutState.SLOT_WEAPON_SECONDARY, profile.inventory)
		check(secondary != null and secondary.definition_id == &"weapon.rocket_launcher_01", "new profile equips a concrete rocket launcher instance as secondary")
		check(player.armor_instance == profile.loadout.get_item(LoadoutState.SLOT_ARMOR, profile.inventory), "hanger preview equips the selected owned armor instance")
		check(player.backpack_instance == profile.loadout.get_item(LoadoutState.SLOT_BACKPACK, profile.inventory), "hanger preview equips the selected owned backpack instance")
		check(player.find_child("CombatAvatarModel", true, false) != null, "hanger uses the complete imported VRM avatar")
		check(player.character_skeleton != null and player.character_skeleton.get_bone_count() >= 90, "avatar uses the complete 91-bone humanoid rig")
		check(player.find_child("CharacterRetarget", true, false) != null, "locomotion source retargets onto the VRM humanoid rig")
		check(player.animation_player != null and player.animation_player.has_animation(&"Run"), "combat android includes locomotion animations")
		check(player.animation_tree != null and player.animation_tree.active, "locomotion runs through an active AnimationTree")
		check(InputMap.has_action("reload"), "combat input exposes reload on the player controller")
		check(InputMap.has_action("switch_weapon"), "combat input exposes weapon switching on the player controller")
		check(InputMap.has_action("interact"), "one shared interaction action is available")
		check(player.animation_player.get_animation(&"Idle_Gun").loop_mode == Animation.LOOP_PINGPONG, "hanger idle loops without a hard pose reset")
		check(_animation_has_clean_lead_in(player.animation_player.get_animation(&"Idle_Gun")), "idle animation removes the imported bind-pose lead-in")
		check(_animation_has_clean_lead_in(player.animation_player.get_animation(&"Run")), "run animation removes the imported bind-pose lead-in")
		var warehouse_summary := ui.warehouse_summary if ui else null
		check(warehouse_summary != null and warehouse_summary.text.contains("WEAPONS") and warehouse_summary.text.contains("AMMO") and warehouse_summary.text.contains("EQUIPMENT"), "hanger Warehouse groups persistent inventory by gameplay category")
		check(warehouse_summary != null and warehouse_summary.text.contains("kg") and warehouse_summary.text.contains("[PRIMARY]"), "hanger Warehouse shows weight and equipped state")
		for weapon_id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
			var weapon := ContentDB.get_weapon(weapon_id)
			player.equip_weapon(weapon)
			for _frame in 3:
				await get_tree().process_frame
			if weapon_id == &"weapon.assault_rifle_01":
				check(player.combat_rig.has_weapon(), "assault rifle visibly mounts on the two-hand combat rig")
				check(player.combat_rig.uses_modifier_ik(), "assault rifle hands use Godot TwoBoneIK3D modifiers")
				check(player.combat_rig.uses_model_forward_axis(), "upper-body aim uses the VRM model's -Z forward axis")
				check(player.combat_rig.uses_forward_axis_correction(), "locomotion retarget mirrors the +Z source animation onto the VRM's -Z forward axis")
				var right_hand_error := player.combat_rig.get_hand_error(&"right")
				var left_hand_error := player.combat_rig.get_hand_error(&"left")
				check(right_hand_error < 0.01, "right hand stays on the assault-rifle primary grip (error %.3f m)" % right_hand_error)
				check(left_hand_error < 0.01, "left hand stays on the assault-rifle support grip (error %.3f m)" % left_hand_error)
				player.debug_reload_once()
				check(player.combat_rig.is_reloading(), "reload starts a visible upper-body weapon pose")
				check(player.combat_rig.get_upper_body_state_name() in [&"AIM", &"RELOAD"], "upper-body state remains independent from locomotion")
			else:
				check(_socket_contains(player, weapon.socket_name, weapon_id), "%s visibly mounts on %s" % [weapon_id, weapon.socket_name])
		var face := player.find_child("Face", true, false) as MeshInstance3D
		check(face != null and face.mesh.get_aabb().size.y > 0.2, "avatar keeps its complete authored face mesh")
		player.equip_armor(ContentDB.get_item(&"armor.bulwark_plate_01") as EquipmentDefinition)
		player.equip_backpack(ContentDB.get_item(&"equipment.thruster_pack_01") as EquipmentDefinition)
		await get_tree().process_frame
		check(_socket_contains(player, &"Chest", &"armor.bulwark_plate_01"), "armor selection replaces the chest model")
		check(_socket_contains(player, &"Backpack", &"equipment.thruster_pack_01"), "backpack selection replaces the back model")
	hanger.queue_free()
	await get_tree().process_frame


func _test_battle() -> void:
	var profile := ProfileRuntime.get_profile()
	var explicit_ammo := ItemInstance.new(&"ammo.556_standard", 60, 100.0, "acceptance_ammo")
	check(profile.inventory.add_item(explicit_ammo), "profile warehouse accepts explicit sortie ammunition")
	explicit_ammo_id = explicit_ammo.instance_id
	var rocket_ammo := _find_item_by_definition(profile.inventory, &"ammo.rocket_standard")
	check(rocket_ammo != null, "profile warehouse owns secondary rocket ammunition")
	explicit_rocket_ammo_id = rocket_ammo.instance_id if rocket_ammo else ""
	warehouse_count_before = profile.inventory.get_items().size()
	for item in profile.inventory.get_items():
		if not profile.loadout.is_equipped(item.instance_id):
			uncarried_warehouse_id = item.instance_id
			break
	var carried_ids: Array[String] = [explicit_ammo_id, explicit_rocket_ammo_id]
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		carried_ids
	)
	var active_session := SortieRuntime.start_sortie(request, profile)
	check(active_session != null and active_session.status == SortieSession.Status.ACTIVE, "prototype flow starts an active SortieSession before Battle")
	check(active_session != null and active_session.inventory.get_items().size() == profile.loadout.get_equipped_instance_ids().size() + 2, "sortie starts with dual-slot loadout and explicitly carried ammunition only")
	check(active_session != null and active_session.inventory.contains(explicit_ammo_id) and active_session.inventory.contains(explicit_rocket_ammo_id), "both weapon reserves enter the active sortie inventory")
	check(active_session != null and explicit_ammo_id in active_session.get_initial_carried_instance_ids() and explicit_rocket_ammo_id in active_session.get_initial_carried_instance_ids(), "active sortie records both ammunition stacks in its initial carried set")
	check(active_session != null and active_session.inventory.get_used_capacity() < profile.inventory.get_used_capacity(), "uncarried warehouse items do not consume battle cargo capacity")
	var battle: Node = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed = _find_loot_seed_for_prefix([&"ammo.556_standard", &"loot.salvage_core_01"])
	add_child(battle)
	for _frame in 5:
		await get_tree().process_frame
	var player := battle.find_child("Player", true, false) as PlayerController
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var navigation := battle.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	var loot_pickups := battle.find_children("*", "LootPickup", true, false)
	var extraction_point := battle.find_child("ExtractionPoint", true, false) as ExtractionPoint
	var objective_terminal := battle.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var objective_reach_zone := battle.find_child("PrototypeSurveyZone", true, false) as ObjectiveReachZone
	var authored_door := battle.find_child("SouthAccessDoor", true, false) as Door
	var interior_lane := battle.find_child("InteriorCombatLane", true, false) as Node3D
	var interior_cover := battle.find_child("InteriorEntryCover", true, false) as CoverObstacle
	var destructible_barrier := battle.find_child("DestructibleBarrier", true, false) as DestructibleWorldObject
	var threat_event := battle.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var cover_obstacles := battle.find_children("*", "CoverObstacle", true, false)
	var enemy_spawn_points: Array[Node] = battle.area_root.find_children("*", "EnemySpawnPoint", true, false)
	var initial_enemy_spawn_points := enemy_spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.initial_spawn)
	var reinforcement_spawn_points := enemy_spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return not point.initial_spawn)
	check(player != null, "battle spawns the player")
	check(battle.area_root != null and battle.area_root.scene_file_path == "res://scenes/areas/prototype_arena.tscn", "Battle loads its authored world through Session area ID and AreaDefinition")
	check(battle.find_child("AreaRoot", false, false) != null, "Battle keeps runtime orchestration outside the loaded AreaRoot")
	check(authored_door != null and not authored_door.is_open(), "loaded Area owns an initially closed interactive door")
	check(cover_obstacles.size() == 3, "loaded Area owns three authored ballistic obstacles")
	check(interior_lane != null and interior_cover != null, "loaded Area authors one tactical interior lane with permanent cover")
	check(destructible_barrier != null and not destructible_barrier.destroyed, "loaded Area owns a separate destructible barrier")
	check(initial_enemy_spawn_points.size() == 12 and reinforcement_spawn_points.size() == 3, "loaded Area separates initial enemies from one authored reinforcement group")
	check(_count_enemy_spawn_definitions(initial_enemy_spawn_points, &"prototype_basic_enemy") == 9 and _count_enemy_spawn_definitions(initial_enemy_spawn_points, &"prototype_heavy_enemy") == 3, "loaded Area preserves nine initial basic and three initial heavy enemy definitions")
	check(threat_event != null and active_session.threat_level == SortieSession.ThreatLevel.NORMAL, "loaded Area starts with one inactive local threat event")
	if player:
		if authored_door:
			player.global_position = authored_door.global_position + Vector3(1.1, 0.0, 1.5)
			await get_tree().physics_frame
			await get_tree().physics_frame
			var door_response := player.interaction_component.interact_with_current()
			check(bool(door_response.get("success", false)) and authored_door.is_open(), "player InteractionComponent opens the authored door")
			check(bool(authored_door.interact(player, active_session).get("success", false)) and not authored_door.is_open(), "authored door closes through the same interaction protocol")
		check(player.weapon_instance == active_session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, active_session.inventory), "battle player resolves its weapon through the active SortieSession")
		var profile_before_runtime_ammo := profile.to_dict()
		var initial_capacity := active_session.inventory.get_used_capacity()
		check(player.get_magazine_ammo() == 30 and player.get_reserve_ammo() == 60, "battle starts with a full magazine and explicit reserve ammunition")
		for _shot in 5:
			check(player.debug_fire_once(), "runtime-ammo acceptance shot fires")
		check(player.get_magazine_ammo() == 25 and player.get_reserve_ammo() == 60, "fire consumes magazine rounds without consuming reserve")
		check(is_equal_approx(active_session.inventory.get_used_capacity(), initial_capacity), "magazine rounds do not count toward carried capacity")
		check(player.reload_weapon(), "partial magazine reload succeeds")
		check(player.get_magazine_ammo() == 30 and player.get_reserve_ammo() == 55, "reload fills magazine and consumes reserve ammunition")
		check(is_equal_approx(active_session.inventory.get_used_capacity(), initial_capacity - 0.06), "reload removes transferred rounds from reserve capacity")
		var primary_state: Variant = active_session.get_weapon_runtime_state(player.weapon_instance.instance_id)
		var secondary_item := active_session.loadout.get_item(LoadoutState.SLOT_WEAPON_SECONDARY, active_session.inventory)
		var secondary_state: Variant = active_session.get_weapon_runtime_state(secondary_item.instance_id) if secondary_item else null
		check(primary_state != null and secondary_state != null and primary_state != secondary_state, "battle owns independent primary and secondary runtime states")
		check(profile.to_dict() == profile_before_runtime_ammo, "fire and reload leave the warehouse unchanged")
		expected_extracted_ammo_quantity = 85
	check(enemies.size() == 12, "expanded battle spawns twelve enemies")
	check(_count_runtime_enemies(enemies, &"prototype_basic_enemy") == 9 and _count_runtime_enemies(enemies, &"prototype_heavy_enemy") == 3, "Battle configures nine basic and three heavy runtime enemies without type branches")
	var packet_basic := _find_runtime_enemy(enemies, &"prototype_basic_enemy")
	var packet_heavy := _find_runtime_enemy(enemies, &"prototype_heavy_enemy")
	if packet_basic and packet_heavy:
		var basic_health_before := packet_basic.health
		var heavy_health_before := packet_heavy.health
		packet_basic.receive_damage(DamagePacket.new(10.0, 0.0, 0.0, player, &"weapon.acceptance", &"player"))
		packet_heavy.receive_damage(DamagePacket.new(10.0, 0.0, 0.0, player, &"weapon.acceptance", &"player"))
		check(is_equal_approx(basic_health_before - packet_basic.health, 10.0), "DamagePacket applies full base damage to the unarmored Basic enemy")
		check(is_equal_approx(heavy_health_before - packet_heavy.health, 2.0), "the same DamagePacket resolves to two damage against Heavy armor")
	if player and interior_cover:
		var covered_basic := EnemySpawnService.spawn(
			ContentDB.get_enemy_definition(&"prototype_basic_enemy"),
			Transform3D(Basis.IDENTITY, interior_cover.global_position + Vector3(0.0, 0.0, -4.0)),
			battle.enemy_container
		)
		covered_basic.set_physics_process(false)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var covered_basic_health := covered_basic.health
		var covered_origin := interior_cover.global_position + Vector3(0.0, 1.0, 2.0)
		player._fire_hitscan(covered_origin, Vector3.FORWARD)
		check(is_equal_approx(covered_basic.health, covered_basic_health), "interior Cover blocks assault-rifle hitscan before Basic")
		var flank_origin := interior_cover.global_position + Vector3(-4.0, 1.0, 2.0)
		player._fire_hitscan(flank_origin, flank_origin.direction_to(covered_basic.global_position + Vector3.UP))
		check(is_equal_approx(covered_basic_health - covered_basic.health, 20.0), "changing angle around Cover makes the same rifle effective again")
		covered_basic.queue_free()
		await get_tree().process_frame
	if player and packet_heavy and destructible_barrier:
		player.global_position = destructible_barrier.global_position + Vector3(0.0, 0.0, 4.0)
		packet_heavy.process_mode = Node.PROCESS_MODE_INHERIT
		packet_heavy.set_physics_process(false)
		packet_heavy.global_position = destructible_barrier.global_position + Vector3(0.0, 0.0, -2.8)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var protected_heavy_health := packet_heavy.health
		var barrier_shot_origin := destructible_barrier.global_position + Vector3(0.0, 1.0, 4.0)
		player._fire_hitscan(barrier_shot_origin, Vector3.FORWARD)
		check(destructible_barrier.current_structure_health == 15.0 and packet_heavy.health == protected_heavy_health, "primary rifle damages the barrier while it shields Heavy")
		check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "battle switches from primary rifle to concrete secondary launcher")
		check(player.active_weapon_slot == LoadoutState.SLOT_WEAPON_SECONDARY and player.weapon_data.id == &"weapon.rocket_launcher_01", "secondary Definition becomes the active combat weapon")
		player.aim_direction = Vector3.FORWARD
		player.aim_world_point = destructible_barrier.global_position + Vector3(0.0, 1.0, -1.0)
		check(player.debug_fire_once(), "secondary launcher consumes its independent magazine")
		for _frame in 30:
			await get_tree().physics_frame
			if destructible_barrier.destroyed:
				break
		check(destructible_barrier.destroyed and destructible_barrier.collision_shape.disabled, "secondary launcher destroys the authored barrier and removes collision")
		check(packet_heavy.health < protected_heavy_health, "launcher explosion damages Heavy behind the Barrier through the shared area DamagePacket path")
		var heavy_health_after_rocket := packet_heavy.health
		check(player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY), "battle switches back to primary rifle")
		check(player.get_magazine_ammo() == 30 and battle.hud.active_weapon_label.text == "ACTIVE  PRIMARY", "primary magazine and HUD active slot survive switching")
		player._fire_hitscan(barrier_shot_origin, Vector3.FORWARD)
		check(is_equal_approx(heavy_health_after_rocket - packet_heavy.health, 12.0), "after breaching, rifle follow-up reaches Heavy and still resolves armor")
		expected_extracted_rocket_quantity = 4
		packet_heavy.process_mode = Node.PROCESS_MODE_DISABLED
	check(navigation != null and navigation.navigation_mesh != null, "urban arena provides Godot navigation")
	if navigation and navigation.navigation_mesh:
		var map_vertices := navigation.navigation_mesh.vertices
		var map_width := absf(map_vertices[0].x - map_vertices[map_vertices.size() - 1].x)
		check(map_vertices.size() >= 60 and map_width >= 50.0, "navigation covers the expanded multi-block district")
	check(battle.find_child("HighAngleCamera", true, false) != null, "battle uses a high-angle follow camera")
	var loot_spawn_points := battle.find_children("*", "LootSpawnPoint", true, false)
	check(loot_spawn_points.size() == 4 and loot_pickups.size() == 5, "battle rolls three standard points and one two-item high-value point exactly once")
	check(
		loot_pickups.size() >= 2
		and (loot_pickups[0] as LootPickup).item_instance.definition_id == &"ammo.556_standard"
		and (loot_pickups[1] as LootPickup).item_instance.definition_id == &"loot.salvage_core_01",
		"deterministic acceptance seed proves loot content comes from the table instead of fixed Salvage Cores"
	)
	check(extraction_point != null, "battle contains one authored extraction point")
	check(objective_terminal != null and objective_reach_zone != null, "battle contains authored interaction and reach objectives")
	if not enemies.is_empty():
		var humanoid_enemy := enemies[0] as EnemyController
		var door_body := authored_door.find_child("DoorBody", true, false) as StaticBody3D if authored_door else null
		check(door_body != null and (humanoid_enemy.collision_mask & door_body.collision_layer) != 0, "authored door collision blocks enemies through the shared world layer")
		var enemy_visual := humanoid_enemy.humanoid_visual
		check(enemy_visual != null, "enemy AI owns a decoupled humanoid character visual")
		if enemy_visual:
			check(enemy_visual.character_model != null and enemy_visual.character_model.name == "EnemyVRMModel", "enemy uses the complete VRM character model")
			check(enemy_visual.character_skeleton != null and enemy_visual.character_skeleton.get_bone_count() >= 90, "enemy uses a complete humanoid Skeleton3D")
			check(enemy_visual.retarget_modifier != null and enemy_visual.find_child("ForwardAxisRetarget", true, false) != null, "enemy locomotion uses retarget and forward-axis correction")
			check(enemy_visual.animation_tree != null and enemy_visual.animation_tree.active, "enemy locomotion runs through an active AnimationTree")
			check(enemy_visual.combat_rig != null and enemy_visual.combat_rig.has_weapon(), "enemy rifle is mounted through the shared combat rig")
			var enemy_aim_point := player.global_position + Vector3.UP * 1.05 if player else humanoid_enemy.global_position - humanoid_enemy.global_basis.z * 8.0
			enemy_visual.set_debug_locomotion(&"Run")
			var enemy_axis_alignment := 0.0
			var enemy_motion_samples := 0
			for frame_index in 36:
				enemy_visual.update_visual(enemy_aim_point, -humanoid_enemy.global_basis.z, 3.2, 1.0 / 60.0)
				await get_tree().process_frame
				if frame_index >= 12:
					var sample := enemy_visual.get_forward_axis_motion_alignment()
					if absf(sample) > 0.00001:
						enemy_axis_alignment += sample
						enemy_motion_samples += 1
			check(enemy_motion_samples >= 8 and enemy_axis_alignment < 0.0, "enemy feet use the proven +Z animation to -Z model forward-axis correction")
			var muzzle_to_aim := enemy_visual.get_muzzle_position().direction_to(enemy_aim_point)
			check(enemy_visual.get_muzzle_direction().dot(muzzle_to_aim) > 0.97, "enemy muzzle direction matches its combat aim ray")
			check(enemy_visual.combat_rig.get_hand_error(&"right") < 0.02, "enemy right hand follows the rifle primary grip")
			check(enemy_visual.combat_rig.get_hand_error(&"left") < 0.02, "enemy left hand follows the rifle support grip")
			enemy_visual.clear_debug_locomotion()
	if player:
		check(player.player_marker != null, "player has a cyan combat readability marker")
		check(player.acceleration >= 50.0 and player.deceleration > player.acceleration, "movement accelerates quickly and stops decisively")
		check(player.dodge_speed * player.dodge_duration >= 2.7 and player.dodge_cooldown <= 0.65, "dodge is short, agile, and quickly reusable")
		check(battle.camera.size <= 25.0, "camera framing keeps combatants readable")
		player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
		Input.action_press("move_forward")
		var forward_axis_alignment := 0.0
		var motion_samples := 0
		for frame_index in 36:
			await get_tree().physics_frame
			if frame_index >= 12:
				var sample := player.combat_rig.get_forward_axis_motion_alignment()
				if absf(sample) > 0.00001:
					forward_axis_alignment += sample
					motion_samples += 1
		Input.action_release("move_forward")
		check(motion_samples >= 8 and forward_axis_alignment < 0.0, "VRM foot motion mirrors the animation source's +Z forward onto model -Z")
		var ground_target := Vector3(player.global_position.x + 4.0, 0.0, player.global_position.z)
		var target_screen_position: Vector2 = battle.camera.unproject_position(ground_target)
		var resolved_aim_point := player._world_aim_point(battle.camera, target_screen_position)
		check(resolved_aim_point.distance_to(ground_target) < 0.2, "screen reticle ray resolves to the same ground point")
		player.aim_world_point = player.global_position + Vector3(4.0, 0.0, 0.0)
		var shot_direction := player._shot_direction_from(player.global_position + Vector3.UP * 1.25)
		check(shot_direction.y < -0.1, "mouse aim target preserves vertical direction toward the ground")
		var rocket: Variant = load("res://scenes/weapons/rocket_projectile.tscn").instantiate()
		battle.add_child(rocket)
		rocket.global_position = player.global_position + Vector3.UP * 1.25
		rocket.setup(player, Vector3(1.0, -0.7, 0.0), ContentDB.get_weapon(&"weapon.rocket_launcher_01"))
		for _frame in 20:
			await get_tree().physics_frame
		check(not is_instance_valid(rocket), "RPG collides with and explodes on the ground")
		var test_enemy := packet_basic if packet_basic else enemies[0] as EnemyController
		test_enemy.process_mode = Node.PROCESS_MODE_INHERIT
		test_enemy.set_physics_process(false)
		test_enemy.global_position = player.global_position + Vector3(0.0, 0.0, -6.0)
		await get_tree().physics_frame
		var enemy_screen_position: Vector2 = battle.camera.unproject_position(test_enemy.global_position + Vector3.UP)
		player.aim_world_point = player._world_aim_point(battle.camera, enemy_screen_position)
		var test_rocket_weapon := ContentDB.get_weapon(&"weapon.rocket_launcher_01").duplicate() as WeaponDefinition
		test_rocket_weapon.damage = 10.0
		player.equip_weapon(test_rocket_weapon)
		var enemy_health_before_rocket := test_enemy.health
		player.debug_fire_once()
		for _frame in 30:
			await get_tree().physics_frame
		check(test_enemy.health < enemy_health_before_rocket, "RPG fired at an enemy reticle point hits the enemy")
		var tracer_from := player.global_position + Vector3.UP
		var tracer_to := tracer_from + Vector3.RIGHT * 10.0
		var tracer := CombatEffects.tracer(battle, tracer_from, tracer_to, Color.WHITE)
		check(tracer.global_position.distance_to(tracer_from) < tracer.global_position.distance_to(tracer_to), "tracer starts at the shooter and travels toward the target")
		tracer.queue_free()
		var previous_health := player.health
		var enemy_source := packet_heavy if packet_heavy else packet_basic
		player.receive_damage(DamagePacket.new(10.0, 0.0, 0.0, enemy_source, &"enemy.prototype_rifle", &"enemy"))
		check(is_equal_approx(previous_health - player.health, 10.0), "player receives enemy attack context through DamagePacket")
	if not enemies.is_empty():
		var enemy := packet_basic if packet_basic else enemies[0] as EnemyController
		check(enemy.find_child("EnemyMarker", true, false) != null, "enemies have red combat readability markers")
		check(enemy.approach_speed >= 1.0 and enemy.approach_speed < enemy.movement_speed * 0.5, "distant enemies advance toward the player without immediately swarming")
		check(enemy.detection_range >= 24.0, "enemy activation range keeps nearby groups discoverable")
		var previous_enemy_health := enemy.health
		enemy.take_damage(5.0, Vector3.RIGHT)
		check(enemy.health < previous_enemy_health, "enemy receives damage and hit reaction")
		battle.ending = true
		enemy.take_damage(999.0, Vector3.UP * 2.0)
		await get_tree().process_frame
		check(battle.find_child("RagdollProxy", true, false) != null, "enemy death creates a physics ragdoll")
	battle.result_transition_enabled = false
	battle.ending = false
	var profile_before_pickup := profile.to_dict()
	if loot_pickups.size() >= 3:
		var capacity_loot := loot_pickups[2] as LootPickup
		var capacity_before := active_session.inventory.capacity
		active_session.inventory.capacity = active_session.inventory.get_used_capacity()
		var inventory_before_rejection := active_session.inventory.to_dict()
		check(capacity_loot.try_pickup(active_session) == LootPickup.PickupResult.CAPACITY_FULL, "generated loot over current carried capacity is rejected")
		check(not capacity_loot.consumed and active_session.inventory.to_dict() == inventory_before_rejection, "capacity rejection keeps generated pickup and inventory unchanged")
		active_session.inventory.capacity = capacity_before
		var ammo_loot := loot_pickups[0] as LootPickup
		generated_ammo_quantity = ammo_loot.item_instance.quantity
		var ammo_before_pickup := _total_quantity(active_session.inventory, &"ammo.556_standard")
		check(ammo_loot.try_pickup(active_session) == LootPickup.PickupResult.SUCCESS, "generated 5.56 ammunition enters active sortie inventory")
		check(_total_quantity(active_session.inventory, &"ammo.556_standard") == ammo_before_pickup + generated_ammo_quantity, "generated ammunition uses InventoryState stack rules")
		var loot := loot_pickups[1] as LootPickup
		extracted_loot_id = loot.item_instance.instance_id
		check(loot.try_pickup(active_session) == LootPickup.PickupResult.SUCCESS, "generated salvage enters active sortie inventory")
		check(active_session.inventory.contains(extracted_loot_id), "sortie inventory owns non-stackable generated loot")
		check(profile.to_dict() == profile_before_pickup, "pickup leaves persistent profile unchanged")
		await get_tree().process_frame
		expected_extracted_ammo_quantity += generated_ammo_quantity
	var high_value_spawn := battle.area_root.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	var high_value_pickups := high_value_spawn.find_children("*", "LootPickup", true, false) if high_value_spawn else []
	var enemies_before_alert: Array[Node] = battle.enemy_container.get_children()
	if player and objective_terminal:
		player.global_position = objective_terminal.global_position
		await get_tree().physics_frame
		await get_tree().physics_frame
		var terminal_response := player.interaction_component.interact_with_current()
		check(bool(terminal_response.get("success", false)), "player accesses the authored interior terminal")
		var interaction_objective := active_session.get_objective_state(&"interact_prototype_terminal")
		check(interaction_objective != null and interaction_objective.progress == 1, "terminal records its INTERACT objective before escalation")
	check(threat_event != null and threat_event.triggered, "the authored terminal binding triggers the local alert")
	var enemies_after_alert: Array[Node] = battle.enemy_container.get_children()
	var reinforcement_enemies: Array[Node] = []
	for candidate in enemies_after_alert:
		if not enemies_before_alert.has(candidate):
			reinforcement_enemies.append(candidate)
	check(active_session.threat_level == SortieSession.ThreatLevel.ALERT and battle.hud.threat_label.text == "THREAT  ALERT", "ThreatEvent raises Session and HUD to ALERT")
	check(threat_event.reinforcement_spawned and reinforcement_enemies.size() == 3, "one alert spawns exactly one authored reinforcement batch")
	check(_count_runtime_enemies(reinforcement_enemies, &"prototype_basic_enemy") == 2 and _count_runtime_enemies(reinforcement_enemies, &"prototype_heavy_enemy") == 1, "reinforcement batch contains two Basic and one Heavy")
	check(not bool(objective_terminal.interact(player, active_session).get("success", false)) and not threat_event.trigger() and battle.enemy_container.get_child_count() == 15, "repeated terminal or alert trigger never creates a second reinforcement batch")
	for reinforcement_node in reinforcement_enemies:
		var reinforcement := reinforcement_node as EnemyController
		reinforcement.process_mode = Node.PROCESS_MODE_DISABLED
		reinforcement.take_damage(reinforcement.health + reinforcement.armor + 1.0)
	await get_tree().process_frame
	var eliminate_after_reinforcement := active_session.get_objective_state(&"eliminate_prototype_enemies")
	check(eliminate_after_reinforcement != null and eliminate_after_reinforcement.progress == 3, "reinforcement deaths advance the existing ELIMINATE objective")
	check(high_value_pickups.size() == 2, "alert-side high-value spawn produces two Salvage Core pickups")
	high_value_loot_ids.clear()
	for pickup_node in high_value_pickups:
		var high_value_pickup := pickup_node as LootPickup
		high_value_loot_ids.append(high_value_pickup.item_instance.instance_id)
		check(high_value_pickup.try_pickup(active_session) == LootPickup.PickupResult.SUCCESS, "high-value alert loot enters carried inventory")
	check(profile.to_dict() == profile_before_pickup, "threat, reinforcements, and high-value loot leave Profile unchanged before extraction")
	if player and objective_reach_zone:
		check(objective_reach_zone.try_reach(player), "player entering authored zone completes REACH objective")
		check(not objective_reach_zone.try_reach(player), "authored reach zone cannot advance its completed objective twice")
		check(active_session.is_mission_completed(), "world objectives combine with reinforcement defeats to complete the Mission")
		check(battle.hud.objective_label.text.contains("ACCESS FIELD TERMINAL") and battle.hud.objective_label.text.contains("REACH SURVEY ZONE"), "Battle HUD reads and displays all ObjectiveState entries")
	check(not battle.ending and active_session.status == SortieSession.Status.ACTIVE, "mission completion and ALERT do not complete or lock the sortie")
	var objective := active_session.get_objective_state(&"eliminate_prototype_enemies")
	check(objective != null and objective.progress == 3 and active_session.is_mission_completed(), "authored reinforcement defeats satisfy the combat objective")
	check(battle.hud.objective_label.text.contains("COMPLETE"), "Battle HUD presents ObjectiveState completion")
	check(battle.hud.banner.text.contains("EXTRACT"), "mission completion directs the player toward extraction")
	if extraction_point:
		check(extraction_point.extract(active_session), "extraction point completes the active sortie")
		check(active_session.status == SortieSession.Status.COMPLETED and battle.ending, "successful extraction ends battle through session state")
	battle.queue_free()
	await get_tree().process_frame


func _test_enemy_character_debug() -> void:
	var debug_page := load("res://scenes/debug/enemy_character_debug.tscn").instantiate() as EnemyCharacterDebug
	add_child(debug_page)
	for _frame in 3:
		await get_tree().process_frame
	check(debug_page.humanoid_visual != null, "enemy debug page displays the shared humanoid visual")
	check(debug_page.find_child("DebugCamera", true, false) != null, "enemy debug page provides fixed character inspection views")
	check(debug_page.find_child("DirectionInfo", true, false) != null, "enemy debug page reports forward, movement, aim, and muzzle directions")
	debug_page._set_animation_view(&"Run")
	await get_tree().process_frame
	check(debug_page.humanoid_visual.get_locomotion_state() == &"Run", "enemy debug page previews run locomotion")
	debug_page._set_animation_view(&"Death / Ragdoll")
	await get_tree().physics_frame
	check(debug_page.find_child("RagdollProxy", true, false) != null, "enemy debug page previews the existing death ragdoll")
	debug_page.queue_free()
	await get_tree().process_frame


func _test_ragdoll() -> void:
	var ragdoll := load("res://scenes/player/ragdoll_proxy.tscn").instantiate() as RagdollProxy
	add_child(ragdoll)
	ragdoll.build(Color("dce8eb"), Vector3(2.0, 1.0, 0.0))
	await get_tree().process_frame
	var rigid_bodies := 0
	var joints := 0
	for child in ragdoll.get_children():
		if child is RigidBody3D:
			rigid_bodies += 1
		elif child is ConeTwistJoint3D:
			joints += 1
	check(rigid_bodies == 6 and joints == 5, "ragdoll has six simulated parts and five joints")
	ragdoll.queue_free()
	await get_tree().process_frame


func _test_result() -> void:
	var session := SortieRuntime.get_current_session()
	session.enemies_defeated = 10
	session.damage_taken = 42
	var result: Node = load("res://scenes/result/result.tscn").instantiate()
	add_child(result)
	await get_tree().process_frame
	var ui := result.find_child("ResultUI", true, false) as ResultUI
	check(ui != null, "result screen instantiates and reads mission state")
	check(ui != null and ui.status_label.text == "EXTRACTION SUCCESSFUL", "completed path reports extraction independently")
	check(ui != null and ui.mission_completion_label.text == "MISSION COMPLETE", "completed path reports mission completion independently")
	check(ui != null and ui.objective_labels.size() == 3 and ui.objective_labels[0].text.contains("3 / 3"), "completed Result reads all objective summaries from Outcome")
	check(ui != null and ui.objective_labels[1].text.contains("1 / 1") and ui.objective_labels[2].text.contains("1 / 1"), "completed Result preserves authored interaction and reach progress")
	check(result.finalize_sortie(acceptance_save_path) == OK, "result finalizes extraction through outcome commit and save")
	var profile := ProfileRuntime.get_profile()
	check(not extracted_loot_id.is_empty() and profile.inventory.contains(extracted_loot_id), "extracted loot reaches persistent profile only after finalize")
	check(profile.inventory.contains(explicit_ammo_id) and profile.inventory.get_item(explicit_ammo_id).quantity == expected_extracted_ammo_quantity, "remaining magazine ammunition materializes into the recovered warehouse stack")
	check(profile.inventory.contains(explicit_rocket_ammo_id) and profile.inventory.get_item(explicit_rocket_ammo_id).quantity == expected_extracted_rocket_quantity, "secondary reserve survives extraction without duplicate magazine ammunition")
	check(not uncarried_warehouse_id.is_empty() and profile.inventory.contains(uncarried_warehouse_id), "finalize preserves an uncarried warehouse item")
	for instance_id in high_value_loot_ids:
		check(profile.inventory.contains(instance_id), "finalize recovers high-value alert loot %s" % instance_id)
	check(profile.inventory.get_items().size() == warehouse_count_before + 3 and profile.validate(), "finalize merges standard and high-value loot into a valid warehouse")
	var restored := SaveService.load_profile(acceptance_save_path, false)
	check(restored != null and restored.inventory.contains(extracted_loot_id), "saved profile reload contains extracted loot")
	check(restored != null and restored.inventory.contains(uncarried_warehouse_id), "saved profile reload preserves uncarried warehouse items")
	check(restored != null and restored.inventory.contains(explicit_ammo_id), "saved profile reload preserves explicitly carried ammunition")
	check(restored != null and restored.inventory.contains(explicit_rocket_ammo_id), "saved profile reload preserves secondary ammunition")
	for instance_id in high_value_loot_ids:
		check(restored != null and restored.inventory.contains(instance_id), "saved profile reload preserves high-value alert loot %s" % instance_id)
	check(SortieRuntime.get_current_session() == null, "successful finalize clears the active sortie")
	result.queue_free()
	await get_tree().process_frame
	var hanger: Node = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	await get_tree().process_frame
	check(hanger.find_child("HangerUI", true, false) != null and profile.inventory.contains(extracted_loot_id), "return Hanger reads the profile containing extracted loot")
	var warehouse_summary := hanger.find_child("WarehouseSummary", true, false) as Label
	check(warehouse_summary != null and warehouse_summary.text.contains("Salvage Core") and warehouse_summary.text.contains("5.56 Standard"), "Hanger warehouse summary shows extracted generated salvage and ammunition")
	hanger.queue_free()
	await get_tree().process_frame


func _test_early_extraction() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var profile_before := _profile_business_state(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session != null and session.record_enemy_defeat(), "early-extraction path records one enemy defeat")
	if not session:
		return
	var objective := session.get_objective_state(&"eliminate_prototype_enemies")
	check(objective != null and objective.progress == 1 and not session.is_mission_completed(), "early-extraction objective remains one of three")
	var extraction := ExtractionPoint.new()
	check(extraction.extract(session), "mission-incomplete acceptance path may extract")
	extraction.free()
	check(session.status == SortieSession.Status.COMPLETED and not session.is_mission_completed(), "extraction completes Sortie without completing Mission")
	var result: Node = load("res://scenes/result/result.tscn").instantiate()
	add_child(result)
	await get_tree().process_frame
	var ui := result.find_child("ResultUI", true, false) as ResultUI
	check(ui != null and ui.status_label.text == "EXTRACTION SUCCESSFUL", "early Result still reports successful extraction")
	check(ui != null and ui.mission_completion_label.text == "MISSION INCOMPLETE", "early Result keeps mission incomplete")
	check(ui != null and ui.objective_labels.size() == 3 and ui.objective_labels[0].text.contains("1 / 3"), "early Result presents incomplete summaries for the three-objective mission")
	check(result.finalize_sortie(early_extraction_save_path) == OK, "early extraction still commits recovery and saves")
	check(_profile_business_state(profile) == profile_before, "early extraction preserves unchanged carried equipment in warehouse")
	var restored := SaveService.load_profile(early_extraction_save_path, false)
	check(restored != null and _profile_business_state(restored) == profile_before, "early extraction profile reloads successfully")
	check(SortieRuntime.get_current_session() == null, "early extraction finalize clears terminal session")
	result.queue_free()
	await get_tree().process_frame
	_cleanup_save(early_extraction_save_path)


func _test_failed_sortie() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var carried_ammo := _find_item_by_definition(profile.inventory, &"ammo.556_standard")
	check(carried_ammo != null, "failed-path profile owns standard ammunition")
	if not carried_ammo:
		return
	var profile_before := profile.to_dict()
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		[carried_ammo.instance_id]
	)
	var session := SortieRuntime.start_sortie(request, profile)
	check(session != null and session.status == SortieSession.Status.ACTIVE, "failed path starts an isolated active sortie")
	if not session:
		return
	check(session.record_enemy_defeat(), "failed path records objective progress before death")
	check(not session.is_mission_completed(), "partial failed-path objective remains incomplete")

	var battle: Node = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed = _find_loot_seed_for_prefix([&"loot.salvage_core_01"])
	add_child(battle)
	for _frame in 5:
		await get_tree().process_frame
	battle.result_transition_enabled = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var player := battle.find_child("Player", true, false) as PlayerController
	var loot_pickups := battle.find_children("*", "LootPickup", true, false)
	var extraction_point := battle.find_child("ExtractionPoint", true, false) as ExtractionPoint
	var objective_terminal := battle.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var threat_event := battle.find_child("LocalAlertEvent", true, false) as ThreatEvent
	var high_value_spawn := battle.find_child("HighValueLootSpawn", true, false) as LootSpawnPoint
	var high_value_pickups := high_value_spawn.find_children("*", "LootPickup", true, false) if high_value_spawn else []
	check(player != null and loot_pickups.size() >= 2 and high_value_pickups.size() == 2 and extraction_point != null and objective_terminal != null and threat_event != null, "failed-path battle exposes player, terminal, alert, high-value loot, and extraction")
	if not player or loot_pickups.size() < 2 or high_value_pickups.size() != 2 or not extraction_point or not objective_terminal or not threat_event:
		battle.queue_free()
		await get_tree().process_frame
		return

	for _shot in 5:
		check(player.debug_fire_once(), "failed-path runtime shot fires before death")
	check(player.reload_weapon(), "failed-path reload consumes sortie reserve before death")
	check(player.get_magazine_ammo() == 30 and player.get_reserve_ammo() == 115, "failed path has magazine and reserve runtime state")
	check(profile.to_dict() == profile_before, "failed-path fire and reload leave warehouse unchanged")
	var enemy_count_before_alert: int = battle.enemy_container.get_child_count()
	check(bool(objective_terminal.interact(player, session).get("success", false)), "failed path accesses the terminal before taking high-value loot")
	check(threat_event.triggered, "failed-path terminal interaction causes the authored alert")
	for enemy in battle.enemy_container.get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	check(session.threat_level == SortieSession.ThreatLevel.ALERT and battle.enemy_container.get_child_count() == enemy_count_before_alert + 3, "failed path receives exactly one authored reinforcement batch")

	var picked_loot := high_value_pickups[0] as LootPickup
	var blocked_loot := loot_pickups[1] as LootPickup
	var failed_loot_id := picked_loot.item_instance.instance_id
	check(picked_loot.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "failed path can pick up loot while active")
	check(session.inventory.contains(failed_loot_id), "failed-path loot exists only in carried inventory")
	check(profile.to_dict() == profile_before, "failed-path pickup leaves warehouse unchanged")

	player.take_damage(player.health + player.max_health)
	await get_tree().process_frame
	check(player.is_dead and battle.ending, "lethal player damage enters the failed battle presentation")
	check(session.status == SortieSession.Status.FAILED and session.threat_level == SortieSession.ThreatLevel.ALERT, "player death transitions the ALERT sortie to FAILED")
	check(not session.is_mission_completed(), "player death cannot mark mission complete")
	check(player.get_magazine_ammo() == 30 and player.get_reserve_ammo() == 115, "death does not materialize magazine ammunition")
	check(not player.debug_fire_once() and not player.reload_weapon(), "dead player cannot fire or reload")
	check(blocked_loot.try_pickup(session) == LootPickup.PickupResult.INVALID_SESSION, "failed sortie rejects further loot pickup")
	check(not extraction_point.extract(session), "failed sortie cannot extract")
	check(profile.to_dict() == profile_before, "death itself does not mutate the warehouse")

	battle.queue_free()
	await get_tree().process_frame
	var result: Node = load("res://scenes/result/result.tscn").instantiate()
	add_child(result)
	await get_tree().process_frame
	var ui := result.find_child("ResultUI", true, false) as ResultUI
	check(ui != null and ui.status_label.text == "SORTIE FAILED", "failed Result clearly reports sortie failure")
	check(ui != null and ui.recovery_label != null and ui.recovery_label.text == "RECOVERED: NOTHING", "failed Result reports that nothing was recovered")
	check(ui != null and ui.mission_completion_label.text == "MISSION INCOMPLETE", "failed Result reports mission incomplete")
	check(ui != null and ui.objective_labels.size() == 3 and ui.objective_labels[0].text.contains("1 / 3"), "failed Result preserves partial three-objective summary")
	check(result.finalize_sortie(failure_save_path) == OK, "failed Result finalizes through Outcome, no-op commit, and save")
	check(profile.to_dict() == profile_before, "failed Outcome commit preserves the exact pre-sortie warehouse")
	check(not profile.inventory.contains(failed_loot_id), "loot collected before death is absent from the warehouse")
	check(_has_unique_instance_ids(profile.inventory), "failed finalize leaves warehouse instance IDs unique")
	check(SortieRuntime.get_current_session() == null, "failed finalize clears the terminal sortie only after save")
	var restored := SaveService.load_profile(failure_save_path, false)
	check(restored != null and restored.to_dict() == profile_before, "failed-path save reload matches the pre-sortie profile")

	result.queue_free()
	await get_tree().process_frame
	var hanger: Node = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	await get_tree().process_frame
	var warehouse_summary := hanger.find_child("WarehouseSummary", true, false) as Label
	check(warehouse_summary != null and not warehouse_summary.text.contains("Salvage Core"), "return Hanger shows no loot recovered from the failed sortie")
	hanger.queue_free()
	await get_tree().process_frame
	_cleanup_save(failure_save_path)


func _cleanup_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _find_item_by_definition(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _count_enemy_spawn_definitions(spawn_points: Array[Node], definition_id: StringName) -> int:
	return spawn_points.filter(func(point: EnemySpawnPoint) -> bool: return point.enemy_definition_id == definition_id).size()


func _count_runtime_enemies(enemies: Array[Node], definition_id: StringName) -> int:
	return enemies.filter(func(enemy: EnemyController) -> bool: return enemy.definition_id == definition_id).size()


func _find_runtime_enemy(enemies: Array[Node], definition_id: StringName) -> EnemyController:
	for enemy in enemies:
		var runtime_enemy := enemy as EnemyController
		if runtime_enemy and runtime_enemy.definition_id == definition_id:
			return runtime_enemy
	return null


func _has_unique_instance_ids(inventory: InventoryState) -> bool:
	var seen: Dictionary = {}
	for item in inventory.get_items():
		if seen.has(item.instance_id):
			return false
		seen[item.instance_id] = true
	return true


func _find_loot_seed_for_prefix(definition_ids: Array[StringName]) -> int:
	var table := ContentDB.get_loot_table(&"prototype_basic_loot")
	for seed_value in range(1, 10001):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var matches := true
		for definition_id in definition_ids:
			var result := LootRollService.roll(table, rng)
			if result.size() != 1 or result[0].definition_id != definition_id:
				matches = false
				break
		if matches:
			return seed_value
	return 1


func _total_quantity(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func _profile_business_state(profile: ProfileState) -> Dictionary:
	var items_by_id: Dictionary = {}
	for item in profile.inventory.get_items():
		items_by_id[item.instance_id] = item.to_dict()
	return {
		"capacity": profile.inventory.capacity,
		"items_by_id": items_by_id,
		"loadout": profile.loadout.to_dict(),
	}


func _socket_contains(player: PlayerController, socket_name: StringName, equipment_id: StringName) -> bool:
	var socket := player.find_child(String(socket_name), true, false)
	if not socket:
		return false
	for child in socket.get_children():
		if child.get_meta("equipment_id", &"") == equipment_id:
			return true
	return false


func _animation_has_clean_lead_in(animation: Animation) -> bool:
	for track_index in animation.get_track_count():
		if animation.track_get_key_count(track_index) < 2:
			continue
		if animation.track_get_key_time(track_index, 0) > 0.001:
			return false
	return true


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
