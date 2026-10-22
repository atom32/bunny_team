extends Node3D
## Controlled component placements/frozen unrelated AI. Earned traversal is a
## separate test. Never count this fixture as a human playthrough or new minutes.
var failures: Array[String]=[]
var checks:=0
var battle: Node3D
var gate: CampusExitGate
var path_name: String
var notes: Dictionary={}
var actual_shots:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func frames(count:=4) -> void:
	for _tick in count:await get_tree().physics_frame

func press(action: String) -> void:
	for state in [true,false]:
		var event:=InputEventAction.new();event.action=action;event.pressed=state;Input.parse_input_event(event);await frames(3)

func freeze() -> void:
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)

func length_of(path: PackedVector3Array) -> float:
	var result:=0.0
	for index in range(1,path.size()):result+=path[index-1].distance_to(path[index])
	return result

func _ready() -> void:
	get_tree().create_timer(90,true).timeout.connect(func():check(false,"exit-gate component deadline");finish())
	await frames(1)
	var args:=OS.get_cmdline_user_args();var loud: bool="--loud" in args
	var variant:=0
	for arg in args:
		if arg.begins_with("--variant="):variant=int(arg.get_slice("=",1))
	path_name="user://campus_exit_gate_"+("loud" if loud else "quiet")+str(variant)+".json"
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",false)
	if "--read" in args:
		var ok:=ProfileRuntime.load_profile(path_name) and SortieRuntime.resume_saved(path_name)==OK
		check(ok,"independent process accepts actual signed gate checkpoint")
		if not ok:finish();return
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle);freeze();await frames()
		gate=battle.area_root.get_node("CampusExitGate")
		check(not FlowMenu.is_open() and int(battle.area_root.get_meta("map_revision"))==8,"restores the v8 authored physical route, no fallback")
		check(gate.mode==(2 if loud else 1) and gate.introduced and gate.get_node("GateLink").enabled and gate.get_node("GateBody").position.y==3.5,"door body and navigation link restore together")
		check(gate.get_node("Chain").destroyed==loud and gate.get_node("Chain/CollisionShape3D").disabled,"quiet/loud chain identity restores with no ghost collider")
		check(gate.get_node("Guard0").has_spawned==loud and gate.get_node("Guard1").has_spawned==loud,"finite response has the same spawn history, no new wave")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"restored complete world validates")
		check(not ProfileRuntime.get_profile().narrative_slice.settled.Q01,"resuming a gate never settles a base request")
		finish();return
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",path_name).error==OK,"explicit first-campus unit fixture deploys normally")
	var rng:=RandomNumberGenerator.new();var chosen:=0
	for value in range(1,200):
		rng.seed=value;rng.randi_range(0,5)
		if rng.randi_range(0,3)==variant:chosen=value;break
	SortieRuntime.layout_seed=chosen
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle);freeze();await frames()
	gate=battle.area_root.get_node("CampusExitGate")
	check(int(battle.area_root.get_meta("map_revision"))==8 and battle.area_root.task_index==variant,"fresh Q01 uses explicit gated scene/navigation variant")
	check(not gate.is_open() and not gate.get_node("GateLink").enabled and not gate.get_node("Guard0").has_spawned and not gate.get_node("Guard1").has_spawned,"new gate is closed and response does not spawn offscreen")
	var exit: ExtractionPoint=battle.area_root.get_node("Exit2")
	var retreat: ExtractionPoint
	for candidate in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if candidate.available and candidate.required_objective_id.is_empty():retreat=candidate
	check(exit.available and exit.required_objective_id==&"streets_terminal" and retreat!=null and retreat!=exit and retreat.can_extract(battle.session),"original unconditional assigned retreat survives")
	battle.player.position=gate.to_global(Vector3(0,0,-3.5));await frames()
	for path in ["GateLabel","Chain/WorldLabel","OutsideLatch/WorldLabel"]:
		var marker:=gate.get_node(path) as Label3D
		check(marker.font_size>=32 and marker.outline_size<=1,"thin-outline, readable-size marker: "+path)
		check(marker.font==UIFactory.FONT,"world hint uses the same readable 400-weight font as the HUD, not the raw variable font's thin default")
	check(gate.get_node("Chain/WorldLabel").visible and not gate.get_node("OutsideLatch/WorldLabel").visible,"inside chain hint never exposes the far-side bolt caption")
	battle.player.position=gate.to_global(Vector3(0,0,-18));await frames()
	check(not gate.get_node("GateLabel").visible and not gate.get_node("Chain/WorldLabel").visible and not gate.get_node("OutsideLatch/WorldLabel").visible,"nearby wayfinding captions do not float over distant scenery")
	battle.player.position=gate.to_global(Vector3(0,0,-3.5));await frames()
	var count: int=battle.session.exit_observations.size()
	check(not exit.get_node("ExitPlaque").interact(battle.player,battle.session).success and battle.session.exit_observations.size()==count,"reading conditions through a closed gate cannot earn Q01 credit")
	check(not gate.get_node("OutsideLatch").interact(battle.player,battle.session).success,"inside interaction radius cannot pull the outside bolt through the gate")
	var required:=exit.required_objective_id;exit.required_objective_id=&""
	check(not exit.can_extract(battle.session),"physical closed gate denies extraction independently of records condition (explicit temporary unit fixture)")
	exit.required_objective_id=required
	var initial:=SortieCheckpoint.capture_world(battle)
	check(exit.find_children("*","Label3D",true,false).all(func(label):return not label.visible),"v8 gate replaces only its old stacked world billboards; plaque interaction remains")
	check(exit.get_node("ExitPlaque").conditions_text(battle.session).contains(tr("LOCKED / RECOVER THIS SORTIE'S RECORDS")),"closed physical gate still discloses actual records requirement")
	check(SortieCheckpoint.validate_world(initial,battle),"unmodified closed fixture validates before negative snapshots")
	for phase in [3,"2",2.5]:
		var forged:=initial.duplicate(true);forged.nodes["CampusExitGate"].mode=phase
		check(not SortieCheckpoint.validate_world(forged,battle),"non-enum gate mode is rejected: "+str(phase))
	var forged:=initial.duplicate(true);forged.nodes["CampusExitGate"].mode=2;forged.nodes["CampusExitGate"].introduced=true
	check(not SortieCheckpoint.validate_world(forged,battle),"loud state without actual broken chain/finite response is refused")
	forged=initial.duplicate(true);forged.exit_observations.append("streets_exit_2")
	check(not SortieCheckpoint.validate_world(forged,battle),"closed gate plus forged north-exit observation is refused")
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	for _tick in 120:
		await frames(1)
		if NavigationServer3D.map_get_iteration_id(map)>0:break
	var inside:=gate.to_global(Vector3(0,0,-4));var outside:=gate.to_global(Vector3(0,0,4))
	var closed:=NavigationServer3D.map_get_path(map,inside,outside,true)
	check(not closed.is_empty() and closed[-1].distance_to(outside)<.6,"outside bolt has an actual navigable detour in this layout")
	notes["closed_path"]=str(closed);notes["closed_path_m"]=length_of(closed)
	check(length_of(closed)>inside.distance_to(outside)+4,"closed navigation goes round the real wing walls, not through the collider")
	battle.player.position=inside;battle.player.set_physics_process(true);Input.action_press("move_forward")
	await frames(55);Input.action_release("move_forward");await frames(3);battle.player.set_physics_process(false)
	check(battle.player.global_position.z>gate.global_position.z+.3,"actual CharacterBody movement cannot cross the closed gate")
	var ammo_before: int=battle.player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY)["magazine"]
	await capture_stage("gate_closed")
	battle.player.weapon_fired.connect(func(_recoil):actual_shots+=1)
	if loud:
		battle.player.position=gate.to_global(Vector3(0,0,-3.5));battle.player.set_physics_process(true)
		Input.action_press("aim_up");Input.action_press("fire")
		for _tick in 90:
			await frames(1)
			if gate.is_open():break
		Input.action_release("fire");Input.action_release("aim_up");freeze();await frames()
		check(gate.mode==2 and gate.get_node("Chain").destroyed,"actual controller fire breaks physical red chain and opens gate")
		check(actual_shots>0 and int(battle.player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY)["magazine"])<ammo_before,"loud solution consumes actual shots, no direct damage assignment")
		check(gate.get_node("Guard0").has_spawned and gate.get_node("Guard1").has_spawned,"only the finite response actually spawns")
	else:
		battle.player.position=gate.to_global(Vector3(0,0,2.4));await frames()
		await capture_stage("gate_outside")
		battle.player.interaction_component._physics_process(0)
		check(battle.player.interaction_component._current_target==gate.get_node("OutsideLatch"),"outside position targets the actual bolt via normal interaction selection")
		await press("interact")
		check(gate.mode==1 and not gate.get_node("Chain").destroyed and not gate.get_node("Guard0").has_spawned and not gate.get_node("Guard1").has_spawned,"actual E releases bolt quietly without a response")
		check(int(battle.player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY)["magazine"])==ammo_before,"quiet solution uses no ammunition or material")
	check(battle.session.exit_observations.size()==count and not profile.narrative_slice.settled.Q01,"opening route grants no observations, base completion or reward")
	check(not gate.open_gate(2,battle.player),"repeat activation cannot spawn or open again")
	await frames(5)
	await capture_stage("gate_open")
	var open:=NavigationServer3D.map_get_path(map,inside,outside,true)
	notes["open_path"]=str(open);notes["open_path_m"]=length_of(open)
	check(not open.is_empty() and length_of(open)<length_of(closed)-4,"opened link gives an actual shorter navigable route")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"actual quiet/loud world validates before save")
	check(SortieRuntime.save_checkpoint()==OK,"actual checkpoint save stores the field route")
	notes["mode"]=gate.mode;notes["shots"]=actual_shots;notes["variant"]=variant
	finish()

func capture_stage(_name: String) -> void:pass

func finish() -> void:
	for action in ["move_forward","fire","aim_up"]:Input.action_release(action)
	notes["checks"]=checks;notes["failures"]=failures
	var directory:=OS.get_environment("BUNNY_EVIDENCE")
	if not directory.is_empty():
		var f:=FileAccess.open(directory.path_join("exit_gate_component.json"),FileAccess.WRITE);f.store_string(JSON.stringify(notes,"\t"));f.close()
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("CAMPUS_EXIT_GATE_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
