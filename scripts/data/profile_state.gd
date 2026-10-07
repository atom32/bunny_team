class_name ProfileState
extends RefCounted

const DEFAULT_WAREHOUSE_CAPACITY := 1000.0
const DEFAULT_CARRIED_CAPACITY := 100.0
const BASE_CARRIED_CAPACITY := 18.0
const DEFAULT_DEFINITIONS := {
	LoadoutState.SLOT_WEAPON_PRIMARY: &"weapon.assault_rifle_01",
	LoadoutState.SLOT_WEAPON_SECONDARY: &"weapon.smg_01",
	LoadoutState.SLOT_ARMOR: &"armor.recon_shell_01",
	LoadoutState.SLOT_BACKPACK: &"equipment.field_pack_01",
}
const DEFAULT_AMMO_QUANTITIES := {
	&"ammo.556_standard": 120,
	&"ammo.rocket_standard": 4,
	&"ammo.9mm_standard": 120,
	&"ammo.12g_buckshot": 24,
	&"ammo.762_standard": 30,
}

var inventory: InventoryState # Persistent warehouse inventory.
var bunny_selected := false
var first_mission_completed := false
var ar_damage_upgraded := false
var loadout: LoadoutState
var credits := 1500
var successful_sorties := 0
var failed_sorties := 0
var relief_claimed_after := 0
var settled_outcomes: Array[String] = []
# Same atomic envelope as the warehouse. A pending sortie locks base transactions.
var sortie_checkpoint: Dictionary = {}
var ammo_pack: Dictionary = {} # Missing caliber means three magazines, not free ammunition.
var medical_pack: Dictionary = {"medical.field_dressing": 2, "medical.medkit": 1}
var narrative_slice: Dictionary = NarrativeSlice.initial_state()
var campaign: Dictionary = {"version": 1, "stage": 0, "progress": 0}
# Presentation positions only; equipped gear remains owned by inventory.
var stash_layout: Dictionary = {}


func _init(p_inventory: InventoryState = null, p_loadout: LoadoutState = null) -> void:
	inventory = p_inventory
	loadout = p_loadout

func get_carried_capacity(gear: LoadoutState = null) -> float:
	if gear == null: gear = loadout
	var pack := inventory.get_item(gear.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)) if inventory and gear else null
	var definition := ContentDB.get_item(pack.definition_id, false) as EquipmentDefinition if pack else null
	return BASE_CARRIED_CAPACITY + (definition.carry_capacity_bonus if definition and definition.has_tag(&"backpack") else 0.0)


static func create_new() -> ProfileState:
	var profile := ProfileState.new(InventoryState.new(DEFAULT_WAREHOUSE_CAPACITY), LoadoutState.new())
	for definition_id in DEFAULT_DEFINITIONS.values():
		profile.inventory.add_item(ItemInstance.new(definition_id))
	for ammo_definition_id in [&"ammo.556_standard", &"ammo.9mm_standard"]:
		if not profile.inventory.add_item(ItemInstance.new(ammo_definition_id, DEFAULT_AMMO_QUANTITIES[ammo_definition_id])):
			push_error("Could not add default profile ammunition: %s" % ammo_definition_id)
	for slot_id in DEFAULT_DEFINITIONS:
		profile._equip_first_definition(slot_id, DEFAULT_DEFINITIONS[slot_id])
	if not profile.validate():
		push_error("New profile failed validation")
	return profile


func validate() -> bool:
	return inventory != null and loadout != null and inventory.validate() and loadout.validate(inventory) and credits >= 0 and credits <= 1000000000 and successful_sorties >= 0 and failed_sorties >= 0 and relief_claimed_after >= 0 and relief_claimed_after <= failed_sorties and _valid_medical_pack() and DeploymentPlan.valid_ammo_pack(ammo_pack) and NarrativeSlice.valid_state(narrative_slice) and (first_mission_completed or not narrative_slice.settled.Q01) and CampaignService.valid_state(campaign) and (first_mission_completed or (campaign.stage == 0 and campaign.progress == 0))


func _valid_medical_pack() -> bool:
	if medical_pack.size() != 2: return false
	for id in ["medical.field_dressing", "medical.medkit"]:
		var amount: Variant = medical_pack.get(id)
		if not SaveService.is_number(amount) or amount < 0 or amount > 4 or floor(amount) != amount: return false
	return true


func create_sortie_request(
	area_id: StringName = SortieRequest.PROTOTYPE_AREA_ID,
	mission_id: StringName = SortieRequest.PROTOTYPE_MISSION_ID,
	carried_item_instance_ids: Array[String] = []
) -> SortieRequest:
	if not validate() or area_id.is_empty() or mission_id.is_empty():
		return null
	var loadout_snapshot := LoadoutState.from_dict(loadout.to_dict())
	if not loadout_snapshot or not loadout_snapshot.validate(inventory):
		return null
	var request := SortieRequest.new(area_id, mission_id, loadout_snapshot)
	for instance_id in carried_item_instance_ids:
		if not request.add_carried_item(instance_id, inventory):
			return null
	return request if request.validate(inventory) else null


