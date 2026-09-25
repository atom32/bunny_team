extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_sortie_snapshot()
	_test_invalid_profile()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("SORTIE_SESSION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("SORTIE_SESSION_TEST: %s" % failure)
		print("SORTIE_SESSION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_sortie_snapshot() -> void:
	var profile := ProfileState.create_new()
	var profile_weapon := profile.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, profile.inventory)
	var profile_weapon_id := profile_weapon.instance_id
	var profile_loadout_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var profile_ammo := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "profile_ammo_001")
	profile.inventory.add_item(profile_ammo)
	var profile_before := profile.to_dict()

	var request := profile.create_sortie_request(&"prototype_arena", &"prototype_combat")
	check(request != null, "valid profile creates a SortieRequest")
	check(request != null and request.loadout != profile.loadout, "request owns an independent loadout selection snapshot")
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null, "valid request creates a SortieSession")
	if not session:
		return
	check(session.status == SortieSession.Status.PREPARING, "new session starts in PREPARING")
	check(session.area_id == &"prototype_arena" and session.mission_id == &"prototype_combat", "session keeps stable area and mission IDs")
	check(session.inventory != profile.inventory and session.loadout != profile.loadout, "session owns independent inventory and loadout objects")
	check(session.inventory.get_items().size() == profile.loadout.get_equipped_instance_ids().size(), "sortie inventory contains only equipped carried instances")
	check(not session.inventory.contains(profile_ammo.instance_id), "unloaded warehouse ammunition is not copied into the sortie")
	check(session.inventory.get_used_capacity() < profile.inventory.get_used_capacity(), "uncarried warehouse items do not consume sortie capacity")

	var session_weapon := session.inventory.get_item(profile_weapon_id)
	check(session_weapon != null and session_weapon != profile_weapon, "sortie item object is independent from profile item object")
	check(session_weapon != null and session_weapon.instance_id == profile_weapon.instance_id, "sortie snapshot preserves stable business item ID")
	check(session_weapon != null and ContentDB.get_weapon(session_weapon.definition_id, false) != null, "sortie item definition resolves through ContentDB")

	session_weapon.durability = 50.0
	var session_ammo := ItemInstance.new(&"ammo.556_ap", 12, 100.0, "sortie_ammo_001")
	check(session.inventory.add_item(session_ammo), "sortie can add a session-only item")
	session_ammo.quantity = 12
	check(profile_weapon.durability == 100.0, "sortie durability changes do not mutate profile")
	check(profile_ammo.quantity == 60, "sortie quantity changes do not mutate profile")
	var session_smg := ItemInstance.new(&"weapon.smg_01", 1, 100.0, "sortie_smg_001")
	check(session.inventory.add_item(session_smg), "sortie can own a recovered alternate weapon")
	check(session.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, session_smg.instance_id, session.inventory), "sortie loadout can select another owned snapshot instance")
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == profile_loadout_id, "sortie loadout changes do not mutate profile loadout")

	check(session.activate(), "PREPARING session activates")
	check(session.status == SortieSession.Status.ACTIVE, "session enters ACTIVE")
	check(session.complete(), "ACTIVE session completes")
	check(session.status == SortieSession.Status.COMPLETED, "session enters COMPLETED")
	check(profile.to_dict() == profile_before, "session creation, mutation, and status changes leave profile unchanged")


func _test_invalid_profile() -> void:
	var profile := ProfileState.create_new()
	var invalid_data := profile.to_dict()
	invalid_data["loadout"][String(LoadoutState.SLOT_WEAPON_PRIMARY)] = "item_999"
	var invalid_profile := ProfileState.from_dict(invalid_data)
	check(not invalid_profile.validate(), "test profile has a missing loadout instance")
	check(invalid_profile.create_sortie_request() == null, "invalid profile cannot create a SortieRequest")
	var invalid_loadout := LoadoutState.from_dict({String(LoadoutState.SLOT_WEAPON_PRIMARY): "item_999"})
	var invalid_request := SortieRequest.new(&"prototype_arena", &"prototype_combat", invalid_loadout)
	check(SortieSession.create_from_profile(invalid_request, profile) == null, "request with a missing item cannot create a SortieSession")
func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
