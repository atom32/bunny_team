extends Node

const RESULT_SCENE := preload("res://scenes/result/result.tscn")

var failures: Array[String] = []
var save_path := "user://result_return_test_%s.json" % OS.get_process_id()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	_cleanup_save()
	var legacy_profile := ProfileState.create_new()
	legacy_profile.inventory.capacity = 100.0
	for index in 10:
		check(
			legacy_profile.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "legacy_core_%02d" % index)),
			"legacy warehouse fixture accepts Salvage Core %d" % index
		)
	check(legacy_profile.inventory.get_used_capacity() > 95.0, "legacy warehouse reproduces the near-full real save state")
	check(SaveService.save_profile(legacy_profile, save_path) == OK, "legacy capacity profile saves")
	check(ProfileRuntime.load_profile(save_path), "ProfileRuntime loads the legacy profile")
	var profile := ProfileRuntime.get_profile()
	check(profile.inventory.capacity == ProfileState.DEFAULT_WAREHOUSE_CAPACITY, "ProfileRuntime upgrades legacy warehouse capacity without changing schema")

	var request := profile.create_sortie_request()
	var session := SortieRuntime.start_sortie(request, profile)
	check(session != null and session.inventory.capacity == ProfileState.DEFAULT_CARRIED_CAPACITY, "sortie keeps independent carried capacity after warehouse upgrade")
	if not session:
		_finish()
		return
	check(session.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "return_loot_a")), "sortie carries first recovered item")
	check(session.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "return_loot_b")), "sortie carries second recovered item")
	check(session.complete_extraction(), "sortie reaches COMPLETED through extraction")

	# Keep this coordinator outside current_scene so it survives Result -> Hanger.
	get_tree().current_scene = null
	var result := RESULT_SCENE.instantiate()
	result.finalize_save_path = save_path
	get_tree().root.add_child(result)
	get_tree().current_scene = result
	await get_tree().process_frame
	await get_tree().process_frame
	var button := result.find_child("ReturnButton", true, false) as Button
	check(button != null and not button.disabled and button.is_visible_in_tree(), "Result exposes an enabled Return to Hanger button")
	await _capture("01_result_ready")
	if button:
		button.pressed.emit()
	for _frame in 4:
		await get_tree().process_frame
	var current := get_tree().current_scene
	check(current != null and current.scene_file_path == "res://scenes/hanger/hanger.tscn", "Return button reaches the real Hanger scene")
	check(SortieRuntime.get_current_session() == null, "Return button clears SortieSession after commit and save")
	var restored := SaveService.load_profile(save_path, false)
	check(restored != null and restored.inventory.contains("return_loot_a") and restored.inventory.contains("return_loot_b"), "Return button persists recovered items before entering Hanger")
	await _capture("02_returned_hanger")
	_finish()


func _finish() -> void:
	_cleanup_save()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("RESULT_RETURN_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("RESULT_RETURN_TEST: %s" % failure)
		print("RESULT_RETURN_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _cleanup_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _capture(stage_name: String) -> void:
	var capture_dir := OS.get_environment("RESULT_CAPTURE_DIR")
	if capture_dir.is_empty():
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(capture_dir)
	check(directory_error == OK, "Result capture directory is available")
	if directory_error != OK:
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := capture_dir.path_join("%s.png" % stage_name)
	var save_error := image.save_png(path)
	check(save_error == OK, "Result frame %s is saved" % stage_name)
	if save_error == OK:
		print("RESULT_CAPTURE: %s" % path)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
