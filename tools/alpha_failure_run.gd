extends "res://tests/streets_combat_run.gd"
## Deliberately non-defending controller; measures real death/resupply continuity,
## not human difficulty. Does not inject damage, money, items or enemy state.
const PATH := "user://alpha_failure_run.json"
func _controls(destination: Vector3) -> void:
	for action in ACTIONS: Input.action_release(action)
	var gap: Vector3 = destination-battle.player.global_position
	gap.y = 0
	var motion: Vector3 = gap.normalized() if gap.length()>.25 else Vector3.ZERO
	_axis("move_left","move_right",motion.x)
	_axis("move_forward","move_back",motion.z)

func _run() -> void:
	var out := OS.get_environment("BUNNY_EVIDENCE")
	if out.is_empty(): get_tree().quit(2);return
	if SaveService.save_exists(PATH) and not ProfileRuntime.load_profile(PATH): get_tree().quit(2);return
	var profile := ProfileRuntime.get_profile()
	if not profile.sortie_checkpoint.is_empty(): push_error("Unfinished failure probe retained; refusing overwrite");get_tree().quit(2);return
	var before := profile.to_dict()
	var round_index := profile.failed_sorties + profile.successful_sorties + 1
	var transactions := []
	if SupplyService.can_claim_relief(profile):
		var relief := SupplyService.transact("relief","",1,PATH)
		transactions.append({"action":"relief","error":relief.error})
		if relief.error != OK: failures.append("Relief refused despite eligibility")
		if SupplyService.transact("relief","",1,PATH).error == OK: failures.append("Duplicate relief granted")
	elif profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY).is_empty():
		var buy := SupplyService.transact("buy","weapon.pistol_01",1,PATH)
		transactions.append({"action":"buy_pistol","error":buy.error})
		if buy.error != OK: failures.append("Cannot afford replacement pistol")
		for item in profile.inventory.get_items():
			if item.definition_id == &"weapon.pistol_01": profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,item.instance_id,profile.inventory);break
		var rounds := maxi(0,15-SupplyService.count(profile,&"ammo.9mm_standard"))
		if rounds > 0:
			var ammo := SupplyService.transact("buy","ammo.9mm_standard",rounds,PATH)
			transactions.append({"action":"buy_rounds","quantity":rounds,"error":ammo.error})
			if ammo.error != OK: failures.append("Cannot afford minimal ammunition")
		if SaveService.save_profile(profile,PATH) != OK: failures.append("Loadout save failed")
	if not failures.is_empty(): push_error(str(failures));get_tree().quit(2);return
	var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH)
	if deployed.error != OK: push_error(str(deployed));get_tree().quit(2);return
	var session: SortieSession = deployed.session
	var carried := session.get_initial_carried_instance_ids()
	var at_deploy := profile.to_dict()
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed = 907
	SortieRuntime.layout_seed = 907
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	battle.result_transition_enabled = false
	for tick in 10: await get_tree().physics_frame
	var retreat := "--retreat" in OS.get_cmdline_user_args()
	if retreat:
		for exit in battle.area_root.find_children("*","ExtractionPoint",true,false):
			if exit.available and exit.can_extract(session):
				if await _walk(exit.global_position): exit.extract(session)
				break
	else:
		var nearest: EnemyController
		for enemy in battle.enemy_container.get_children():
			if not nearest or battle.player.global_position.distance_to(enemy.global_position)<battle.player.global_position.distance_to(nearest.global_position): nearest=enemy
		if nearest: await _walk(nearest.global_position)
		for action in ACTIONS: Input.action_release(action)
		for tick in 12000:
			if battle.player.is_dead: break
			await get_tree().physics_frame
		if not battle.player.is_dead or session.status != SortieSession.Status.FAILED: failures.append("Real enemy did not produce terminal death")
	if retreat and session.status != SortieSession.Status.COMPLETED: failures.append("Retreat did not successfully extract")
	var health: float = battle.player.health
	var taken: int = session.damage_taken
	for action in ACTIONS: Input.action_release(action)
	if session.status == SortieSession.Status.ACTIVE: failures.append("Unfinished attempt preserved")
	else:
		if "--capture-result" in OS.get_cmdline_user_args():
			get_tree().root.remove_child(battle)
			var result_scene: Node = load("res://scenes/result/result.tscn").instantiate()
			get_tree().root.add_child(result_scene)
			get_tree().current_scene = result_scene
			for locale in ["en","zh_CN"]:
				GameLanguage.set_language(locale,false)
				for frame in 6: await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out.path_join("empty_result_"+locale+".png"))
			result_scene.free()
		if SortieRuntime.finalize_sortie(PATH) != OK: failures.append("Finalization failed")
		if not retreat and not ArmoryFixture.loss_matches(profile,at_deploy,carried): failures.append("Loss did not match actual deployed IDs")
	var report := {"run":round_index,"retreat":retreat,"before":before,"after":profile.to_dict(),"transactions":transactions,"health":health,"damage":taken,"carried":carried,"failures":failures}
	FileAccess.open(out.path_join("attempt_%02d.json"%round_index),FileAccess.WRITE).store_string(JSON.stringify(report))
	print("ALPHA_FAILURE run=",round_index," retreat=",retreat," health=",health," damage=",taken," credits=",profile.credits," failures=",failures)
	battle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	get_tree().quit(0 if failures.is_empty() else 1)
