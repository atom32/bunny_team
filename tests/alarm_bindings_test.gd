extends Node
## Test-specific preference files only; never writes ControlBindings.PATH or a Person save.
const PATH := "user://alarm_bindings_test.cfg"
const LEGACY_PATH := "user://alarm_bindings_legacy_test.cfg"
const BAD_PATH := "user://alarm_bindings_bad_test.cfg"
const OLD_ACTIONS := ["move_forward","move_back","move_left","move_right","fire","dodge","precision_walk","reload","switch_weapon","interact","use_dressing","use_medkit","route_map"]
const LETTERS := [KEY_G,KEY_K,KEY_L,KEY_T,KEY_Y,KEY_U,KEY_O,KEY_P,KEY_B,KEY_C,KEY_F,KEY_N,KEY_X,KEY_Z]
var checks := 0
var failures: Array[String] = []

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func key(value: int,pressed:=true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode=value;event.keycode=value;event.pressed=pressed
	return event

func write_fixture(path: String,bindings: Variant) -> void:
	var file := ConfigFile.new();file.set_value("controls","bindings",bindings)
	check(file.save(path)==OK,"test-only control fixture saves")

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var previous := ControlBindings.current.duplicate()
	var previous_events := InputMap.action_get_events("place_alarm")
	if "--read" in OS.get_cmdline_user_args():
		ControlBindings.initialize(PATH)
		check(ControlBindings.valid(ControlBindings.current) and ControlBindings.current.place_alarm==KEY_H,"independent process reads the saved complete alarm binding")
		check(InputMap.event_is_action(key(KEY_H),"place_alarm") and ControlBindings.label("place_alarm")=="H","independent binding and label use the same physical key")
	else:
		await exercise()
	FlowMenu.close()
	ControlBindings._publish(previous)
	InputMap.action_erase_events("place_alarm")
	for event in previous_events: InputMap.action_add_event("place_alarm",event)
	AudioDirector.shutdown_for_test()
	for failure in failures: push_error("ALARM_BINDINGS: "+failure)
	print("ALARM_BINDINGS_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func exercise() -> void:
	InputMap.erase_action("place_alarm")
	ControlBindings.install_input_actions()
	var events := InputMap.action_get_events("place_alarm")
	check(events.size()==1 and events[0] is InputEventKey and events[0].physical_keycode==KEY_G,"absent action installs one physical G event")
	ControlBindings.install_input_actions()
	check(InputMap.action_get_events("place_alarm").size()==1,"repeated installer does not duplicate the default")
	InputMap.erase_action("place_alarm")
	ControlBindings.initialize("user://alarm_bindings_no_fixture.cfg")
	check(InputMap.has_action("place_alarm") and InputMap.event_is_action(key(KEY_G),"place_alarm"),"initialize itself installs a missing action before publishing preferences")
	InputMap.action_erase_events("place_alarm");InputMap.action_add_event("place_alarm",key(KEY_L))
	var pad := InputEventJoypadButton.new();pad.device=-1;pad.button_index=JOY_BUTTON_Y
	InputMap.action_add_event("place_alarm",pad)
	ControlBindings.install_input_actions()
	check(InputMap.action_get_events("place_alarm").size()==2 and InputMap.event_is_action(key(KEY_L),"place_alarm") and not InputMap.event_is_action(key(KEY_G),"place_alarm"),"installer leaves an existing customized action and its pad event unchanged")
	ControlBindings.initialize("user://alarm_bindings_no_fixture.cfg")
	check(ControlBindings.valid(ControlBindings.defaults) and ControlBindings.current==ControlBindings.defaults and ControlBindings.label("place_alarm")=="G","initialize publishes complete defaults including the new G label")
	check(ControlBindings.LABELS.place_alarm=="PLACE NOISE DECOY","ordinary settings expose the alarm action through the existing labels")
	var legacy := {}
	var custom := [KEY_Q,KEY_W,KEY_E,KEY_R,-2,KEY_T,KEY_Y,KEY_U,KEY_I,KEY_O,KEY_P,KEY_B,KEY_C]
	for index in OLD_ACTIONS.size(): legacy[OLD_ACTIONS[index]]=custom[index]
	write_fixture(LEGACY_PATH,legacy)
	var original_disk := FileAccess.get_file_as_string(LEGACY_PATH)
	ControlBindings.initialize(LEGACY_PATH)
	check(ControlBindings.valid(ControlBindings.current) and ControlBindings.current.place_alarm==KEY_G,"complete valid old schema gains G when G is free")
	for action in OLD_ACTIONS: check(ControlBindings.current[action]==legacy[action],"legacy customization retained: "+action)
	check(FileAccess.get_file_as_string(LEGACY_PATH)==original_disk,"initialization upgrades in memory without silently rewriting old preferences")
	# All but the last suggested letter are legitimately occupied by old actions.
	# No preference is sacrificed to make room for the fourteenth binding.
	for index in OLD_ACTIONS.size(): legacy[OLD_ACTIONS[index]]=LETTERS[index]
	write_fixture(LEGACY_PATH,legacy);ControlBindings.initialize(LEGACY_PATH)
	check(ControlBindings.current.place_alarm==KEY_Z and ControlBindings.label("place_alarm")=="Z" and ControlBindings.valid(ControlBindings.current),"G collision selects the only unused suggested letter without creating conflicts")
	for action in OLD_ACTIONS: check(ControlBindings.current[action]==legacy[action],"crowded legacy customization retained: "+action)
	check(InputMap.event_is_action(key(KEY_Z),"place_alarm") and not InputMap.event_is_action(key(KEY_G),"place_alarm") and InputMap.event_is_action(key(KEY_G),"move_forward"),"one physical key maps to the new action without stealing the old G action")
	Input.parse_input_event(key(KEY_Z));await get_tree().process_frame
	check(Input.is_action_pressed("place_alarm"),"migrated physical key actually presses the action")
	Input.parse_input_event(key(KEY_Z,false));await get_tree().process_frame
	check(not Input.is_action_pressed("place_alarm"),"matching release does not leave the action held")
	var complete := ControlBindings.current.duplicate();complete.place_alarm=KEY_H
	check(ControlBindings.apply(complete,PATH)==OK,"normal Apply saves the upgraded complete schema")
	ControlBindings.initialize(PATH)
	check(ControlBindings.current==complete and InputMap.event_is_action(key(KEY_H),"place_alarm") and not InputMap.event_is_action(key(KEY_Z),"place_alarm") and ControlBindings.label("place_alarm")=="H","saved custom action reloads exactly with its matching label")
	check(InputMap.action_has_event("place_alarm",pad),"keyboard migration and Apply retain independent pad events")
	var disk := FileAccess.get_file_as_string(PATH)
	var revision := ControlBindings.revision
	var alternate := complete.duplicate();alternate.place_alarm=KEY_I
	check(ControlBindings.apply(alternate,"user://alarm_bindings_absent_parent/controls.cfg")!=OK,"failed settings write reports its error")
	check(ControlBindings.current==complete and ControlBindings.revision==revision and FileAccess.get_file_as_string(PATH)==disk,"failed write publishes neither a new key nor a revision and leaves the saved file intact")
	for action in OLD_ACTIONS:
		var invalid := legacy.duplicate();invalid[action]=0
		write_fixture(BAD_PATH,invalid);ControlBindings.initialize(BAD_PATH)
		check(ControlBindings.current==ControlBindings.defaults,"invalid legacy field rejects the entire migration: "+action)
	var duplicate := legacy.duplicate();duplicate.move_back=duplicate.move_forward
	var missing := legacy.duplicate();missing.erase("reload")
	var unknown := legacy.duplicate();unknown.erase("reload");unknown.mystery=KEY_H
	var fractional := legacy.duplicate();fractional.reload=float(KEY_R)
	var reserved := legacy.duplicate();reserved.reload=KEY_ESCAPE
	var new_incomplete := complete.duplicate();new_incomplete.erase("reload")
	for invalid in [duplicate,missing,unknown,fractional,reserved,new_incomplete,[]]:
		write_fixture(BAD_PATH,invalid);ControlBindings.initialize(BAD_PATH)
		check(ControlBindings.current==ControlBindings.defaults,"malformed legacy or incomplete new schema falls back as a whole")
	for value in [0,KEY_ESCAPE,KEY_F11,-4,-5,KEY_UNKNOWN+1,complete.reload]:
		var invalid := complete.duplicate();invalid.place_alarm=value
		check(not ControlBindings.valid(invalid),"new schema preserves reserved-key and uniqueness checks")
	var extra := complete.duplicate();extra.mystery=KEY_Z
	check(not ControlBindings.valid(extra),"new schema still rejects unknown actions")
	ControlBindings.initialize(PATH)
	check(ControlBindings.current==complete and FileAccess.get_file_as_string(PATH)==disk,"invalid fixtures never replace the valid saved controls")
