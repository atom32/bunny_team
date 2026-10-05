extends Node3D
## Targeted regression and screenshots. Run only with an isolated user:// profile.
var failures: Array[String] = []
var evidence := OS.get_environment("BUNNY_EVIDENCE")

func _ready() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS / " if ok else "FAIL / ", message)
	if not ok: failures.append(message)

func capture(label: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": return
	await get_tree().create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label + ".png"))

func _run() -> void:
	GameLanguage.set_language("en", false)
	if DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_FULLSCREEN
	await _test_hanger()
	await _test_failed_result()
	await _test_occlusion()
	await _test_crowd()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	print("FULLSCREEN_FIXES_PROBE: ", "PASS" if failures.is_empty() else "FAIL", " / ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_hanger() -> void:
	var profile := ProfileRuntime.new_profile()
	FirstMissionPreparation.equip_starter_kit(profile)
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	hub.show_section("Operations")
	check(_labels(hub.screen).contains("Defeat the PMC patrol"), "First briefing retains the actual patrol objective")
	profile.first_mission_completed = true
	hub.show_section("Operations")
	var text := _labels(hub.screen)
	check(text.contains("Old Town / Records Run") and text.contains("Recover district records") and text.contains("Survey the opposite courtyard"), "Later briefing names the deployed Streets mission and objectives")
	check(not text.contains("south") and text.contains("Two exits are assigned on arrival"), "Later briefing does not invent an extraction direction")
	await capture("01_streets_briefing_en")
	GameLanguage.set_language("zh_CN", false)
	check(_labels(hub.screen).contains("抵达后分配两个撤离点"), "Chinese briefing uses the same assignment semantics")
	await capture("02_streets_briefing_zh")
	hub.show_section("Hanger")
	var ui: HangerUI = hub.hanger.hanger_ui
	var panel: Control = ui.get("warehouse_panel")
	var toggle: Button = ui.get("warehouse_button")
	check(panel != null and not panel.visible, "Warehouse is closed on Hanger entry")
	await capture("03_hanger_character")
	if toggle:
		toggle.pressed.emit()
		check(panel.visible and ui.stash_grid.is_visible_in_tree(), "Warehouse button opens the real interactive grid")
		await capture("04_warehouse_open")
		toggle.pressed.emit()
		check(not panel.visible, "Back to character removes the covering panel")
		toggle.pressed.emit()
		hub.show_section("Operations")
		hub.show_section("Hanger")
		check(not panel.visible, "Returning from another bay restores the character preview")
	else: check(false, "Warehouse has a visible mode toggle")
	hub.queue_free()
	await get_tree().process_frame
	GameLanguage.set_language("en", false)

func _test_failed_result() -> void:
	var profile := ProfileRuntime.new_profile()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session.inventory.get_used_capacity() > 0, "Failure fixture actually carries equipment")
	session.fail()
	var outcome := SortieOutcomeService.create_outcome(session)
	var ui := ResultUI.new()
	ui.configure(outcome)
	add_child(ui)
	var text := _labels(ui)
	check(text.contains("RECOVERED CARGO") and text.contains("LOOT RECOVERED") and not text.contains("AT SIGNAL LOSS"), "Failure statistics accurately label recovered rather than carried cargo")
	check(outcome.inventory.get_items().is_empty(), "Failure still recovers nothing; no economy or save semantics changed")
	GameLanguage.set_language("zh_CN", false)
	await capture("05_failure_recovery_labels")
	ui.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()
	GameLanguage.set_language("en", false)

