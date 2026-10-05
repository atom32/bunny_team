extends SceneTree
## Rendered base/result UI and cross-process campaign flow. Explicit fixtures:
## first mission done, one prior recon, controlled loot, objective APIs rather
## than a simulated full combat sortie. No production saves or actor art edited.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var failures: Array[String] = []
var checks := 0
var service
var supply
var save
var items

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	service = load("res://scripts/systems/campaign_service.gd")
	supply = load("res://scripts/systems/supply_service.gd")
	save = load("res://scripts/systems/save_service.gd")
	items = load("res://scripts/data/item_instance.gd")
	root.get_node("GameLanguage").set_language("zh_CN",false)
	root.get_node("GameState").presentation_enabled = true
	if "--read" in OS.get_cmdline_user_args(): await _read()
	else: await _write()
	FileAccess.open(evidence.path_join("read_result.json" if "--read" in OS.get_cmdline_user_args() else "write_result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pass":failures.is_empty(),"method":"Rendered UI mouse events and actual result/claim/craft/save services. Explicit first-mission/prior-sortie/loot fixtures; not manual play or a full combat route."},"\t"))
	for failure in failures: push_error("CAMPAIGN_UI: " + failure)
	root.get_node("FlowMenu").close()
	root.get_node("SortieRuntime").clear_session()
	if is_instance_valid(current_scene): current_scene.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("CAMPAIGN_GRAPHICAL_ROUTE: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func _write() -> void:
	var profile = root.get_node("ProfileRuntime").new_profile()
	profile.first_mission_completed = true
	profile.campaign.progress = 1
	change_scene_to_file("res://scenes/presentation/slice/hideout.tscn")
	await _wait_hub()
	await _capture("01_partial_zh")
	var runtime = root.get_node("SortieRuntime")
	var session = runtime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon"),profile)
	session.record_objective_interaction(&"streets_terminal")
	session.record_objective_reached(&"streets_survey")
	check(session.complete_extraction(),"fixture sortie completes actual objective/extraction API")
	change_scene_to_file("res://scenes/result/result.tscn")
	await _frames(60)
	check(profile.campaign.progress == 1,"debrief preview does not settle before Return")
	check(current_scene.result_ui.find_child("CampaignPreview",true,false) != null,"real Result exposes campaign preview")
	await _capture("02_debrief_zh")
	await _click(current_scene.result_ui.return_button)
	await _wait_hub()
	check(profile.campaign.progress == 2 and runtime.get_current_session() == null,"Return atomically settles recon and opens production Hideout")
	await _click(current_scene.screen.get_node("CampaignPanel").find_child("ClaimContract",true,false))
	check(profile.campaign.stage == 1,"actual claim button starts delivery contract")
	await _capture("03_delivery_zh")
	root.get_node("GameLanguage").set_language("en",false)
	await _frames(5)
	await _capture("03_delivery_en")
	root.get_node("GameLanguage").set_language("zh_CN",false)
	# Controlled loot fixture goes through real carried inventory and result,
	# rather than directly granting a facility or bypassing material consumption.
	session = runtime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon"),profile)
	for row in [[&"material.fabric",6],[&"material.parts",2],[&"medical.field_dressing",1],[&"medical.field_dressing",1]]:
		check(session.inventory.add_item(items.new(row[0],row[1])),"controlled material/medicine enters actual carried inventory")
	session.complete_extraction()
	change_scene_to_file("res://scenes/result/result.tscn")
	await _frames(45)
	await _click(current_scene.result_ui.return_button)
	await _wait_hub()
	check(supply.count(profile,&"material.fabric") == 6,"extracted materials arrive in actual warehouse")
	await _click(current_scene.screen.get_node("CampaignPanel").find_child("ClaimContract",true,false))
	check(profile.campaign.stage == 2 and supply.count(profile,&"material.fabric") == 2 and supply.count(profile,&"material.parts") == 0,"delivery consumes exact materials and enables clinic")
	current_scene.show_section("Workshop")
	await _frames(45)
	var panel = current_scene.screen.get_node("SupplyPanel")
	var tabs = panel.find_child("*",true,false)
	for child in panel.find_children("*","TabContainer",true,false): tabs = child; break
	tabs.current_tab = 2
	await _frames(5)
	var recipe_button = null
	for label in panel.find_children("*","Label",true,false):
		if label.text.begins_with(TranslationServer.translate("CLINIC / ASSEMBLE MEDKIT")):
			for child in label.get_parent().get_children():
				if child is Button: recipe_button = child
	check(recipe_button != null,"clinic appears in ordinary Workshop recipe list")
	if recipe_button:
		var parent = recipe_button.get_parent()
		while parent:
			if parent is ScrollContainer:
				parent.ensure_control_visible(recipe_button)
				break
			parent = parent.get_parent()
		await _frames(5)
		await _capture("04_clinic_recipe_ready_zh")
	await _click(recipe_button)
	check(supply.count(profile,&"medical.medkit") == 1 and supply.count(profile,&"medical.field_dressing") == 0,"ordinary recipe button crafts usable medkit and spends doses")
	await _capture("04_clinic_recipe_zh")
	check(save.save_profile(profile) == OK,"campaign and crafted inventory saved together")
	FileAccess.open("user://campaign_graph_expected.json",FileAccess.WRITE).store_string(JSON.stringify(profile.to_dict()))

func _read() -> void:
	check(root.get_node("ProfileRuntime").load_profile(),"second process loads real campaign file")
	var profile = root.get_node("ProfileRuntime").get_profile()
	var expected = load("res://scripts/data/profile_state.gd").from_dict(JSON.parse_string(FileAccess.get_file_as_string("user://campaign_graph_expected.json")))
	check(expected != null and expected.to_dict() == profile.to_dict(),"second process retains exact IDs, credits, progress and consumed materials")
	check(profile.campaign.stage == 2 and service.unlocked(profile,"clinic") and not service.unlocked(profile,"workbench"),"only actually earned facility remains online")
	check(supply.count(profile,&"medical.medkit") == 1,"crafted medical item persists, no duplicate reward")
	change_scene_to_file("res://scenes/presentation/slice/hideout.tscn")
	await _wait_hub()
	await _capture("05_restarted_zh")
	check(current_scene.screen.get_node("CampaignPanel").find_child("ClaimContract",true,false).disabled,"next unfunded contract still cannot be claimed after restart")

func _wait_hub() -> void:
	for tick in 240:
		await _frames(1)
		if is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("hideout.tscn") and not root.get_node("GameState").is_transitioning():
			await _frames(45)
			await _click(current_scene.screen.get_node("ContractsToggle"))
			return
	check(false,"Hideout scene transition timed out")

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

func _capture(name: String) -> void:
	var contracts = current_scene.find_child("CampaignPanel",true,false)
	if contracts and not contracts.visible:
		await _click(current_scene.screen.get_node("ContractsToggle"))
	await _frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
	var panel = current_scene.find_child("CampaignPanel",true,false)
	if panel:
		check(panel.get_global_rect().end.y <= 634,"contract content fits above production navigation bar")
		for label in panel.find_children("*","Label",true,false):
			check(label.get_global_rect().end.x <= 844 and label.get_global_rect().end.y <= 634,"contract label remains inside its panel")

func check(condition: bool, message: String) -> void:
	checks += 1
	print("CAMPAIGN_UI ","PASS: " if condition else "FAIL: ",message)
	if not condition: failures.append(message)
