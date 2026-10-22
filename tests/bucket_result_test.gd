extends "res://tests/waterworks_return_test.gd"
## Settlement/UI fixture, not a claim of physical combat. bucket_return_run earns it.

func wait_scene(path: String) -> bool:
	for tick in 1800:
		await get_tree().process_frame
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path==path and not GameState.is_transitioning():return true
	return false

func _run() -> void:
	get_tree().current_scene=null;GameState.presentation_enabled=true
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	var session:=_deploy("water_public")
	check(session.complete_extraction(),"settlement fixture actually closes the session")
	var before:=profile.to_dict();var credits:=profile.credits
	var result=load("res://scenes/result/result.tscn").instantiate();result.finalize_save_path="user://bucket_missing_directory/profile.json";get_tree().root.add_child(result);get_tree().current_scene=result
	await _frames()
	check(result.result_ui.bucket_button!=null and not result.result_ui.bucket_button.disabled,"valid delivered outcome offers optional return moment before settlement")
	await _click(result.result_ui.bucket_button)
	check(get_tree().current_scene==result and result.result_ui.return_error_label.visible and not result.result_ui.bucket_button.disabled,"failed save stays at debrief and permits retry")
	check(profile.to_dict()==before and profile.waterworks_memory.is_empty(),"failed optional transition publishes neither memory nor reward")
	result.finalize_save_path=PATH
	await _click(result.result_ui.bucket_button)
	check(await wait_scene("res://scenes/presentation/slice/bucket_return.tscn"),"successful atomic retry opens bucket scene")
	check(ProfileRuntime.get_profile().waterworks_memory=="water_public" and ProfileRuntime.get_profile().credits>credits and ProfileRuntime.get_profile().successful_sorties==1,"new scene opens only after durable memory, recovered cargo and one reward")
	var saved:=FileAccess.get_sha256(PATH)
	var room=get_tree().current_scene
	await _click(room.screen.find_child("SkipBucketMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/hideout.tscn") and FileAccess.get_sha256(PATH)==saved,"early skip keeps earned settlement byte-identical")
	var home=get_tree().current_scene
	await _click(home.find_child("OpenBucketMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/bucket_return.tscn"),"ordinary Rest replay remains available after early exit")
	room=get_tree().current_scene;await _click(room.screen.find_child("SkipBucketMoment",true,false));check(await wait_scene("res://scenes/presentation/slice/hideout.tscn") and FileAccess.get_sha256(PATH)==saved,"replay and second skip do not settle twice")
	# A prior memory must not make an unfinished sortie look delivered.
	session=_deploy();check(session.complete_extraction(),"unfinished safe retreat fixture")
	var ui:=ResultUI.new();ui.configure(SortieRuntime.get_outcome());get_tree().root.add_child(ui)
	check(ui.bucket_button==null,"incomplete retreat offers no new water-return scene even with a prior memory")
	ui.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("BUCKET_RESULT_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
