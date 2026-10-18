extends Node3D
const PATH := "user://supply_art_v1_test.json"
const FOOD := [&"supply.field_ration",&"supply.energy_bar",&"supply.canned_beans",&"supply.bottled_water",&"supply.citrus_drink"]
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func verify_visual(id: StringName) -> void:
	var model:=ItemPresentation.create(id)
	check(model!=null,"Mapped real model: "+String(id))
	if not model:return
	check(model.get_meta("presentation_definition_id")==String(id),"Visual uses exact existing/new registered ID")
	check(not ItemPresentation.bounds(model).size.is_zero_approx(),"Visible nonempty native mesh")
	check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Art adds no physics or pickup entity")
	check(ContentDB.get_item(id).icon!=null,"Real inventory icon is loadable")
	model.free()
func _ready() -> void: run.call_deferred()
func seed_for(id: StringName) -> int:
	for seed in 4000:
		var rng:=RandomNumberGenerator.new();rng.seed=seed
		if LootRollService.roll(ContentDB.get_loot_table(&"street_apartment_loot"),rng,1)[0].definition_id==id:return seed
	return -1
func spawn_food(point: LootSpawnPoint,id: StringName) -> LootPickup:
	for child in point.get_children():
		if child is LootPickup:child.free()
	point.has_rolled=false
	var rng:=RandomNumberGenerator.new();rng.seed=seed_for(id)
	var pickups:=point.spawn(rng)
	check(pickups.size()==1 and pickups[0].item_instance.definition_id==id,"Actual authored loot roll/spawner yields "+String(id))
	return pickups[0]
