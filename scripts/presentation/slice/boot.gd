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
var preferences := ConfigFile.new()

func _ready() -> void:
	GameState.presentation_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	preferences.load("user://presentation.cfg")
	var backdrop = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	backdrop.menu_backdrop = true
	add_child(backdrop)
	AudioDirector.set_music_context(&"menu")
	for bus in ["Music", "SFX"]:
		if preferences.has_section_key("audio", bus):
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(preferences.get_value("audio", bus)))
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	screen = SliceUI.root(layer)
	if preferences.get_value("opening", "seen", false): show_menu()
	else: _intro(0)

func _process(delta: float) -> void:
	if not opening: return
	intro_time += delta
	if intro_time >= 24.0: show_menu()
	elif int(intro_time / 8.0) != intro_card: _intro(int(intro_time / 8.0))

func _unhandled_input(event: InputEvent) -> void:
	if opening and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
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
	preferences.set_value("opening", "seen", true)
	preferences.save("user://presentation.cfg")
	_clear()
	SliceUI.panel(screen, Vector2(0,0), Vector2(436,720))
	SliceUI.label(screen, "BASTION 07 / FIELD OPERATIONS", Vector2(46,66), 15, SliceUI.CYAN)
	SliceUI.label(screen, "NEON\nBASTION", Vector2(40,106), 62)
	SliceUI.label(screen, "GO OUT. RECOVER. COME HOME.", Vector2(46,280), 15, SliceUI.MUTED)
	SliceUI.button(screen, "CONTINUE" if SaveService.save_exists() else "START", Vector2(46,352), Vector2(342,60), _enter)
	SliceUI.button(screen, "LOADOUT", Vector2(46,426), Vector2(342,50), func(): GameState.hideout_section = "Hanger"; _enter())
	SliceUI.button(screen, "SETTINGS", Vector2(46,490), Vector2(342,50), _settings)
	SliceUI.button(screen, "QUIT", Vector2(46,554), Vector2(342,50), func(): get_tree().quit())
	SliceUI.label(screen, "INTERNAL VERTICAL SLICE  /  07", Vector2(46,659), 13, SliceUI.MUTED)
	SliceUI.label(screen, "KOHAKU\nBATTLE FRAME / STANDBY", Vector2(892,574), 17, SliceUI.CYAN)

func _enter() -> void:
	GameState.open_hideout()

func _settings() -> void:
	_clear()
	var panel := SliceUI.panel(screen, Vector2(50,110), Vector2(470,490))
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
	SliceUI.label(panel, "WASD move / Mouse aim / LMB fire\nQ switch / R reload / Space dodge / E interact", Vector2(28,326), 15, SliceUI.MUTED)
	SliceUI.button(panel, "BACK", Vector2(28,402), Vector2(405,54), show_menu)
