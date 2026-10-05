extends "res://tests/streets_combat_run.gd"
## Persistent-profile autonomous stress run, NOT human balance/fun acceptance.
## Only initial tutorial-complete flag is a fixture. Never grants loot or credits.
const PATH := "user://alpha_campaign_run.json"
func _run() -> void:
	var out := OS.get_environment("BUNNY_EVIDENCE")
	if out.is_empty(): get_tree().quit(2);return
	var profile: ProfileState
	if SaveService.save_exists(PATH):
		if not ProfileRuntime.load_profile(PATH): get_tree().quit(2);return
		profile = ProfileRuntime.get_profile()
	else:
		profile = ProfileRuntime.new_profile()
		profile.first_mission_completed = true # Skip tutorial only; retain finite starter kit.
		if SaveService.save_profile(profile,PATH) != OK: get_tree().quit(2);return
	if not profile.sortie_checkpoint.is_empty():
		push_error("Campaign probe refuses to overwrite an unfinished sortie.")
		get_tree().quit(2);return
	var before := profile.to_dict()
	var index := profile.successful_sorties + profile.failed_sorties
	var purchases := []
	for ammo in [&"ammo.556_standard",&"ammo.9mm_standard"]:
		var quantity := maxi(0,90-SupplyService.count(profile,ammo))
		if quantity > 0:
			var result := SupplyService.transact("buy",String(ammo),quantity,PATH)
			purchases.append({"id":ammo,"quantity":quantity,"error":result.error})
	var mission: StringName = &"streets_relay" if profile.campaign.stage >= 4 and index%2 == 1 else &"streets_recon"
	var deployed := DeploymentPlan.deploy(profile,&"street_district",mission,PATH)
	if deployed.error != OK: push_error("Campaign deploy failed: "+str(deployed));get_tree().quit(2);return
	var session: SortieSession = deployed.session
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed = 907 + index
	SortieRuntime.layout_seed = battle.loot_seed
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	battle.result_transition_enabled = false
	battle.player.weapon_fired.connect(func(_recoil: float): fired += 1)
	var area: Node3D = battle.area_root
	for tick in 10: await get_tree().physics_frame
	var targets: Array[Node3D] = [area.get_node("StreetTerminal"),area.get_node("StreetSurvey")]
	if mission == &"streets_relay": targets = [area.get_node("RelayOffice"),area.get_node("RelayRepair")]
	# Visit actual spawned indoor supplies, no synthetic loot rolls or material grants.
	for point in area.loot_points:
		if point.enabled and String(point.name).begins_with("IndoorLoot"): targets.append(point)
	for target in targets:
		if not await _walk(target.global_position):
			failures.append("Could not reach "+String(target.name));break
		if target is ObjectiveInteractable:
			target.interact(battle.player,session)
			if target is RelayStation or target is RecordsTerminal:
				for tick in 1800:
					await get_tree().physics_frame
					if battle.player.is_dead or session.get_objective_state(target.objective_id).status == ObjectiveState.Status.COMPLETED: break
					_controls(battle.player.global_position)
					if target.remaining == 0: target.interact(battle.player,session)
		if target is LootSpawnPoint:
			for pickup in target.get_children():
				if pickup is LootPickup and pickup.interact(battle.player,session).success: recovered_ids.append(pickup.item_instance.instance_id)
		print("CAMPAIGN reached ",target.name," health=",battle.player.health)
	if failures.is_empty():
		for exit in area.find_children("*","ExtractionPoint",true,false):
			if exit.available and exit.can_extract(session):
				if await _walk(exit.global_position): exit.extract(session)
				else: failures.append("Cannot reach extraction")
				break
	for action in ACTIONS: Input.action_release(action)
	var stats := {"run":index+1,"seed":907+index,"mission":mission,"shots":fired,"recovered":recovered_ids.size(),"health":battle.player.health,"kills":session.enemies_defeated,"failures":failures,"purchases":purchases,"before":before}
	if session.status != SortieSession.Status.ACTIVE:
		if SortieRuntime.finalize_sortie(PATH) != OK: failures.append("Durable finalize failed")
		while CampaignService.ready(profile):
			if CampaignService.claim(CampaignService.current(profile).id,PATH).error != OK: failures.append("Claim failed");break
	else:
		failures.append("Unfinished route retained as checkpoint")
	stats.after = profile.to_dict()
	stats.failures = failures
	FileAccess.open(out.path_join("campaign_%02d.json"%(index+1)),FileAccess.WRITE).store_string(JSON.stringify(stats))
	print("ALPHA_CAMPAIGN run=",index+1," shots=",fired," kills=",stats.kills," credits=",profile.credits," stage=",profile.campaign.stage," failures=",failures)
	battle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	get_tree().quit(0 if failures.is_empty() else 1)
