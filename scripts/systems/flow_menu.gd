extends CanvasLayer
## One always-processing owner for pause, leave confirmation, save recovery and window close.
var screen: Control
var content: VBoxContainer
var mode := ""
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var waiting_for_transition := false
var save_path := SaveService.DEFAULT_SAVE_PATH
var display_return_to_pause := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_leave("quit")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		var session := SortieRuntime.get_current_session()
		if session and session.status == SortieSession.Status.ACTIVE and not is_open() and not GameState.is_transitioning():
			show_pause()

func _input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		if mode in ["pause", "error"]:
			close()
		elif mode == "confirm":
			show_pause()
		elif mode in ["display", "language"]:
			if display_return_to_pause: show_pause()
			else: close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if not GameState.is_transitioning():
			show_pause()
		get_viewport().set_input_as_handled()

func is_open() -> bool:
	return is_instance_valid(screen)

func _release_controls() -> void:
	for action in ["fire", "move_left", "move_right", "move_forward", "move_back", "dodge", "reload", "interact", "switch_weapon"]:
		Input.action_release(action)
	for player in get_tree().get_nodes_in_group("player"):
		if player is PlayerController:
			player.clear_buffered_input()

func close() -> void:
	if is_open():
		remove_child(screen)
		screen.queue_free()
		screen = null
	mode = ""
	get_tree().paused = false
	_release_controls()
	Input.mouse_mode = previous_mouse_mode

func _panel(title: String, message: String, new_mode: String) -> void:
	if not is_open():
		previous_mouse_mode = Input.mouse_mode
	else:
		remove_child(screen)
		screen.queue_free()
	mode = new_mode
	get_tree().paused = true
	_release_controls()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = UIFactory.theme()
	add_child(screen)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.045, 0.91)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("0f1824"), Color("557895")))
	center.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 27)
	content.add_child(heading)
	var detail := Label.new()
	detail.text = message
	detail.custom_minimum_size.x = 530
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	content.add_child(detail)

func _button(caption: String, action: Callable, focus := false) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 46
	button.pressed.connect(action)
	content.add_child(button)
	if focus:
		button.grab_focus()

func show_pause() -> void:
	if ProfileRuntime.recovery_required:
		show_save_recovery()
		return
	var session := SortieRuntime.get_current_session()
	var active := session != null and session.status == SortieSession.Status.ACTIVE
	_panel("PAUSED", "Simulation stopped. Esc resumes. Saves resume at base; mid-mission progress is not saved.", "pause")
	_button("RESUME", close, true)
	_button("DISPLAY / FULLSCREEN & RESOLUTION", show_display_settings)
	_button("LANGUAGE / 中文 & ENGLISH", show_language_settings)
	_button("ABANDON MISSION / RETURN TO BASE" if active else "RETURN TO BASE", func(): request_leave("base"))
	_button("MAIN MENU", func(): request_leave("menu"))
	_button("SAVE & QUIT" if not active else "ABANDON & QUIT", func(): request_leave("quit"))

func show_display_settings(return_to_pause := true) -> void:
	display_return_to_pause = return_to_pause
	_panel("DISPLAY", "Fullscreen uses your desktop resolution. Window resolution applies in windowed mode. F11 toggles fullscreen.", "display")
	var mode_option := OptionButton.new()
	mode_option.name = "WindowMode"
	mode_option.add_item("WINDOWED")
	mode_option.add_item("FULLSCREEN / DESKTOP")
	mode_option.select(1 if DisplaySettings.fullscreen else 0)
	content.add_child(mode_option)
	var resolution := OptionButton.new()
	resolution.name = "WindowResolution"
	for size in DisplaySettings.RESOLUTIONS:
		resolution.add_item(tr("%d × %d") % [size.x, size.y])
	resolution.select(DisplaySettings.RESOLUTIONS.find(DisplaySettings.window_size))
	resolution.disabled = DisplaySettings.fullscreen
	content.add_child(resolution)
	mode_option.item_selected.connect(func(index: int): resolution.disabled = index == 1)
	var feedback := Label.new()
	feedback.add_theme_font_size_override("font_size", 14)
	content.add_child(feedback)
	_button("APPLY", func():
		var error := DisplaySettings.apply_preferences(mode_option.selected == 1, DisplaySettings.RESOLUTIONS[resolution.selected])
		feedback.text = "APPLIED / SAVED" if error == OK else "Could not save: " + error_string(error)
	)
	_button("BACK", show_pause if return_to_pause else close)

func show_language_settings(return_to_pause := true) -> void:
	display_return_to_pause = return_to_pause
	_panel("LANGUAGE / 语言", "", "language")
	var language := OptionButton.new()
	language.name = "LanguageOption"
	language.add_item("简体中文")
	language.add_item("English")
	language.select(0 if TranslationServer.get_locale().begins_with("zh") else 1)
	content.add_child(language)
	var feedback := Label.new()
	content.add_child(feedback)
	_button("APPLY", func():
		var error := GameLanguage.set_language("zh_CN" if language.selected == 0 else "en")
		feedback.text = "SAVED / RESTART NOT REQUIRED" if error == OK else tr("Could not save: ") + error_string(error)
	)
	_button("BACK", show_pause if return_to_pause else close)

