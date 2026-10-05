class_name ArmoryFixture
extends RefCounted
## Explicit test inventory, never a production new-profile or load-time grant.
static func grant(profile: ProfileState, rocket_secondary := true) -> ProfileState:
	var ids: Array[StringName] = ModernArsenal.WEAPON_IDS.duplicate()
	ids.append_array([&"armor.recon_shell_01", &"armor.bulwark_plate_01", &"equipment.field_pack_01", &"equipment.thruster_pack_01"])
	for id in ids:
		if SupplyService.count(profile, id) == 0: profile.inventory.add_item(ItemInstance.new(id))
	for id in ProfileState.DEFAULT_AMMO_QUANTITIES:
		if SupplyService.count(profile, id) == 0: profile.inventory.add_item(ItemInstance.new(id, ProfileState.DEFAULT_AMMO_QUANTITIES[id]))
	if rocket_secondary:
		profile._equip_first_definition(LoadoutState.SLOT_WEAPON_SECONDARY, &"weapon.rocket_launcher_01")
	return profile

static func create_profile() -> ProfileState:
	return grant(ProfileState.create_new())

static func loss_matches(profile: ProfileState, before: Dictionary, carried: Array[String]) -> bool:
	var expected := ProfileState.from_dict(before)
	for id in carried:
		expected.inventory.remove_item(id)
		expected.stash_layout.erase(id)
		for slot in LoadoutState.SLOT_IDS:
			if expected.loadout.get_equipped_instance_id(slot) == id: expected.loadout.unequip(slot)
	return profile.inventory.to_dict() == expected.inventory.to_dict() and profile.loadout.to_dict() == expected.loadout.to_dict() and profile.credits == expected.credits and profile.failed_sorties == expected.failed_sorties + 1 and profile.bunny_selected == expected.bunny_selected and profile.ar_damage_upgraded == expected.ar_damage_upgraded and profile.first_mission_completed == expected.first_mission_completed
