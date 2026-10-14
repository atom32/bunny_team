extends Node
const PATH := "user://q04_slice_test.json"
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("CHECK FAILED: " + message)
func _ready() -> void:
	await get_tree().process_frame
	for completed in [false, true]:
		var profile := ProfileState.create_new()
		profile.first_mission_completed = true
		var old := NarrativeSlice.initial_state()
		old.version = 3
		old.settled.Q01 = true; old.q01_exits = ["streets_exit_0", "streets_exit_1"]
		old.settled.Q02 = true; old.q02.observed_batch = NarrativeSlice.PHARMACY_BATCH
		old.q02.delivered = {"medical.field_dressing": 2, "material.fabric": 2}; old.q02.message = NarrativeSlice.Q02_MESSAGE
		old.q04.receipt_id = NarrativeSlice.DELIVERY_RECEIPT
		if completed:
			old.q04.observed_batch = NarrativeSlice.PHARMACY_BATCH
			old.settled.Q04 = true; old.q04.log = NarrativeSlice.Q04_LOG
		profile.narrative_slice = old
		profile.credits = 4321
		var inventory := profile.inventory.to_dict()
		check(profile.validate(), "legacy partial/complete Q04 valid before migration")
		check(SaveService.save_profile(profile, PATH) == OK, "legacy save can be read and rotated")
		var migrated := SaveService.load_profile(PATH, false)
		check(migrated != null and migrated.narrative_slice.version == 4, "validated legacy story migrates to v4")
		check(migrated.inventory.to_dict() == inventory and migrated.credits == 4321 and migrated.narrative_slice.q04 == old.q04 and migrated.narrative_slice.settled == old.settled, "migration preserves possessions, rewards and historical facts")
		check(not migrated.narrative_slice.settled.Q03 and not migrated.narrative_slice.settled.Q05 and not migrated.narrative_slice.settled.Q06, "legacy evidence never grants new story progress")
		check(NarrativeSlice.prepare_q04_submission(migrated).error == ERR_UNAVAILABLE, "legacy submission permanently retired")
		check(SaveService.save_profile(migrated, PATH) == OK and SaveService.load_profile(PATH, false).to_dict() == migrated.to_dict(), "migration is idempotent on disk")
		var bad := old.duplicate(true); bad.q04.log = "forged"
		check(NarrativeSlice.restore_state(bad).is_empty(), "malformed old evidence not laundered by migration")
	var bad := NarrativeSlice.initial_state()
	bad.q02.delivered["medical.field_dressing"] = 1
	check(not NarrativeSlice.valid_state(bad), "cannot pre-deliver before Q01")
	bad = NarrativeSlice.initial_state(); bad.version = 999
	check(NarrativeSlice.restore_state(bad).is_empty(), "unknown story version rejected")
	AudioDirector.shutdown_for_test()
	print("Q04_SLICE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)
