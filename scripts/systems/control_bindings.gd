class_name ControlBindings
extends RefCounted
## Device-local preferences. Save first, then publish; never part of a Person save.
const PATH := "user://controls.cfg"
const LABELS := {
	"move_forward":"MOVE FORWARD", "move_back":"MOVE BACK", "move_left":"MOVE LEFT", "move_right":"MOVE RIGHT",
	"fire":"FIRE", "dodge":"DODGE", "precision_walk":"QUIET WALK", "reload":"RELOAD", "switch_weapon":"SWITCH WEAPON",
	"interact":"INTERACT", "use_dressing":"FIELD DRESSING", "use_medkit":"MEDKIT", "route_map":"ROUTE MAP"}
static var defaults: Dictionary = {}
static var current: Dictionary = {}
static var revision := 0

static func initialize(path := PATH) -> void:
	if defaults.is_empty():
		MedicalTreatment.install_input_actions()
		if not InputMap.has_action("route_map"):
			InputMap.add_action("route_map")
			var key := InputEventKey.new()
			key.physical_keycode = KEY_M
			InputMap.action_add_event("route_map",key)
		for action in LABELS:
			for event in InputMap.action_get_events(action):
				var value := code(event)
				if value != 0:
					defaults[action] = value
					break
	var config := ConfigFile.new()
	var saved: Variant = {}
	if config.load(path) == OK: saved = config.get_value("controls","bindings",{})
	_publish(saved if valid(saved) else defaults)

static func code(event: InputEvent) -> int:
	if event is InputEventKey:
		var value: int = event.physical_keycode if event.physical_keycode else event.keycode
		if (event.ctrl_pressed and value != KEY_CTRL) or event.alt_pressed or event.meta_pressed: return 0
		return value
	if event is InputEventMouseButton: return -event.button_index
	return 0

static func valid(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() != LABELS.size(): return false
	var used := []
	for action in LABELS:
		var value: Variant = raw.get(action)
		if not value is int or value in used: return false
		if value < 0:
			if value not in [-1,-2,-3,-8,-9]: return false
		elif value == 0 or value in [KEY_ESCAPE,KEY_F11] or value >= KEY_UNKNOWN or OS.get_keycode_string(value).is_empty(): return false
		used.append(value)
	return true

static func apply(bindings: Dictionary, path := PATH) -> Error:
	if not valid(bindings): return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	config.set_value("controls","bindings",bindings)
	var error := config.save(path)
	if error == OK: _publish(bindings)
	return error

static func _publish(bindings: Dictionary) -> void:
	for action in LABELS:
		Input.action_release(action)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton: InputMap.action_erase_event(action,event)
		var value: int = bindings[action]
		var event: InputEvent
		if value < 0:
			event = InputEventMouseButton.new()
			event.button_index = -value
		else:
			event = InputEventKey.new()
			event.physical_keycode = value
		InputMap.action_add_event(action,event)
	current = bindings.duplicate()
	revision += 1

static func key_label(value: int) -> String:
	if value < 0: return { -1:"LMB", -2:"RMB", -3:"MMB", -8:"MOUSE 4", -9:"MOUSE 5" }.get(value,"?")
	return OS.get_keycode_string(value)

static func label(action: String) -> String:
	return key_label(current.get(action,defaults.get(action,0)))
