extends Node
var failures: Array[String]=[]
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func _ready() -> void:
	var profile:=ProfileState.create_new();profile.first_mission_completed=true
	profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits=["streets_exit_0","streets_exit_1"]
	profile.narrative_slice.settled.Q02=true;profile.narrative_slice.q02.delivered={"medical.field_dressing":2,"material.fabric":2};profile.narrative_slice.q02.message=NarrativeSlice.Q02_MESSAGE
	profile.narrative_slice.settled.Q04=true;profile.narrative_slice.q04={"receipt_id":NarrativeSlice.DELIVERY_RECEIPT,"observed_batch":NarrativeSlice.PHARMACY_BATCH,"log":NarrativeSlice.Q04_LOG}
	check(profile.validate(),"Retired logistics history remains valid")
	var old:=profile.to_dict();old.erase("campus_chapter")
	var file:=FileAccess.open("user://campus_migration.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":7,"profile":old}));file.close()
	var loaded:=SaveService.load_profile("user://campus_migration.json",false)
	check(loaded!=null and loaded.narrative_slice==profile.narrative_slice and not CampusChapter.started(loaded.campus_chapter),"Schema 7 preserves legacy facts/rewards without granting new recorder/relay milestones")
	check(SaveService.save_profile(loaded,"user://campus_migration_v8.json")==OK and SaveService.load_profile("user://campus_migration_v8.json",false).validate(),"Explicit schema 8 migration roundtrip")
	file=FileAccess.open("user://campus_migration_bad.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":8,"profile":old}));file.close()
	check(SaveService.load_profile("user://campus_migration_bad.json",false)==null,"Schema 8 cannot silently recreate missing chapter progress")
	for mutation in ["recorder_returned","branch_disconnected","power_returned","finished"]:
		var broken:=CampusChapter.initial_state();broken[mutation]=true
		check(not CampusChapter.valid_state(broken),"Out-of-order chapter milestone rejected: "+mutation)
	var request:=loaded.create_sortie_request(&"street_district",&"streets_recon")
	var session:=SortieSession.create_from_profile(request,loaded);session.activate()
	var data:=SortieCheckpoint.session_data(session);data.erase("campus")
	var restored:=SortieCheckpoint.restore_session(data)
	check(restored!=null and restored.campus.is_empty(),"Old session payload keeps old world contract, not new actors or quest credit")
	var facts:=CampusChapter.initial_facts(loaded,&"street_district")
	var incoherent:=facts.duplicate(true);incoherent.stage="supply";incoherent.relay_ready=true;incoherent.recorder_ready=true;incoherent.power_cut=true;incoherent.power_confirmed=true
	check(CampusChapter.valid_facts(incoherent,&"street_district") and not CampusChapter.matches_profile(incoherent,loaded,&"street_district"),"Structurally valid but unearned chapter stage rejected against profile")
	facts.recorder_revealed=true
	check(not CampusChapter.valid_facts(facts,&"street_district"),"Fabricated reveal without real recorder instance rejected")
	ProfileRuntime.new_profile().replace_with(loaded)
	var journal:={"version":6,"seed":1,"phase":"deployment","session":SortieCheckpoint.session_data(session),"world":{},"outcome":{}}
	var current:=ProfileRuntime.get_profile();current.sortie_checkpoint=journal.duplicate(true)
	current.sortie_checkpoint.session.erase("campus")
	check(SortieRuntime.resume_saved("user://campus_resume.json")==ERR_INVALID_DATA and SortieRuntime.get_current_session()==null,"V6 journal missing chapter contract fails before publishing runtime")
	current.sortie_checkpoint=journal.duplicate(true);current.sortie_checkpoint.session.campus=incoherent
	check(SortieRuntime.resume_saved("user://campus_resume.json")==ERR_INVALID_DATA and SortieRuntime.get_current_session()==null,"Unearned but structurally valid suspended stage cannot resume")
	current.sortie_checkpoint=journal.duplicate(true);current.sortie_checkpoint.version=5;current.sortie_checkpoint.session.erase("campus")
	check(SortieRuntime.resume_saved("user://campus_resume.json")==OK and SortieRuntime.get_current_session().campus.is_empty(),"V5 deployment really resumes with legacy world contract")
	SortieRuntime.clear_session();current.sortie_checkpoint={}
	# Explicit supply-stage fixture; never published to a player's save.
	var supply:=ProfileState.from_dict(loaded.to_dict())
	for key in ["relays_returned","recorder_revealed","recorder_returned","branch_disconnected","power_returned"]:supply.campus_chapter[key]=true
	for item in supply.inventory.get_items():
		if item.definition_id==&"ammo.556_standard":supply.inventory.remove_item(item.instance_id)
	var normal:=ItemInstance.new(&"ammo.556_standard",20);supply.inventory.add_item(normal)
	var ap:=ItemInstance.new(&"ammo.556_ap",60);supply.inventory.add_item(ap)
	var damaged:=ItemInstance.new(&"armor.recon_shell_01");damaged.durability=49;supply.inventory.add_item(damaged)
	var partial:=CampusChapter.prepare_delivery(supply)
	check(partial.error==OK and partial.candidate.campus_chapter.delivered_ammo==20 and not partial.candidate.campus_chapter.delivered_armor,"Partial standard-ammo delivery excludes worn armor and spare below 50 durability")
	check(partial.candidate.inventory.contains(ap.instance_id) and partial.candidate.inventory.contains(damaged.instance_id),"AP ammunition and invalid spare are never consumed")
	check(CampusChapter.prepare_delivery(partial.candidate).error!=OK,"No double-spend when only AP, damaged spare and worn armor remain")
	var heavy:=ItemInstance.new(&"armor.bulwark_plate_01");heavy.durability=50;partial.candidate.inventory.add_item(heavy)
	var armor:=CampusChapter.prepare_delivery(partial.candidate)
	check(armor.error==OK and armor.candidate.campus_chapter.delivered_armor and armor.candidate.campus_chapter.delivered_ammo==20 and not armor.candidate.inventory.contains(heavy.instance_id),"Bulwark at minimum durability accepted without inventing missing 40 rounds")
	check(CampusChapter.RELAY_REWARD+CampusChapter.RECORDER_REWARD+CampusChapter.POWER_REWARD+CampusChapter.FINAL_REWARD < 900+60*3,"Single-use chapter reward budget cannot buy-deliver normal armor/ammunition for profit")
	AudioDirector.shutdown_for_test()
	print("CAMPUS_MIGRATION_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
