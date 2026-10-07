extends Node3D
const INTRO := [
	["01 / HOME SIGNAL", "The city went silent. Bastion 07 stayed on the air."],
	["02 / FIELD OPERATOR", "You are Kohaku. Your frame is ready. The security network is not on your side."],
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
	var panel := SliceUI.panel(screen, Vector2(42,486), Vector2(1196,176))
	SliceUI.label(panel, INTRO[index][0], Vector2(24,20), 20, SliceUI.CYAN)
	SliceUI.label(panel, INTRO[index][1], Vector2(24,72), 21)
	SliceUI.button(screen, "SKIP OPENING  /  ENTER", Vector2(922,34), Vector2(316,44), show_menu)
	AudioDirector.play_sfx(&"ui_confirm", -6)

func show_menu() -> void:
	opening = false
	settings_open = false
	preferences.set_value("opening", "seen", true)
	preferences.save("user://presentation.cfg")
	_clear()
	SliceUI.panel(screen, Vector2(24,24), Vector2(412,672))
	SliceUI.divider(screen, Vector2(46,316), 342)
	SliceUI.divider(screen, Vector2(46,634), 342)
	SliceUI.label(screen, "BASTION 07  /  FIELD OPERATIONS", Vector2(46,66), 15, SliceUI.CYAN)
	SliceUI.label(screen, "NEON\nBASTION", Vector2(42,116), 58)
	SliceUI.label(screen, "GO OUT. RECOVER. COME HOME.", Vector2(46,280), 15, SliceUI.MUTED)
	var resume_pending := not ProfileRuntime.get_profile().sortie_checkpoint.is_empty()
	var primary := SliceUI.button(screen, "RESUME SORTIE" if resume_pending else ("CONTINUE / BASE" if SaveService.save_exists() and not ProfileRuntime.recovery_required else "START"), Vector2(46,352), Vector2(342,60), _enter)
	primary.add_theme_stylebox_override("normal", SliceUI.menu_style(Color("b5aa81"), SliceUI.CYAN))
	primary.add_theme_color_override("font_color", Color("171914"))
	SliceUI.button(screen, "LOADOUT", Vector2(46,426), Vector2(342,50), func(): GameState.hideout_section = "Hanger"; _enter())
	SliceUI.button(screen, "SETTINGS", Vector2(46,490), Vector2(342,50), _settings)
	SliceUI.button(screen, "QUIT", Vector2(46,554), Vector2(342,50), func(): FlowMenu.request_leave("quit"))
	SliceUI.label(screen, "ALPHA  /  BASTION 07", Vector2(46,658), 13, SliceUI.MUTED)
	SliceUI.label(screen, "FIELD OPERATOR\nREADY / HOME SIGNAL ONLINE", Vector2(910,642), 17, SliceUI.CYAN)

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
	var panel := SliceUI.panel(screen, Vector2(50,80), Vector2(470,550))
	SliceUI.label(panel, "SIGNAL / SETTINGS", Vector2(28,26), 28, SliceUI.CYAN)
	var index := 0
	for bus in ["Music", "SFX"]:
		SliceUI.label(panel, bus.to_upper(), Vector2(28,108+index*100), 17)
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
