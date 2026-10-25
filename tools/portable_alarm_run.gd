extends "res://tools/water_market_run.gd"
## Earned cargo -> actual warehouse -> requested next-sortie pack -> G -> resume.
## Precise controller harness, NOT human playtime. No grants/teleports/AI disable.
var alarm_id := ""
const EXPECTED := "user://portable_alarm_earned_expected.json"

func _run() -> void:
	if "--pack-owned" in OS.get_cmdline_user_args():
		tree=get_tree();tree.current_scene=null
		var profile:=ProfileRuntime.get_profile()
		for item in profile.inventory.get_items():
			if item.definition_id==PortableAlarm.ITEM_ID:alarm_id=item.instance_id;break
		check(profile.successful_sorties==9 and profile.sortie_checkpoint.is_empty() and not alarm_id.is_empty(),"continue actual ninth-return base after ordinary retreat, without resetting saved input")
		if not failures.is_empty():finish();return
		tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
		if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
		await _click(_button("CONTINUE / BASE"))
		if await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):
			route_results.append({"method":"continued genuine ninth-return base; headless production checkbox callback"})
			await _pack_and_place()
		finish();return
	if "--continue-owned" in OS.get_cmdline_user_args():
		await _continue_owned();finish();return
	if "--read" not in OS.get_cmdline_user_args():
		await super._run()
		return
	tree=get_tree();tree.current_scene=null
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(EXPECTED))
	alarm_id=expected.id
	var profile:=ProfileRuntime.get_profile()
	check(profile.successful_sorties==_expected_returns(8) and profile.waterworks_memory=="water_public" and profile.pack_alarm,"independent reader retains genuine return and requested packing")
	check(profile.sortie_checkpoint.get("phase")=="battle" and alarm_id in profile.sortie_checkpoint.get("session",{}).get("initial_ids",[]),"actual unfinished sortie retains original at-risk ownership record")
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("RESUME SORTIE"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"normal BOOT resumes armed device world");finish();return
	battle=tree.current_scene
	var alarms:=PortableAlarm.live(battle)
	check(alarms.size()==1 and alarms[0].snapshot().id==alarm_id and alarms[0].snapshot().pulses==0,"actual armed device resumes same identity and delay without fresh item")
	check(battle.session.inventory.get_item(alarm_id)==null,"resume cannot refund spent item")
	if not failures.is_empty():finish();return
	var device:=alarms[0]
	var start_age:float=device.snapshot().elapsed
	var pulse_peak:=0
	for tick in 660:
		await tree.physics_frame
		if not is_instance_valid(device) or device.is_queued_for_deletion():break
		pulse_peak=maxi(pulse_peak,int(device.snapshot().pulses))
	check(pulse_peak==3 and PortableAlarm.live(battle).is_empty(),"normal remaining clock emits exactly scheduled three pulses then expires")
	check(SortieRuntime.save_checkpoint()==OK,"normal autosave supports expired consumed device state")
	evidence["resumed"]={"start_age":start_age,"pulse_peak":pulse_peak,"expired":PortableAlarm.live(battle).is_empty(),"profile":profile.to_dict()}
	finish()

func _continue_owned() -> void:
	# Preserve the failed harness checkpoint; retreat normally instead of reseeding.
	tree=get_tree();tree.current_scene=null
	var profile:=ProfileRuntime.get_profile()
	for item in profile.inventory.get_items():
		if item.definition_id==PortableAlarm.ITEM_ID:alarm_id=item.instance_id;break
	check(profile.successful_sorties==8 and not alarm_id.is_empty() and profile.sortie_checkpoint.get("phase")=="battle","continue original earned tool and actual failed harness sortie without resetting input")
	if not failures.is_empty():return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("RESUME SORTIE"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"resume preserved failed route checkpoint");return
	battle=tree.current_scene
	var retreat:ExtractionPoint=battle.area_root.get_node("Retreat")
	if not await walk(retreat.global_position):return
	check(use_point(retreat).success,"ordinary south retreat safely returns from mistaken unpacked sortie")
	if not await _wait_scene("res://scenes/result/result.tscn"):return
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return
	check(profile.successful_sorties==9 and not profile.blockade_cleared and profile.inventory.contains(alarm_id),"real extra retreat preserves earned box without completing checkpoint mission")
	route_results.append({"mission":"blockade_run","method":"ordinary retreat from original failed harness checkpoint","main_mission_completed":false})
	await _pack_and_place()

