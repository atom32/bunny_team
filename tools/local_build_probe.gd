extends Node
## Only copied into explicitly LOCAL_ONLY builds. Never part of normal export scenes.
const SAVE := "user://local_build_checkpoint.json"
var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--local-qa")
	if index < 0:
		queue_free()
		return
	var mode := args[index+1] if index+1 < args.size() else "boot"
	var tree := get_tree()
	var content = tree.root.get_node("ContentDB")
	var profiles = tree.root.get_node("ProfileRuntime")
	var runtime = tree.root.get_node("SortieRuntime")
	var save_service = load("res://scripts/systems/save_service.gd")
	var profile_script = load("res://scripts/data/profile_state.gd")
	var deployment = load("res://scripts/systems/deployment_plan.gd")
	var checkpoint = load("res://scripts/systems/sortie_checkpoint.gd")
	check(not OS.has_feature("editor"), "must run an exported template, not the editor")
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://local_qa/expected.json"))
	var ids: Array = []
	for item in content.get_items(): ids.append(String(item.id))
	ids.sort()
	check(ids == expected.items, "every source-manifest item ID is packaged, without stale hardcoded counts")
	var conversations: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/narrative/campus_conversations.json"))
	check(conversations is Dictionary and conversations.size() == expected.narrative_count and FileAccess.get_sha256("res://resources/narrative/campus_conversations.json") == expected.narrative_sha256, "complete runtime narrative JSON matches source bytes")
	check(not ResourceLoader.exists("res://tools/audio_exit_probe.gd") and not FileAccess.file_exists("res://tools/verify_migration.py"), "developer tools are excluded")
	if mode == "inventory":
		var inventory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_executable_path().get_base_dir().path_join("runtime_inventory.json")))
		check(inventory.get("public_release_approved") == false,"inventory never grants missing publication rights")
		for path in inventory.get("resources",[]):
			check(ResourceLoader.exists(path),"selected resource is packaged: "+path)
			if ResourceLoader.exists(path): check(load(path) != null,"selected resource decodes in actual release: "+path)
		for path in inventory.get("plain_files",[]):check(FileAccess.file_exists(path),"plain data/notice is packaged: "+path)
		for path in inventory.get("verification_absent_resources",[]):check(not ResourceLoader.exists(path),"unused review/rollback model is not packaged: "+path)
	elif mode == "boot":
		await tree.create_timer(3.0).timeout
		check(is_instance_valid(tree.current_scene) and tree.current_scene.scene_file_path == "res://scenes/presentation/slice/boot.tscn", "actual default BOOT loads")
		for pressed in [true,false]:
			var event := InputEventAction.new()
			event.action = "ui_accept"; event.pressed = pressed
			Input.parse_input_event(event)
			await tree.process_frame
		check(is_instance_valid(tree.current_scene) and tree.current_scene.has_method("show_menu") and not tree.current_scene.opening, "opening accepts input and reaches the real menu")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var folder := OS.get_environment("BUNNY_EVIDENCE")
			check(not folder.is_empty() and tree.root.get_texture().get_image().save_png(folder.path_join("packaged_menu.png")) == OK, "exported native menu capture succeeds")
	elif mode in ["write","read"]:
		if is_instance_valid(tree.current_scene): tree.current_scene.free()
		tree.current_scene = null
		if mode == "write":
			var profile = profiles.new_profile()
			profile.first_mission_completed = true
			profile.credits = 1777
			check(deployment.deploy(profile,&"street_district",&"streets_recon",SAVE).error == OK, "packaged deployment persists")
		else:
			profiles.initialize(SAVE)
			check(not profiles.recovery_required and profiles.get_profile().credits == 1777, "second process reads actual saved profile")
			check(runtime.resume_saved(SAVE) == OK, "second process resumes saved session")
		var battle = load("res://scenes/battle/battle.tscn").instantiate()
		battle.result_transition_enabled = false
		tree.root.add_child(battle)
		tree.current_scene = battle
		await tree.process_frame
		await tree.physics_frame
		tree.paused = true
		if mode == "write":
			battle.player.health = 137.0
			check(runtime.save_checkpoint() == OK, "packaged checkpoint saves real world")
		else:
			check(is_equal_approx(battle.player.health,137.0), "packaged checkpoint restores actual player health")
			check(checkpoint.validate_world(checkpoint.capture_world(battle),battle), "restored packaged world is valid")
			if "--expect-legacy-campus" in args:
				check(battle.area_root.get_meta("map_revision")==3 and not battle.area_root.has_node("RecordsIsolator"),"actual old campus save retains its original solid layout without new cabinet")
				check(not battle.area_root.get_node("StreetTerminal/RecordsAlarm").snapshot().has("isolation_remaining"),"re-saving old suspended campus cannot introduce cabinet on next load")
				check(runtime.save_checkpoint()==OK,"legacy-campus resume can be durably saved again")
		tree.paused = false
	elif mode == "legacy":
		var old: Dictionary = profile_script.create_new().to_dict()
		old.erase("sortie_checkpoint")
		var file := FileAccess.open("user://legacy_profile.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema_version":2,"profile":old}));file.close()
		var loaded = save_service.load_profile("user://legacy_profile.json",false)
		check(loaded != null and loaded.validate() and loaded.sortie_checkpoint.is_empty(), "packaged runtime migrates a schema-2 fixture")
	elif mode in ["campus_exit_gate", "campus_exit_gate_earned", "maintenance_shared", "shared_earned", "recovered_carrier", "carrier_earned", "carrier_use", "recovered_arms", "recovered_earned", "debrief_guidance", "relay_diversion", "relay_earned", "campus_packing", "packing_earned", "normal_start_wait", "medical_runners", "medical_intercept", "campus_handoff", "water_market", "market_earned", "rescue_moment", "rescue_result", "rescue_earned", "maintenance_art", "maintenance_journey", "finale", "homecoming", "story_finish", "maintenance", "maintenance_route", "seat", "seat_return", "campus_q01", "campus_q02", "campus_chapter", "fitting", "first_sortie", "normal_start", "campus", "melee", "waterworks", "water_delivery", "bucket_moment", "bucket_result", "bucket_route", "campus_power", "water_return", "water_public", "water_tanker", "training", "blockade_journey", "blockade_earned", "blockade", "blockade_route", "blockade_readability", "isolation", "isolation_route", "cutaway"]:
		if is_instance_valid(tree.current_scene): tree.current_scene.free()
		tree.current_scene = null
		var path: String = {"campus_exit_gate":"campus_exit_gate", "campus_exit_gate_earned":"campus_exit_gate_earned", "maintenance_shared":"maintenance_shared", "shared_earned":"shared_earned", "recovered_carrier":"recovered_carrier", "carrier_earned":"carrier_earned", "carrier_use":"carrier_use", "recovered_arms":"recovered_arms", "recovered_earned":"recovered_earned", "debrief_guidance":"debrief_guidance", "relay_diversion":"relay_diversion", "relay_earned":"relay_earned", "campus_packing":"campus_packing", "packing_earned":"packing_earned", "normal_start_wait":"normal_start_wait", "medical_runners":"medical_runners", "medical_intercept":"medical_intercept", "campus_handoff":"campus_handoff", "water_market":"water_market", "market_earned":"market_earned", "rescue_moment":"rescue_moment", "rescue_result":"rescue_result", "rescue_earned":"rescue_earned", "maintenance_art":"maintenance_art", "maintenance_journey":"maintenance_journey", "finale":"finale", "homecoming":"homecoming", "story_finish":"story_finish", "maintenance":"maintenance", "maintenance_route":"maintenance_route", "seat":"seat", "seat_return":"seat_return", "campus_q01":"campus_q01", "campus_q02":"campus_q02", "campus_chapter":"campus_chapter", "fitting":"fitting", "first_sortie":"first_sortie", "normal_start":"normal_start", "campus":"campus_route", "melee":"melee", "waterworks":"waterworks", "water_delivery":"water_delivery", "bucket_moment":"bucket_moment", "bucket_result":"bucket_result", "bucket_route":"bucket_route", "campus_power":"campus_power", "water_return":"water_return", "water_public":"water_route", "water_tanker":"water_route", "training":"training", "blockade_journey":"blockade_journey", "blockade_earned":"blockade_earned", "blockade":"blockade", "blockade_route":"blockade_route", "blockade_readability":"blockade_readability", "isolation":"isolation", "isolation_route":"isolation_route", "cutaway":"cutaway"}[mode]
		var route = load("res://local_qa/" + path + ".tscn").instantiate()
		tree.root.add_child(route)
		tree.current_scene = route
		return
	else:
		check(false,"unknown local build probe mode")
	print("LOCAL_BUILD_PROBE: ","PASS" if failures.is_empty() else "FAIL"," / ",mode," / executable=",OS.get_executable_path())
	tree.quit(0 if failures.is_empty() else 1)

