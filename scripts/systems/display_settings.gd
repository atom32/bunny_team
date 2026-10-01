extends Node
## Window preferences are independent of the player's save/profile.
const PATH := "user://display.cfg"
const RESOLUTIONS := [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(3840,2160)]
var fullscreen := false
var window_size := Vector2i(1280,720)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_preferences()
	_apply_window()

func load_preferences(path := PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	fullscreen = config.get_value("display", "fullscreen", false) == true
	var saved: Variant = config.get_value("display", "window_size", Vector2i(1280,720))
	if saved is Vector2i and saved in RESOLUTIONS: window_size = saved

func apply_preferences(use_fullscreen: bool, resolution: Vector2i, path := PATH) -> Error:
	if resolution not in RESOLUTIONS: return ERR_INVALID_PARAMETER
	fullscreen = use_fullscreen
	window_size = resolution
	_apply_window()
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_size", window_size)
	return config.save(path)

func _apply_window() -> void:
	if DisplayServer.get_name() == "headless": return
	var window := get_window()
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = window_size
		window.move_to_center()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		var error := apply_preferences(not fullscreen, window_size)
		if error != OK: FlowMenu.show_error("Display preferences could not be saved: " + error_string(error))
		get_viewport().set_input_as_handled()