func deploy_next(wanted: StringName) -> bool:
	if not await super.deploy_next(wanted):return false
	var point:LootSpawnPoint=battle.area_root.get_node("DepotParts")
	if not await walk(point.global_position):return false
	release();await _frames(3)
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed;Input.parse_input_event(event);await _frames(3)
	var ui:Node=battle.get_node("SlicePresentation")
	check(is_instance_valid(ui.panel) and ui.container.get_parent()==point,"nearby E opens actual depot parts case")
	if not is_instance_valid(ui.panel):return false
	var before_weight:float=battle.session.inventory.current_weight
	for row in ui._cache_rows:
		if row.pickup.item_instance.definition_id!=PortableAlarm.ITEM_ID:continue
		alarm_id=row.pickup.item_instance.instance_id
		var scroll:Node=row.take.get_parent()
		while scroll and not scroll is ScrollContainer:scroll=scroll.get_parent()
		if scroll:scroll.ensure_control_visible(row.take)
		await _frames(3);await _click(row.take);break
	check(not alarm_id.is_empty() and battle.session.inventory.contains(alarm_id) and is_equal_approx(battle.session.inventory.current_weight,before_weight+1),"TAKE loads real one-kilo alarm identity alongside actual heavy core")
	await _capture("alarm_01_earned_take")
	await _click(ui.panel.find_child("CloseCache",true,false))
	return failures.is_empty()

func return_home(exit: ExtractionPoint,ending:=false) -> bool:
	if not await super.return_home(exit,ending):return false
	return await _pack_and_place()

func _pack_and_place() -> bool:
	var profile:=ProfileRuntime.get_profile()
	check(profile.inventory.contains(alarm_id) and not profile.pack_alarm and DeploymentPlan.build(profile,BlockadeStory.MISSION).tool_ids.is_empty(),"safe return retains exact earned alarm and never silently packs it")
	if not failures.is_empty():return false
	await _click(tree.current_scene.find_child("NavHanger",true,false))
	var choice:=tree.current_scene.find_child("PackAlarm",true,false) as CheckBox
	check(choice!=null and not choice.button_pressed,"existing supplies panel exposes optional real-tool checkbox")
	if not choice:return false
	var scroll:Node=choice.get_parent()
	while scroll and not scroll is ScrollContainer:scroll=scroll.get_parent()
	if scroll:scroll.ensure_control_visible(choice)
	await _frames(4)
	# Match the base harness: headless exercises production UI callbacks, not OS input.
	if DisplayServer.get_name()=="headless":
		choice.button_pressed=true;await _frames(3)
	else:
		for pressed in [true,false]:
			var event:=InputEventMouseButton.new();event.position=choice.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;tree.root.push_input(event);await _frames(3)
	check(profile.pack_alarm and DeploymentPlan.build(profile,BlockadeStory.MISSION).tool_ids==[alarm_id],"real checkbox atomically requests one exact owned device for next sortie")
	if not failures.is_empty():return false
	await _capture("alarm_02_requested_pack")
	# Ordinary main-story UI, deliberately not the parent water-specific deploy hook.
	check(FinaleStory.next_mission(profile)==BlockadeStory.MISSION,"earned water return selects blockade normally")
	check(SupplyService.transact("buy","ammo.556_standard",120).error==OK,"next sortie ammo bought with earned credits")
	await _click(tree.current_scene.find_child("NavOverview",true,false))
	await _click(_button("CONTINUE MAIN STORY"));await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"normal next-sortie transition");return false
	battle=tree.current_scene
	for tick in 30:await tree.physics_frame
	check(battle.session.inventory.contains(alarm_id) and alarm_id in battle.session.get_initial_carried_instance_ids(),"next deployment carries exact requested original identity at risk")
	release();await _frames(3)
	var count_before:int=battle.enemy_container.get_child_count()
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="place_alarm";event.pressed=pressed;Input.parse_input_event(event);await _frames(3)
	var alarms:=PortableAlarm.live(battle)
	check(alarms.size()==1 and alarms[0].snapshot().id==alarm_id and not battle.session.inventory.contains(alarm_id),"normal bound placement action consumes earned identity and creates real device")
	check(battle.enemy_container.get_child_count()==count_before,"device placement does not create extra enemies")
	if not failures.is_empty():return false
	for tick in 30:await tree.physics_frame
	check(alarms[0].snapshot().pulses==0 and SortieRuntime.save_checkpoint()==OK,"actual unfinished arming clock durably checkpoints before first pulse")
	var file:=FileAccess.open(EXPECTED,FileAccess.WRITE);file.store_string(JSON.stringify({"id":alarm_id,"armed":alarms[0].snapshot()}));file.close()
	evidence["earned_alarm"]={"id":alarm_id,"placed":alarms[0].snapshot(),"profile":profile.to_dict()}
	await _capture("alarm_03_placed_next_sortie")
	return failures.is_empty()

func finish() -> void:
	if "--read" not in OS.get_cmdline_user_args():check(route_results.size()==1 and not alarm_id.is_empty() and not ProfileRuntime.get_profile().sortie_checkpoint.is_empty(),"full earned return and real next-sortie tool deployment required")
	release();evidence["checks"]=checks;evidence["routes"]=route_results;evidence["failures"]=failures
	var file:=FileAccess.open(out.path_join("portable_alarm_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("PORTABLE_ALARM_RUN: %s (%d checks; ordinary synthetic controller, not human playtime)"%["PASS" if failures.is_empty() else "FAIL",checks]);tree.quit(0 if failures.is_empty() else 1)