func run() -> void:
	if "--read" in OS.get_cmdline_user_args():
		var profile:=SaveService.load_profile(PATH,false)
		check(profile!=null and profile.validate(),"Fresh process reads normal profile with food possessions")
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://supply_art_expected.json"))
		for id: StringName in FOOD:
			check(SupplyService.count(profile,id)==int(expected[String(id)]),"Fresh process restores exact owned quantity: "+String(id));verify_visual(id)
		await finish();return
	for id: StringName in ItemPresentation.SCENES:verify_visual(id)
	for id: StringName in ItemPresentation.EXISTING:verify_visual(id)
	check(ItemPresentation.create(&"ammo.9mm_standard")==null,"Unmapped items keep their original fallback presentation")
	SortieRuntime.clear_session();var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	for id: StringName in FOOD:
		var d:=ContentDB.get_item(id)
		check(d.has_tag(&"loot") and d.has_tag(&"supply") and not d is MedicalDefinition and not d.has_tag(&"ammo"),"Food is ordinary trade cargo, not a healing/ammunition system")
		check(ContactDefinition.owns_stock("tang_kui",d) and not ContactDefinition.owns_stock("shen_yanshuang",d) and not ContactDefinition.owns_stock("su_mi",d),"Existing resident supplier owns food/drink")
		var money:=profile.credits
		check(SupplyService.transact("buy",String(id),2,PATH).error==OK and SupplyService.count(profile,id)==2 and profile.credits==money-2*d.base_value,"Real buy consumes exact finite credits")
		var item: ItemInstance
		for candidate in profile.inventory.get_items():
			if candidate.definition_id==id:item=candidate
		money=profile.credits;var price:=SupplyService.sell_price(item)
		check(SupplyService.transact("sell",item.instance_id,1,PATH).error==OK and SupplyService.count(profile,id)==1 and profile.credits==money+price,"Real partial-stack sale uses existing transaction")
	var before:=profile.to_dict()
	check(SupplyService.transact("buy",String(FOOD[0]),1,"user://missing_supply_dir/profile.json").error!=OK and profile.to_dict()==before,"Failed save publishes no money/items/layout changes")
	var probe:=LootPickup.new();probe.setup(ItemInstance.new(FOOD[0]));add_child(probe)
	check(probe.has_node("ItemArt") and not probe.has_node("LootCore"),"Actual pickup replaces placeholder core with real food model")
	probe.setup(ItemInstance.new(&"material.parts"))
	check(probe.get_node("ItemArt").get_meta("presentation_definition_id")=="material.parts","setup/checkpoint replacement refreshes identity, not stale food art")
	probe.queue_free();await get_tree().process_frame
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).error==OK,"Normal deployment with unchanged medical/ammo packing")
	var battle: Node3D=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	var point: LootSpawnPoint
	for candidate in battle.area_root.loot_points:
		if candidate.loot_table_id==&"street_apartment_loot":point=candidate;break
	check(point!=null,"Uses existing apartment storage site, not a new map location")
	var health: float=battle.player.health
	for id: StringName in FOOD:
		var pickup:=spawn_food(point,id)
		check(pickup.has_node("ItemArt"),"Rolled cargo uses actual model")
		check(pickup.try_pickup(battle.session)==LootPickup.PickupResult.SUCCESS,"Real pickup transfers the owned instance")
		await get_tree().process_frame
	check(battle.player.health==health,"Food pickup grants no healing/buff or consumption effect")
	var uncollected:=spawn_food(point,&"supply.bottled_water");var world_id:=uncollected.item_instance.instance_id;var point_name:=String(point.name)
	var crate:=SliceLootContainer.new();point.add_child(crate);crate.set_open(true)
	check(uncollected.get_node("ItemArt").visible and uncollected.get_node("ItemArt").position.y>.7,"Actual open supply case exposes owned model above lid, without moving entity")
	crate.set_open(false);check(not uncollected.get_node("ItemArt").visible,"Closing case hides content model")
	check(SortieRuntime.save_checkpoint()==OK,"Save food in inventory and uncollected world slot through unchanged schema")
	battle.queue_free();SortieRuntime.clear_session();await get_tree().process_frame
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"Resume actual saved sortie with new cargo IDs")
	profile=ProfileRuntime.get_profile();battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	var restored: LootPickup
	for candidate in battle.area_root.find_children("*","LootPickup",true,false):
		if candidate.item_instance.instance_id==world_id:restored=candidate
	check(restored!=null and String(restored.get_parent().name)==point_name,"World restore preserves exact item instance/location without reroll")
	check(restored.get_node("ItemArt").get_meta("presentation_definition_id")=="supply.bottled_water","Restored world content reconstructs the matching model")
	check(restored.try_pickup(battle.session)==LootPickup.PickupResult.SUCCESS,"Restored food remains genuinely collectible")
	check(battle.session.complete_extraction() and SortieRuntime.finalize_sortie(PATH)==OK,"Ordinary extraction settles all recovered food")
	battle.queue_free();await get_tree().process_frame
	var expected: Dictionary={}
	for id: StringName in FOOD:
		expected[String(id)]=3 if id==&"supply.bottled_water" else 2
		check(SupplyService.count(profile,id)==expected[String(id)],"Base + recovered cargo quantity conserved: "+String(id))
	var legacy:=ProfileState.create_new().to_dict()
	var file:=FileAccess.open("user://supply_art_legacy.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":7,"profile":legacy}));file.close()
	var old:=SaveService.load_profile("user://supply_art_legacy.json",false)
	check(old!=null and old.validate(),"Legacy profile reads without a schema bump or free food grant")
	for id: StringName in FOOD:check(SupplyService.count(old,id)==0,"Old saves do not acquire invented possessions")
	check(SaveService.SCHEMA_VERSION==8 and SortieCheckpoint.VERSION==6,"Profile/checkpoint contracts unchanged")
	check(SaveService.save_profile(profile,PATH)==OK,"Final normal owned quantities saved")
	file=FileAccess.open("user://supply_art_expected.json",FileAccess.WRITE);file.store_string(JSON.stringify(expected));file.close()
	await finish()
func finish() -> void:
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	for frame in 5:await get_tree().process_frame
	print("SUPPLY_ART_V1_TEST: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)");get_tree().quit(0 if failures.is_empty() else 1)