func _test_occlusion() -> void:
	var profile := ProfileRuntime.new_profile()
	SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	battle.set_process(false)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var office: Node3D = battle.find_child("FieldOffice", true, false)
	var canopy: MeshInstance3D = office.get_node("OfficeArt/Architecture/Canopy")
	check(canopy.is_in_group("camera_occluder"), "Official visual-only canopy participates in camera occlusion")
	var shapes_before := office.find_children("*", "CollisionShape3D", true, false).size()
	for side in [-1, 1]:
		# From the south-facing camera the rear lintel occludes just OUTSIDE its door.
		battle.player.global_position = office.to_global(Vector3(0,.08,-7.7 if side < 0 else 6.6))
		battle._process(1.0)
		await get_tree().physics_frame
		for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,battle.player,.05)
		var lintel: MeshInstance3D = office.get_node("OfficeArt/Architecture/Lintel" + str(side*7))
		check(lintel.transparency > .8, "Door lintel fades at entrance side " + str(side))
		if side < 0: check(office.get_node("ExitHeader").transparency > .8, "Rear trim header no longer covers the player's head")
		await capture("06_office_entrance_" + str(side))
	check(canopy.transparency > .8, "South canopy fades while it masks the actor")
	check(office.get_node("OfficeArt/Lights/EntryLightStrip").transparency > .8, "Canopy light strip fades along with the canopy")
	check(battle.camera.size < 21, "Production combat camera brings the character closer")
	battle.player.global_position += Vector3.RIGHT * 20
	battle._process(1.0)
	for step in 20: battle._camera_occlusion.update_occlusion(battle.camera,battle.player,.05)
	check(canopy.transparency < .01, "Canopy opacity restores outside the sightline")
	check(office.find_children("*", "CollisionShape3D", true, false).size() == shapes_before, "Visual fade never adds or removes gameplay collision")
	battle.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()

func _test_crowd() -> void:
	var world := Node3D.new()
	add_child(world)
	VisualFactory.add_world_environment(world, Color("202c37"), .65)
	VisualFactory.static_box(world,Vector3(70,.2,70),Vector3(0,-.1,0),Color("58626a"),"Floor")
	var region := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(-30,0,-30),Vector3(30,0,-30),Vector3(30,0,30),Vector3(-30,0,30)])
	mesh.add_polygon(PackedInt32Array([0,1,2,3]))
	region.navigation_mesh = mesh
	world.add_child(region)
	var profile := ProfileRuntime.new_profile()
	var player := load("res://scenes/player/player.tscn").instantiate() as PlayerController
	player.configure_loadout(profile.inventory,profile.loadout)
	world.add_child(player)
	player.set_physics_process(false)
	var crowd: Array[EnemyController] = []
	for index in 3:
		var enemy := load("res://scenes/enemies/enemy.tscn").instantiate() as EnemyController
		enemy.configure_from_definition(ContentDB.get_enemy_definition(&"prototype_basic_enemy"))
		enemy.position = Vector3(index*.002,.08,-18)
		world.add_child(enemy)
		enemy._strafe_direction = 1 # Same intended path reproduces converging patrols.
		crowd.append(enemy)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0,20,7)
	camera.look_at(Vector3(0,0,-8))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23
	camera.current = true
	var min_after_settle := INF
	for tick in 600:
		await get_tree().physics_frame
		if tick > 120:
			for a in crowd.size():
				for b in range(a+1,crowd.size()):
					min_after_settle = minf(min_after_settle,crowd[a].global_position.distance_to(crowd[b].global_position))
	check(min_after_settle >= .95, "PMC separation stays >= .95 m after settling; min = %.4f" % min_after_settle)
	check(crowd[0].global_position.distance_to(Vector3(0,.08,-18)) > 2, "Avoidance does not freeze pursuit")
	check(player.health < player.max_health, "Normal enemy attacks still reach and damage the player")
	check(crowd[0].collision_mask == 5 and crowd[0].movement_speed == 3.2 and crowd[0].attack_damage == 3.2, "Collision mask, movement tuning and damage stay unchanged")
	var stopped := crowd[0].global_position
	crowd[0].set_physics_process(false)
	for tick in 30: await get_tree().physics_frame
	check(crowd[0].global_position.is_equal_approx(stopped), "Paused/training-disabled enemy is not moved by an avoidance callback")
	await capture("07_separated_pmc")
	world.queue_free()
	await get_tree().process_frame

func _labels(root: Node) -> String:
	var result := ""
	for label in root.find_children("*", "Label", true, false): result += label.text + "\n"
	return result
