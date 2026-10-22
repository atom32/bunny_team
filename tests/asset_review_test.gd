extends Node
const REVIEW := preload("res://addons/neon_content/asset_review.gd")
const RUNTIME_SAFETY := preload("res://scripts/data/scene_safety.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var before := JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var session := SortieRuntime.get_current_session()
	var root := MeshInstance3D.new(); root.mesh = BoxMesh.new(); root.scale = Vector3.ONE * 2
	var packed := PackedScene.new(); packed.pack(root); root.free()
	var report: Dictionary = REVIEW.inspect(packed)
	check(report.pass and report.meshes == 1 and is_equal_approx(report.bounds.size[1], 2), "Root meshes and root scale are included in inspection")
	var script_root := StaticBody3D.new(); script_root.set_script(load("res://scripts/debug/workbench_target.gd"))
	var unsafe := PackedScene.new(); unsafe.pack(script_root); script_root.free()
	check(not REVIEW.inspect(unsafe).pass, "Arbitrary scene scripts are refused before instantiation")
	check(not RUNTIME_SAFETY.has_scripts(packed) and RUNTIME_SAFETY.has_scripts(unsafe), "Runtime and editor use the same script-free scene contract")
	var nested_root := Node3D.new()
	var nested_script := StaticBody3D.new(); nested_script.set_script(load("res://scripts/debug/workbench_target.gd"))
	nested_root.add_child(nested_script); nested_script.owner = nested_root
	var nested_scene := PackedScene.new(); nested_scene.pack(nested_root); nested_root.free()
	check(RUNTIME_SAFETY.has_scripts(nested_scene) and REVIEW.has_scripts(nested_scene), "Both guards reject scripted children without instantiating the candidate")
	var original := Animation.new(); var track := original.add_track(Animation.TYPE_METHOD)
	original.track_set_path(track, NodePath(".")); original.track_insert_key(track,0,{"method":&"queue_free","args":[]})
	var safe: Animation = REVIEW.safe_copy(original)
	check(not safe.track_is_enabled(track) and original.track_is_enabled(track), "Preview disables method events without changing the source")
	var bench := load("res://scenes/tools/asset_workbench.tscn").instantiate() as AssetWorkbench
	add_child(bench)
	await get_tree().process_frame
	var heights := []
	for folder in ["subjects", "subjects_female"]:
		var path: String = "res://resources/presentation/" + folder + "/campus_subject_profile.tres"
		var profile := load(path) as PresentationProfile
		check(profile.validate_profile() and bench.load_profile(path), "Adult profile model/map/semantic tracks validate: " + folder)
		check(bench.current_clip == &"Idle" and bench.clip_picker.get_item_text(bench.clip_picker.selected) == "Idle", "Preset starts at idle and keeps UI selection synchronized")
		check(bench.skeleton.get_bone_count() == 65 and profile.animation_library.get_animation_list().size() == 7, "Native adult rig and seven authored semantic clips")
		heights.append(bench.skeleton.get_bone_global_rest(bench.skeleton.find_bone("pelvis")).origin.y)
		var source := profile.animation_library.get_animation("Punch_Left")
		var original_loop := source.loop_mode
		check(bench.select_clip("Punch_Left"), "Explicit clip selection")
		bench.seek(.2); bench.set_paused(false); bench._process(.1); bench.set_paused(true)
		check(bench.animation_player.current_animation_position > .2 and source.loop_mode == original_loop, "Advance and preview looping leave the original one-shot clip untouched")
		bench._rest_pose(); bench._process(.1)
		check(bench.current_clip.is_empty(), "Rest pose clears playback safely")
		bench.set_paused(false); bench._process(.1); bench.set_paused(true)
		check(not bench.current_clip.is_empty() and bench.preview_time > 0, "Play resumes the selected clip after rest")
		bench.select_clip("Walk"); bench.show_bones = true; bench.seek(.3)
		check(bench.bone_mesh.mesh.get_surface_count() == 1, "Actual bone visualization")
		bench.set_camera(3)
		check(is_equal_approx(bench.get_node("Camera").size,19.5), "Production camera scale can be reviewed")
		var invalid := profile.duplicate() as PresentationProfile
		invalid.skeleton_path = NodePath("missing")
		check(not invalid.validate_profile(), "Bad skeleton path is rejected")
		invalid = profile.duplicate() as PresentationProfile
		invalid.animation_library = profile.animation_library.duplicate(true) as AnimationLibrary
		invalid.animation_library.add_animation("Unsafe", original)
		check(not invalid.validate_profile(), "Gameplay presentation profiles reject animation method events")
	check(not is_equal_approx(heights[0],heights[1]), "Male/female adaptations use different target proportions, not renamed copies")
	var wrapper := Node3D.new()
	var mesh := MeshInstance3D.new(); mesh.mesh = BoxMesh.new(); wrapper.add_child(mesh); mesh.owner = wrapper
	for index in 2:
		var player := AnimationPlayer.new(); player.name = "NamedPrimaryPlayer" if index == 0 else "SecondaryPlayer"
		var library := AnimationLibrary.new(); library.add_animation("Unsafe",original)
		player.add_animation_library("",library); player.autoplay = "Unsafe"
		wrapper.add_child(player); player.owner = wrapper
	var model := PackedScene.new(); model.pack(wrapper); wrapper.free()
	check(bench.load_model(model), "Script-free multi-player wrapper loads")
	check(bench.animation_player.name == "NamedPrimaryPlayer", "Imported player discovery uses native type, not a hardcoded node name")
	for player in bench.model.find_children("*","AnimationPlayer",true,false):
		check(player.autoplay.is_empty() and not player.get_animation("Unsafe").track_is_enabled(0), "Every embedded animation player has autoplay/events disabled")
	await get_tree().process_frame
	check(is_instance_valid(bench.model), "Secondary autoplay cannot execute queue_free on preview model")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict()) == before and SortieRuntime.get_current_session() == session, "Review never changes player profile or sortie")
	bench.queue_free(); await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("ASSET_REVIEW_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
