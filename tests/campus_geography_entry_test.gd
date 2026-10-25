extends Node
## Native entry/return clicks through the real scene transition owner.
var failures: Array[String] = []
var checks := 0
var evidence := OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)

func settle() -> void:
	for i in 160:
		await get_tree().process_frame
		if i>20 and not GameState.is_transitioning():return

func click(button: Button) -> void:
	check(button!=null and not button.disabled,"Enabled geographic entry/return exists")
	if not button:return
	check(get_viewport().get_visible_rect().encloses(button.get_global_rect()),"Geographic action fits viewport")
	if DisplayServer.get_name()=="headless":button.pressed.emit()
	else:
		for pressed: bool in [true,false]:
			var event:=InputEventMouseButton.new()
			event.position=button.get_global_rect().get_center()
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=pressed
			get_viewport().push_input(event)
			await get_tree().process_frame
	await settle()

func capture(label: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))

func _ready() -> void:
	# Keep this coordinator alive as a root sibling while real scenes replace.
	get_tree().current_scene=null
	var boot:=preload("res://scenes/presentation/slice/boot.tscn").instantiate()
	get_tree().root.add_child.call_deferred(boot)
	await get_tree().process_frame
	get_tree().current_scene=boot
	boot.show_menu()
	await settle()
	var profile_before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	await capture("05_menu_entry")
	await click(boot.screen.get_node("OpenRealCampus"))
	var survey:=get_tree().current_scene
	check(survey.scene_file_path=="res://scenes/presentation/campus_survey.tscn","Menu entry loads real whole-campus scene")
	if not survey.scene_file_path.ends_with("campus_survey.tscn"):get_tree().quit(1);return
	check(survey.return_scene.ends_with("boot.tscn"),"Menu entry retains return destination")
	await click(survey.screen.get_node("LeaveCampusSurvey"))
	boot=get_tree().current_scene
	check(boot.scene_file_path.ends_with("boot.tscn"),"Return from survey reaches actual menu")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==profile_before,"Menu survey roundtrip preserves profile and checkpoint")
	await click(boot.screen.get_node("EnterGame"))
	var hub:=get_tree().current_scene
	check(hub.scene_file_path.ends_with("hideout.tscn"),"Normal base entry still works")
	if not hub.scene_file_path.ends_with("hideout.tscn"):get_tree().quit(1);return
	hub.show_section("Operations")
	await settle()
	await capture("06_operations_entry")
	await click(hub.screen.get_node("OpenRealCampus"))
	survey=get_tree().current_scene
	check(survey.scene_file_path.ends_with("campus_survey.tscn"),"Operations entry loads whole campus")
	if not survey.scene_file_path.ends_with("campus_survey.tscn"):get_tree().quit(1);return
	check(survey.return_scene.ends_with("hideout.tscn"),"Operations survey retains base destination")
	await click(survey.screen.get_node("LeaveCampusSurvey"))
	hub=get_tree().current_scene
	check(hub.scene_file_path.ends_with("hideout.tscn") and hub.section=="Operations","Survey returns to the operations panel, not a different scene")
	print("CAMPUS GEOGRAPHY ENTRY: ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