func show_error(message: String, fatal := false) -> void:
	_panel("ACTION UNAVAILABLE", message, "fatal" if fatal else "error")
	if not fatal:
		_button("BACK / RETRY", close, true)
	else:
		_button("DISCARD UNAVAILABLE SORTIE / RETURN TO BASE", _confirm_discard, true)
	_button("PAUSE / EXIT OPTIONS", show_pause)

func _confirm_discard() -> void:
	_panel("RETURN TO BASE?", "This discards the unavailable sortie. Your last warehouse state remains intact.", "confirm")
	_button("CANCEL", show_pause, true)
	_button("DISCARD SORTIE / RETURN TO BASE", func(): SortieRuntime.clear_session(); _leave("base", true))

func request_leave(destination: String) -> void:
	if ProfileRuntime.recovery_required:
		if destination == "quit":
			get_tree().quit()
		else:
			show_save_recovery()
		return
	if GameState.is_transitioning():
		if waiting_for_transition:
			return
		waiting_for_transition = true
		while GameState.is_transitioning():
			await get_tree().process_frame
		waiting_for_transition = false
		request_leave(destination)
		return
	var session := SortieRuntime.get_current_session()
	if session and session.status == SortieSession.Status.ACTIVE:
		_panel("ABANDON THIS MISSION?", "Mission progress and loot collected on this sortie will be lost. Your pre-deployment warehouse and equipment remain available.", "confirm")
		_button("CANCEL / KEEP PLAYING", close, true)
		_button(tr("ABANDON & ") + tr(destination.to_upper()), func(): _leave(destination, true))
	else:
		_leave(destination, true)

func _leave(destination: String, persist: bool) -> void:
	var session := SortieRuntime.get_current_session()
	if session and session.status == SortieSession.Status.ACTIVE:
		session.abandon()
	var error := OK
	if session:
		error = SortieRuntime.finalize_sortie(save_path, persist)
	elif persist:
		error = ProfileRuntime.save_profile(save_path)
	if error == ERR_INVALID_DATA:
		_panel("SORTIE RECOVERY", "The sortie cannot be committed. The warehouse is intact. Discard this unavailable sortie to continue.", "fatal")
		_button("BACK TO EXIT OPTIONS", show_pause, true)
		_button(tr("DISCARD SORTIE / ") + tr(destination.to_upper()), func(): SortieRuntime.clear_session(); _leave(destination, persist))
		return
	if error != OK:
		_panel("COULD NOT SAVE", tr("Error: %s. Progress is still in memory. Check disk space and permissions, then retry. Continuing without saving retains progress only until the app closes.") % error_string(error), "save_failure")
		_button("RETRY SAVE", func(): _leave(destination, true), true)
		_button("QUIT WITHOUT SAVING" if destination == "quit" else "CONTINUE WITHOUT SAVING", func(): _leave(destination, false))
		_button("BACK TO EXIT OPTIONS", show_pause)
		return
	close()
	GameState.arrival_pending = false
	if destination == "quit":
		get_tree().quit()
		return
	var scene_error := GameState.open_menu() if destination == "menu" else GameState.return_to_hanger()
	if scene_error != OK:
		show_error(tr("Could not open the destination: %s. Progress is retained; retry from exit options.") % error_string(scene_error))

func show_save_recovery() -> void:
	_panel("SAVE RECOVERY", "The saved profile is unreadable or unsupported. The original file will be archived before recovery. Choose a valid backup or start fresh; no automatic overwrite occurs.", "recovery")
	_button("RETRY ORIGINAL SAVE", func():
		if ProfileRuntime.load_profile(ProfileRuntime.recovery_path):
			_recovered()
		else:
			show_save_recovery()
	, true)
	if SaveService.load_profile(ProfileRuntime.recovery_path + ".bak", false):
		_button("RESTORE LAST VALID BACKUP", func(): _recover(true))
	_button("ARCHIVE BROKEN SAVE / START FRESH", func(): _recover(false))
	_button("QUIT / KEEP FILES", func(): get_tree().quit())

func _recover(backup: bool) -> void:
	var error := ProfileRuntime.recover_profile(backup)
	if error == OK:
		_recovered()
	else:
		show_save_recovery()
		var label := Label.new()
		label.text = tr("Recovery could not be saved: %s") % error_string(error)
		content.add_child(label)

func _recovered() -> void:
	close()
	# Rebuild previews/UI that referenced the temporary fallback profile.
	var error := GameState.return_to_hanger()
	if error != OK:
		show_error(tr("Profile recovered. Retry returning to base: %s") % error_string(error))
