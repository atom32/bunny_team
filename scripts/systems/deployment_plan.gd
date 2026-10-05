class_name DeploymentPlan
extends RefCounted
const STREET_MISSIONS := [&"streets_recon", &"streets_relay"]
static var selected_street_mission: StringName = &"streets_recon"

# Preview exact rounds; materialize partial stacks only inside deployment transaction.
var ammo_ids: Array[String] = []
var ammo_quantities: Dictionary = {} # Source stack ID -> exact quantity to carry.
var medical_ids: Array[String] = []
var weight := 0.0
var capacity := 0.0
var message := ""
var error := ""

static func build(profile: ProfileState) -> DeploymentPlan:
	var plan := DeploymentPlan.new()
	if not profile or not profile.validate():
		plan.error = "Profile is unavailable. Return to the menu to recover your save."
		return plan
	var carried_capacity := profile.get_carried_capacity()
	plan.capacity = carried_capacity
	var targets: Dictionary = {}
	for id in profile.loadout.get_equipped_instance_ids():
		var item := profile.inventory.get_item(id)
		var definition := ContentDB.get_item(item.definition_id)
		plan.weight += item.total_weight()
		if definition is WeaponDefinition:
			var ammo_id: StringName = definition.get_runtime_ammo_definition_id()
			targets[ammo_id] = int(targets.get(ammo_id, 0)) + definition.magazine_capacity * 3
	for ammo_id in targets:
		targets[ammo_id] = profile.ammo_pack.get(String(ammo_id), targets[ammo_id])
	if targets.is_empty():
		plan.error = "Equip at least one weapon before deployment."
	if plan.weight > carried_capacity:
		plan.error = "Equipment is overweight. Select a lighter loadout."
	var lines: Array[String] = []
	for ammo_id in targets:
		var count := 0
		var definition := ContentDB.get_ammo(ammo_id, false)
		if not definition:
			continue
		for item in profile.inventory.get_items():
			if item.definition_id != ammo_id or count >= targets[ammo_id]:
				continue
			var quantity := mini(item.quantity, int(targets[ammo_id])-count)
			if definition.weight > 0:
				quantity = mini(quantity, maxi(0, int(floor((carried_capacity-plan.weight+0.00001)/definition.weight))))
			if quantity <= 0: continue
			plan.ammo_ids.append(item.instance_id)
			plan.ammo_quantities[item.instance_id] = quantity
			plan.weight += definition.weight * quantity
			count += quantity
		lines.append(TranslationServer.translate("%s x%d%s") % [GameLanguage.item_name(definition.display_name), count, TranslationServer.translate(" (EMPTY)") if count == 0 else ""])
	for id in profile.medical_pack:
		var packed := 0
		var definition := ContentDB.get_item(StringName(id))
		for item in profile.inventory.get_items():
			if item.definition_id != StringName(id) or packed >= int(profile.medical_pack[id]): continue
			if plan.weight + definition.weight > carried_capacity: continue
			plan.medical_ids.append(item.instance_id)
			plan.weight += definition.weight
			packed += 1
		lines.append(TranslationServer.translate("%s x%d%s") % [GameLanguage.item_name(definition.display_name), packed, TranslationServer.translate(" (NOT PACKED)") if packed == 0 else ""])
	plan.message = TranslationServer.translate("SORTIE  %.1f / %.0f kg\n%s\nExtra warehouse ammunition stays at base.") % [plan.weight, carried_capacity, " / ".join(lines)]
	return plan

## Source IDs for legacy whole-stack fixtures, NOT an exact deployment request.
## Production callers must use prepare/deploy so partial stacks get distinct IDs.
func carried_ids() -> Array[String]:
	var ids := ammo_ids.duplicate()
	ids.append_array(medical_ids)
	return ids

