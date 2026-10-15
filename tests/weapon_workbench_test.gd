extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var before := JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var session := SortieRuntime.get_current_session()
	var bench := load("res://scenes/tools/weapon_workbench.tscn").instantiate() as WeaponWorkbench
	add_child(bench)
	for frame in 6: await get_tree().process_frame
	check(bench.actor.preview_mode and not bench.actor.is_physics_processing(), "Workbench actor is a collision-free presentation preview")
	for index in bench.IDS.size():
		check(bench.select_weapon(index), "Every production weapon can be previewed")
		for frame in 6: await get_tree().process_frame
		check(bench.actor.combat_rig.has_weapon(), "Production grip/muzzle rig remains mounted")
		check(bench.definition != ContentDB.get_weapon(bench.IDS[index]), "Editable definition is a local copy")
		var original := ContentDB.get_weapon(bench.IDS[index]).damage
		bench.damage.value=original+1
		check(bench.definition.damage == original+1 and ContentDB.get_weapon(bench.IDS[index]).damage == original, "UI tuning cannot mutate production definitions")
		check(bench.reload_preview(), "Existing reload rig plays in the preview")
		for frame in 200: bench.advance_preview(1.0/60.0)
	check(bench.select_weapon(2), "Select assault rifle for actual hit-path check")
	for frame in 20: await get_tree().physics_frame
	check(bench.fire(), "Preview invokes existing firing path")
	check(bench.get_node("Target").hits > 0, "Real hitscan reaches workbench-local target")
	bench.dodge_preview()
	bench.advance_preview(.05)
	check(bench.actor._dodge_time > 0, "Existing dodge locomotion can be previewed")
	bench.set_paused(true)
	var clock := bench.elapsed
	bench.advance_preview(.25)
	check(is_equal_approx(clock, bench.elapsed) and not bench.fire(), "Pause freezes the preview clock and blocks firing")
	bench.set_paused(false)
	bench.set_camera(3)
	check(is_equal_approx(bench.get_node("Camera").size, 19.5), "Actual production battle camera scale is available")
	bench.set_markers(false)
	for dot in bench.actor.find_children("WorkbenchMarker", "MeshInstance3D", true, false): check(not dot.visible, "Marker toggle affects only preview dots")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict()) == before and SortieRuntime.get_current_session() == session, "All preview actions leave profile and sortie untouched")
	bench.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("WEAPON_WORKBENCH_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
