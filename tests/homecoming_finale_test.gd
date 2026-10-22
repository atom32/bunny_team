extends "res://tests/finale_test.gd"
var room: Node3D
func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var profile:=core_fixture();profile.maintenance_closed=true
	check(profile.validate(),"explicit completed-story presentation fixture validates")
	var before:=JSON.stringify(profile.to_dict())
	room=load("res://scenes/presentation/slice/homecoming_finale.tscn").instantiate();add_child(room)
	check(room.eligible and is_instance_valid(room.guest) and room.guest.visible,"ending contains original heroine and actual existing CC0 survivor, not a second voice label")
	for tick in 600:
		await get_tree().physics_frame
		if room.phase=="intro":break
	check(room.phase=="intro" and room.motion.seated and room.guest.position.distance_to(Vector3(1.15,0,.35))<.05,"both actors actually arrive; heroine sits before conversation")
	await capture("homecoming_two_actors")
	for i in room.HOME_INTRO.size():room.advance_line()
	check(room.phase=="choice","unforced presentation choice appears after complete dialogue")
	room.choose("rise")
	for tick in 300:
		await get_tree().physics_frame
		if room.phase=="hesitate":break
	check(room.phase=="hesitate" and not room.motion.seated,"making room actually stands up")
	for i in room.HOME_WAIT.size():room.advance_line()
	for tick in 600:
		await get_tree().physics_frame
		if room.phase=="ending":break
	check(room.phase=="ending" and room.motion.seated and room.cup_held,"reply is followed by actual re-seat and cup pickup")
	for i in room.HOME_END.size():room.advance_line()
	check(room.phase=="done" and room.dialogue.text==tr(room.HOME_END[-1]),"the ending retains its last line, not the opening")
	room._enter("credits");await frames()
	check(room.end_card.visible and room.end_card.get_node("FinaleEndTitle").text==tr("THE END / EVERYONE IS HOME"),"a real end card closes this crisis, not a to-be-continued promise")
	await capture("homecoming_end_card")
	room.replay();await frames();check(room.phase=="approach" and not room.end_card.visible,"replay resets staging and hides end card")
	check(JSON.stringify(profile.to_dict())==before,"ending, choice, end card and replay award nothing and alter no story/save facts")
	room.free();room=null
	await finish()
func finish() -> void:
	if is_instance_valid(room):room.free()
	SortieRuntime.clear_session();get_tree().paused=false;await frames();AudioDirector.shutdown_for_test()
	print("HOMECOMING_FINALE_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
