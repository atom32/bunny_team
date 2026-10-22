extends "res://tests/waterworks_test.gd"
## Controlled component fixtures; enemy freeze and local placement are deliberate.
## Not ordinary earned combat, human timing, or proof of surprise/fun.
const SAVE := "user://recovered_carrier_test.json"
const EXPECTED := "user://carrier_expected.json"

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var args := OS.get_cmdline_user_args()
	if "--read" in args:
		var profile := SaveService.load_profile(SAVE,false)
		var expected := ProfileState.from_dict(JSON.parse_string(FileAccess.get_file_as_string(EXPECTED)))
		check(profile != null and expected != null and profile.to_dict()==expected.to_dict(),"separate process retains exact equipped conversion, wallet and inventory")
	elif "--world-read" in args or "--legacy-read" in args:
		check(ProfileRuntime.load_profile(SAVE) and SortieRuntime.resume_saved(SAVE)==OK,"actual separately saved battle resumes")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		check(not FlowMenu.is_open(),"unchanged geometry/signature restores without recovery error")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		battle.player.set_physics_process(false)
		if "--legacy-read" in args:
			check(_frame_in_world().is_empty() and SupplyService.count(ProfileRuntime.get_profile(),RecoveredCarrier.FRAME)==0,"actual old opened cache gains no retroactive frame")
			check(battle.area_root.get_node("Market").carrier_hint().is_empty(),"actual old opened depot does not promise a nonexistent recovered frame")
		else:
			var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(EXPECTED))
			check(_frame_in_world()==ItemInstance.from_dict(old).to_dict(),"unlooted frame identity survives process termination exactly")
	else:
		await _depot("--write-world" in args)
		if "--write-world" not in args:
			_death()
			await _choices()
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session(); AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("RECOVERED_CARRIER: "+failure)
	print("RECOVERED_CARRIER_TEST: %s (%d checks; controlled fixtures)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func start() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
	check(DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,SAVE).error==OK,"controlled normal deployment")
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.set_physics_process(false)
	await frames()

func _frame_in_world() -> Dictionary:
	for point in battle.area_root.find_children("*","LootSpawnPoint",true,false):
		for child in point.get_children():
			if child is LootPickup and not child.consumed and child.item_instance.definition_id==RecoveredCarrier.FRAME:return child.item_instance.to_dict()
	return {}

