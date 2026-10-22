extends "res://tools/water_market_run.gd"
## Ordinary earned market run, live combat, actual cargo return and base UI.
## No profile fixtures, grants, seed override, relocation, AI disable or unpause.
var carrier := {}
var rebuilt_id := ""

func _run() -> void:
	evidence["profile_before"]=ProfileRuntime.get_profile().to_dict()
	if "--save-owned-choice" in OS.get_cmdline_user_args():
		tree=get_tree();tree.current_scene=null
		var owned: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://carrier_run_expected.json"))
		carrier=owned.carrier;rebuilt_id=owned.rebuilt_id
		check(ProfileRuntime.get_profile().inventory.contains(rebuilt_id) and not ProfileRuntime.get_profile().inventory.contains(carrier.instance_id),"continue the same genuinely earned and converted pack; no reset or new frame")
		if not failures.is_empty():finish();return
		tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
		if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
		await _click(_button("CONTINUE / BASE"))
		if await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):await _equip_owned()
		finish();return
	if "--read" not in OS.get_cmdline_user_args():
		await super._run();return
	tree=get_tree();tree.current_scene=null
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://carrier_run_expected.json"))
	var before:=ProfileRuntime.get_profile().to_dict()
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):finish();return
	var profile:=ProfileRuntime.get_profile()
	var after:=profile.to_dict()
	var wanted:=ProfileState.from_dict(expected.profile).to_dict()
	for data in [before,after,wanted]:data.erase("stash_layout")
	check(before==after and after==wanted,"ordinary independent BOOT changes no gameplay field and retains exact recovered conversion")
	check(profile.inventory.contains(expected.rebuilt_id) and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)==expected.rebuilt_id,"independent BOOT retains exact equipped rebuilt pack")
	rebuilt_id=expected.rebuilt_id;carrier=expected.carrier
	evidence["profile_after"]=profile.to_dict();finish()

func deploy_next(wanted: StringName) -> bool:
	if not await super.deploy_next(wanted):return false
	var point:LootSpawnPoint=battle.area_root.get_node("DepotParts")
	if not await walk(point.global_position):return false
	release();await _frames()
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed;Input.parse_input_event(event)
		await _frames()
	var ui:Node=battle.get_node("SlicePresentation")
	check(is_instance_valid(ui.panel) and ui.container.get_parent()==point,"real nearby E opens workbench supply case")
	if not is_instance_valid(ui.panel):return false
	var contents:=[]
	for row in ui._cache_rows:
		contents.append(row.pickup.item_instance.to_dict())
		if row.pickup.item_instance.definition_id!=RecoveredCarrier.FRAME:continue
		carrier=row.pickup.item_instance.to_dict()
		await _scroll_to(row.take);await _click(row.take);break
	check(not carrier.is_empty() and battle.session.inventory.contains(carrier.instance_id) and not ProfileRuntime.get_profile().inventory.contains(carrier.instance_id),"TAKE puts exact frame in field cargo, not warehouse")
	evidence["actual_workbench_contents"]=contents
	await _capture("carrier_01_actual_take")
	await _click(ui.panel.find_child("CloseCache",true,false))
	return failures.is_empty()

func _scroll_to(control: Control) -> void:
	var node:=control.get_parent()
	while node and not node is ScrollContainer:node=node.get_parent()
	if node:node.ensure_control_visible(control)
	await _frames(4)

