extends SceneTree
## Real teardown probe. Deliberately never calls shutdown_for_test().
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio := root.get_node("AudioDirector")
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "music"
	if mode not in ["music", "effects", "paused"]:
		push_error("Unknown audio teardown mode")
		quit(1)
		return
	audio.set_music_context(&"battle") # Quit during a real music transition.
	if mode != "music":
		for index in 24:
			audio.play_sfx(&"explosion" if index % 2 == 0 else &"reload")
			audio.play_movement(.7, -1.0 if index % 2 == 0 else 1.0)
	await create_timer(.1, true).timeout
	if not audio.music_player.playing:
		push_error("Audio exit fixture did not actually start music")
		quit(1)
		return
	if mode == "paused": paused = true
	print("AUDIO_EXIT_PROBE: PASS / mode=", mode, " / production _exit_tree cleanup only")
	quit(0)
