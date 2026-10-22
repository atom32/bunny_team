extends Node
var checks := 0
var failures: Array[String] = []
var battle: Node3D
const PATH := "user://waterworks_test.json"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames() -> void:
	for tick in 4: await get_tree().physics_frame

func click(button: Button) -> void:
	if DisplayServer.get_name()=="headless":button.pressed.emit();return
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		get_viewport().push_input(event)
		await get_tree().process_frame
	await frames()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png")) == OK,"native waterworks capture saved")

func start() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
	check(DeploymentPlan.deploy(profile,WaterworksStory.AREA,WaterworksStory.MISSION,PATH).error == OK,"actual new area deployment persists")
	battle = load("res://scenes/battle/battle.tscn").instantiate(); battle.result_transition_enabled = false; add_child(battle)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	battle.player.set_physics_process(false)
	await frames()

func use(name: String) -> Dictionary:
	var point: WaterworksAction = battle.area_root.get_node(name)
	battle.player.position = point.position + Vector3.RIGHT
	return point.interact(battle.player,battle.session)

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	SortieRuntime.clear_session()
	var initial := ProfileRuntime.new_profile(); initial.first_mission_completed=true
	var home: Node3D=load("res://scenes/presentation/slice/hideout.tscn").instantiate();add_child(home);home.show_section("Operations")
	await frames()
	var choices:=home.find_child("MissionChoice",true,false) as OptionButton
	var index:=DeploymentPlan.STREET_MISSIONS.find(WaterworksStory.MISSION)
	check(index>=0 and choices.item_count==DeploymentPlan.STREET_MISSIONS.size(),"normal Operations menu includes the new expedition")
	choices.select(index);choices.item_selected.emit(index)
	await frames()
	check(home.find_child("MissionBriefing",true,false).text.contains(tr(ContentDB.get_mission(WaterworksStory.MISSION).display_name)),"selecting new mission displays its own briefing, not campus chores")
	check(home.find_child("LightingChoice",true,false).disabled,"new authored dawn does not pretend to have a night variant")
	await capture("waterworks_operations")
	home.free();DeploymentPlan.selected_street_mission=&"streets_recon"
	check(ContentDB.get_mission(WaterworksStory.MISSION).validate_definition() and ContentDB.get_area_definition(WaterworksStory.AREA).validate_definition(),"registered real mission and separate authored map")
	check(ContentDB.get_item(WaterworksStory.CELL).weight == 8,"battery is actual eight-kilo carried item")
	check(DeploymentPlan.area_for_mission(WaterworksStory.MISSION) == WaterworksStory.AREA,"normal mission selector deploys new area, not campus reskin")
	for branch in ["public","tanker"]:
		await start()
		var world: Node3D = battle.area_root
		var session: SortieSession = battle.session
		check(session.campus.is_empty() and not session.q02_active and session.slice_context.is_empty(),"new expedition never fabricates campus quest progress")
		check(battle.enemy_container.get_child_count() == 13,"market and pump district contain thirteen authored live enemies")
		check(world.get_node("Retreat").can_extract(session) and not world.get_node("PublicExit").can_extract(session) and not world.get_node("TankerExit").can_extract(session),"retreat open before delivery, both reward exits locked")
		check(not use("Pump").success,"cannot install without physical battery")
		check(not use("PublicValve").success and not use("TankerValve").success,"cannot choose a delivery before pumping")
		var weight := session.inventory.current_weight
		var capacity := session.inventory.capacity
		session.inventory.capacity = weight + 7
		check(not use("Battery").success and not WaterworksStory.done(session,&"water_battery"),"insufficient capacity does not grant or mark battery")
		session.inventory.capacity = capacity
		check(use("Battery").success and is_equal_approx(session.inventory.current_weight,weight+8),"real battery increases carry weight by eight")
		check(not use("Battery").success,"fixed battery cannot be duplicated")
		var guard: EnemyController = battle.enemy_container.get_child(0)
		guard.awareness = EnemyAwareness.new(); guard.ensure_awareness(); guard.set_physics_process(true)
		check(use("Decoy").success and guard.awareness.last_known.is_equal_approx(world.get_node("Loudspeaker").global_position),"broadcast attracts actual hearing to the square, never remote player coordinates")
		guard.set_physics_process(false)
		check(not use("Decoy").success and battle.enemy_container.get_child_count()==13,"decoy is once per sortie and invents no extra enemies")
		check(use("Pump").success,"actual timed installation starts")
		var pump: WaterworksAction = world.get_node("Pump")
		pump._process(3)
		pump._health_changed(pump.observed_health-1,260)
		check(pump.remaining == 0 and WaterworksStory.battery(session)!=null and not WaterworksStory.done(session,&"water_pump"),"damage interrupts without consuming battery")
		check(use("Pump").success,"work can restart")
		pump._process(2)
		get_tree().paused = true
		check(SortieRuntime.save_checkpoint() == OK,"save mid-installation through actual persistence")
		var cell_id := WaterworksStory.battery(session).instance_id
		battle.free(); SortieRuntime.clear_session()
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK,"reload and resume new area checkpoint")
		battle = load("res://scenes/battle/battle.tscn").instantiate(); battle.result_transition_enabled = false; add_child(battle)
		world = battle.area_root; session = battle.session; pump = world.get_node("Pump")
		check(not FlowMenu.is_open() and pump.remaining == 6 and WaterworksStory.battery(session).instance_id == cell_id,"resume exact remaining work and same physical battery")
		get_tree().paused = false
		pump._process(6)
		check(WaterworksStory.done(session,&"water_pump") and WaterworksStory.battery(session)==null and world.get_node("WaterFlow").visible,"finished pump consumes one battery and shows flow")
		var chosen := "PublicValve" if branch == "public" else "TankerValve"
		var other := "TankerValve" if branch == "public" else "PublicValve"
		var point: WaterworksAction = world.get_node(chosen)
		check(use(chosen).success and is_instance_valid(point.choice_layer) and not session.is_mission_completed(),"inspection opens explicit confirmation without committing route")
		await frames()
		await capture("waterworks_"+branch+"_choice")
		await click(point.choice_layer.get_node("DeliveryConfirmation").find_child("CancelDelivery",true,false))
		check(not WaterworksStory.done(session,&"water_delivery"),"cancel preserves both routes")
		use(chosen)
		await click(point.choice_layer.get_node("DeliveryConfirmation").find_child("ConfirmDelivery",true,false))
		check(not session.is_mission_completed() and session.waterworks.branch==branch and session.validate(),"confirmation commits a route, NOT a completed delivery")
		check(not world.get_node("PublicReward").has_rolled and not world.get_node("TankerReward").has_rolled,"confirmation gives no premature reward")
		check(battle.enemy_container.get_child_count()==15,"choice response adds exactly two guards to thirteen initial market/district enemies")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		battle.player.set_physics_process(false)
		if branch=="public":
			var latch: WaterPublicLatch=world.get_node("Latch")
			check(latch.receive_damage(DamagePacket.new(0,0,16,null,&"test",&"enemy"))==0,"enemy fire cannot complete player relief action")
			latch.receive_damage(DamagePacket.new(0,0,4,battle.player,&"fixture",&"player"))
			check(latch.current_structure_health==12 and not latch.destroyed,"fixture damage leaves real partially damaged latch")
			battle.player.position=Vector3(-25,0,-18);world.jet_cooldown=0
			var damage:=session.damage_taken;world._physics_process(0)
			check(session.damage_taken>damage,"active pressure jet applies real player damage")
			battle.player.position=world.get_node("Bypass").position+Vector3.BACK
			check(world.get_node("Bypass").interact(battle.player,session).success,"physical west bypass relieves pressure without ammunition")
			check(not world.get_node("PressureJet").visible and not latch.destroyed,"bypass stops the jet without pretending latch was shot")
			for tick in 420:await get_tree().physics_frame
			check(world.get_node("Resident0").arrived and world.get_node("Resident1").arrived,"both adult placeholder residents actually walk to the flowing courtyard tap")
		else:
			var truck: WaterTanker=world.get_node("Tanker")
			battle.player.position=truck.position+Vector3.LEFT*2.4
			check(truck.interact(battle.player,session).success,"physical handbrake releases truck")
			truck._physics_process(1)
			check(truck.progress>0 and truck.progress<truck.GATE_STOP,"truck really moves before loading gate")
			truck.moving=false # Controlled checkpoint fixture, not normal-input route.
			get_tree().paused=true
			var saved_progress:=truck.progress
			check(SortieRuntime.save_checkpoint()==OK,"suspend physically moved truck")
			battle.free();SortieRuntime.clear_session()
			check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"resume actual partial truck checkpoint")
			battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
			world=battle.area_root;session=battle.session;truck=world.get_node("Tanker");get_tree().paused=false
			for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
			battle.player.set_physics_process(false)
			check(is_equal_approx(truck.progress,saved_progress) and truck.position==truck.START+Vector3.FORWARD*saved_progress,"resume derives matching collider position without resetting truck")
			battle.player.position=Vector3(28,0,-31)
			check(world.get_node("LoadingLever").interact(battle.player,session).success,"physical lever raises real loading gate")
			truck.moving=true
			for tick in 540:await get_tree().physics_frame
			check(truck.progress==truck.DISTANCE and not truck.moving,"actual truck arrives in north yard and stops")
			check(not world.get_node("TankerWater").visible,"legacy loading stream does not float in empty bay after truck leaves")
		check(session.is_mission_completed() and session.validate(),"onsite route work, not button alone, completes delivery")
		battle.player.position=Vector3(-38,0,-20) if branch=="public" else Vector3(30,0,-38)
		await frames()
		await capture("waterworks_"+branch+"_delivered")
		var forged := SortieCheckpoint.session_data(session)
		for state in forged.objectives:
			if state.objective_id == ("water_tanker" if branch=="public" else "water_public"):state.status=ObjectiveState.Status.COMPLETED;state.progress=1
		check(SortieCheckpoint.restore_session(forged)==null,"tampered save cannot select both delivery branches")
		check(not use(other).success,"other valve cannot grant the second route")
		var exit: ExtractionPoint = world.get_node("PublicExit" if branch == "public" else "TankerExit")
		check(exit.can_extract(session) and not world.get_node("TankerExit" if branch == "public" else "PublicExit").can_extract(session),"only chosen alternate exit opens")
		var reward: LootSpawnPoint = world.get_node("PublicReward" if branch == "public" else "TankerReward")
		var pickups := reward.get_children().filter(func(child): return child is LootPickup)
		check((pickups.size()==2 and pickups[0].item_instance.quantity==1 and pickups[1].item_instance.quantity==1) if branch=="public" else (pickups.size()==1 and pickups[0].item_instance.quantity==90),"chosen delivery unlocks its promised physical supply, not text-only reward")
		var reward_id: String = pickups[0].item_instance.instance_id
		check(pickups[0].interact(battle.player,session).success,"reward actually enters carried inventory")
		if branch=="public": check(pickups[1].interact(battle.player,session).success,"second nonstackable dressing actually recovered")
		get_tree().paused = true
		check(SortieRuntime.save_checkpoint()==OK,"save completed branch and picked-up reward")
		battle.free();SortieRuntime.clear_session()
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"branch resumes through saved file")
		battle = load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		session=battle.session;world=battle.area_root;get_tree().paused=false
		check(session.inventory.contains(reward_id) and world.get_node("PublicReward" if branch=="public" else "TankerReward").get_children().filter(func(child):return child is LootPickup).is_empty(),"resume preserves reward identity without reroll/duplication")
		exit=world.get_node("PublicExit" if branch=="public" else "TankerExit")
		check(exit.extract(session),"new route actually extracts")
		var outcome := SortieRuntime.get_outcome()
		check(outcome != null and not WaterworksStory.ending(outcome).is_empty(),"branch has matching actual result epilogue")
		check(SortieRuntime.finalize_sortie(PATH)==OK and ProfileRuntime.get_profile().inventory.contains(reward_id),"return commits real recovered supply to warehouse")
		check(ProfileRuntime.get_profile().waterworks_memory == ("water_public" if branch == "public" else "water_tanker"), "Real valve, reward pickup, resume and extraction commit matching base conversation")
		battle.free();battle=null;SortieRuntime.clear_session()
	# A battery brought home via the unconditional retreat is useful next time,
	# not an eight-kilo dead quest object stuck in the warehouse.
	await start()
	check(use("Battery").success,"retry fixture takes real battery")
	var retained_id := WaterworksStory.battery(battle.session).instance_id
	check(battle.area_root.get_node("Retreat").extract(battle.session) and SortieRuntime.finalize_sortie(PATH)==OK,"early retreat actually returns battery to warehouse")
	battle.free();SortieRuntime.clear_session()
	var stored := ProfileRuntime.get_profile()
	check(stored.inventory.contains(retained_id),"warehouse retains exact recovered battery identity")
	check(DeploymentPlan.deploy(stored,WaterworksStory.AREA,WaterworksStory.MISSION,PATH).error==OK,"next waterworks sortie packs recovered battery through normal deployment")
	check(WaterworksStory.battery(SortieRuntime.get_current_session()).instance_id==retained_id,"same battery returns to the field, not a free replacement")
	check(SortieRuntime.get_current_session().fail() and SortieRuntime.finalize_sortie(PATH)==OK and not ProfileRuntime.get_profile().inventory.contains(retained_id),"redeployed battery is genuinely at risk on death")
	SortieRuntime.clear_session()
	await frames()
	AudioDirector.shutdown_for_test()
	print("WATERWORKS_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
