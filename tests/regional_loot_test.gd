extends Node3D
var failures: Array[String] = []
var checks := 0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func _ready() -> void:
	await get_tree().process_frame
	var expected := {
		&"street_office_loot": [&"material.electronics",&"material.wiring",&"material.data_drive",&"material.scrap"],
		&"street_pharmacy_loot": [&"medical.field_dressing",&"medical.medkit",&"material.fabric",&"material.parts"],
		&"street_apartment_loot": [&"material.fabric",&"material.wiring",&"material.scrap",&"medical.field_dressing"],
		&"street_repair_loot": [&"material.parts",&"material.wiring",&"material.propellant",&"material.scrap"]}
	for id in expected:
		var table := ContentDB.get_loot_table(id)
		check(table!=null and table.validate_definition(),"registered valid regional table")
		var a := RandomNumberGenerator.new();a.seed=4407
		var b := RandomNumberGenerator.new();b.seed=4407
		var rolls := LootRollService.roll(table,a,2000)
		var repeated := LootRollService.roll(table,b,2000)
		var counts := {}
		var valid := rolls.size()==2000
		var deterministic := true
		for i in rolls.size():
			var item := rolls[i]
			valid=valid and item.definition_id in expected[id] and InventoryState.new(100).add_item(item)
			deterministic=deterministic and item.definition_id==repeated[i].definition_id and item.quantity==repeated[i].quantity
			counts[item.definition_id]=int(counts.get(item.definition_id,0))+1
		check(valid,"all rolls produce real compatible inventory items from regional pool")
		check(deterministic,"same seed reproduces content/quantities without assuming new item IDs repeat")
		check(counts.size()==expected[id].size(),"all authored resource uses observed")
		if id==&"street_pharmacy_loot": check(counts[&"medical.field_dressing"]+counts[&"medical.medkit"]>1200,"pharmacy materially favors usable medicine")
		if id==&"street_apartment_loot": check(counts[&"material.fabric"]>1000,"apartments materially favor fabric needed for clinic and equipment")
		if id==&"street_repair_loot": check(counts[&"material.parts"]+counts[&"material.wiring"]>1200,"repair shop materially favors fittings/workbench inputs")
		if id==&"street_office_loot": check(counts[&"material.electronics"]+counts[&"material.wiring"]>1300,"office materially favors workbench electronics/wiring")
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","user://regional_test.json",false)
	check(deployed.error==OK,"normal finite loadout deploys")
	var battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed=907
	add_child(battle)
	battle.result_transition_enabled=false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await get_tree().physics_frame
	var area=battle.area_root
	var high:=0
	var street:=0
	var regional:={}
	for point in area.loot_points:
		if point.loot_table_id==&"prototype_high_value_loot":high+=1
		elif point.loot_table_id==&"street_supply_loot":street+=1
		else:
			var index:=int(String(point.name).substr(10,1))
			check(point.loot_table_id==area.REGIONAL_LOOT[index],"actual room binds its intended resource table")
			regional[point.loot_table_id]=int(regional.get(point.loot_table_id,0))+1
	check(high==4 and street==6 and regional.size()==4,"existing valuable cache/street pools preserved; four regional pools in actual map")
	for id in regional: check(regional[id]==2,"exactly two ordinary resource points per room; no extra loot sites")
	var world:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle),"regional world snapshot validates")
	check(SortieCheckpoint.restore_world(world,battle),"actual saved contents restore without rerolling regional tables")
	var again:=SortieCheckpoint.capture_world(battle)
	check(world.nodes==again.nodes,"saved loot IDs/quantities/empty points exactly preserved on restore")
	if "--capture" in OS.get_cmdline_user_args():
		area.route_map.expanded=true
		for locale in ["en","zh_CN"]:
			GameLanguage.set_language(locale,false)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("regional_map_"+locale+".png"))
	battle.free()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("REGIONAL_LOOT: "+failure)
	print("REGIONAL_LOOT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
