extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var director := root.get_node("AudioDirector")
	await process_frame
	for index in 20:
		director.play_sfx(&"impact")
	var playbacks: Array[WeakRef] = []
	for player in director.get_children():
		if player is AudioStreamPlayer and player.has_stream_playback():
			playbacks.append(weakref(player.get_stream_playback()))
	# Reproduce a long test frame without changing game timing or assertions.
	OS.delay_msec(250)
	var start := Time.get_ticks_msec()
	director.shutdown_for_test()
	var drain_ms := Time.get_ticks_msec() - start
	await create_timer(0.2).timeout
	var timer_wall_ms := Time.get_ticks_msec() - start - drain_ms
	# Allow the AudioServer's main-thread deletion queue to be serviced.
	await process_frame
	await process_frame
	var released := true
	for playback in playbacks:
		released = released and playback.get_ref() == null
	var checks := {
		"observed_music_and_full_sfx_pool": playbacks.size() == 21,
		"playback_resources_released": released,
		"music_reference_cleared": director.music_player == null,
		"sfx_pool_cleared": director._sfx_players.is_empty(),
	}
	var cue_before = director.last_cue
	director.play_sfx(&"ar_fire")
	director.set_music_context(&"battle")
	director.shutdown_for_test()
	checks["late_test_callbacks_cannot_restart_audio"] = director.last_cue == cue_before
	checks["shutdown_is_idempotent"] = director.get_child_count() == 0
	print("AUDIO_SHUTDOWN_PROBE: ", JSON.stringify({"checks": checks, "driver": AudioServer.get_driver_name(), "drain_ms": drain_ms, "timer_wall_ms": timer_wall_ms}))
	quit(0 if not checks.values().has(false) else 1)
