extends "res://tests/normal_start_test.gd"
## Controlled QA fixture: no deployment, victory, profile edits or focus changes.
var expected_timeouts: Array[String] = []
var expecting_timeout := false

func check(value: bool, message: String) -> void:
	# Capture the expected failure hook without emitting an expected engine ERROR.
	# Ordinary assertions still use the inherited failure list and exit status.
	if expecting_timeout and not value:
		checks += 1
		expected_timeouts.append(message)
		return
	super.check(value, message)

func _run() -> void:
	tree = get_tree()
	process_mode = Node.PROCESS_MODE_ALWAYS
	check(tree.current_scene == self, "fixture is the actual current scene")
	check(await _wait_scene(scene_file_path, 100), "matching current scene succeeds")
	check(not evidence.has("scene_wait_timeout"), "success does not record a timeout")
	var missing := "res://scenes/battle/battle.tscn"
	expecting_timeout = true
	var reached := await _wait_scene(missing, 1)
	expecting_timeout = false
	check(not reached and expected_timeouts == ["Timed out waiting for scene " + missing], "timeout invokes the failure hook, not just an early false return")
	check(evidence.scene_wait_timeout.wanted == missing and evidence.scene_wait_timeout.actual == scene_file_path, "timeout records the requested and actual scene")
	check(not tree.paused, "ordinary timeout does not alter pause state")
	# Explicit fixture pause, not an earned play route or automatic focus recovery.
	tree.paused = true
	expecting_timeout = true
	reached = await _wait_scene(missing, 1)
	expecting_timeout = false
	check(not reached and expected_timeouts.size() == 2 and evidence.scene_wait_timeout.paused, "paused timeout also reports failure and preserves its diagnostic state")
	check(tree.paused, "wait helper never force-resumes a paused game")
	tree.paused = false
	evidence["checks"] = checks
	evidence["failures"] = failures
	evidence["expected_failure_callbacks"] = expected_timeouts
	var file := FileAccess.open(out.path_join("normal_start_wait.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t")); file.close()
	AudioDirector.shutdown_for_test()
	print("NORMAL_START_WAIT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	tree.quit(0 if failures.is_empty() else 1)
