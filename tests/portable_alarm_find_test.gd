extends "res://tests/water_market_test.gd"
## Controlled acquisition fixtures, not an ordinary combat or old-binary proof.
const SAVE := "user://portable_alarm_find_test.json"
const ALARM := &"tool.portable_alarm"

func start() -> void:
	SortieRuntime.clear_session()
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,SAVE).error==OK,"normal waterworks deployment uses isolated test save")
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.set_physics_process(false)
	await frames()

func pickups(point: LootSpawnPoint) -> Array[LootPickup]:
	var result:Array[LootPickup]=[]
	for child in point.get_children():
		if child is LootPickup and not child.consumed and not child.is_queued_for_deletion():result.append(child)
	return result

func content(item: ItemInstance) -> Dictionary:
	var result:=item.to_dict();result.erase("instance_id");return result

func _run() -> void:
	GameLanguage.set_language("en",false)
	var definition:=ContentDB.get_item(ALARM,false)
	check(definition!=null,"portable alarm is registered content")
	if definition:
		check(definition.weight==1 and not definition.stackable and definition.max_stack==1 and definition.icon!=null,"complete one-kilo alarm is nonstackable and reuses an existing icon")
		check(definition.has_tag(&"field_tool") and definition.has_tag(&"recovered_only") and definition.has_tag(&"loot"),"recovered field tool remains exchangeable cargo")
		check(definition not in SupplyService.stock(ProfileState.new()),"recovered alarm never appears as newly purchasable stock")
	await start()
	var world:Node3D=battle.area_root
	var market:WaterMarket=world.get_node("Market")
	var parts:LootSpawnPoint=world.get_node("DepotParts")
	var core:LootSpawnPoint=world.get_node("DepotCore")
	var alarm_hint:=tr(WaterMarket.ALARM_NOTICE)%ControlBindings.label("place_alarm")
	check(pickups(parts).is_empty() and not parts.has_rolled and not parts.enabled,"closed depot has not rolled or granted alarm remotely")
	check(market.carrier_hint()==tr(WaterMarket.FRAME_NOTICE) and not market.carrier_hint().contains(alarm_hint),"closed notice retains frame offer but does not promise a nonexistent alarm")
	check(operate("MarketBreaker").success and operate("MarketShutter").success,"actual local quiet switches begin depot opening")
	market._physics_process(1.1)
	check(not parts.has_rolled and pickups(parts).is_empty(),"partial shutter movement cannot grant the extra tool")
	market._physics_process(2)
	var found:=pickups(parts)
	check(found.size()==4,"successful repair-cache roll contains two supplies, frame, then one alarm")
	var alarm:LootPickup
	if found.size()==4:
		var rng:=RandomNumberGenerator.new();rng.seed=4604
		var baseline:=LootRollService.roll(ContentDB.get_loot_table(&"street_repair_loot"),rng,2)
		check(baseline.size()==2 and content(found[0].item_instance)==content(baseline[0]) and content(found[1].item_instance)==content(baseline[1]),"ordinary first two repair results preserve exact seeded content, quantities and durability")
		var bonus_rng:=RandomNumberGenerator.new();bonus_rng.state=rng.state;bonus_rng.randf()
		var baseline_frame:=LootRollService.roll(ContentDB.get_loot_table(&"market_carrier_frame"),bonus_rng)
		check(baseline_frame.size()==1 and content(found[2].item_instance)==content(baseline_frame[0]) and found[2].item_instance.definition_id==RecoveredCarrier.FRAME and found[2].item_instance.total_weight()==3,"original seeded frame remains third with unchanged content and three-kilo weight")
		alarm=found[3]
		check(alarm.item_instance.definition_id==ALARM and alarm.item_instance.quantity==1 and alarm.item_instance.total_weight()==1,"new final pickup is exactly one complete alarm")
		var ids:Dictionary={}
		for pickup in found:ids[pickup.item_instance.instance_id]=true
		check(ids.size()==4 and not ids.has(""),"alarm owns a nonempty new identity distinct from all existing cargo")
	var core_rng:=RandomNumberGenerator.new();core_rng.seed=4603
	var expected_core:=LootRollService.roll(ContentDB.get_loot_table(&"prototype_high_value_loot"),core_rng)
	var core_found:=pickups(core)
	check(core_found.size()==expected_core.size() and not core_found.is_empty() and content(core_found[0].item_instance)==content(expected_core[0]),"independent salvage-core roll is unchanged")
	if alarm:
		var alarm_id:=alarm.item_instance.instance_id
		check(market.carrier_hint().contains(tr(WaterMarket.FRAME_NOTICE)) and market.carrier_hint().contains(alarm_hint),"actual alarm and original three-kilo frame both receive notice space")
		var original_bindings:=ControlBindings.current.duplicate()
		ControlBindings.current["place_alarm"]=KEY_H
		check(market.carrier_hint().contains(tr(WaterMarket.ALARM_NOTICE)%"H"),"alarm help follows the actual rebound placement key")
		ControlBindings.current=original_bindings
		var original:=SortieCheckpoint.capture_world(battle)
		check(SortieCheckpoint.validate_world(original,battle),"new physical alarm is accepted by unchanged world checkpoint schema")
		market.apply_progress();market.apply_progress()
		check(SortieCheckpoint.capture_world(battle).nodes.DepotParts.items==original.nodes.DepotParts.items,"repeated refresh cannot reroll any cache identity or duplicate the alarm")
		check(SortieCheckpoint.restore_world(original,battle) and SortieCheckpoint.capture_world(battle).nodes.DepotParts.items==original.nodes.DepotParts.items,"restored cache retains exact frame, supplies and alarm with no extra grant")
		alarm=pickups(parts)[3]
		var capacity:float=battle.session.inventory.capacity
		battle.session.inventory.capacity=battle.session.inventory.current_weight+.5
		check(not alarm.interact(battle.player,battle.session).success and not alarm.consumed and alarm.item_instance.instance_id==alarm_id,"full pack leaves same one-kilo alarm in world")
		battle.session.inventory.capacity=capacity
		check(alarm.interact(battle.player,battle.session).success and battle.session.inventory.contains(alarm_id),"actual pickup carries the same alarm identity")
		check(not alarm.interact(battle.player,battle.session).success,"consumed tool pickup cannot duplicate")
		check(market.carrier_hint().contains(alarm_hint),"carried alarm still has truthful same-sortie help")
		battle.session.inventory.remove_item(alarm_id)
		market.apply_progress()
		check(pickups(parts).size()==3 and not market.carrier_hint().contains(alarm_hint) and market.carrier_hint()==tr(WaterMarket.FRAME_NOTICE),"opened legacy-style cache without alarm gains none; frame hint survives")
		var legacy:=SortieCheckpoint.capture_world(battle)
		check(SortieCheckpoint.validate_world(legacy,battle) and SortieCheckpoint.restore_world(legacy,battle),"controlled already-rolled no-alarm fixture restores without migration fields")
		market.apply_progress();market.apply_progress()
		check(SortieCheckpoint.capture_world(battle).nodes.DepotParts.items==legacy.nodes.DepotParts.items and not market.carrier_hint().contains(alarm_hint),"restore and re-open refresh never backfill or promise a missing alarm")
	# A failed original roll must not become a back door to a free extra item.
	battle.free();battle=null;SortieRuntime.clear_session()
	await start()
	market=battle.area_root.get_node("Market");parts=battle.area_root.get_node("DepotParts")
	parts.loot_table_id=&"fixture_missing_table"
	check(operate("MarketBreaker").success and operate("MarketShutter").success,"failure fixture still uses normal depot switch flow")
	market._physics_process(3);market.apply_progress()
	check(not parts.has_rolled and pickups(parts).is_empty(),"failed base roll never creates a free alarm or changes has_rolled")
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("PORTABLE_ALARM_FIND_TEST: %s (%d checks; controlled fixtures)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
