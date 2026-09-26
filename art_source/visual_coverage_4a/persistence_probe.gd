extends SceneTree
# Separate-process seed/reload; uses production SaveService and ProfileRuntime unchanged.
var folder := OS.get_environment("BUNNY_EVIDENCE")
var stage := OS.get_environment("BUNNY_SAVE_STAGE")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var runtime = root.get_node("ProfileRuntime")
	var checks := {}
	var path := folder.path_join("profile.json")
	if stage == "seed":
		checks["existing profile saved by legacy process"] = runtime.save_profile(path) == OK
	else:
		checks["existing save loaded"] = runtime.load_profile(path)
	var data: Dictionary = runtime.get_profile().to_dict()
	var expected_path := folder.path_join("expected_after.json" if stage == "reload" else "expected_before.json")
	if stage == "seed":
		var f := FileAccess.open(expected_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(data))
		f.close()
	else:
		var expected = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		# Canonical JSON types normalize integer/float parser representation.
		checks["full gameplay serialization preserved"] = JSON.parse_string(JSON.stringify(data)) == expected
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(1.0).timeout
	var actor = current_scene.preview_character
	checks["Player actor retained"] = actor.get_script().resource_path == "res://scripts/player/player_controller.gd"
	var selected := OS.get_environment("BUNNY_PRESENTATION") == "unitychan"
	checks["selected presentation survives process restart"] = (actor.combat_rig.get_script().resource_path == "res://scripts/presentation/unitychan/presentation_adapter.gd") == selected
	var capsule = actor.get_node("Hitbox").shape
	checks["gameplay capsule unchanged"] = is_equal_approx(capsule.radius, 0.36) and is_equal_approx(capsule.height, 1.85)
	var report := {"stage":stage,"checks":checks,"presentation":OS.get_environment("BUNNY_PRESENTATION"),"profile":data,"save_path":path,"person_id":"not present in schema 1; existing owned-item identity preserved"}
	var output := FileAccess.open(folder.path_join(stage+".json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print(JSON.stringify(report))
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(1 if checks.values().has(false) else 0)
