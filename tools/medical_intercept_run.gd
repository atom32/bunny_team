extends "res://tests/campus_q02_run.gd"
## Actual earned Q01 return -> ordinary Q02 interception, loot, extraction, delivery.
func _run() -> void:
	if "--english" in OS.get_cmdline_user_args():
		check(GameLanguage.set_language("en",true)==OK,"isolated English preference persists through ordinary BOOT")
	if "--read" not in OS.get_cmdline_user_args():
		await super._run();return
	tree=get_tree();tree.current_scene=null
	var profile:=ProfileRuntime.get_profile()
	evidence["profile_before"]=profile.to_dict()
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	check(profile.successful_sorties==_expected_returns(3) and profile.narrative_slice.settled.Q02 and profile.sortie_checkpoint.is_empty(),"separate ordinary BOOT reads actual completed medical delivery without new rewards")
	check(SortieGuidance.contact_at_base(profile)=="su_mi","real completion advances ordinary next contact to Su Mi")
	evidence["profile_after"]=profile.to_dict();_finish()

func _scavenge(profile: ProfileState,outing: int) -> bool:
	check(outing==1,"medical bag route does not count repeats as new content")
	var before_sorties:=profile.successful_sorties
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("01_medical_brief")
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):return false
	await tree.create_timer(3.0).timeout
	battle=tree.current_scene;battle.player.weapon_fired.connect(func(_r:float):shots+=1)
	if "--english" in OS.get_cmdline_user_args():check(TranslationServer.get_locale()=="en","real BOOT preserves selected English locale")
	var runners:=battle.area_root.get_node("CampusMedicalRunners") as CampusMedicalRunners
	check(battle.session.q02_active and runners!=null,"normal Q02 deployment includes physical carrier and escort")
	var carried_before:={"medical.field_dressing":_cargo_count(&"medical.field_dressing"),"material.fabric":_cargo_count(&"material.fabric")}
	if not await _walk(runners.get_node("Route/ClinicDoor").global_position):return false
	for attempt in 4:
		if runners.phase==CampusMedicalRunners.Phase.DROPPED:break
		if not is_instance_valid(runners.carrier):break
		if not await _walk(runners.carrier.global_position):return false
		for tick in 180:
			await tree.physics_frame;_controls(battle.player.position)
			if runners.phase==CampusMedicalRunners.Phase.DROPPED or battle.player.is_dead:break
	_release()
	check(runners.phase==CampusMedicalRunners.Phase.DROPPED and shots>0,"live-AI carrier defeated with actual gunfire; no direct damage or AI disable")
	if not failures.is_empty():return false
	await _capture("02_medical_interception")
	var taken:=[]
	for name in ["Dressings","Linen"]:
		var cache:=runners.get_node(name) as LootSpawnPoint
		if cache.get_child_count()==0:continue
		if not await _walk(cache.global_position,.6):return false
		_release();await _frames();await _tap("interact")
		var presentation=battle.get_node("SlicePresentation")
		check(is_instance_valid(presentation.panel),"actual E opens dropped medical supply case")
		if not is_instance_valid(presentation.panel):return false
		for guard in 8:
			var button: Button;var pickup: LootPickup
			for row in presentation._cache_rows:
				if row.pickup.item_instance.definition_id in [&"medical.field_dressing",&"material.fabric"]:
					button=row.take;pickup=row.pickup;break
			if button==null:break
			var id:=pickup.item_instance.instance_id
			var definition:=pickup.item_instance.definition_id;var quantity:=pickup.item_instance.quantity
			var before:=_cargo_count(definition)
			await _scroll(button);await _click(button)
			check(_cargo_count(definition)==before+quantity,"actual TAKE transfers exact drop quantity with ordinary carry capacity")
			taken.append({"source_id":id,"definition":String(definition),"quantity":quantity})
			if not failures.is_empty():return false
		await _click(presentation.panel.find_child("CloseCache",true,false))
	check(_cargo_count(&"medical.field_dressing")==carried_before["medical.field_dressing"]+2 and _cargo_count(&"material.fabric")==carried_before["material.fabric"]+2,"two real dressings and two fabric recovered, not grant-on-kill")
	evidence["intercepted_medical_drop"]=taken
	await _capture("03_medical_cargo")
	var retreat: ExtractionPoint
	for index in 4:
		var exit:=battle.area_root.get_node("Exit%d"%index) as ExtractionPoint
		if exit.available and exit.required_objective_id.is_empty():retreat=exit
	if not await _walk(retreat.global_position,.4):return false
	_release();await _frames();await _tap("interact")
	check(battle.session.status==SortieSession.Status.COMPLETED,"normal physical extraction brings intercepted supplies home")
	evidence["shots"]=shots;evidence["health"]=battle.player.health;evidence["kills"]=battle.session.enemies_defeated
	evidence["outings"].append({"number":outing,"source":"physical intercepted carrier","cargo":{"dressings":2,"fabric":2}})
	if not await _wait_scene("res://scenes/result/result.tscn"):return false
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return false
	check(profile.successful_sorties==before_sorties+1 and not profile.narrative_slice.settled.Q02,"one real return retains supplies but delivery remains a separate base action")
	return failures.is_empty()