func _depot(write_world: bool) -> void:
	await start()
	var market: WaterMarket=battle.area_root.get_node("Market")
	var point: LootSpawnPoint=battle.area_root.get_node("DepotParts")
	check(not point.enabled and not point.has_rolled and _frame_in_world().is_empty(),"closed optional depot offers no remote frame")
	check(not market.carrier_hint().is_empty(),"unopened current depot clearly offers actual future frame, without rolling it remotely")
	check(SupplyService.count(ProfileRuntime.get_profile(),RecoveredCarrier.FRAME)==0 and not SupplyService.recipes(ProfileRuntime.get_profile()).has("carrier_courier"),"no starting gift or unearned conversion")
	use_market("MarketBreaker");use_market("MarketShutter");market._physics_process(3);await frames()
	var raw := _frame_in_world()
	check(not raw.is_empty() and raw.quantity==1,"actual open workbench rolls exactly one physical frame")
	var rng:=RandomNumberGenerator.new();rng.seed=4604
	var baseline:=LootRollService.roll(ContentDB.get_loot_table(&"street_repair_loot"),rng,2)
	var contents: Array[ItemInstance]=[]
	for child in point.get_children():
		if child is LootPickup:contents.append(child.item_instance)
	check(contents.size()==3 and contents[0].definition_id==baseline[0].definition_id and contents[0].quantity==baseline[0].quantity and contents[1].definition_id==baseline[1].definition_id and contents[1].quantity==baseline[1].quantity,"frame appends without replacing repair supplies or changing their roll")
	market.apply_progress();market.apply_progress()
	check(_frame_in_world()==raw,"refresh cannot reroll frame identity")
	var before:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(before,battle) and SortieCheckpoint.restore_world(before,battle) and _frame_in_world()==raw,"current world roundtrip preserves actual unopened frame")
	if write_world:
		check(SortieRuntime.save_checkpoint()==OK,"actual frame world saved for independent process")
		var file:=FileAccess.open(EXPECTED,FileAccess.WRITE);file.store_string(JSON.stringify(raw));return
	var ui: Node=battle.get_node("SlicePresentation")
	ui.container=ui.register_loot_cache(point)
	battle.player.position=point.position+Vector3.RIGHT
	ui._show_loot();await frames()
	var note:=ui.panel.find_child("ModifiedFind2",true,false) as Label
	check(note!=null and note.text==tr(ContentDB.get_item(RecoveredCarrier.FRAME).description),"real cache explains two uses before TAKE")
	check(note!=null and note.get_minimum_size().y<=note.size.y,"carrier use text fits real loot row")
	await capture("carrier_cache")
	ui._close_loot()
	var pickup:LootPickup
	for child in point.get_children():
		if child is LootPickup and child.item_instance.definition_id==RecoveredCarrier.FRAME:pickup=child;break
	var capacity:float=battle.session.inventory.capacity
	battle.session.inventory.capacity=battle.session.inventory.get_used_capacity()+2
	check(not pickup.interact(battle.player,battle.session).success and not pickup.consumed,"overweight leaves actual three-kilo frame in world")
	battle.session.inventory.capacity=capacity
	check(pickup.interact(battle.player,battle.session).success and battle.session.inventory.contains(raw.instance_id),"actual TAKE carries exact generated frame")
	check(not SupplyService.recipes(ProfileRuntime.get_profile()).has("carrier_freight") and SupplyService.transact("barter","carrier_freight",1,SAVE).error==ERR_BUSY,"field cargo does not unlock or perform base conversion")
	check(battle.area_root.get_node("Retreat").extract(battle.session) and SortieRuntime.finalize_sortie(SAVE)==OK,"actual extraction/finalization transfers frame without false water completion")
	check(ProfileRuntime.get_profile().inventory.contains(raw.instance_id) and ProfileRuntime.get_profile().waterworks_memory.is_empty(),"exact frame reaches warehouse, optional retreat gives no delivery memory")
	battle.free();battle=null;SortieRuntime.clear_session()
	var profile:=ProfileRuntime.get_profile()
	var before_conversion:=profile.to_dict()
	var panel:=SupplyPanel.new();panel.contact_id="su_mi";panel.save_path=SAVE;add_child(panel);await frames()
	# Scroll restoration waits for render/layout frames, not physics ticks.
	for tick in 3:await get_tree().process_frame
	var selected: String = "carrier_freight" if "--freight" in OS.get_cmdline_user_args() else "carrier_courier"
	var button:=panel.find_child("Exchange_"+selected,true,false) as Button
	check(button!=null and not button.disabled and panel.find_child("Exchange_carrier_freight",true,false)!=null and panel.find_child("RecoveredCarrierReply",true,false)!=null,"actual engineering UI offers both mutually exclusive uses and character response")
	var scroll:=panel.find_child("WORKSHOP EXCHANGE",true,false) as ScrollContainer
	scroll.ensure_control_visible(button)
	for tick in 3:await get_tree().process_frame
	await capture("carrier_choice")
	check(SupplyService.transact("barter",selected,1,"user://missing_carrier_dir/profile.json").error!=OK and profile.to_dict()==before_conversion,"failed durable save consumes no recovered frame or money")
	var presses := []
	button.pressed.connect(func():presses.append(true))
	if DisplayServer.get_name()!="headless":
		var motion:=InputEventMouseMotion.new();motion.position=button.get_global_rect().get_center()
		get_viewport().push_input(motion);await frames()
		var pos:=button.get_global_rect().get_center()
		check(scroll.get_global_rect().has_point(pos),"selected conversion center is inside the settled scroll viewport")
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.position=pos;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
			get_viewport().push_input(event);await frames()
	else:await click(button)
	await frames()
	check(presses==[true],"native UI gesture emits exactly one selected conversion press")
	var chosen: StringName=RecoveredCarrier.RECIPES[selected].output
	var other: StringName=RecoveredCarrier.COURIER if chosen==RecoveredCarrier.FREIGHT else RecoveredCarrier.FREIGHT
	check(SupplyService.count(profile,RecoveredCarrier.FRAME)==0 and SupplyService.count(profile,chosen)==1 and SupplyService.count(profile,other)==0,"real UI consumes one frame for chosen pack only")
	var after:=profile.to_dict()
	check(SupplyService.transact("barter","carrier_courier" if selected=="carrier_freight" else "carrier_freight",1,SAVE).error!=OK and profile.to_dict()==after,"stale second choice cannot consume nonexistent frame or create other pack")
	check(profile.credits==before_conversion.credits,"frame conversion needs no added materials/credit grind")
	panel.free()

