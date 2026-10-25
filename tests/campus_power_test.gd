extends "res://tests/campus_chapter_test.gd"
## Controlled placements and damage fixtures, not an earned campaign run.
var checks:=0

func chapter_path() -> String:return "user://campus_power_test.json"

func check(ok: bool,message: String) -> void:
	checks+=1
	super.check(ok,message)

func frames(count:=3) -> void:
	for index in count:await get_tree().physics_frame

func freeze() -> void:
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.area_root.get_node("CampusPowerEncounter").set_physics_process(false)

func check_hardware(control: CampusAction, guarded: bool, cut: bool, context: String) -> void:
	var hardware:=control.get_node_or_null("BranchHardware") as Node3D
	check(hardware!=null,context+": v3 control has its actual safety covers and lever")
	if not hardware:return
	check(is_equal_approx(hardware.get_node("ShelterCover").rotation.x,0.0 if guarded else CampusPowerEncounter.COVER_OPEN) and is_equal_approx(hardware.get_node("ExperimentCover").rotation.x,CampusPowerEncounter.COVER_OPEN if guarded else 0.0),context+": A is covered only after confirmation; B is exposed, not cut")
	check(absf(wrapf(hardware.get_node("ExperimentLever").rotation.z-(PI if cut else 0.0),-PI,PI))<.00001 and (control.get_node("BranchBLight").light_energy==0)==cut and control.get_node("BranchALight").light_energy>0,context+": only the real cut moves B OFF; shelter power stays on")
	check(hardware.get_node("ShelterCover/ShelterNote").text==tr(CampusPowerEncounter.SHELTER_NOTE),context+": the visible paper carries the translated patient's label")

