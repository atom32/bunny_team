extends SceneTree
## Subprocess regression for actual quit; run only against an isolated profile.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var save_service = load("res://scripts/systems/save_service.gd")
	var item_script = load("res://scripts/data/item_instance.gd")
	var profiles := root.get_node("ProfileRuntime")
	var runtime := root.get_node("SortieRuntime")
	var flow := root.get_node("FlowMenu")
	var game := root.get_node("GameState")
	game.presentation_enabled = false
	var profile = profiles.new_profile()
	flow.save_path = "user://exit_probe.json"
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "base"
	if mode == "base":
		profile.loadout.unequip(&"weapon_secondary")
		flow.request_leave("quit")
		var saved = save_service.load_profile(flow.save_path, false)
		_finish(saved != null and not saved.loadout.has_slot(&"weapon_secondary"))
	elif mode == "battle":
		var before = profile.to_dict()
		var session = runtime.start_sortie(profile.create_sortie_request(), profile)
		session.inventory.add_item(item_script.new(&"loot.salvage_core_01", 1, 100, "abandoned-loot"))
		flow._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		if flow.mode != "confirm":
			_finish(false)
			return
		for button in flow.find_children("*", "Button", true, false):
			if button.text == "ABANDON & QUIT":
				button.pressed.emit()
				break
		var saved = save_service.load_profile(flow.save_path, false)
		_finish(saved != null and saved.to_dict() == before and runtime.get_current_session() == null)
	elif mode == "transition":
		game.present_scene("res://scenes/presentation/slice/hideout.tscn", "EXIT DURING TRANSITION")
		await flow.request_leave("quit")
		_finish(not game.is_transitioning() and save_service.load_profile(flow.save_path, false) != null)
	elif mode == "recovery":
		var file := FileAccess.open("user://exit_corrupt.json", FileAccess.WRITE)
		file.store_string("{broken")
		file.close()
		profiles.initialize("user://exit_corrupt.json")
		flow._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		_finish(profiles.recovery_required and FileAccess.get_file_as_string("user://exit_corrupt.json") == "{broken")
	elif mode == "failure":
		flow.save_path = "user://not-a-directory/exit.json"
		flow.request_leave("quit")
		if flow.mode != "save_failure":
			_finish(false)
			return
		for button in flow.find_children("*", "Button", true, false):
			if button.text == "QUIT WITHOUT SAVING":
				button.pressed.emit()
				_finish(not flow.is_open())
				return
		_finish(false)

func _finish(success: bool) -> void:
	root.get_node("AudioDirector").shutdown_for_test()
	print("P0_EXIT_PROBE: " + ("PASS" if success else "FAIL"))
	if not success: quit(1)
