extends Node3D

class Target extends StaticBody3D:
	var packets: Array[DamagePacket] = []
	func receive_damage(packet: DamagePacket) -> float:
		packets.append(packet)
		return packet.base_damage

var failures: Array[String] = []

func _ready() -> void:
	_test_migration()
	await _test_trigger_modes()
	await _test_shotgun_and_sniper()
	await _test_reload_switching()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	for failure in failures:
		push_error(failure)
	print("MODERN_ARSENAL_TEST: " + ("PASS" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_migration() -> void:
	var profile := ProfileState.create_new()
	for item in profile.inventory.get_items():
		if item.definition_id in [&"weapon.pistol_01", &"weapon.shotgun_01", &"weapon.sniper_01", &"weapon.lmg_01", &"ammo.9mm_standard", &"ammo.12g_buckshot", &"ammo.762_standard"]:
			profile.inventory.remove_item(item.instance_id)
	var old_items := profile.inventory.get_items()
	var loadout_before := profile.loadout.to_dict()
	profile.inventory.capacity = profile.inventory.get_used_capacity()
	var path := "user://modern_arsenal_migration.json"
	check(SaveService.save_profile(profile, path) == OK and ProfileRuntime.load_profile(path), "existing save loads without regranting missing equipment")
	profile = ProfileRuntime.get_profile()
	check(profile.validate() and profile.loadout.to_dict() == loadout_before, "migration retains a valid existing loadout")
	for old in old_items:
		check(profile.inventory.get_item(old.instance_id).to_dict() == old.to_dict(), "migration preserves existing item IDs, quantities and durability")
	check(profile.inventory.get_items().size() == old_items.size(), "loading never grants missing weapons or ammunition")
	var once := profile.to_dict()
	check(SaveService.save_profile(profile, path) == OK and ProfileRuntime.load_profile(path), "updated save reloads")
	check(ProfileRuntime.get_profile().to_dict() == once, "repeated loading does not restore sold or lost items")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_trigger_modes() -> void:
	for id in [&"weapon.pistol_01", &"weapon.smg_01", &"weapon.assault_rifle_01", &"weapon.shotgun_01", &"weapon.sniper_01", &"weapon.lmg_01"]:
		var player := await _player(id)
		var before := player.get_magazine_ammo()
		var event := InputEventAction.new()
		event.action = &"fire"
		event.pressed = true
		Input.action_press(&"fire")
		player._unhandled_input(event)
		await get_tree().create_timer(.35).timeout
		Input.action_release(&"fire")
		var spent := before - player.get_magazine_ammo()
		check(spent == 1 if player.weapon_data.fire_mode == &"single" else spent >= 2, "%s respects held versus single trigger input" % id)
		AudioDirector.play_weapon(id)
		check(AudioDirector.last_cue != &"", "each firearm resolves a shot sound")
		player.queue_free()
		await get_tree().process_frame

func _test_shotgun_and_sniper() -> void:
	var target := Target.new()
	target.collision_layer = 2
	target.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12, 12, .5)
	shape.shape = box
	target.add_child(shape)
	add_child(target)
	target.position = Vector3(0, 1, -6)
	var player := await _player(&"weapon.shotgun_01")
	player.set_physics_process(false)
	player.aim_world_point = Vector3(0, 1.15, -10)
	await get_tree().physics_frame
	check(player.debug_fire_once(), "shotgun fires through the production raycast path")
	check(player.get_magazine_ammo() == 5 and target.packets.size() == 8, "one shell sends eight damage packets through physics")
	var hit_points: Array[Vector3] = []
	for packet in target.packets:
		hit_points.append(packet.hit_position)
	check(hit_points.size() > 1 and hit_points[0].distance_to(hit_points[-1]) > .2, "buckshot reaches different points across its cone")
	player.queue_free()
	await get_tree().process_frame
	target.packets.clear()
	target.position.z = -42
	player = await _player(&"weapon.sniper_01")
	player.set_physics_process(false)
	player.aim_world_point = Vector3(0, 1.15, -50)
	await get_tree().physics_frame
	check(player.debug_fire_once() and target.packets.size() == 1, "sniper hits targets beyond assault-rifle range")
	if not target.packets.is_empty():
		check(target.packets[0].armor_penetration >= 8, "sniper carries penetration through DamagePacket")
	check(player.weapon_data.aim_camera_extension > 0, "sniper enables the precision observation camera")
	var camera := Camera3D.new()
	add_child(camera)
	camera.size = 24.5
	var controller: Node3D = load("res://scripts/battle/battle.gd").new()
	controller.player = player
	controller.camera = camera
	Input.action_press(&"precision_walk")
	controller._process(1.0)
	check(camera.size > 38.0, "holding precision input extends the actual battle camera")
	Input.action_release(&"precision_walk")
	controller._process(1.0)
	check(absf(camera.size - controller.COMBAT_CAMERA_SIZE) < .1, "releasing precision input restores the normal camera")
	controller.free()
	camera.queue_free()
	player.queue_free()
	target.queue_free()
	await get_tree().process_frame

func _test_reload_switching() -> void:
	var player := await _player(&"weapon.lmg_01")
	check(player.get_magazine_capacity() == 80, "LMG exposes its larger magazine")
	check(player.debug_fire_once() and player.reload_weapon(), "LMG reload starts after firing")
	check(not player.debug_fire_once(), "reload prevents immediate firing")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY), "sidearm remains usable during primary reload")
	check(player.debug_fire_once(), "sidearm fires independently")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY), "return to reloading LMG")
	check(not player.debug_fire_once(), "weapon swapping cannot skip the LMG reload")
	await get_tree().create_timer(player.weapon_data.reload_seconds + .1).timeout
	check(player.debug_fire_once(), "LMG fires after its authored reload interval")
	player.queue_free()
	await get_tree().process_frame

func _player(id: StringName) -> PlayerController:
	var profile := ArmoryFixture.create_profile()
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, _find(profile, id).instance_id, profile.inventory)
	if id != &"weapon.pistol_01":
		profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, _find(profile, &"weapon.pistol_01").instance_id, profile.inventory)
	var ammo: Array[String] = []
	for item in profile.inventory.get_items():
		if ContentDB.get_item(item.definition_id).has_tag(&"ammo"):
			ammo.append(item.instance_id)
	var session := SortieSession.create_from_profile(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, ammo), profile)
	check(session != null and session.activate(), "modern fixture can deploy")
	var player := preload("res://scenes/player/player.tscn").instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	await get_tree().physics_frame
	await get_tree().physics_frame
	return player

func _find(profile: ProfileState, id: StringName) -> ItemInstance:
	for item in profile.inventory.get_items():
		if item.definition_id == id:
			return item
	return null

func check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
