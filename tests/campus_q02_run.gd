extends "res://tests/campus_q01_run.gd"
func _deadline_seconds() -> float: return 900.0 # At most three real outings, not a single-roll fixture.

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	evidence["method"]="Continue actually earned Q01 save through normal menu, live campus loot UI and base Q02 delivery; no new_profile, fabricated progress or pickups"
	var profile:=ProfileRuntime.get_profile()
	evidence["profile_before"]=profile.to_dict()
	check(profile.narrative_slice.settled.Q01 and not profile.narrative_slice.settled.Q02 and profile.successful_sorties==2,"actual normal Q01 return starts Q02")
	if not failures.is_empty():_finish();return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening: await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): _finish();return
	evidence["outings"]=[]
	# Loot is random. Keep real returns, use warehouse stock, and buy missing
	# medical supplies at their displayed price instead of demanding one roll.
	for outing in 3:
		if not await _scavenge(profile,outing+1):_finish();return
		if SupplyService.count(profile,&"material.fabric")>=2:break
	check(SupplyService.count(profile,&"material.fabric")>=2,"actual recovered warehouse fabric meets delivery after at most three normal sorties")
	if not failures.is_empty():_finish();return
	if SupplyService.count(profile,&"medical.field_dressing")<2:
		await _click(tree.current_scene.find_child("NavWorkshop",true,false))
		var shop=tree.current_scene.screen.get_node("ContactPanel")
		await _click(shop.find_child("Contact_tang_kui",true,false))
		var purchased:=0
		while SupplyService.count(profile,&"medical.field_dressing")<2:
			var before:=SupplyService.count(profile,&"medical.field_dressing")
			var money: int=profile.credits
			var price:=SupplyService.buy_price(ContentDB.get_item(&"medical.field_dressing"),profile)
			var buy: Button=shop.find_child("Supply_buy_medical_field_dressing",true,false)
			check(buy!=null and not buy.disabled,"ordinary medical shop offers missing dressing")
			if buy==null:_finish();return
			await _scroll(buy);await _click(buy)
			check(SupplyService.count(profile,&"medical.field_dressing")==before+1 and profile.credits==money-price,"one real dressing purchase increases stock and charges exact displayed price")
			if not failures.is_empty():_finish();return
			purchased+=1
		evidence["purchased_dressings"]=purchased
	evidence["warehouse_before_delivery"]={"dressings":SupplyService.count(profile,&"medical.field_dressing"),"fabric":SupplyService.count(profile,&"material.fabric")}
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _click(tree.current_scene.screen.find_child("RequestDetails",true,false))
	var panel=tree.current_scene.screen.get_node("ContactPanel")
	var submit: Button=panel.find_child("SubmitQ02",true,false)
	check(submit!=null and not submit.disabled,"actual warehouse delivery available after return")
	var credits: int=profile.credits
	await _scroll(submit);await _click(submit)
	check(profile.narrative_slice.settled.Q02 and profile.credits==credits+NarrativeSlice.Q02_REWARD,"normal delivery commits real materials and one reward")
	await _capture("03_q02_delivered")
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("04_relay_request_after_q02")
	evidence["next_mission"]=String(DeploymentPlan.selected_street_mission)
	evidence["next_brief"]=SortieGuidance.at_base(profile)
	evidence["profile_after"]=profile.to_dict()
	_finish()

func _scavenge(profile: ProfileState,outing: int) -> bool:
	var before_sorties:=profile.successful_sorties
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("01_outing_%d_q02_brief"%outing)
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"): return false
	await tree.create_timer(3.0).timeout
	battle=tree.current_scene
	battle.player.weapon_fired.connect(func(_r:float):shots+=1)
	check(battle.session.q02_active and battle.session.slice_context.is_empty(),"real deployment advances context to active medical request")
	for tick in 120:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(battle.area_root.get_node("StreetNavigation").get_navigation_map())>0:break
	var targets: Array[Node3D]=[]
	for point in battle.area_root.loot_points:
		if point.enabled and point.loot_table_id in [&"street_pharmacy_loot",&"street_apartment_loot"]:targets.append(point)
	targets.sort_custom(func(a,b):return battle.player.global_position.distance_to(a.global_position)<battle.player.global_position.distance_to(b.global_position))
	var taken: Array=evidence.get("taken_ids",[])
	for point in targets:
		if _cargo_count(&"material.fabric")+SupplyService.count(profile,&"material.fabric")>=2:break
		if not await _walk(point.global_position,0.6):return false
		_release();await _frames();await _tap("interact")
		var presentation=battle.get_node("SlicePresentation")
		check(is_instance_valid(presentation.panel),"real E opens campus supply case "+point.name)
		if not is_instance_valid(presentation.panel):return false
		for guard in 20:
			var button: Button
			var pickup: LootPickup
			for row in presentation._cache_rows:
				if row.pickup.item_instance.definition_id in [&"medical.field_dressing",&"material.fabric"] and _cargo_count(row.pickup.item_instance.definition_id)<2:
					button=row.take;pickup=row.pickup;break
			if button==null:break
			var id: String=pickup.item_instance.instance_id
			var definition: StringName=pickup.item_instance.definition_id
			var quantity: int=pickup.item_instance.quantity
			var before:=_cargo_count(definition)
			var consumed:=[false]
			pickup.picked_up.connect(func(_item:ItemInstance):consumed[0]=true,CONNECT_ONE_SHOT)
			await _scroll(button);await _click(button)
			check(consumed[0] and _cargo_count(definition)==before+quantity and (not is_instance_valid(pickup) or pickup.consumed),"actual TAKE consumes world pickup and adds exact quantity, including legal merges")
			taken.append({"source_instance":id,"definition":String(definition),"quantity":quantity,"retained_source_id":battle.session.inventory.contains(id)})
		await _capture("02_outing_%d_cache_"%outing+point.name)
		await _click(presentation.panel.find_child("CloseCache",true,false))
	evidence["taken_ids"]=taken
	var cargo := {"dressings":_cargo_count(&"medical.field_dressing"),"fabric":_cargo_count(&"material.fabric")}
	evidence["cargo"]=cargo
	evidence["outings"].append({"number":outing,"cargo":cargo})
	if not failures.is_empty():return false
	var retreat: ExtractionPoint
	for i in 4:
		var exit: ExtractionPoint=battle.area_root.get_node("Exit%d"%i)
		if exit.available and exit.required_objective_id.is_empty():retreat=exit
	if not await _walk(retreat.global_position,0.4):return false
	_release();await _frames();await _tap("interact")
	check(battle.session.status==SortieSession.Status.COMPLETED,"medical cargo returns through normal E extraction")
	evidence["shots"]=shots;evidence["health"]=battle.player.health;evidence["kills"]=battle.session.enemies_defeated
	if not await _wait_scene("res://scenes/result/result.tscn"): return false
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): return false
	check(profile.successful_sorties==before_sorties+1 and not profile.narrative_slice.settled.Q02,"one actual safe return preserves materials without auto-completing delivery")
	return failures.is_empty()

func _cargo_count(id: StringName) -> int:
	var count:=0
	for item in battle.session.inventory.get_items():
		if item.definition_id==id:count+=item.quantity
	return count

func _scroll(button: Control) -> void:
	var parent:=button.get_parent()
	while parent:
		if parent is ScrollContainer:parent.ensure_control_visible(button)
		parent=parent.get_parent()
	await _frames(3)
