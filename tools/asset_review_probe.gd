extends Node
## Automated visual evidence only; run in an isolated imported snapshot.
var evidence := OS.get_environment("BUNNY_ASSET_EVIDENCE")
func _ready() -> void: _run.call_deferred()
func _capture(name: String) -> void:
	await get_tree().process_frame; await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(evidence + "/" + name + ".png") == OK)
func _run() -> void:
	assert(not evidence.is_empty() and DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(evidence)
	var bench: AssetWorkbench = load("res://scenes/tools/asset_workbench.tscn").instantiate()
	add_child(bench)
	var reports := {}
	for folder in ["subjects","subjects_female"]:
		assert(bench.load_profile("res://resources/presentation/" + folder + "/campus_subject_profile.tres"))
		var clips := {}
		for clip in ["Idle","Walk","Run","Punch_Left","Hit_Chest","Death","Interact"]:
			assert(bench.select_clip(clip))
			bench._set_loop(false)
			var animation := bench.animation_player.get_animation(clip)
			clips[clip] = bench.REVIEW.clip_report(animation,clip)
			for sample in [0.0,.25,.5,.75,1.0]:
				bench.seek(animation.length * sample)
				await _capture(folder + "_" + clip + "_" + str(int(sample*100)))
		for camera in [1,2,3]:
			bench.select_clip("Idle"); bench.seek(.5); bench.set_camera(camera)
			await _capture(folder + "_camera_" + str(camera))
		reports[folder] = {"model":bench.report,"clips":clips,"profile":String(bench.profile.id)}
	bench.free()
	var weapon: WeaponWorkbench = load("res://scenes/tools/weapon_workbench.tscn").instantiate()
	add_child(weapon); weapon.set_process(false); weapon.set_markers(false)
	await get_tree().process_frame
	for state in ["Idle","Walk","Run","Reload","Dodge"]:
		weapon.motion = 1 if state == "Walk" else (2 if state == "Run" else 0)
		if state == "Reload": weapon.reload_preview()
		if state == "Dodge": weapon.dodge_preview()
		for frame in 15:
			weapon.advance_preview(1.0/60.0); await get_tree().process_frame
		await _capture("heroine_" + state)
		for frame in 150: weapon.advance_preview(1.0/60.0)
	weapon.free(); await get_tree().process_frame
	var file := FileAccess.open(evidence + "/asset_review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(reports,"\t")); file.close()
	get_tree().root.get_node("AudioDirector").shutdown_for_test()
	print("ASSET_REVIEW_PROBE: PASS / automated frame captures, not manual acceptance")
	get_tree().quit()
