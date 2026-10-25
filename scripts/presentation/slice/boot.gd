extends Node3D
const INTRO := [
	["01 / IS THIS THING ON?", "Tang Kui: Can you hear me? Knock twice if you can. Do not shoot the radio.\nSu Mi: She is still in the room.\nTang Kui: I know. I am saying it now."],
	["02 / YOUR CHAIR IS STILL HERE", "Shen Yanshuang: I kept your chair. When you go out, remember to come back and sit in it.\nTang Kui: That is not what you said a minute ago.\nShen Yanshuang: Mute your radio, Tang Kui."],
	["03 / BEFORE IT GETS COLD", "Tang Kui: I saved you a bowl. If it gets cold, I am eating it.\nSu Mi: She just filled another one.\nTang Kui: Could you pretend you did not hear that?"],
]
var screen: Control
var intro_time := 0.0
var intro_card := -1
var opening := true
var settings_open := false
var preferences := ConfigFile.new()

func _ready() -> void:
	GameLanguage.initialize_game_language()
	GameLanguage.language_changed.connect(_refresh_language)
	GameState.presentation_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	preferences.load("user://presentation.cfg")
	var backdrop = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	backdrop.menu_backdrop = true
	add_child(backdrop)
	AudioDirector.set_music_context(&"menu")
	for bus in ["Music", "SFX"]:
		if preferences.has_section_key("audio", bus):
			var value: Variant = preferences.get_value("audio", bus)
			if SaveService.is_number(value):
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(clampf(value, 0.0, 1.0)))
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	screen = SliceUI.root(layer)
	screen.theme = FieldManualStyle.theme()
	if preferences.get_value("opening", "seen", false): show_menu()
	else: _intro(0)
	if ProfileRuntime.recovery_required:
		FlowMenu.call_deferred("show_save_recovery")

func _process(delta: float) -> void:
	if not opening: return
	intro_time += delta
	if intro_time >= 24.0: show_menu()
	elif int(intro_time / 8.0) != intro_card: _intro(int(intro_time / 8.0))

func _unhandled_input(event: InputEvent) -> void:
	if settings_open and event.is_action_pressed("ui_cancel"):
		show_menu()
		get_viewport().set_input_as_handled()
	elif opening and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		show_menu()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	for child in screen.get_children():
		screen.remove_child(child)
		child.queue_free()

func _intro(index: int) -> void:
	intro_card = index
	_clear()
	var panel := _panel(screen, Vector2(42,486), Vector2(1196,176))
	_label(panel, INTRO[index][0], Vector2(24,20), 20, FieldManualStyle.ACCENT)
	var description := _label(panel, INTRO[index][1], Vector2(24,72), 21)
	description.size = Vector2(1148, 94)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SliceUI.button(screen, "SKIP OPENING  /  ENTER", Vector2(922,34), Vector2(316,44), show_menu)
	AudioDirector.play_sfx(&"ui_confirm", -6)

