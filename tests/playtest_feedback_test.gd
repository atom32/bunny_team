extends Node
## Actual form controls and explicit local saves. Never writes a real clipboard.
const DIRECTORY := "user://playtest_feedback_test"
var checks:=0
var failures:Array[String]=[]

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures.append(message)

func frames() -> void:
	for tick in 4:await get_tree().process_frame

func files(path: String) -> Array[String]:
	var result:Array[String]=[]
	if not DirAccess.dir_exists_absolute(path):return result
	for directory in DirAccess.get_directories_at(path):
		for file in DirAccess.get_files_at(path.path_join(directory)):result.append(directory.path_join(file))
	result.sort();return result

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameLanguage.set_language("en",false)
	var context:=PlaytestReport.build_context(get_tree())
	var before_profile:=ProfileRuntime.get_profile().to_dict()
	var before_files:=files(DIRECTORY)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
	center.theme=UIFactory.theme()
	var form:=PlaytestFeedback.new();form.configure(context);form.save_directory=DIRECTORY;center.add_child(form)
	await frames()
	check(form.size.x<=530.1 and form.custom_minimum_size.x==530,"form remains within its promised 530-pixel content width")
	check(not form.preview_edit.visible and form.save_button.disabled and form.copy_button.disabled,"new form does not expose save/copy before explicit preview")
	check(form.open_folder_button.disabled and form._last_saved_path.is_empty(),"folder opening starts disabled without a successful saved path")
	check(form.stuck_edit.text.is_empty() and form.remembered_edit.text.is_empty() and form.minutes_edit.text.is_empty(),"questions and self-estimated minutes begin genuinely blank")
	check(form.replay_choice.get_item_metadata(form.replay_choice.selected)=="undecided" and form.first_play_choice.get_item_metadata(form.first_play_choice.selected)=="unspecified","form presets neither positive replay intent nor first-time status")
	check(not form.report().is_empty() and not form._answers().has("estimated_minutes"),"configure-before-ready composes a valid neutral report and omits blank minutes")
	check(files(DIRECTORY)==before_files and ProfileRuntime.get_profile().to_dict()==before_profile,"construction and reading draft write neither reports nor profile")
	form.stuck_edit.text="  Lost at the depot.\nThen bored.  "
	form.remembered_edit.text="Tang Kui and the bell."
	form.replay_choice.select(2);form.replay_choice.item_selected.emit(2)
	form.first_play_choice.select(1);form.first_play_choice.item_selected.emit(1)
	form.minutes_edit.text="37"
	await frames()
	check(form._answers()=={"stuck":form.stuck_edit.text,"remembered":"Tang Kui and the bell.","replay":"no","first_play":"yes","estimated_minutes":37},"actual controls preserve whitespace and negative replay intent with explicit estimated minutes")
	form.preview_button.pressed.emit();await frames()
	# Button.pressed.emit() does not toggle state, unlike a user click.
	if not form.preview_edit.visible:form.preview_button.button_pressed=true;form.preview_button.pressed.emit()
	await frames()
	check(form.preview_edit.visible and not form.preview_edit.editable and form.preview_edit.custom_minimum_size.y==150,"full JSON preview is explicit, read-only and bounded rather than a growing dialog")
	check(form.preview_edit.text==PlaytestReport.preview(form.report()) and JSON.parse_string(form.preview_edit.text)==JSON.parse_string(JSON.stringify(form.report())),"preview contains the complete report including the whitelisted context, not a shortened summary")
	check(not form.save_button.disabled and form.copy_button.disabled==(not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD)),"save enables only after preview and clipboard follows actual platform support")
	check(files(DIRECTORY)==before_files,"previewing never creates a file")
	var answers_before:=form._answers().duplicate(true)
	var blocker:=DIRECTORY.path_join("blocker-"+Crypto.new().generate_random_bytes(8).hex_encode())
	check(DirAccess.make_dir_recursive_absolute(DIRECTORY)==OK,"isolated test directory can be created")
	var file:=FileAccess.open(blocker,FileAccess.WRITE);file.store_string("test-only path blocker");file.close()
	form.save_directory=blocker.path_join("child")
	form.save_button.pressed.emit();await frames()
	check(form.status_label.text.contains("Could not save report:") and form.status_label.text.contains("("),"failed explicit save displays the report service error rather than a success")
	check(form._answers()==answers_before and not form.save_button.disabled,"save failure retains every answer and permits an explicit retry")
	check(form.open_folder_button.disabled and form._last_saved_path.is_empty(),"failed first save cannot invent a report path or enable folder opening")
	form.save_directory=DIRECTORY
	var before_save:=files(DIRECTORY)
	form.save_button.pressed.emit();await frames()
	var after_first:=files(DIRECTORY)
	check(after_first.size()==before_save.size()+1 and form.status_label.text.begins_with("Saved on this device only:"),"explicit save creates one new local report")
	check(not form.open_folder_button.disabled and form._saved_folder_available() and form._last_saved_path.begins_with(DIRECTORY+"/report-"),"successful save enables only the existing local report folder without opening it")
	var written_path:=""
	for path in after_first:
		if path not in before_save:written_path=DIRECTORY.path_join(path)
	var written:=FileAccess.get_file_as_string(written_path)
	check(JSON.parse_string(written)==JSON.parse_string(form.preview_edit.text),"saved JSON exactly matches the reviewed report")
	form.save_button.pressed.emit();await frames()
	check(files(DIRECTORY).size()==after_first.size()+1 and FileAccess.get_file_as_string(written_path)==written,"second explicit save creates another report without overwriting the first")
	var last_success:String=form._last_saved_path
	form.save_directory=blocker.path_join("child");form.save_button.pressed.emit();await frames()
	check(form.status_label.text.contains("Could not save report:") and form._last_saved_path==last_success and not form.open_folder_button.disabled and form._saved_folder_available(),"later save failure remains a failure but preserves the last genuinely saved folder")
	form.save_directory=DIRECTORY
	form._last_saved_path="res"+"://project.godot" # Forbidden test data, not an export dependency.
	check(not form._saved_folder_available(),"folder guard rejects a non-user path without invoking the OS")
	form._last_saved_path=DIRECTORY+"/missing-report/report.json"
	check(not form._saved_folder_available(),"folder guard rejects a missing report without invoking the OS")
	form._last_saved_path=last_success
	form.stuck_edit.text="x".repeat(2001);form.refresh_preview()
	check(form.stuck_edit.text.length()==2001 and form.report().is_empty() and form.save_button.disabled and form.copy_button.disabled,"oversized answer is rejected without silent truncation or enabling save/copy")
	check(form.status_label.text.contains(str(ERR_INVALID_DATA)),"invalid draft surfaces the exact compose error code")
	form.stuck_edit.text="Still my answer."
	for invalid in ["601","-1","2.5","not a number"]:
		form.minutes_edit.text=invalid;form.refresh_preview()
		check(form.report().is_empty() and form.save_button.disabled and form.minutes_edit.text==invalid,"invalid minute estimate is retained and refused: "+invalid)
	form.minutes_edit.text="";form.refresh_preview()
	check(not form._answers().has("estimated_minutes") and not form.report().is_empty(),"blank minute estimate remains unspecified after errors")
	var kept:=form._answers().duplicate(true)
	form.configure(context);await frames()
	check(form._answers()==kept and not form.report().is_empty(),"configure-after-ready refreshes context without erasing the draft")
	check(ProfileRuntime.get_profile().to_dict()==before_profile,"feedback UI and explicit saves never mutate gameplay profile")
	form.free();center.free();AudioDirector.shutdown_for_test()
	for failure in failures:push_error("PLAYTEST_FEEDBACK: "+failure)
	print("PLAYTEST_FEEDBACK_TEST: %s (%d checks; actual controls, no clipboard write)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
