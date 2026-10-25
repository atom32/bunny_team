extends Node
## Real production menu entries, explicit isolated profile, no clipboard writes.
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func frames() -> void:
	for tick in 4:await get_tree().process_frame

func escape() -> void:
	var event := InputEventAction.new();event.action="ui_cancel";event.pressed=true
	FlowMenu._input(event)

func _ready() -> void:
	await get_tree().process_frame
	SortieRuntime.clear_session()
	GameLanguage.set_language("zh_CN",false)
	var profile := ProfileRuntime.new_profile()
	check(SaveService.save_profile(profile)==OK,"isolated input profile saves before opening menus")
	var saved_hash := FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	var before := profile.to_dict()
	var boot:Node3D=load("res://scenes/presentation/slice/boot.tscn").instantiate()
	get_tree().root.add_child(boot);get_tree().current_scene=boot;boot.show_menu();await frames()
	before=profile.to_dict() # Existing warehouse layout initialization is not feedback.
	var menu_button := boot.find_child("PlaytestFeedbackButton",true,false) as Button
	check(menu_button!=null and menu_button.is_visible_in_tree(),"normal BOOT exposes an optional feedback entry")
	if menu_button:menu_button.pressed.emit()
	await frames()
	check(FlowMenu.mode=="feedback" and get_tree().paused and FlowMenu.screen.find_child("PlaytestFeedback",true,false)!=null,"BOOT entry opens bounded form and pauses without leaving menu")
	escape();await frames()
	check(not FlowMenu.is_open() and not get_tree().paused,"Escape from BOOT feedback returns without opening pause menu")
	check(not DirAccess.dir_exists_absolute("user://feedback"),"opening and cancelling do not auto-save feedback")
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(),profile)
	check(session!=null,"real active sortie fixture opens before testing pause entry")
	if session:
		var state := SortieCheckpoint.session_data(session)
		FlowMenu.show_pause();await frames()
		var entry:Button
		for child in FlowMenu.content.get_children():
			if child is Button and child.text in ["PLAYTEST FEEDBACK / LOCAL ONLY",tr("PLAYTEST FEEDBACK / LOCAL ONLY")]:entry=child;break
		check(entry!=null,"real pause page exposes feedback separately from abandon")
		if entry:entry.pressed.emit()
		await frames();check(FlowMenu.mode=="feedback" and get_tree().paused,"pause feedback remains paused")
		escape();await frames()
		check(FlowMenu.mode=="pause" and get_tree().paused,"Escape returns to pause, never resumes combat behind the player")
		FlowMenu.close()
		check(SortieCheckpoint.session_data(session)==state,"opening/cancelling changes no ammunition, objectives, inventory or outcome")
		check(session.fail(),"explicit failure creates a genuine terminal session fixture")
		var outcome := SortieRuntime.get_outcome()
		var result_scene:Node3D=load("res://scenes/result/result.tscn").instantiate()
		get_tree().root.add_child(result_scene);get_tree().current_scene=result_scene
		await frames()
		var result:ResultUI=result_scene.result_ui
		var context:=PlaytestReport.build_context(get_tree())
		check(context.scene=="result" and context.sortie_status=="failed","actual result scene reports its own failed context rather than the prior menu")
		check(result.feedback_button!=null and not result.feedback_button.disabled,"failed-result feedback is available too, not just victories")
		result.feedback_button.pressed.emit();await frames()
		check(FlowMenu.mode=="feedback" and get_tree().paused,"result entry opens the same form without finalizing or returning")
		escape();await frames()
		check(not FlowMenu.is_open() and not get_tree().paused and SortieRuntime.get_outcome()==outcome,"result cancel retains the same unsettled outcome")
		result.set_return_pending(true)
		check(result.feedback_button.disabled,"finalization disables competing feedback entry")
		get_tree().current_scene=boot;result_scene.free()
	check(profile.to_dict()==before and FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)==saved_hash,"all entries preserve profile memory and exact saved bytes")
	get_tree().current_scene=self;boot.free();SortieRuntime.clear_session()
	if FlowMenu.is_open():FlowMenu.close()
	AudioDirector.shutdown_for_test()
	for failure in failures:push_error(failure)
	print("FEEDBACK_ENTRY_TEST: %s (%d checks; controlled UI callbacks, not native input)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