static func set_medical_count(id: String, quantity: int, path := SaveService.DEFAULT_SAVE_PATH) -> Error:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or not profile.sortie_checkpoint.is_empty() or ProfileRuntime.recovery_required: return ERR_BUSY
	if not profile.medical_pack.has(id) or quantity < 0 or quantity > 4: return ERR_INVALID_PARAMETER
	var candidate := ProfileState.from_dict(profile.to_dict())
	candidate.medical_pack[id] = quantity
	var error := SaveService.save_profile(candidate, path)
	if error == OK: profile.medical_pack = candidate.medical_pack.duplicate()
	return error

static func valid_ammo_pack(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY or raw.size() > 32: return false
	for id in raw:
		if typeof(id) != TYPE_STRING or not ContentDB.get_ammo(StringName(id), false): return false
		var amount: Variant = raw[id]
		if not SaveService.is_number(amount) or amount < 0 or amount > 1000 or floor(amount) != amount: return false
	return true

static func set_ammo_count(id: String, quantity: int, path := SaveService.DEFAULT_SAVE_PATH) -> Error:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or not profile.sortie_checkpoint.is_empty() or ProfileRuntime.recovery_required: return ERR_BUSY
	if not valid_ammo_pack({id:quantity}): return ERR_INVALID_PARAMETER
	var candidate := ProfileState.from_dict(profile.to_dict())
	candidate.ammo_pack[id] = quantity
	var error := SaveService.save_profile(candidate,path)
	if error == OK: profile.ammo_pack = candidate.ammo_pack.duplicate()
	return error

static func default_ammo_counts(profile: ProfileState) -> Dictionary:
	var counts := {}
	for id in profile.loadout.get_equipped_instance_ids():
		var item := profile.inventory.get_item(id)
		var weapon := ContentDB.get_item(item.definition_id) as WeaponDefinition
		if weapon:
			var ammo := String(weapon.get_runtime_ammo_definition_id())
			counts[ammo] = int(counts.get(ammo,0)) + weapon.magazine_capacity*3
	return counts

static func prepare(profile: ProfileState, area: StringName, mission: StringName) -> Dictionary:
	var plan := build(profile)
	if not plan.error.is_empty(): return {"error":ERR_INVALID_DATA,"message":plan.error}
	var candidate := ProfileState.from_dict(profile.to_dict())
	var ids: Array[String] = plan.medical_ids.duplicate()
	for id in plan.ammo_quantities:
		var source := candidate.inventory.get_item(id)
		var amount: int = plan.ammo_quantities[id]
		if amount == source.quantity:
			ids.append(id)
		else:
			# Keep the original identity/warehouse placement for the base remainder.
			# The carried part receives its own ID: loss must not remove the remainder.
			var packed := ItemInstance.new(source.definition_id,amount,source.durability)
			source.quantity -= amount
			if not candidate.inventory.add_item_preserving_instance(packed): return {"error":ERR_INVALID_DATA,"message":"Could not split ammunition."}
			ids.append(packed.instance_id)
	var request := candidate.create_sortie_request(area,mission,ids)
	if not request: return {"error":ERR_INVALID_DATA,"message":"Invalid deployment request."}
	return {"error":OK,"candidate":candidate,"request":request}

static func deploy(profile: ProfileState, area: StringName, mission: StringName, path := SaveService.DEFAULT_SAVE_PATH, persist := true) -> Dictionary:
	if not profile or profile != ProfileRuntime.get_profile(): return {"error":ERR_INVALID_PARAMETER,"message":"Invalid deployment profile."}
	if SortieRuntime.get_current_session() or not profile.sortie_checkpoint.is_empty() or ProfileRuntime.recovery_required:
		return {"error":ERR_BUSY,"message":"Resume or finish the current sortie first."}
	var result := prepare(profile,area,mission)
	if result.error != OK: return result
	var session := SortieRuntime.start_sortie(result.request,result.candidate)
	if not session: return {"error":ERR_INVALID_DATA,"message":SortieRuntime.last_error}
	if persist:
		var error := SortieRuntime.begin_persistence(path,result.candidate)
		if error != OK:
			SortieRuntime.clear_session()
			return {"error":error,"message":"Deployment was not saved. Equipment and ammunition are unchanged."}
	else:
		profile.replace_with(result.candidate)
	return {"error":OK,"session":session}
