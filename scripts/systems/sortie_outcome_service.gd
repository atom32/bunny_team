class_name SortieOutcomeService
extends RefCounted


static func create_outcome(session: SortieSession) -> SortieOutcome:
	return SortieOutcome.create_from_session(session)


static func commit_outcome(profile: ProfileState, outcome: SortieOutcome) -> Error:
	if not profile or not profile.validate() or not outcome or not outcome.validate():
		return ERR_INVALID_DATA
	match outcome.result_type:
		SortieOutcome.ResultType.COMPLETED:
			var inventory_snapshot := InventoryState.from_dict(profile.inventory.to_dict())
			var loadout_snapshot := LoadoutState.from_dict(outcome.loadout.to_dict())
			if (
				not inventory_snapshot
				or not loadout_snapshot
			):
				return ERR_INVALID_DATA
			for carried_instance_id in outcome.initial_carried_instance_ids:
				inventory_snapshot.remove_item(carried_instance_id)
			for recovered_item in outcome.inventory.get_items():
				inventory_snapshot.remove_item(recovered_item.instance_id)
				var recovered_snapshot := ItemInstance.from_dict(recovered_item.to_dict())
				if not recovered_snapshot or not inventory_snapshot.add_item_preserving_instance(recovered_snapshot):
					return ERR_INVALID_DATA
			var committed_profile := ProfileState.new(inventory_snapshot, loadout_snapshot)
			if not committed_profile.validate():
				return ERR_INVALID_DATA
			profile.inventory = committed_profile.inventory
			profile.loadout = committed_profile.loadout
			return OK
		SortieOutcome.ResultType.FAILED, SortieOutcome.ResultType.ABANDONED:
			# Carried state was an isolated snapshot, so no recovery means no warehouse mutation.
			return OK
	return ERR_INVALID_DATA
