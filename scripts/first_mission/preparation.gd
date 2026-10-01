class_name FirstMissionPreparation
extends RefCounted

static func has_starter_kit(profile: ProfileState) -> bool:
	var primary := profile.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, profile.inventory)
	var secondary := profile.loadout.get_item(LoadoutState.SLOT_WEAPON_SECONDARY, profile.inventory)
	return primary != null and secondary != null and primary.definition_id == &"weapon.assault_rifle_01" and secondary.definition_id == &"weapon.smg_01"

static func equip_starter_kit(profile: ProfileState) -> void:
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	profile._equip_first_definition(LoadoutState.SLOT_WEAPON_PRIMARY, &"weapon.assault_rifle_01")
	profile._equip_first_definition(LoadoutState.SLOT_WEAPON_SECONDARY, &"weapon.smg_01")

static func salvage_count(profile: ProfileState) -> int:
	var total := 0
	for item in profile.inventory.get_items():
		if item.definition_id == &"loot.salvage_core_01": total += item.quantity
	return total

static func upgrade_weapon(path: String = SaveService.DEFAULT_SAVE_PATH) -> Error:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or not profile.first_mission_completed or profile.ar_damage_upgraded or salvage_count(profile) < 1:
		return ERR_UNAVAILABLE
	var candidate := ProfileState.from_dict(profile.to_dict())
	for item in candidate.inventory.get_items():
		if item.definition_id == &"loot.salvage_core_01":
			candidate.inventory.consume_item(item.instance_id, 1)
			break
	candidate.ar_damage_upgraded = true
	var error := SaveService.save_profile(candidate, path)
	if error == OK:
		profile.inventory = candidate.inventory
		profile.ar_damage_upgraded = true
	return error
