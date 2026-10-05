class_name WeaponFitting
extends RefCounted
## Limited instance-owned workshop conversions, not shared WeaponDefinition edits.
## No new character/weapon meshes. A single utility slot forces a real tradeoff.
const OPTIONS := {
	"": {"name":"STANDARD", "weight":0.0, "reload":1.0, "noise":1.0, "credits":0, "inputs":{}},
	"quickloader": {"name":"QUICK RELOAD KIT", "weight":0.8, "reload":0.8, "noise":1.0, "credits":120, "inputs":{&"material.parts":2, &"material.wiring":1}},
	"suppressor": {"name":"SUPPRESSOR", "weight":0.35, "reload":1.15, "noise":0.5, "credits":180, "inputs":{&"material.parts":2, &"material.fabric":2}},
}

static func eligible(item: ItemInstance) -> bool:
	var definition := ContentDB.get_item(item.definition_id, false) as WeaponDefinition if item else null
	return definition != null and definition.action_type == &"hitscan" and definition.pellets_per_shot == 1 and item.quantity == 1

static func valid(item: ItemInstance) -> bool:
	return OPTIONS.has(item.fitting) and (item.fitting.is_empty() or eligible(item))

static func caption(id: String) -> String:
	return OPTIONS.get(id, OPTIONS[""]).name

static func _value(item: ItemInstance, key: String) -> float:
	return float(OPTIONS.get(item.fitting if item else "", OPTIONS[""])[key])

static func extra_weight(item: ItemInstance) -> float: return _value(item, "weight")
static func reload_factor(item: ItemInstance) -> float: return _value(item, "reload")
static func noise_factor(item: ItemInstance) -> float: return _value(item, "noise")

static func prepare(profile: ProfileState, instance_id: String, id: String) -> Dictionary:
	if not profile or not profile.validate() or not OPTIONS.has(id): return {"error":ERR_INVALID_PARAMETER,"message":"Invalid fitting."}
	if not CampaignService.unlocked(profile, "workbench"): return {"error":ERR_UNAVAILABLE,"message":"Restore the workbench first."}
	var item := profile.inventory.get_item(instance_id)
	if not eligible(item): return {"error":ERR_UNAVAILABLE,"message":"Fittings require a single-projectile hitscan firearm."}
	if item.fitting == id: return {"error":ERR_ALREADY_EXISTS,"message":"This fitting is already installed."}
	var spec: Dictionary = OPTIONS[id]
	if profile.credits < spec.credits: return {"error":ERR_UNAVAILABLE,"message":"Not enough credits."}
	for material: StringName in spec.inputs:
		if SupplyService.count(profile, material) < spec.inputs[material]: return {"error":ERR_UNAVAILABLE,"message":"Missing fitting materials."}
	var candidate := ProfileState.from_dict(profile.to_dict())
	candidate.inventory.get_item(instance_id).fitting = id
	candidate.credits -= spec.credits
	for material: StringName in spec.inputs:
		var remaining: int = spec.inputs[material]
		for stack in candidate.inventory.get_items():
			if stack.definition_id != material or remaining == 0: continue
			var used := mini(remaining, stack.quantity)
			candidate.inventory.consume_item(stack.instance_id, used)
			if not candidate.inventory.contains(stack.instance_id): candidate.stash_layout.erase(stack.instance_id)
			remaining -= used
	if not candidate.validate(): return {"error":ERR_INVALID_DATA,"message":"Fitting would exceed warehouse capacity."}
	return {"error":OK,"candidate":candidate,"message":"FITTING SAVED / Old fitting is not refunded."}

static func install(instance_id: String, id: String, path := SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not profile.sortie_checkpoint.is_empty():
		return {"error":ERR_BUSY,"message":"Fittings are only available at base."}
	var result := prepare(profile, instance_id, id)
	if result.error != OK: return result
	var error := SaveService.save_profile(result.candidate, path)
	if error != OK: return {"error":error,"message":"Could not save. Credits and items are unchanged."}
	profile.replace_with(result.candidate)
	return result
