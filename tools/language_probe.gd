extends Node
var failures: Array[String] = []
var path := "user://language_probe_%s.cfg" % OS.get_process_id()

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if condition: print("PASS / ", message)
	else:
		failures.append(message)
		push_error(message)

func _capture(label: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/language_"+label+".png")

func _run() -> void:
	get_tree().current_scene = null
	get_window().size = Vector2i(1280,720)
	var original_locale := TranslationServer.get_locale()
	var original_saved := GameLanguage.has_saved_language
	_check(GameLanguage.set_language("zh_CN", true, path) == OK, "Language preference saves separately from profile")
	var preferences := ConfigFile.new()
	preferences.load(path)
	_check(preferences.get_value("language", "locale") == "zh_CN", "Saved language is Simplified Chinese")
	_check(GameLanguage.set_language("invalid", false) == ERR_INVALID_PARAMETER, "Unsupported language rejects without changing locale")
	_check(tr("START") == "开始游戏", "Native translation catalog translates menu controls")
	var missing := ""
	for character in "简体中文任务调查护甲撤离回收核心机库工坊":
		if not UIFactory.FONT.has_char(character.unicode_at(0)): missing += character
	_check(missing.is_empty(), "Bundled font contains Chinese gameplay glyphs")
	_check(GameLanguage.item_name("AR-556 Carbine [+10% DMG]").contains("突击步枪"), "Upgraded weapon names preserve localized base name")
	var profile := ProfileRuntime.new_profile()
	FirstMissionPreparation.equip_starter_kit(profile)
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hideout)
	await _capture("base_zh")
	hideout.show_section("Hanger")
	_check(hideout.hanger.hanger_ui.armor_detail.text.contains("防护"), "Armor tradeoff and numeric stats translate")
	_check(hideout.hanger.hanger_ui.warehouse_summary.text.contains("回收") or hideout.hanger.hanger_ui.warehouse_summary.text.contains("突击步枪"), "Warehouse summary translates item names and dynamic loadout")
	await _capture("hanger_zh")
	GameLanguage.set_language("en", false)
	_check(hideout.hanger.hanger_ui.armor_detail.text.contains("PROTECTION"), "Existing Hanger updates back to English")
	await _capture("hanger_en")
	GameLanguage.set_language("zh_CN", false)
	hideout.show_section("Operations")
	await _capture("operations_zh")
	profile.first_mission_completed = true
	hideout.show_section("Workshop")
	await _capture("workshop_zh")
	hideout.queue_free()
	await get_tree().process_frame
	profile.first_mission_completed = false
	var plan := DeploymentPlan.build(profile)
	SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area", &"first_mission", plan.ammo_ids), profile)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.player.set_physics_process(false)
	var tutorial = battle.get_node("FirstMissionDirector")
	tutorial.set_process(false)
	for locale in ["zh_CN", "en"]:
		GameLanguage.set_language(locale, false)
		for stage in range(10):
			tutorial.stage = stage
			tutorial._refresh_guide()
			tutorial._refresh_destination()
			await get_tree().process_frame
			_check(tutorial.guide.get_line_count() <= 3, "Tutorial fits three lines %s stage %d" % [locale,stage])
		tutorial.stage = tutorial.Stage.MOVE
		tutorial._refresh_guide()
		tutorial._refresh_destination()
		await _capture("battle_"+locale)
	GameLanguage.set_language("zh_CN", false)
	_check(battle.hud.weapon_label.text.contains("突击步枪"), "Active weapon HUD updates language without restarting battle")
	_check(battle.hud.ammo_label.text.contains("备用"), "Dynamic ammunition HUD translates")
	_check(battle.hud.objective_label.text.contains("巡逻兵"), "Objective names translate without changing IDs")
	var terminal = battle.area_root.find_child("PrototypeTerminal", true, false)
	tutorial.stage = tutorial.Stage.TERMINAL
	terminal.investigation_remaining = 4.5
	_check(terminal.get_interaction_prompt(battle.player, battle.session).contains("调查中"), "Investigation countdown is localized")
	var presentation = battle.get_node("SlicePresentation")
	var supplies = battle.area_root.find_child("PatrolSalvage",true,false)
	tutorial._set_loot_enabled(supplies,true)
	presentation.container = presentation.crates[supplies.get_instance_id()]
	battle.player.global_position = supplies.global_position
	presentation._show_loot()
	await _capture("loot_zh")
	GameLanguage.set_language("en", false)
	var english_loot := false
	for label in presentation.panel.find_children("*", "Label", true, false):
		if label.text.contains("Salvage Core"): english_loot = true
	_check(english_loot, "Open loot panel updates language without changing contents")
	GameLanguage.set_language("zh_CN", false)
	presentation._close_loot()
	tutorial.stage = tutorial.Stage.CHOICE
	tutorial._refresh_guide()
	tutorial._refresh_destination()
	tutorial.choice_buttons.show()
	await _capture("choice_zh")
	FlowMenu.show_language_settings(false)
	await _capture("settings_zh")
	FlowMenu.close()
	var session := SortieRuntime.get_current_session()
	session.fail()
	battle.queue_free()
	await get_tree().process_frame
	var result_scene = load("res://scenes/result/result.tscn").instantiate()
	add_child(result_scene)
	var result: ResultUI = result_scene.result_ui
	await _capture("result_zh")
	_check(result.mission_label.text.contains("归途信号"), "Debrief localizes mission name")
	GameLanguage.set_language("en", false)
	_check(result.mission_label.text.contains("Home Signal"), "Debrief returns to English live")
	result_scene.queue_free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
	GameLanguage.has_saved_language = original_saved
	GameLanguage.set_language(original_locale, false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("LANGUAGE_TEST failures=", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
