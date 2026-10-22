extends "res://tests/campus_q02_run.gd"
var starting_stage := ""
func _deadline_seconds() -> float: return 300.0

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	if "--english" in OS.get_cmdline_user_args():GameLanguage.set_language("en")
	evidence["method"]="Continue actual preceding earned Q02/campus profile via normal menu, work inputs, store buttons and extraction; no progress assignment or fixture items"
	var profile:=ProfileRuntime.get_profile()
	if "--read-complete" in OS.get_cmdline_user_args():
		check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.validate(),"independent process loads valid actual completed profile")
		check(profile.first_mission_completed and profile.ar_damage_upgraded and profile.narrative_slice.settled.Q01 and profile.narrative_slice.settled.Q02 and profile.campus_chapter.finished,"independent process retains six earned resident/campus requests")
		check(profile.successful_sorties>=_expected_returns(6) and profile.failed_sorties==0 and profile.sortie_checkpoint.is_empty(),"independent process retains at least six real safe returns, no pending sortie")
		evidence["profile_after"]=profile.to_dict();_finish();return
	starting_stage=CampusChapter.stage(profile.campus_chapter)
	evidence["stage_before"]=starting_stage;evidence["profile_before"]=profile.to_dict()
	check(profile.narrative_slice.settled.Q02 and (starting_stage in ["relay","power","supply"] or "--bootstrap-only" in OS.get_cmdline_user_args()),"actual earned campus stage is available")
	if not failures.is_empty():_finish();return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	if "--bootstrap-only" in OS.get_cmdline_user_args():
		var before: Dictionary=evidence["profile_before"].duplicate(true)
		var after:=profile.to_dict()
		before.erase("stash_layout");after.erase("stash_layout")
		check(before==after and profile.validate() and profile.sortie_checkpoint.is_empty(),"ordinary BOOT/Continue only initializes owned stash display positions, never gameplay progress or inventory")
		evidence["method"]="Preview preparation via ordinary BOOT/Continue only. All profile fields except stash display layout must remain identical; no field route or rewards."
		evidence["profile_after"]=profile.to_dict()
		_finish();return
	if starting_stage=="supply":
		if not (profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==60):
			await _buy_and_deliver()
		if not failures.is_empty():_finish();return
		if "--pack-only" in OS.get_cmdline_user_args():
			check(profile.successful_sorties==_expected_returns(5) and profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==60 and not profile.campus_chapter.finished and profile.sortie_checkpoint.is_empty(),"real packing-only preview seed has no invented sortie, field receipt or reward")
			evidence["method"]="Normal BOOT and shop/contact inputs prepare actual fifth-return supplies, then stop at base. This is seed preparation, NOT a field handoff route."
			evidence["profile_after"]=profile.to_dict()
			_finish();return
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("01_campus_"+starting_stage+"_brief")
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):_finish();return
	await tree.create_timer(3.0).timeout
	battle=tree.current_scene
	battle.player.weapon_fired.connect(func(_r:float):shots+=1)
	check(battle.session.campus.stage==starting_stage,"ordinary recon deployment has the actual campus story context")
	evidence["mission"]=String(battle.session.mission_id)
	for tick in 120:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(battle.area_root.get_node("StreetNavigation").get_navigation_map())>0:break
	if starting_stage=="relay":
		for name in ["CampusRelayOffice","CampusRelayRepair"]:
			var point: CampusAction=battle.area_root.get_node(name)
			if not await _walk(point.global_position,2.2):_finish();return
			if not await _work(point):_finish();return
			await _capture("02_"+name)
		check(not profile.campus_chapter.relays_returned,"field repairs are not settled before safe return")
		var recorder: CampusAction=battle.area_root.get_node("ExperimentRecorder")
		if not await _walk(recorder.global_position,2.2):_finish();return
		_release();await _frames();await _tap("interact")
		check(not battle.session.campus.recorder_instance.is_empty() and battle.session.inventory.contains(battle.session.campus.recorder_instance),"actual E takes physical recorder after real repairs")
		evidence["recorder_instance"]=battle.session.campus.recorder_instance
		await _capture("03_real_recorder")
	elif starting_stage=="power":
		var point: CampusAction=battle.area_root.get_node("L02BranchControl")
		if not await _walk(Vector3(-38.7,0,-28) if point._encounter() else point.global_position, .2 if point._encounter() else 2.2):_finish();return
		if point._encounter() and not await _precise_walk(Vector3(-38.7,0,-28)):_finish();return
		if not await _work(point):_finish();return
		check(battle.session.campus.power_cut and battle.session.campus.power_confirmed,"actual confirmed field action cuts experimental branch only")
		await _capture("04_real_branch_off")
	elif starting_stage=="supply":
		check(battle.session.campus.gear_ready and not profile.campus_chapter.finished,"base packing is real but does not bypass field handoff")
		var handoff:=battle.area_root.get_node_or_null("CampusSupplyHandoff") as CampusSupplyHandoff
		if handoff:
			if not await _walk(handoff.global_position+Vector3(0,0,1),.6):_finish();return
			for tick in 2400:
				await tree.physics_frame
				if battle.player.is_dead:failures.append("Died during actual dormitory approach");_finish();return
				if handoff.threats_remaining()==0:break
				_controls(battle.player.global_position)
			_release();await _frames();await _capture("04a_dormitory_approach")
			await _tap("interact")
			for tick in 300:
				await tree.physics_frame
				if battle.session.campus.supply_received:break
				_controls(battle.player.global_position)
			_release()
			check(battle.session.campus.supply_received and not profile.campus_chapter.finished,"normal E sends actual packed equipment inside; safe extraction still required")
			await _capture("04b_dormitory_received")
			if not failures.is_empty():_finish();return
	var retreat: ExtractionPoint
	for i in 4:
		var exit: ExtractionPoint=battle.area_root.get_node("Exit%d"%i)
		if exit.available and exit.required_objective_id.is_empty():retreat=exit
	if not await _walk(retreat.global_position,0.4):_finish();return
	_release();await _frames();await _tap("interact")
	check(battle.session.status==SortieSession.Status.COMPLETED,"normal E at open campus exit completes story sortie")
	evidence["shots"]=shots;evidence["health"]=battle.player.health;evidence["kills"]=battle.session.enemies_defeated
	if not await _wait_scene("res://scenes/result/result.tscn"):_finish();return
	await _capture("05_"+starting_stage+"_debrief")
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	if starting_stage=="relay":check(profile.campus_chapter.relays_returned and profile.campus_chapter.recorder_returned,"safe return settles actual relays plus carried recorder")
	elif starting_stage=="power":check(profile.campus_chapter.power_returned,"safe return settles actual branch action")
	else:check(profile.campus_chapter.finished,"real post-delivery field extraction completes campus chapter")
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("06_"+starting_stage+"_returned")
	evidence["stage_after"]=CampusChapter.stage(profile.campus_chapter);evidence["profile_after"]=profile.to_dict()
	_finish()

