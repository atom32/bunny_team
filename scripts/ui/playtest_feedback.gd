class_name PlaytestFeedback
extends VBoxContainer
## Explicit, device-local feedback only. No profile writes or automatic copying.
var save_directory := "user://feedback"
var stuck_edit: TextEdit
var remembered_edit: TextEdit
var replay_choice: OptionButton
var first_play_choice: OptionButton
var minutes_edit: LineEdit
var preview_button: Button
var preview_edit: TextEdit
var save_button: Button
var copy_button: Button
var open_folder_button: Button
var status_label: Label
var _context: Dictionary = {}
var _answer_error := OK
var _last_error := OK
var _previewed := false
var _last_saved_path := ""

func configure(context: Dictionary) -> void:
	_context=context.duplicate(true)
	if is_node_ready():_changed()

func _ready() -> void:
	name="PlaytestFeedback"
	custom_minimum_size.x=530
	size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	add_theme_constant_override("separation",8)
	_label("Saved on this device only. Nothing is sent automatically. Please do not enter names, account details or contact information.")
	_label("Where did you get stuck or bored? / Up to 2000 characters")
	stuck_edit=_text("StuckAnswer")
	_label("Which person, moment or joke do you remember? / Up to 2000 characters")
	remembered_edit=_text("RememberedAnswer")
	replay_choice=_choice("Play another sortie?","ReplayAnswer",["UNDECIDED","WOULD PLAY AGAIN","WOULD NOT PLAY AGAIN"],["undecided","yes","no"])
	first_play_choice=_choice("First time playing?","FirstPlayAnswer",["NOT SPECIFIED","YES / FIRST PLAY","NO / PLAYED BEFORE"],["unspecified","yes","no"])
	var row:=HBoxContainer.new();add_child(row)
	var caption:=Label.new();caption.text=tr("Estimated playtime / minutes");caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	caption.add_theme_font_size_override("font_size",16);row.add_child(caption)
	minutes_edit=LineEdit.new();minutes_edit.name="EstimatedMinutes";minutes_edit.custom_minimum_size=Vector2(180,34)
	minutes_edit.placeholder_text=tr("Optional / 0 to 600");minutes_edit.add_theme_font_size_override("font_size",16)
	row.add_child(minutes_edit);minutes_edit.text_changed.connect(func(_value:String):_changed())
	_label("Your estimate, not an automatic playtime measurement. Leave it blank if unsure.")
	preview_button=Button.new();preview_button.name="PreviewReport";preview_button.text=tr("PREVIEW FULL REPORT / SHOW INCLUDED DETAILS")
	preview_button.toggle_mode=true;preview_button.custom_minimum_size.y=38;preview_button.add_theme_font_size_override("font_size",15)
	add_child(preview_button);preview_button.pressed.connect(_toggle_preview)
	preview_edit=_text("ReportPreview",150);preview_edit.editable=false;preview_edit.visible=false
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);add_child(actions)
	save_button=_button("SAVE NEW LOCAL REPORT","SaveFeedback",_save);actions.add_child(save_button)
	copy_button=_button("COPY PREVIEW","CopyFeedback",_copy);actions.add_child(copy_button)
	save_button.disabled=true;copy_button.disabled=true
	open_folder_button=_button("OPEN REPORT FOLDER","OpenReportFolder",_open_report_folder)
	open_folder_button.custom_minimum_size.y=34;open_folder_button.disabled=true;add_child(open_folder_button)
	status_label=_label("Preview the included details before saving or copying. No positive answer is required.")
	status_label.name="FeedbackStatus"

func _label(caption: String) -> Label:
	var result:=Label.new();result.text=tr(caption);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x=0;result.add_theme_font_size_override("font_size",15);add_child(result);return result

func _text(node_name: String,height:=64) -> TextEdit:
	var result:=TextEdit.new();result.name=node_name;result.custom_minimum_size=Vector2(530,height)
	result.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;result.add_theme_font_size_override("font_size",16)
	add_child(result)
	if node_name!="ReportPreview":result.text_changed.connect(_changed)
	return result

func _choice(caption: String,node_name: String,labels: Array,values: Array) -> OptionButton:
	var row:=HBoxContainer.new();add_child(row)
	var title:=Label.new();title.text=tr(caption);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",16);row.add_child(title)
	var result:=OptionButton.new();result.name=node_name;result.custom_minimum_size=Vector2(240,34)
	result.add_theme_font_size_override("font_size",16)
	for index in labels.size():result.add_item(tr(labels[index]));result.set_item_metadata(index,values[index])
	result.select(0);row.add_child(result);result.item_selected.connect(func(_index:int):_changed());return result