func show_menu() -> void:
	opening = false
	settings_open = false
	preferences.set_value("opening", "seen", true)
	preferences.save("user://presentation.cfg")
	_clear()
	# Frame the room instead of burying it under a full-screen dashboard.
	OperationUI.block(screen, Vector2.ZERO, Vector2(444,720))
	OperationUI.block(screen, Vector2.ZERO, Vector2(8,720), OperationUI.DARK)
	OperationUI.eyebrow(screen, "BASTION / FIELD OPERATIONS", Vector2(40,32))
	OperationUI.rule(screen, Vector2(40,68), 364)
	var wordmark := OperationUI.text(screen, "NEON", Vector2(36,94), 76, FieldManualStyle.INK, true)
	wordmark.add_theme_font_override("font", OperationUI.typeface(800))
	var second := OperationUI.text(screen, "BASTION", Vector2(38,180), 54, FieldManualStyle.INK, true)
	second.add_theme_font_override("font", OperationUI.typeface(800,112))
	OperationUI.text(screen, "GO OUT. RECOVER. COME HOME.", Vector2(42,266), 12, FieldManualStyle.MUTED, true)
	OperationUI.rule(screen, Vector2(40,306), 364)
	OperationUI.eyebrow(screen, "NEXT / CONTINUE", Vector2(42,326))
	var resume_pending := not ProfileRuntime.get_profile().sortie_checkpoint.is_empty()
	var entry_text := "RESUME SORTIE" if resume_pending else ("CONTINUE / BASE" if SaveService.save_exists() and not ProfileRuntime.recovery_required else "START")
	var primary := OperationUI.action(screen, entry_text, Vector2(40,360), Vector2(364,64), _enter, true)
	primary.name = "EnterGame"
	OperationUI.text(screen, tr("Your suspended operation is waiting." if resume_pending else "Prepare at base. What you bring home stays yours."), Vector2(42,436), 13, FieldManualStyle.MUTED)
	OperationUI.action(screen, "SETTINGS", Vector2(40,492), Vector2(222,48), _settings)
	OperationUI.action(screen, "QUIT", Vector2(274,492), Vector2(130,48), func(): FlowMenu.request_leave("quit"))
	OperationUI.rule(screen, Vector2(40,570), 364)
	var feedback := OperationUI.action(screen, "PLAYTEST FEEDBACK / LOCAL ONLY", Vector2(40,590), Vector2(364,44), func(): FlowMenu.show_feedback(false))
	feedback.name = "PlaytestFeedbackButton"
	feedback.add_theme_font_size_override("font_size",13)
	OperationUI.text(screen, tr("LOCAL PREVIEW / %s") % BuildIdentity.current().id, Vector2(40,666), 11, FieldManualStyle.MUTED)
	OperationUI.block(screen, Vector2(476,32), Vector2(162,28), OperationUI.DARK)
	OperationUI.text(screen, "// HOME BASE", Vector2(488,34), 12, Color.WHITE, true)
	var geography := OperationUI.action(screen,"整校园 1:1 / 室内任务",Vector2(914,82),Vector2(326,48),func():
		GameState.set_meta("campus_geography_return","res://scenes/presentation/slice/boot.tscn")
		GameState.present_scene("res://scenes/presentation/campus_survey.tscn","WEIJIN CAMPUS / 1:1"))
	geography.name="OpenRealCampus"
	geography.tooltip_text="真实比例路网与四湖；12栋/21空间，O目录、J雨前接力。实走到东门按N接取断电夜线：战斗、破坏与带出loot；独立保存，不改旧主线或装备。"
	var status := OperationUI.block(screen, Vector2(914,580), Vector2(326,108), OperationUI.DARK)
	OperationUI.eyebrow(status, "OPERATOR / BUNNY", Vector2(20,12), true)
	OperationUI.text(status, "GO OUT. COME HOME.", Vector2(20,38), 18, Color.WHITE, true)
	OperationUI.text(status, tr("Recover. Re-equip. Return."), Vector2(20,72), 13, Color("b4bbb6"))
	primary.grab_focus()

func _enter() -> void:
	if ProfileRuntime.recovery_required:
		FlowMenu.show_save_recovery()
		return
	FlowMenu.request_leave("base")

func _refresh_language() -> void:
	if opening: _intro(intro_card)
	elif settings_open: _settings()
	else: show_menu()

func _settings() -> void:
	settings_open = true
	_clear()
	OperationUI.block(screen, Vector2.ZERO, Vector2(566,720))
	OperationUI.heading(screen, "PREFERENCES", tr("SETTINGS"), Vector2(40,32))
	OperationUI.rule(screen, Vector2(40,112),486)
	var panel := _panel(screen, Vector2(24,128), Vector2(518,554))
	var index := 0
	for bus in ["Music", "SFX"]:
		OperationUI.eyebrow(panel, "0%d / AUDIO" % (index+1), Vector2(20,12+index*100))
		_label(panel, tr(bus.to_upper()), Vector2(20,38+index*100), 18)
		var slider := HSlider.new()
		slider.name = bus + "Volume"
		slider.position = Vector2(20,72+index*100)
		slider.size = Vector2(390,24)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))
		panel.add_child(slider)
		var value_label := _label(panel, "%d%%" % roundi(slider.value*100), Vector2(430,70+index*100), 14)
		slider.value_changed.connect(func(value: float):
			value_label.text = "%d%%" % roundi(value*100)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(value))
			preferences.set_value("audio", bus, value)
			preferences.save("user://presentation.cfg")
		)
		index += 1
	OperationUI.rule(panel, Vector2(20,224),478)
	OperationUI.action(panel, "DISPLAY / FULLSCREEN & RESOLUTION", Vector2(20,248), Vector2(478,48), func(): FlowMenu.show_display_settings(false))
	OperationUI.action(panel, "LANGUAGE / 中文 & ENGLISH", Vector2(20,310), Vector2(478,48), func(): FlowMenu.show_language_settings(false))
	OperationUI.action(panel, "CONTROLS / KEY BINDINGS", Vector2(20,372), Vector2(478,48), func(): FlowMenu.show_control_settings(false))
	var back := OperationUI.action(panel, "BACK", Vector2(20,470), Vector2(478,52), show_menu, true)
	back.grab_focus()


# Presentation-only adapters; callbacks and data ownership remain unchanged.
func _panel(parent: Node, at: Vector2, extent: Vector2) -> Panel:
	var result := SliceUI.panel(parent, at, extent)
	result.add_theme_stylebox_override("panel", FieldManualStyle.panel())
	return result

func _label(parent: Node, text: String, at: Vector2, font_size: int = 18, color: Color = FieldManualStyle.INK) -> Label:
	return SliceUI.label(parent, text, at, font_size, color)