func _work(point: CampusAction) -> bool:
	_release();await _frames()
	evidence["work_target"]={"actual":str(battle.player.interaction_component._current_target),"player":str(battle.player.position),"control":str(point.position)}
	check(battle.player.interaction_component._current_target==point,"normal nearby interaction selects actual campus device")
	await _tap("interact")
	if point.kind==&"power":
		check(is_instance_valid(point.choice_layer),"normal E opens power choice without changing branch")
		if not is_instance_valid(point.choice_layer):return false
		await _capture("03_power_choice")
		await _click(point.choice_layer.find_child("ConfirmBranch",true,false))
		if point._encounter():return await _charge_work(point)
	for tick in 2400:
		await tree.physics_frame
		if battle.player.is_dead:failures.append("Died during real campus work");return false
		var done: bool=String(point.action_id) in battle.session.campus.relays if point.kind==&"relay" else battle.session.campus.power_cut
		if done:_release();return true
		_controls(battle.player.global_position)
		if point.remaining<=0 and not is_instance_valid(point.choice_layer):
			_release();await _tap("interact")
			if point.kind==&"power" and is_instance_valid(point.choice_layer):await _click(point.choice_layer.find_child("ConfirmBranch",true,false))
	failures.append("Actual campus work did not complete");return false

func _buy_and_deliver() -> void:
	var profile:=ProfileRuntime.get_profile()
	await _click(tree.current_scene.find_child("NavWorkshop",true,false))
	await _click(tree.current_scene.screen.get_node("ContactPanel").find_child("Contact_shen_yanshuang",true,false))
	var loadout:=profile.loadout.to_dict()
	var ammo_before:=SupplyService.count(profile,&"ammo.556_standard")
	var credits_before:=profile.credits
	var price:=SupplyService.buy_price(ContentDB.get_item(&"armor.recon_shell_01"),profile)+60*SupplyService.buy_price(ContentDB.get_item(&"ammo.556_standard"),profile)
	var panel=tree.current_scene.screen.get_node("ContactPanel")
	var buy: Button=panel.find_child("Supply_buy_armor_recon_shell_01",true,false)
	check(buy!=null and not buy.disabled,"normal combat shop offers spare recon armor")
	await _scroll(buy);await _click(buy)
	for i in 2:
		panel=tree.current_scene.screen.get_node("ContactPanel")
		buy=panel.find_child("Supply_buy_ammo_556_standard",true,false)
		await _scroll(buy);await _click(buy)
	check(SupplyService.count(profile,&"ammo.556_standard")==ammo_before+60 and profile.loadout.to_dict()==loadout,"two real default 30-round purchases and spare armor leave equipped loadout alone")
	check(profile.credits==credits_before-price,"normal store purchases charge the displayed armor and round prices")
	await _capture("00_spare_supplies_bought")
	await _click(panel.find_child("ContactQuests",true,false))
	var submit: Button=panel.find_child("SubmitCampusEquipment",true,false)
	check(submit!=null and not submit.disabled,"normal contact exposes spare-equipment hand-in")
	await _scroll(submit);await _click(submit)
	check(profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==60 and not profile.campus_chapter.finished and profile.loadout.to_dict()==loadout,"real hand-in consumes spares, not worn armor, and does not finish early")
	await _capture("00_equipment_delivered")

