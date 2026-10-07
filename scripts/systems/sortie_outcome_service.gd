class_name SortieOutcomeService
extends RefCounted


static func create_outcome(session: SortieSession) -> SortieOutcome:
	return SortieOutcome.create_from_session(session)


static func credit_reward(outcome: SortieOutcome, profile: ProfileState) -> int:
	if outcome.result_type != SortieOutcome.ResultType.COMPLETED: return 0
	if outcome.mission_completed: return 600 if outcome.mission_id == &"first_mission" else 450
	return 100 if not recovered_quantities(outcome,profile).is_empty() else 0


static func recovered_quantities(outcome: SortieOutcome, profile: ProfileState) -> Dictionary:
	# Recovered magazine rounds may receive new instance IDs. Compare quantities,
	# not ID novelty, against the exact deployed warehouse snapshots.
	var carried := {}
	for id in outcome.initial_carried_instance_ids:
		var item := profile.inventory.get_item(id)
		if item: carried[item.definition_id] = int(carried.get(item.definition_id,0)) + item.quantity
	var recovered := {}
	for item in outcome.inventory.get_items():
		recovered[item.definition_id] = int(recovered.get(item.definition_id,0)) + item.quantity
	var net := {}
	for id in recovered:
		var amount := int(recovered[id]) - int(carried.get(id,0))
		if amount > 0: net[id] = amount
	return net


static func commit_outcome(profile: ProfileState, outcome: SortieOutcome) -> Error:
	if not profile or not profile.validate() or not outcome or not outcome.validate():
		return ERR_INVALID_DATA
	if outcome.outcome_id in profile.settled_outcomes: return OK
	var candidate := ProfileState.from_dict(profile.to_dict())
	# All deployed instances are at risk. Warehouse-only instances never leave home.
	for carried_id in outcome.initial_carried_instance_ids:
		candidate.inventory.remove_item(carried_id)
		candidate.stash_layout.erase(carried_id)
		for slot in LoadoutState.SLOT_IDS:
			if candidate.loadout.get_equipped_instance_id(slot) == carried_id:
				candidate.loadout.unequip(slot)
	if outcome.result_type == SortieOutcome.ResultType.COMPLETED:
		for recovered_item in outcome.inventory.get_items():
			# Never overwrite an unrelated owned ID; repeated commits exit above.
			if candidate.inventory.contains(recovered_item.instance_id): return ERR_INVALID_DATA
			candidate.inventory.capacity = maxf(candidate.inventory.capacity, candidate.inventory.current_weight + recovered_item.total_weight())
			if not candidate.inventory.add_item_preserving_instance(ItemInstance.from_dict(recovered_item.to_dict())):
				return ERR_INVALID_DATA
		candidate.loadout = LoadoutState.from_dict(outcome.loadout.to_dict())
		candidate.credits += credit_reward(outcome, profile)
		candidate.successful_sorties += 1
	else:
		candidate.failed_sorties += 1
	CampaignService.record_outcome(candidate, outcome)
	NarrativeSlice.record_outcome(candidate, outcome)
	candidate.settled_outcomes.append(outcome.outcome_id)
	if not candidate.validate(): return ERR_INVALID_DATA
	profile.replace_with(candidate)
	return OK