func _button(caption: String,node_name: String,action: Callable) -> Button:
	var result:=Button.new();result.name=node_name;result.text=tr(caption);result.custom_minimum_size.y=40
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.add_theme_font_size_override("font_size",15)
	result.pressed.connect(action);return result

func _answers() -> Dictionary:
	_answer_error=OK
	var result:Dictionary={"stuck":stuck_edit.text if is_instance_valid(stuck_edit) else "","remembered":remembered_edit.text if is_instance_valid(remembered_edit) else "","replay":"undecided","first_play":"unspecified"}
	if is_instance_valid(replay_choice):result.replay=replay_choice.get_item_metadata(replay_choice.selected)
	if is_instance_valid(first_play_choice):result.first_play=first_play_choice.get_item_metadata(first_play_choice.selected)
	if is_instance_valid(minutes_edit) and not minutes_edit.text.is_empty():
		if not minutes_edit.text.is_valid_int():_answer_error=ERR_INVALID_DATA
		else:result.estimated_minutes=minutes_edit.text.to_int()
	return result

func report() -> Dictionary:
	var answers:=_answers()
	if _answer_error!=OK:_last_error=_answer_error;return {}
	var result:=PlaytestReport.compose(_context,answers)
	_last_error=int(result.get("error",ERR_INVALID_DATA))
	return result.get("report",{}) if _last_error==OK else {}

func _changed() -> void:
	_previewed=false
	if not is_node_ready():return
	save_button.disabled=true;copy_button.disabled=true
	if preview_edit.visible:refresh_preview()
	else:status_label.text=tr("Draft changed. Preview the included details before saving or copying.")

func _toggle_preview() -> void:
	if preview_button.button_pressed:refresh_preview()
	else:
		preview_edit.visible=false;_previewed=false;save_button.disabled=true;copy_button.disabled=true

func refresh_preview() -> void:
	if not is_node_ready():return
	preview_button.button_pressed=true;preview_edit.visible=true
	var value:=report()
	if _last_error!=OK:
		preview_edit.text="";_previewed=false;save_button.disabled=true;copy_button.disabled=true
		status_label.text=tr("Cannot prepare report: %s (%d). Answers are unchanged. Text must be at most 2000 characters per answer; minutes must be blank or an integer from 0 to 600.")%[error_string(_last_error),_last_error]
		return
	preview_edit.text=PlaytestReport.preview(value);_previewed=true
	save_button.disabled=false;copy_button.disabled=not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD)
	status_label.text=tr("Review the full JSON above. Save creates a new local file; it does not upload anything.")

func _save() -> void:
	if not _previewed or not preview_edit.visible:return
	var value:=report()
	if _last_error!=OK:refresh_preview();return
	var result:=PlaytestReport.save_local(value,save_directory)
	var error:int=result.get("error",ERR_INVALID_DATA)
	if error!=OK:
		status_label.text=tr("Could not save report: %s (%d). Your answers are still here.")%[error_string(error),error]
	else:
		_last_saved_path=str(result.get("path",""))
		open_folder_button.disabled=not _saved_folder_available()
		status_label.text=tr("Saved on this device only: %s")%_last_saved_path

func _saved_folder_available() -> bool:
	return _last_saved_path.begins_with("user://") and FileAccess.file_exists(_last_saved_path) and DirAccess.dir_exists_absolute(_last_saved_path.get_base_dir())

func _open_report_folder() -> void:
	# Only an explicit press reaches the OS; reports retain their relative paths.
	var error:=ERR_FILE_NOT_FOUND
	if _saved_folder_available():error=OS.shell_open(ProjectSettings.globalize_path(_last_saved_path.get_base_dir()))
	else:open_folder_button.disabled=true
	if error!=OK:status_label.text=tr("Could not open report folder: %s (%d).")%[error_string(error),error]

func _copy() -> void:
	if not _previewed or not preview_edit.visible or not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):return
	var value:=report()
	if _last_error!=OK:refresh_preview();return
	DisplayServer.clipboard_set(PlaytestReport.preview(value))
	status_label.text=tr("Copied the preview only. Nothing was sent automatically.")
