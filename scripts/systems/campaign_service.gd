class_name CampaignService
extends RefCounted
## Small sequential contract chain. Claims share the warehouse's atomic save,
## and sortie progress is recorded only inside its idempotent outcome commit.
const QUESTS := [
	{"id": "routes", "title": "01 / ESTABLISH THE ROUTES", "detail": "Complete Streets Recon and extract twice. Only results returned to base count.", "kind": "recon", "target": 2, "inputs": {}, "credits": 300, "reward": "300 credits / next contract"},
	{"id": "clinic", "title": "02 / STOCK THE INFIRMARY", "detail": "Bring construction supplies home for a field clinic. Turning in consumes the listed warehouse materials.", "kind": "delivery", "target": 0, "inputs": {&"material.fabric": 4, &"material.parts": 2}, "credits": 200, "reward": "200 credits / field clinic: assemble medkits"},
	{"id": "workbench", "title": "03 / RESTORE THE AMMUNITION BENCH", "detail": "Restore precision tooling. Keep these materials instead of selling or bartering them.", "kind": "delivery", "target": 0, "inputs": {&"material.electronics": 3, &"material.wiring": 4}, "credits": 250, "reward": "250 credits / ammunition bench: press AP rounds"},
	{"id": "security", "title": "04 / SECURE THE SUPPLY LINE", "detail": "Defeat eight enemies across successful Streets extractions. A failed sortie gives no contract progress.", "kind": "kills", "target": 8, "inputs": {}, "credits": 500, "reward": "500 credits / trusted supplier: equipment prices -10%"},
	{"id": "bastion", "title": "05 / KEEP THE BASE RUNNING", "detail": "Complete and extract from three more Streets operations: records or relay repairs. Secure a sustainable foothold.", "kind": "operations", "target": 3, "inputs": {}, "credits": 800, "reward": "800 credits / Bastion established; free sorties remain available"},
]

static func valid_state(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY or raw.size() != 3: return false
	for key in ["version", "stage", "progress"]:
		var value: Variant = raw.get(key)
		if not SaveService.is_number(value) or value < 0 or floor(value) != value: return false
	if raw.version != 1 or raw.stage > QUESTS.size(): return false
	var limit: int = QUESTS[int(raw.stage)].target if raw.stage < QUESTS.size() else 0
	return raw.progress <= limit

static func current(profile: ProfileState) -> Dictionary:
	var stage := int(profile.campaign.stage)
	return QUESTS[stage] if stage < QUESTS.size() else {}

static func unlocked(profile: ProfileState, facility: String) -> bool:
	match facility:
		"clinic": return profile.campaign.stage >= 2
		"workbench": return profile.campaign.stage >= 3
		"supplier": return profile.campaign.stage >= 4
	return false

static func record_outcome(profile: ProfileState, outcome: SortieOutcome) -> void:
	if not profile.first_mission_completed or outcome.result_type != SortieOutcome.ResultType.COMPLETED or outcome.area_id != &"street_district": return
	var quest := current(profile)
	if quest.is_empty(): return
	var amount := 0
	if quest.kind == "recon" and outcome.mission_id == &"streets_recon" and outcome.mission_completed: amount = 1
	elif quest.kind == "operations" and outcome.mission_id in DeploymentPlan.STREET_MISSIONS and outcome.mission_completed: amount = 1
	elif quest.kind == "kills": amount = outcome.enemies_defeated
	profile.campaign.progress = mini(int(profile.campaign.progress) + amount, quest.target)

static func ready(profile: ProfileState) -> bool:
	var quest := current(profile)
	if not profile.first_mission_completed or quest.is_empty(): return false
	if profile.campaign.progress < quest.target: return false
	for id: StringName in quest.inputs:
		if SupplyService.count(profile, id) < quest.inputs[id]: return false
	return true

static func prepare_claim(profile: ProfileState, expected_id: String) -> Dictionary:
	if not profile or not profile.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid contract state."}
	var quest := current(profile)
	# An old/double-clicked button cannot claim the NEXT contract by accident.
	if quest.is_empty() or quest.id != expected_id: return {"error": ERR_UNAVAILABLE, "message": "This contract is no longer active."}
	if not ready(profile): return {"error": ERR_UNAVAILABLE, "message": "Complete the contract and bring the required materials home."}
	var candidate := ProfileState.from_dict(profile.to_dict())
	for id: StringName in quest.inputs:
		var remaining: int = quest.inputs[id]
		for item in candidate.inventory.get_items():
			if item.definition_id != id or remaining == 0: continue
			var used := mini(item.quantity, remaining)
			candidate.inventory.consume_item(item.instance_id, used)
			if not candidate.inventory.contains(item.instance_id): candidate.stash_layout.erase(item.instance_id)
			remaining -= used
	candidate.credits += quest.credits
	candidate.campaign.stage = int(candidate.campaign.stage) + 1
	candidate.campaign.progress = 0
	if not candidate.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid contract state."}
	return {"error": OK, "candidate": candidate, "message": "CONTRACT SAVED / REWARD AND UNLOCK RECEIVED"}

static func claim(expected_id: String, path := SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not ProfileRuntime.get_profile().sortie_checkpoint.is_empty():
		return {"error": ERR_BUSY, "message": "Contracts can only be turned in at base."}
	var profile := ProfileRuntime.get_profile()
	var result := prepare_claim(profile, expected_id)
	if result.error != OK: return result
	var error := SaveService.save_profile(result.candidate, path)
	if error != OK: return {"error": error, "message": "Could not save. Credits and items are unchanged."}
	profile.replace_with(result.candidate)
	return result
