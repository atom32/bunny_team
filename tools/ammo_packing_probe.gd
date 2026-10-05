extends SceneTree
## Real Hideout controls -> normal deployment -> battle -> durable checkpoint.
## New isolated profile, first mission completed fixture; not a combat playthrough.
var checks := 0
var failures: Array[String] = []
var evidence := OS.get_environment("BUNNY_EVIDENCE")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless": quit(2);return
	DirAccess.make_dir_recursive_absolute(evidence)
	root.get_node("GameLanguage").set_language("zh_CN",false)
	var profile=root.get_node("ProfileRuntime").new_profile()
	profile.first_mission_completed=true
	root.get_node("GameState").presentation_enabled=true
	change_scene_to_file("res://scenes/presentation/slice/hideout.tscn")
	await _frames(90)
	current_scene.show_section("Operations")
	await _frames(10)
	var packing=current_scene.screen.get_node("MedicalPacking")
	var amount=packing.find_child("PackAmmo_ammo_556_standard",true,false)
	check(amount!=null,"normal Operations exposes ammo control")
	amount.value=37
	await _frames(5)
	check(profile.ammo_pack["ammo.556_standard"]==37,"control publishes exact durable preference")
	check(packing.get_global_rect().end.y<=540,"packing stays above risk warning/navigation")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join("operations.png"))
	var deploy=null
	for button in current_scene.screen.find_children("*","Button",true,false):
		if button.text=="CONFIRM DEPLOYMENT": deploy=button
	await _click(deploy)
	for frame in 900:
		await _frames(1)
		if current_scene and current_scene.scene_file_path.ends_with("battle.tscn") and not root.get_node("GameState").is_transitioning(): break
	check(current_scene.scene_file_path.ends_with("battle.tscn"),"normal deployment transition arrives in production battle")
	if current_scene.scene_file_path.ends_with("battle.tscn"):
		await _frames(60)
		var session=root.get_node("SortieRuntime").get_current_session()
		var total=0
		for item in session.inventory.get_items():
			if item.definition_id==&"ammo.556_standard": total+=item.quantity
		for state in session._weapon_runtime_states.values():
			if state.ammo_definition_id==&"ammo.556_standard": total+=state.magazine_ammo
		check(total==37,"production battle receives 37 total rounds, not original 120-stack")
		check(root.get_node("SortieRuntime").save_checkpoint()==OK,"actual battle/world checkpoint saves split deployment")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence.path_join("arrival.png"))
	FileAccess.open(evidence.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pass":failures.is_empty()}))
	root.get_node("FlowMenu").close()
	root.get_node("SortieRuntime").clear_session()
	if is_instance_valid(current_scene): current_scene.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("AMMO_PACKING_PRODUCTION: ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
func check(ok: bool,message: String) -> void:
	checks+=1
	print("PACKING_UI ","PASS " if ok else "FAIL ",message)
	if not ok: failures.append(message)

func _click(button) -> void:
	if button == null or button.disabled:
		check(false,"required UI button missing or disabled")
		return
	var parent = button.get_parent()
	while parent:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await _frames(4)
			break
		parent = parent.get_parent()
	var at = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
	await _frames(10)

func _frames(count: int) -> void:
	for tick in count:
		await process_frame
		if paused and root.get_node("FlowMenu").mode == "pause": root.get_node("FlowMenu").close()