# Input-only v3 controller: demonstrate the authored counterplay, then fight normally.
# No target relocation, damage calls, health/ammo grants or direct world-state writes.
func _controls(destination: Vector3) -> void:
	super._controls(destination)
	var encounter:=battle.area_root.get_node_or_null("CampusPowerEncounter") as CampusPowerEncounter
	if encounter and encounter.phase==CampusPowerEncounter.Phase.ACTIVE:
		var ram:=encounter.rammer()
		if ram and ram.wall_impacts==0:Input.action_release("fire")

func _precise_walk(destination: Vector3) -> bool:
	for tick in 240:
		await tree.physics_frame
		var gap:=Vector2(destination.x-battle.player.position.x,destination.z-battle.player.position.z)
		if gap.length()<.3:_release();return true
		_controls(destination)
	failures.append("Could not reach actual charge bait position");return false

func _charge_work(point: CampusAction) -> bool:
	var encounter:=point._encounter()
	var proof:={"windup_seen":false,"committed_direction":[],"wall_impacts":0,"player_impacts":0,"ordinary_shots_before":shots}
	evidence["power_encounter"]=proof
	var captured_wall:=false
	for tick in 2400:
		await tree.physics_frame
		if battle.player.is_dead:failures.append("Died during actual charger encounter");return false
		var ram:=encounter.rammer()
		if ram:
			proof.wall_impacts=maxi(proof.wall_impacts,ram.wall_impacts);proof.player_impacts=maxi(proof.player_impacts,ram.player_impacts)
			if ram.ram_phase==CampusRammer.Phase.WINDUP and not proof.windup_seen:
				proof.windup_seen=true;proof.committed_direction=[ram.ram_direction.x,ram.ram_direction.y,ram.ram_direction.z]
				await _capture("03b_committed_charge")
			if ram.wall_impacts>0 and not captured_wall:
				captured_wall=true
				_controls(battle.player.global_position);Input.action_release("fire")
				await _frames(3);_release();await _capture("03c_actual_wall_stun")
			_controls(Vector3(-41,0,-28) if proof.windup_seen and proof.wall_impacts==0 else battle.player.global_position)
		if encounter.phase==CampusPowerEncounter.Phase.CLEARED:
			_release()
			check(proof.windup_seen and proof.wall_impacts>0 and proof.player_impacts==0,"ordinary movement sidesteps committed charge and baits actual workshop wall, without collision hit")
			check(not battle.session.campus.power_cut,"live combat victory still requires console interaction")
			if not await _walk(point.global_position,2.0):return false
			_release();await _frames();await _tap("interact")
			proof.ordinary_shots_after=shots;proof.frames=tick
			return battle.session.campus.power_cut
	failures.append("Actual charger encounter did not complete");return false
