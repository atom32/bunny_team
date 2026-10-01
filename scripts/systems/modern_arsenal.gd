class_name ModernArsenal
extends RefCounted
## Content migration only. Existing item identities and schema-1 saves stay valid.
const WEAPON_IDS: Array[StringName] = [
	&"weapon.pistol_01", &"weapon.smg_01", &"weapon.assault_rifle_01",
	&"weapon.shotgun_01", &"weapon.sniper_01", &"weapon.lmg_01",
	&"weapon.rocket_launcher_01",
]


static func upgrade_profile(profile: ProfileState) -> void:
	var owned: Dictionary = {}
	for item in profile.inventory.get_items():
		owned[item.definition_id] = item
	var grants: Array[ItemInstance] = []
	var new_calibers: Dictionary = {}
	for weapon_id in WEAPON_IDS:
		if owned.has(weapon_id):
			continue
		var weapon := ContentDB.get_weapon(weapon_id)
		var item := ItemInstance.new(weapon_id)
		grants.append(item)
		owned[weapon_id] = item
		new_calibers[weapon.get_runtime_ammo_definition_id()] = true
	for ammo_id in new_calibers:
		if not owned.has(ammo_id):
			grants.append(ItemInstance.new(ammo_id, ProfileState.DEFAULT_AMMO_QUANTITIES.get(ammo_id, 30)))
	# A full old warehouse must not lose items or prevent this one-time content grant.
	var grant_weight := 0.0
	for item in grants:
		grant_weight += ContentDB.get_item(item.definition_id).weight * item.quantity
	profile.inventory.capacity = maxf(profile.inventory.capacity, profile.inventory.get_used_capacity() + grant_weight)
	for item in grants:
		profile.inventory.add_item(item)
