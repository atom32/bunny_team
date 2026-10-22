extends "res://tests/bucket_result_test.gd"
## Explicit settlement fixture. rescue_return_run earns the real rescue separately.
const RESCUE_PATH:="user://rescue_result_test.json"

func capture_replay_layout() -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("rescue_and_bucket_replay_layout.png"))==OK,"actual replay layout screenshot saved")

func check_replay_layout(home: Node) -> void:
	for name in ["OpenRescueMoment","OpenBucketMoment"]:
		var button:=home.find_child(name,true,false) as Button
		if not button:continue
		var rect:=button.get_global_rect()
		check(button.is_visible_in_tree() and rect.end.y<=632,"replay stays above the bottom navigation panel: "+name)
		for key in ["Overview","Hanger","Operations","Workshop","Rest"]:
			check(not rect.intersects(home.find_child("Nav"+key,true,false).get_global_rect()),"replay never shares a mouse target with navigation: "+name+" / "+key)
		var font:=button.get_theme_font("font")
		check(font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x<=button.size.x-16,"localized replay text fits the actual clickable width: "+name)
	var door:=home.find_child("OpenRescueMoment",true,false) as Button
	var bucket:=home.find_child("OpenBucketMoment",true,false) as Button
	if door and bucket:check(not door.get_global_rect().intersects(bucket.get_global_rect()),"both unlocked replays have separate hit areas")

func _run() -> void:
	get_tree().current_scene=null;GameState.presentation_enabled=true;SortieRuntime.clear_session()
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var owner=load("res://tests/maintenance_test.gd").new();var profile: ProfileState=owner.fixture();owner.free()
	check(DeploymentPlan.deploy(profile,MaintenanceStory.AREA,MaintenanceStory.MISSION,RESCUE_PATH).error==OK,"explicit result fixture deploys rescue")
	var session:=SortieRuntime.get_current_session()
	for id in MaintenanceStory.ORDER:
		if id==&"maintenance_gate":session.maintenance.steam_off=true
		check(session.record_objective_interaction(id),"controlled objective fixture: "+String(id))
	check(session.complete_extraction(),"result fixture really closes active session")
	var before:=profile.to_dict();var credits:=profile.credits
	var result=load("res://scenes/result/result.tscn").instantiate();result.finalize_save_path="user://rescue_missing_directory/profile.json";get_tree().root.add_child(result);get_tree().current_scene=result
	check(result.result_ui.rescue_button!=null and result.result_ui.bucket_button==null,"only safely completed rescue offers its optional door scene")
	await _click(result.result_ui.rescue_button)
	check(get_tree().current_scene==result and result.result_ui.return_error_label.visible and not result.result_ui.rescue_button.disabled,"failed save stays at debrief with retry enabled")
	check(profile.to_dict()==before and not profile.maintenance_rescued,"failed presentation request cannot publish rescue or rewards")
	result.finalize_save_path=RESCUE_PATH;await _click(result.result_ui.rescue_button)
	check(await wait_scene("res://scenes/presentation/slice/rescue_return.tscn"),"atomic retry saves first, then opens the physical return scene")
	check(ProfileRuntime.get_profile().maintenance_rescued and ProfileRuntime.get_profile().successful_sorties==1 and ProfileRuntime.get_profile().credits>credits,"one durable settlement, not a scene-only rescued flag")
	var saved:=FileAccess.get_sha256(RESCUE_PATH)
	await _click(get_tree().current_scene.screen.find_child("SkipRescueMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/hideout.tscn") and saved==FileAccess.get_sha256(RESCUE_PATH),"skip during approach cannot erase or duplicate rescue")
	var home=get_tree().current_scene
	check(home.section=="Rest" and home.find_child("OpenRescueMoment",true,false)!=null,"ordinary quarters offers replay from the saved rescue")
	await _frames();check_replay_layout(home)
	await _click(home.find_child("OpenRescueMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/rescue_return.tscn"),"real quarters button opens replay")
	await _click(get_tree().current_scene.screen.find_child("SkipRescueMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/hideout.tscn") and saved==FileAccess.get_sha256(RESCUE_PATH),"second skip leaves durable bytes unchanged")
	# Explicit UI fixture: make the other replay available without earning a fake
	# water mission. Restore this in-memory fixture before any subsequent save.
	ProfileRuntime.get_profile().waterworks_memory="water_public"
	home=get_tree().current_scene;home.show_section("Rest");await _frames();check_replay_layout(home)
	await capture_replay_layout()
	await _click(home.find_child("OpenBucketMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/bucket_return.tscn"),"when both are unlocked the bucket button opens the bucket, not a navigation tab")
	await _click(get_tree().current_scene.screen.find_child("SkipBucketMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/hideout.tscn"),"bucket exits back to quarters")
	await _click(get_tree().current_scene.find_child("OpenRescueMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/rescue_return.tscn"),"when both are unlocked the door button opens the door scene")
	await _click(get_tree().current_scene.screen.find_child("SkipRescueMoment",true,false))
	check(await wait_scene("res://scenes/presentation/slice/hideout.tscn") and saved==FileAccess.get_sha256(RESCUE_PATH),"both replay hit tests leave durable profile bytes unchanged")
	ProfileRuntime.get_profile().waterworks_memory=""
	check(DeploymentPlan.deploy(ProfileRuntime.get_profile(),MaintenanceStory.AREA,MaintenanceStory.MISSION,RESCUE_PATH).error==OK,"independent unfinished retreat fixture deploys")
	check(SortieRuntime.get_current_session().complete_extraction(),"unfinished retreat can still return")
	var ui:=ResultUI.new();ui.configure(SortieRuntime.get_outcome());get_tree().root.add_child(ui)
	check(ui.rescue_button==null,"prior rescued memory cannot turn an unfinished sortie into a new rescue scene")
	ui.free();SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test();print("RESCUE_RESULT_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