func report() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("CAMPUS_POWER_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _ready() -> void:
	await get_tree().process_frame
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var args:=OS.get_cmdline_user_args()

	if "--legacy-read" in args:
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"genuine previous-v2-code checkpoint is accepted")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		battle.player.set_physics_process(false)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
		check(not FlowMenu.is_open() and battle.session.campus.version==2 and not control._encounter(),"old suspended route never acquires new enemies or rules")
		check(not control.has_node("BranchHardware"),"old v2 continuation does not acquire new covers, labels or lever geometry")
		check(is_equal_approx(control.remaining,4) and not battle.session.campus.power_cut,"old remaining four seconds survive real signed-layout recovery")
		control._process(control.remaining)
		check(battle.session.campus.power_cut and control.get_node("BranchALight").light_energy>0,"old work still completes original safe branch cut")
		await finish_world(true)
		check(ProfileRuntime.get_profile().campus_chapter.power_returned,"legacy continuation can settle only after actual extraction")
		report();return
	if "--read" in args:
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"independent process accepts pending charge checkpoint")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		freeze()
		var encounter:=battle.area_root.get_node("CampusPowerEncounter") as CampusPowerEncounter
		var ram:=encounter.rammer()
		check(not FlowMenu.is_open() and ram!=null,"resume does not silently discard encounter")
		if not ram:report();return
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://ram_expected.json"))
		var actual:=ram.ram_snapshot()
		var same: bool=actual.phase==expected.phase and actual.wall_impacts==expected.wall_impacts and actual.player_impacts==expected.player_impacts
		for key in ["remaining","traveled"]:same=same and absf(actual[key]-expected[key])<.000001
		for index in 3:same=same and absf(actual.direction[index]-expected.direction[index])<.000001
		check(same,"phase/counters survive exactly; committed direction, timer and travel within JSON/physics precision 1e-6")
		check(not battle.session.campus.power_cut and encounter.phase==CampusPowerEncounter.Phase.ACTIVE,"pending charge never becomes a free branch cut")
		var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
		check_hardware(control,true,false,"independent active restore")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"resumed physical world is still strict-valid")
		ram.take_damage(1000);encounter._physics_process(0)
		battle.player.position=control.position+Vector3.RIGHT
		check(control.interact(battle.player,battle.session).success and battle.session.campus.power_cut,"restored encounter can finish through real control action")
		check_hardware(control,true,true,"independent restored cut")
		var profile:=ProfileRuntime.get_profile();var credits:=profile.credits
		await finish_world(true)
		check(profile.campus_chapter.power_returned and profile.credits==credits+CampusChapter.POWER_REWARD,"safe return, not the charge checkpoint, grants power reward once")
		report();return
	var profile:=profile_at_batch2()
	profile.campus_chapter.relays_returned=true;profile.campus_chapter.recorder_revealed=true;profile.campus_chapter.recorder_returned=true
	check(profile.validate(),"explicit power-stage fixture is valid")
	await start_world();freeze();await frames()
	var encounter:=battle.area_root.get_node("CampusPowerEncounter") as CampusPowerEncounter
	var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
	check(encounter!=null and encounter.phase==CampusPowerEncounter.Phase.IDLE,"fresh v3 power sortie has idle authored encounter")
	check_hardware(control,false,false,"idle")
	var hardware:=control.get_node("BranchHardware") as Node3D
	check(hardware.find_children("*","CollisionShape3D",true,false).is_empty() and hardware.find_children("*","CollisionObject3D",true,false).is_empty() and SortieCheckpoint.layout_signature(battle.area_root)==battle.checkpoint_layout_signature,"new hardware is non-colliding presentation and leaves the signed layout unchanged")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"idle world checkpoint is valid")
	battle.player.position=Vector3(-38.7,0,-28)
	check(not control.confirm_power(),"cannot start without explicit branch choice")
	var unconfirmed_count: int=battle.enemy_container.get_child_count()
	control.interact(battle.player,battle.session)
	check(control.choice_layer.find_child("PowerOperation",true,false).text==tr(CampusPowerEncounter.OPERATION) and control.choice_layer.find_child("ConfirmBranch",true,false).text==tr(CampusPowerEncounter.CONFIRM),"scene separates character conflict from clear current-operation instructions")
	var backing:=control.choice_layer.find_child("PowerChoice",true,false).get_theme_stylebox("panel") as StyleBoxFlat
	check(backing!=null and backing.bg_color.a==1.0,"current-operation dialogue has an opaque backing against world labels")
	control.choice_layer.find_child("CancelBranch",true,false).pressed.emit()
	check(encounter.phase==CampusPowerEncounter.Phase.IDLE and not encounter.rammer(),"declining spawns nothing and changes no power")
	check(battle.enemy_container.get_child_count()==unconfirmed_count,"cancel leaves every enemy count unchanged")
	check_hardware(control,false,false,"cancelled")
	# A failed start is an explicit fixture: temporarily withhold every group's
	# spawn membership, then put it back. Neither power nor the hardware may lie.
	for point in encounter.get_children():
		if point is EnemySpawnPoint:point.activation_group_id=&"fixture_no_power_group"
	control.interact(battle.player,battle.session)
	check(not control.confirm_power() and encounter.phase==CampusPowerEncounter.Phase.IDLE and battle.enemy_container.get_child_count()==unconfirmed_count,"unavailable encounter cannot publish confirmation or create partial actors")
	check_hardware(control,false,false,"failed start")
	for point in encounter.get_children():
		if point is EnemySpawnPoint:point.activation_group_id=CampusPowerEncounter.GROUP
	control.interact(battle.player,battle.session)
	check(control.confirm_power(),"actual branch confirmation releases encounter")
	check_hardware(control,true,false,"confirmed before combat")
	freeze();await frames()
	var ram:=encounter.rammer()
	check(ram!=null and ram.health==55 and control.remaining==0,"charger is real, finite and replaces rather than extends timer")
	if not ram:report();return
	var spawned: int=battle.enemy_container.get_child_count()
	check(not encounter.begin(battle.player) and spawned==battle.enemy_container.get_child_count(),"repeated confirmation cannot duplicate three actors")
	control._process(600)
	check(not battle.session.campus.power_cut and not control.interact(battle.player,battle.session).success,"waiting or interacting during charge cannot bypass encounter")
	ram.target=battle.player;ram.awareness.state=EnemyAwareness.State.COMBAT;ram.awareness.last_known=battle.player.position
	ram._telegraph_shot();ram._physics_process(.15)
	check(ram.ram_phase==CampusRammer.Phase.WINDUP and ram._shot_timer==null and not ram._is_telegraphing,"charger has one explicit checkpointable windup, no hidden async punch")
	await capture("01_committed_lane")
	var committed:=ram.ram_direction
	ram._telegraph_shot()
	check(ram.ram_direction==committed and is_equal_approx(ram.ram_remaining,.8),"second windup request cannot reset attack")
	var world:=SortieCheckpoint.capture_world(battle)
	hardware.get_node("ShelterCover").rotation.x=.3;hardware.get_node("ExperimentCover").rotation.x=.4;hardware.get_node("ExperimentLever").rotation.z=PI
	check(SortieCheckpoint.validate_world(world,battle) and SortieCheckpoint.restore_world(world,battle),"active windup captures and restores strict physical state")
	check_hardware(control,true,false,"active derived restore")
	check(not world.nodes.has("L02BranchControl/BranchHardware"),"covers and lever require no new checkpoint node or mutable save field")
	var key: String=ram.get_meta("spawn_key")
	for bad in [null,{}, {"phase":1}, {"phase":1,"remaining":.8,"direction":[0,0,0],"traveled":0,"wall_impacts":0,"player_impacts":0}, {"phase":1,"remaining":99,"direction":[0,0,1],"traveled":0,"wall_impacts":0,"player_impacts":0}]:
		var forged:=world.duplicate(true);forged.enemies[key].ram=bad
		check(not SortieCheckpoint.validate_world(forged,battle),"malformed committed attack is rejected before mutation")
	for path in ["CampusPowerEncounter","CampusPowerEncounter/Ram","CampusPowerEncounter/Follower0"]:
		var forged:=world.duplicate(true)
		if path=="CampusPowerEncounter":forged.nodes[path].phase=CampusPowerEncounter.Phase.CLEARED
		else:forged.nodes[path].has_spawned=false
		check(not SortieCheckpoint.validate_world(forged,battle),"phase and once-only spawn flags must agree with living charger")
	var forged:=world.duplicate(true);forged.nodes.L02BranchControl.remaining=1
	check(not SortieCheckpoint.validate_world(forged,battle),"v3 cannot smuggle the retired timer into a checkpoint")
	if "--write" in args:
		if "--charge" in args:ram._physics_process(.81)
		if "--stun" in args:ram._recover(true)
		var file:=FileAccess.open("user://ram_expected.json",FileAccess.WRITE);file.store_string(JSON.stringify(ram.ram_snapshot()));file.close()
		check(SortieRuntime.save_checkpoint()==OK,"durable pending charge fixture written for independent process")
		report();return
	# Physics counterplay in the actual workshop. Other actors are explicitly frozen.
	var health: float=battle.player.health
	battle.player.position=Vector3(-41,0,-28)
	ram.set_physics_process(true)
	for tick in 180:
		await get_tree().physics_frame
		if ram.wall_impacts>0:break
	ram.set_physics_process(false)
	check(ram.ram_direction==committed and ram.player_impacts==0 and battle.player.health==health,"sidestep avoids a non-homing real collision attack")
	check(ram.wall_impacts==1 and ram.ram_phase==CampusRammer.Phase.STUN,"existing workshop wall physically stuns charger")
	await capture("02_real_wall_stun")
	world=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle) and SortieCheckpoint.restore_world(world,battle),"wall-impact stun is checkpointable without restarting attack")
	check(is_equal_approx(ram.receive_damage(DamagePacket.new(10)),15),"wall stun exposes shield and increases real applied damage")
	ram.ram_phase=CampusRammer.Phase.RECOVER
	var forward:=-ram.global_basis.z
	check(is_equal_approx(ram.receive_damage(DamagePacket.new(10,8,0,null,&"fixture",&"player",Vector3.ZERO,Vector3.ZERO,-forward)),3),"ordinary front impact is shielded using trajectory")
	check(is_equal_approx(ram.receive_damage(DamagePacket.new(10,8,0,null,&"fixture",&"player",Vector3.ZERO,Vector3.ZERO,forward)),10),"rear impact bypasses front shield")
	check(is_equal_approx(ram.receive_damage(DamagePacket.new(10,22,0,null,&"fixture",&"player",Vector3.ZERO,Vector3.ZERO,-forward)),10),"penetrating front impact bypasses shield")
	# Hold the lane in a separate explicit placement fixture: attack still hurts.
	ram.position=Vector3(-37,0,-35);ram.velocity=Vector3.ZERO
	ram.ram_phase=CampusRammer.Phase.HUNT;ram.ram_remaining=0;ram.ram_traveled=0;ram.ram_direction=Vector3.ZERO
	battle.player.position=Vector3(-37,0,-29);await frames()
	ram.awareness.last_known=battle.player.position;ram._telegraph_shot();ram.set_physics_process(true)
	for tick in 180:
		await get_tree().physics_frame
		if ram.player_impacts>0:break
	ram.set_physics_process(false)
	check(ram.player_impacts==1 and battle.player.health<health,"holding the committed lane takes actual collision damage exactly once")
	var after: float=battle.player.health
	await frames(12)
	check(battle.player.health==after,"one hit cannot stack repeated damage from a lingering contact")
	ram.take_damage(1000);encounter._physics_process(0)
	check(encounter.phase==CampusPowerEncounter.Phase.CLEARED and not battle.session.campus.power_cut,"enemy death alone does not magically operate console")
	check_hardware(control,true,false,"charger defeated before return")
	battle.player.position=control.position+Vector3.RIGHT
	check(control.interact(battle.player,battle.session).success and battle.session.campus.power_cut,"returning to actual control cuts experimental branch")
	check(control.get_node("BranchALight").light_energy>0 and control.get_node("BranchBLight").light_energy==0,"shelter stays powered while experimental screen goes dark")
	check_hardware(control,true,true,"actual returned control cut")
	check(not profile.campus_chapter.power_returned,"field success is not a settled extraction reward")
	world=SortieCheckpoint.capture_world(battle)
	hardware.get_node("ShelterCover").rotation.x=CampusPowerEncounter.COVER_OPEN;hardware.get_node("ExperimentLever").rotation.z=0
	check(SortieCheckpoint.validate_world(world,battle) and SortieCheckpoint.restore_world(world,battle),"cleared/cut world restores without resurrecting charger")
	check_hardware(control,true,true,"cut derived restore")
	for source in [CampusPowerEncounter.INTRO,CampusPowerEncounter.CLEAR,CampusPowerEncounter.CHOICE,CampusPowerEncounter.OPERATION,CampusPowerEncounter.CONFIRM,CampusPowerEncounter.SHELTER_NOTE]:
		check(TranslationServer.translate(source)!=source if TranslationServer.get_locale()=="zh_CN" else TranslationServer.translate(source)==source,"authored scene has both language forms")
	report()



func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"save rendered encounter evidence")