func to_dict() -> Dictionary:
	return {
		"inventory": inventory.to_dict(),
		"stash_layout": stash_layout.duplicate(true),
		"loadout": loadout.to_dict(),
		"bunny_selected": bunny_selected,
		"first_mission_completed": first_mission_completed,
		"ar_damage_upgraded": ar_damage_upgraded,
		"credits": credits,
		"successful_sorties": successful_sorties,
		"failed_sorties": failed_sorties,
		"relief_claimed_after": relief_claimed_after,
		"settled_outcomes": settled_outcomes.duplicate(),
		"sortie_checkpoint": sortie_checkpoint.duplicate(true),
		"medical_pack": medical_pack.duplicate(),
		"ammo_pack": ammo_pack.duplicate(),
		"campaign": campaign.duplicate(),
		"narrative_slice": narrative_slice.duplicate(true),
	}


static func from_dict(data: Dictionary) -> ProfileState:
	var inventory_data: Variant = data.get("inventory", null)
	var loadout_data: Variant = data.get("loadout", null)
	var restored_inventory: InventoryState = null
	var restored_loadout: LoadoutState = null
	if typeof(inventory_data) == TYPE_DICTIONARY:
		restored_inventory = InventoryState.from_dict(inventory_data)
	if typeof(loadout_data) == TYPE_DICTIONARY:
		restored_loadout = LoadoutState.from_dict(loadout_data)
	var profile := ProfileState.new(restored_inventory, restored_loadout)
	var slice_data: Variant = data.get("narrative_slice", NarrativeSlice.initial_state())
	profile.narrative_slice = NarrativeSlice.restore_state(slice_data)
	if profile.narrative_slice.is_empty(): return null
	var campaign_data: Variant = data.get("campaign", profile.campaign)
	if not CampaignService.valid_state(campaign_data): return null
	profile.campaign = {"version": int(campaign_data.version), "stage": int(campaign_data.stage), "progress": int(campaign_data.progress)}
	if typeof(data.get("sortie_checkpoint", {})) != TYPE_DICTIONARY: return null
	profile.sortie_checkpoint = data.get("sortie_checkpoint", {}).duplicate(true)
	var ammo_packed: Variant = data.get("ammo_pack", {})
	if not DeploymentPlan.valid_ammo_pack(ammo_packed): return null
	for id in ammo_packed: profile.ammo_pack[id] = int(ammo_packed[id])
	var packed: Variant = data.get("medical_pack", profile.medical_pack)
	if typeof(packed) != TYPE_DICTIONARY or packed.size() != 2: return null
	for id in profile.medical_pack:
		var amount: Variant = packed.get(id)
		if not SaveService.is_number(amount) or amount < 0 or amount > 4 or floor(amount) != amount: return null
		profile.medical_pack[id] = int(amount)
	for key in ["credits", "successful_sorties", "failed_sorties", "relief_claimed_after"]:
		var value: Variant = data.get(key, 1500 if key == "credits" else 0)
		if not SaveService.is_number(value) or value < 0 or value > 1000000000 or floor(value) != value:
			return null
		profile.set(key, int(value))
	var settled: Variant = data.get("settled_outcomes", [])
	if typeof(settled) != TYPE_ARRAY or settled.size() > 10000: return null
	for id in settled:
		if typeof(id) != TYPE_STRING or id.is_empty() or id.length() > 128 or id in profile.settled_outcomes: return null
		profile.settled_outcomes.append(id)
	# Old saves have no positions. Invalid presentation entries are repaired on opening.
	if typeof(data.get("stash_layout")) == TYPE_DICTIONARY:
		for instance_id in data["stash_layout"]:
			var entry: Variant = data["stash_layout"][instance_id]
			if typeof(entry) == TYPE_ARRAY and entry.size() == 3 and SaveService.is_number(entry[0]) and SaveService.is_number(entry[1]) and typeof(entry[2]) == TYPE_BOOL:
				profile.stash_layout[instance_id] = [int(entry[0]), int(entry[1]), entry[2]]
	for key in ["bunny_selected", "first_mission_completed", "ar_damage_upgraded"]:
		if typeof(data.get(key, false)) != TYPE_BOOL:
			return null
		profile.set(key, data.get(key, false))
	# Replace the previous one-off pack upgrade without charging recovered materials again.
	if not data.has("ar_damage_upgraded"):
		if typeof(data.get("field_pack_upgraded", false)) != TYPE_BOOL:
			return null
		profile.ar_damage_upgraded = data.get("field_pack_upgraded", false)
	return profile


func replace_with(candidate: ProfileState) -> void:
	# Keep the profile owner stable; publish an already validated/saved transaction.
	inventory = candidate.inventory
	loadout = candidate.loadout
	stash_layout = candidate.stash_layout.duplicate(true)
	bunny_selected = candidate.bunny_selected
	first_mission_completed = candidate.first_mission_completed
	ar_damage_upgraded = candidate.ar_damage_upgraded
	credits = candidate.credits
	successful_sorties = candidate.successful_sorties
	failed_sorties = candidate.failed_sorties
	relief_claimed_after = candidate.relief_claimed_after
	settled_outcomes = candidate.settled_outcomes.duplicate()
	sortie_checkpoint = candidate.sortie_checkpoint.duplicate(true)
	medical_pack = candidate.medical_pack.duplicate()
	ammo_pack = candidate.ammo_pack.duplicate()
	campaign = candidate.campaign.duplicate()
	narrative_slice = candidate.narrative_slice.duplicate(true)


func _equip_first_definition(slot_id: StringName, definition_id: StringName) -> void:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			if not loadout.equip(slot_id, item.instance_id, inventory):
				push_error("Could not equip default profile content ID: %s" % definition_id)
			return
	push_error("Default profile content ID is not owned: %s" % definition_id)