func return_home(exit: ExtractionPoint,ending:=false) -> bool:
	if not await super.return_home(exit,ending):return false
	var profile:=ProfileRuntime.get_profile()
	check(not carrier.is_empty() and profile.inventory.contains(carrier.instance_id) and profile.inventory.get_item(carrier.instance_id).to_dict()==carrier,"real safe return banks exact recovered frame")
	if not failures.is_empty():return false
	var recipe: String="carrier_freight" if "--freight" in OS.get_cmdline_user_args() else "carrier_courier"
	var output: StringName=RecoveredCarrier.RECIPES[recipe].output
	var original_ids:=[]
	for item in profile.inventory.get_items():original_ids.append(item.instance_id)
	var wallet:=profile.credits
	await _click(tree.current_scene.find_child("NavWorkshop",true,false))
	await _click(tree.current_scene.find_child("Contact_su_mi",true,false))
	var button:=tree.current_scene.find_child("Exchange_"+recipe,true,false) as Button
	check(button!=null and not button.disabled,"ordinary Su Mi workshop offers the earned frame choice")
	if button==null:return false
	await _scroll_to(button);await _capture("carrier_02_workshop_choice");await _click(button);await _frames()
	for item in profile.inventory.get_items():
		if item.definition_id==output and item.instance_id not in original_ids:rebuilt_id=item.instance_id
	check(not rebuilt_id.is_empty() and not profile.inventory.contains(carrier.instance_id) and profile.credits==wallet,"actual choice consumes the recovered frame once, creates one chosen pack, no material/credit bill")
	if not failures.is_empty():return false
	return await _equip_owned()

func _equip_owned() -> bool:
	var profile:=ProfileRuntime.get_profile()
	await _click(tree.current_scene.find_child("NavHanger",true,false))
	var ui:HangerUI=tree.current_scene.hanger.hanger_ui
	var tile:StashTile
	for child in ui.stash_grid.get_children():
		if child is StashTile and child.instance_id==rebuilt_id:tile=child;break
	check(tile!=null,"normal warehouse displays the actual rebuilt pack")
	if tile==null:return false
	await _scroll_to(tile)
	var event:=InputEventMouseButton.new();event.position=tile.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.double_click=true
	if DisplayServer.get_name()=="headless":tile._gui_input(event)
	else:tree.root.push_input(event)
	await _frames()
	event=InputEventMouseButton.new();event.position=ui.backpack_option.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false;tree.root.push_input(event);await _frames()
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)==rebuilt_id and ui.backpack_option.get_item_metadata(ui.backpack_option.selected)==rebuilt_id,"actual warehouse double-click equips exact rebuilt pack and refreshes visible slot")
	check(profile.get_carried_capacity()==(47.0 if profile.inventory.get_item(rebuilt_id).definition_id==RecoveredCarrier.FREIGHT else 27.0),"earned equipped pack changes actual deployment capacity")
	await _capture("carrier_03_earned_equipped")
	# Ordinary equipment selection is saved on deployment or normal menu/quit.
	# A raw test-runner tree.quit() is not the player's Save & Quit route.
	await _click(_button("MENU"))
	if not await _wait_scene("res://scenes/presentation/slice/boot.tscn"):return false
	var saved:=SaveService.load_profile(SaveService.DEFAULT_SAVE_PATH,false)
	check(saved!=null and saved.loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)==rebuilt_id,"ordinary Menu departure durably saves the equipped choice")
	evidence["profile_after"]=profile.to_dict()
	var file:=FileAccess.open("user://carrier_run_expected.json",FileAccess.WRITE);file.store_string(JSON.stringify({"carrier":carrier,"rebuilt_id":rebuilt_id,"profile":profile.to_dict()}));file.close()
	return failures.is_empty()

func finish() -> void:
	check(evidence.has("profile_after") and not rebuilt_id.is_empty() and not carrier.is_empty(),"full earned cargo/return/choice/equip or independent read required; partial run is FAIL")
	evidence["carrier"]=carrier;evidence["rebuilt_id"]=rebuilt_id;evidence["checks"]=checks;evidence["failures"]=failures;evidence["routes"]=route_results
	evidence["scope"]="Synthetic ordinary live-AI market+water route and base UI, not human playtime/fun. Subsequent pack movement is tested separately in explicit component fixtures."
	var file:=FileAccess.open(out.path_join("carrier_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	release();AudioDirector.shutdown_for_test()
	print("RECOVERED_CARRIER_RUN: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);tree.quit(0 if failures.is_empty() else 1)
