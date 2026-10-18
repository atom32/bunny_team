extends Node3D
const INTRO := [
	["01 / HOME SIGNAL", "The city went silent. Bastion 07 stayed on the air."],
	["02 / FIELD OPERATOR", "Your frame is ready. The security network is not on your side."],
	["03 / SIGNAL RECOVERY", "Access the Field Office. Recover supplies. Reach extraction. Come home."],
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
	description.size = Vector2(1148, 80)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SliceUI.button(screen, "SKIP OPENING  /  ENTER", Vector2(922,34), Vector2(316,44), show_menu)
	AudioDirector.play_sfx(&"ui_confirm", -6)

func show_menu() -> void:
	opening = false
	settings_open = false
	preferences.set_value("opening", "seen", true)
	preferences.save("user://presentation.cfg")
	_clear()
	_panel(screen, Vector2(24,24), Vector2(412,672))
	SliceUI.divider(screen, Vector2(46,316), 342).color = FieldManualStyle.LINE
	SliceUI.divider(screen, Vector2(46,634), 342).color = FieldManualStyle.LINE
	_label(screen, "BASTION 07  /  FIELD OPERATIONS", Vector2(46,66), 15, FieldManualStyle.ACCENT)
	_label(screen, "NEON\nBASTION", Vector2(42,116), 58)
	_label(screen, "GO OUT. RECOVER. COME HOME.", Vector2(46,280), 15, FieldManualStyle.MUTED)
	var resume_pending := not ProfileRuntime.get_profile().sortie_checkpoint.is_empty()
	var primary := SliceUI.button(screen, "RESUME SORTIE" if resume_pending else ("CONTINUE / BASE" if SaveService.save_exists() and not ProfileRuntime.recovery_required else "START"), Vector2(46,352), Vector2(342,60), _enter)
	FieldManualStyle.primary(primary)
	SliceUI.button(screen, "SETTINGS", Vector2(46,426), Vector2(342,50), _settings)
	SliceUI.button(screen, "QUIT", Vector2(46,490), Vector2(342,50), func(): FlowMenu.request_leave("quit"))
	_label(screen, "ALPHA  /  BASTION 07", Vector2(46,658), 13, FieldManualStyle.MUTED)
	var status := _panel(screen, Vector2(886,626), Vector2(352,70))
	_label(status, "FIELD OPERATOR\nREADY / HOME SIGNAL ONLINE", Vector2(18,12), 15, FieldManualStyle.MUTED)

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
	var panel := _panel(screen, Vector2(50,80), Vector2(470,550))
	_label(panel, "SIGNAL / SETTINGS", Vector2(28,26), 28, FieldManualStyle.ACCENT)
	var index := 0
	for bus in ["Music", "SFX"]:
		_label(panel, bus.to_upper(), Vector2(28,108+index*100), 17)
		var slider := HSlider.new()
		slider.position = Vector2(28,146+index*100)
		slider.size = Vector2(405,28)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))
		panel.add_child(slider)
		slider.value_changed.connect(func(value: float):
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(value))
			preferences.set_value("audio", bus, value)
			preferences.save("user://presentation.cfg")
		)
		index += 1
	SliceUI.button(panel, "DISPLAY / FULLSCREEN & RESOLUTION", Vector2(28,318), Vector2(405,48), func(): FlowMenu.show_display_settings(false))
	SliceUI.button(panel, "LANGUAGE / 中文 & ENGLISH", Vector2(28,370), Vector2(405,40), func(): FlowMenu.show_language_settings(false))
	SliceUI.button(panel, "CONTROLS / KEY BINDINGS", Vector2(28,414), Vector2(405,40), func(): FlowMenu.show_control_settings(false))
	SliceUI.button(panel, "BACK", Vector2(28,466), Vector2(405,46), show_menu)


# Presentation-only adapters; callbacks and data ownership remain unchanged.
func _panel(parent: Node, at: Vector2, extent: Vector2) -> Panel:
	var result := SliceUI.panel(parent, at, extent)
	result.add_theme_stylebox_override("panel", FieldManualStyle.panel())
	return result

func _label(parent: Node, text: String, at: Vector2, font_size: int = 18, color: Color = FieldManualStyle.INK) -> Label:
	return SliceUI.label(parent, text, at, font_size, color)
