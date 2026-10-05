extends Node
## Captures the actual SFX bus, not only logical play() calls. Isolated profile only.
func _ready() -> void:
	await get_tree().process_frame
	var out := OS.get_environment("BUNNY_EVIDENCE")
	if out.is_empty(): get_tree().quit(2);return
	DirAccess.make_dir_recursive_absolute(out)
	AudioDirector.music_player.stop()
	var bus := AudioServer.get_bus_index("SFX")
	var recorder := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus,recorder)
	var results := []
	for pan in [-1.0,1.0]:
		AudioDirector.clear_movement()
		AudioDirector._next_movement = 0 # Same source clip; only bearing differs.
		recorder.set_recording_active(true)
		AudioDirector.play_movement(1.0,pan)
		await get_tree().create_timer(.65).timeout
		recorder.set_recording_active(false)
		var sample := recorder.get_recording()
		var file := out.path_join("left.wav" if pan < 0 else "right.wav")
		results.append(sample.save_to_wav(file))
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	AudioDirector.shutdown_for_test()
	print("MOVEMENT_AUDIO_CAPTURE ",results)
	get_tree().quit(0 if results == [OK,OK] else 1)
