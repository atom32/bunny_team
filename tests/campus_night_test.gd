extends Node
const PATH := "user://campus_night_test.json"
var failures: Array[String] = []
var battle: Node3D
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	ProfileRuntime._profile=ArmoryFixture.create_profile()
	var profile := ProfileRuntime.get_profile()
	profile.first_mission_completed=true
	var hideout=load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hideout);hideout.show_section("Operations")
	var selector := hideout.screen.find_child("LightingChoice",true,false) as OptionButton
	check(selector != null and selector.item_count == 2, "Operations exposes playable day/night choice")
	selector.item_selected.emit(1)
	check(DeploymentPlan.selected_lighting_variant == "night", "UI selection updates deployment variant")
	hideout.free()
	DeploymentPlan.selected_lighting_variant="night"
	var prepared := DeploymentPlan.prepare(profile,&"street_district",&"streets_recon")
	check(prepared.error == OK and prepared.request.lighting_variant == "night", "UI deployment plan carries night")
	var session := SortieRuntime.start_sortie(prepared.request, prepared.candidate)
	check(session != null and session.lighting_variant == "night", "Request becomes night Session")
	check(SortieRuntime.begin_persistence(PATH, prepared.candidate) == OK, "Night deployment saved")
	SortieRuntime.layout_seed=907
	battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled=false
	add_child(battle)
	await get_tree().process_frame
	get_tree().paused=true
	check(battle.area_root.get_meta("lighting") == "night", "Actual battle loads night")
	check(battle.area_root.find_children("AftermathDecal*","MeshInstance3D",true,false).size() == 5, "Five fixed alpha decals are in actual scene")
	check(battle.area_root.find_children("*","OmniLight3D",true,false).size() > 25, "Outdoor practical lighting active")
	check(SortieRuntime.save_checkpoint() == OK, "Night world saved")
	var durable := profile.sortie_checkpoint.duplicate(true)
	check(SortieCheckpoint.validate_world(durable.world, battle), "Matching night world valid")
	var corrupt: Dictionary=durable.world.duplicate(true)
	corrupt.lighting="day"
	check(not SortieCheckpoint.validate_world(corrupt,battle), "Mismatched world lighting rejected")
	corrupt.erase("lighting")
	check(not SortieCheckpoint.validate_world(corrupt,battle), "Missing lighting cannot restore night as day")
	corrupt=durable.session.duplicate(true)
	corrupt.lighting="dusk"
	check(SortieCheckpoint.restore_session(corrupt) == null, "Unknown lighting rejected")
	corrupt=durable.session.duplicate(true)
	corrupt.erase("lighting")
	check(SortieCheckpoint.restore_session(corrupt).lighting_variant == "day", "Legacy Session defaults day")
	battle.free();SortieRuntime.clear_session()
	var mismatched := durable.duplicate(true)
	mismatched.world.lighting="day"
	profile.sortie_checkpoint=mismatched
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA and SortieRuntime.get_current_session() == null, "Mismatch rejected before publishing Session")
	mismatched=durable.duplicate(true)
	mismatched.session.erase("lighting");mismatched.world.erase("lighting")
	profile.sortie_checkpoint=mismatched
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA, "Version 5 cannot erase both lighting fields")
	mismatched.version=4
	profile.sortie_checkpoint=mismatched
	check(SortieRuntime.resume_saved(PATH) == OK and SortieRuntime.get_current_session().lighting_variant == "day", "Legacy v4 checkpoint resumes as day")
	SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH), "Durable night Profile loads")
	check(SortieRuntime.resume_saved(PATH) == OK, "Night Session resumes")
	check(SortieRuntime.get_current_session().lighting_variant == "night", "Night survives disk roundtrip")
	get_tree().paused=false
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	await get_tree().process_frame
	get_tree().paused=true
	check(battle.area_root.get_meta("lighting") == "night" and SortieRuntime.resumed_world.is_empty(), "Night world actually restored")
	battle.free();SortieRuntime.clear_session();get_tree().paused=false
	var request := profile.create_sortie_request(&"first_mission_area",&"first_mission")
	request.lighting_variant="night"
	check(not request.validate(profile.inventory), "Tutorial cannot accidentally select night")
	DeploymentPlan.selected_lighting_variant="day"
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	print("CAMPUS_NIGHT_TEST ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