func use_market(name: String) -> void:
	var point:Node3D=battle.area_root.get_node(name)
	battle.player.position=point.position+Vector3.RIGHT*.8
	check(point.interact(battle.player,battle.session).success,"local market interaction: "+name)

func _choices() -> void:
	for id in [RecoveredCarrier.FRAME,RecoveredCarrier.COURIER,RecoveredCarrier.FREIGHT]:
		var definition:=ContentDB.get_item(id)
		check(definition!=null and definition not in SupplyService.stock(ProfileRuntime.get_profile()),"recovered-only item never sold as stock: "+String(id))
		check(GameLanguage.item_name(definition.display_name)!=definition.display_name if TranslationServer.get_locale()=="zh_CN" else true,"new item name localized")
	for recipe_id in RecoveredCarrier.RECIPES:
		SortieRuntime.clear_session()
		var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
		profile.inventory.add_item(ItemInstance.new(RecoveredCarrier.FRAME)) # Explicit choice fixture, not earned route.
		var recipe:Dictionary=RecoveredCarrier.RECIPES[recipe_id]
		check(SupplyService.transact("barter",recipe_id,1,SAVE).error==OK,"both authored choices use atomic existing service: "+recipe_id)
		var pack:ItemInstance
		for item in profile.inventory.get_items():
			if item.definition_id==recipe.output:pack=item
		var ui:=HangerUI.new();ui.configure(profile.inventory,profile.loadout);add_child(ui);await frames()
		check(ui.stash_grid.model.equip_item(pack.instance_id,LoadoutState.SLOT_BACKPACK),"real warehouse model equips rebuilt pack")
		ui.sync_loadout_selection();await frames()
		check(ui.backpack_option.get_item_metadata(ui.backpack_option.selected)==pack.instance_id,"visible backpack selection matches actual equipped conversion")
		await capture(recipe_id+"_equipped")
		ui.free()
		var expected_capacity:=27.0 if recipe.output==RecoveredCarrier.COURIER else 47.0
		var definition:=ContentDB.get_item(recipe.output) as EquipmentDefinition
		check(profile.get_carried_capacity()==expected_capacity,"actual equipped profile capacity differs by choice")
		check(DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,SAVE).error==OK,"real deployment accepts chosen pack without grants")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		check(battle.session.inventory.capacity==expected_capacity and battle.player.backpack_instance.instance_id==pack.instance_id,"session uses exact owned pack and actual capacity")
		var standard:=ContentDB.get_item(&"equipment.field_pack_01") as EquipmentDefinition
		var baseline:=PlayerController.movement_speed_for(battle.player.weapon_data,battle.player.armor_data,standard,battle.player.base_speed)
		check(is_equal_approx(battle.player.get_movement_speed(),baseline+definition.movement_modifier),"real movement calculation uses chosen pack's gain/tradeoff")
		Input.action_press("move_left")
		for tick in 24:await get_tree().physics_frame
		Input.action_release("move_left")
		check(is_equal_approx(Vector2(battle.player.velocity.x,battle.player.velocity.z).length(),battle.player.get_movement_speed()),"ordinary input actually moves at the selected pack speed")
		check(battle.player.find_child("Backpack",true,false).get_child_count()>0,"equipped alternative has a real attached visual")
		battle.player.set_physics_process(false)
		check(battle.area_root.get_node("Retreat").extract(battle.session) and SortieRuntime.finalize_sortie(SAVE)==OK,"equipped choice survives an actual return transaction")
		battle.free();battle=null;SortieRuntime.clear_session()
		check(SaveService.save_profile(profile,SAVE)==OK,"settled equipped choice saved")
		var file:=FileAccess.open(EXPECTED,FileAccess.WRITE);file.store_string(JSON.stringify(profile.to_dict()));file.close()
func _death() -> void:
	# A carried recovered frame remains ordinary risky loot, never a permanent unlock.
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,SAVE).error==OK,"death fixture starts normal deployment")
	var session:=SortieRuntime.get_current_session();var lost:=ItemInstance.new(RecoveredCarrier.FRAME)
	check(session.inventory.add_item(lost),"explicit carried death fixture owns frame")
	session.fail()
	check(SortieRuntime.finalize_sortie(SAVE)==OK and not profile.inventory.contains(lost.instance_id) and not SupplyService.recipes(profile).has("carrier_courier"),"death loses frame and creates no recipe unlock")
