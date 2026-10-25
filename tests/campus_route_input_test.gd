extends Node3D
## Route/input regression, NOT human or combat acceptance. Q02-complete fixture;
## normal player/controller/collision and actual interaction UI, enemies disabled.
## Charger removal below is an explicit damage fixture, not combat/playthrough proof.
const PATH := "user://campus_route_input_test.json"
const MOVEMENT := ["move_left","move_right","move_forward","move_back"]
var battle: Node3D
var failures: Array[String]=[]
var states: Dictionary={}
var precision_states: Dictionary={}
var walked:=0.0
func check(ok: bool,message: String) -> bool:
	if not ok:failures.append(message);push_error(message)
	return ok
func _ready() -> void: run.call_deferred()
func release_movement() -> void:
	for action in MOVEMENT:Input.action_release(action)
func axis(negative: String,positive: String,value: float) -> void:
	Input.action_release(negative);Input.action_release(positive)
	if value<-.01:Input.action_press(negative,-value)
	elif value>.01:Input.action_press(positive,value)
func tap(action: String) -> void:
	var event:=InputEventAction.new();event.action=action;event.pressed=true;Input.parse_input_event(event)
	await get_tree().physics_frame
	event=InputEventAction.new();event.action=action;event.pressed=false;Input.parse_input_event(event)
	await get_tree().physics_frame
func walk_to(target: Vector3,precision:=false) -> bool:
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path:=NavigationServer3D.map_get_path(map,battle.player.global_position,target,true)
	if path.is_empty():return check(false,"No navigation path to "+str(target))
	if precision:Input.action_press("precision_walk")
	for waypoint in path:
		var reached:=false
		for tick in 900:
			var gap: Vector3=waypoint-battle.player.global_position;gap.y=0
			if gap.length()<.32:reached=true;break
			var right: Vector3=battle.camera.global_basis.x;right.y=0;right=right.normalized()
			var forward: Vector3=-battle.camera.global_basis.z;forward.y=0;forward=forward.normalized()
			axis("move_left","move_right",gap.normalized().dot(right))
			axis("move_back","move_forward",gap.normalized().dot(forward))
			var before: Vector3=battle.player.global_position
			await get_tree().physics_frame
			walked+=before.distance_to(battle.player.global_position)
			states[String(battle.player.locomotion_playback.get_current_node())]=true
			if precision and Input.is_action_pressed("precision_walk"):
				precision_states[String(battle.player.locomotion_playback.get_current_node())]=true
			var nearest: Node3D=battle.player.interaction_component._find_nearest_interactable()
			if nearest is Door and not nearest.is_open():await tap("interact")
		if not reached:
			release_movement();Input.action_release("precision_walk")
			return check(false,"Input route stuck at %s toward %s" % [battle.player.global_position,waypoint])
	release_movement();Input.action_release("precision_walk")
	for frame in 30:await get_tree().physics_frame
	states[String(battle.player.locomotion_playback.get_current_node())]=true
	return check(Vector2(battle.player.position.x-target.x,battle.player.position.z-target.z).length()<1,"Actual capsule reaches route target "+str(target))
func start_world() -> void:
	check(DeploymentPlan.deploy(ProfileRuntime.get_profile(),&"street_district",&"streets_recon",PATH).error==OK,"Owned finite equipment deploys")
	SortieRuntime.layout_seed=907 # Deterministic route fixture; no actor relocation.
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false);enemy.collision_layer=0
	for tick in 60:await get_tree().physics_frame
func extract() -> bool:
	var exit: ExtractionPoint
	for candidate in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if candidate.available and candidate.required_objective_id.is_empty():exit=candidate;break
	if not exit or not await walk_to(exit.global_position):return false
	await tap("interact")
	for frame in 12:await get_tree().physics_frame
	if not check(battle.session.status==SortieSession.Status.COMPLETED,"Actual exit input completes the sortie"):return false
	check(SortieRuntime.finalize_sortie(PATH)==OK,"Actual return settles and persists, not direct quest mutation")
	battle.free();battle=null;await get_tree().process_frame
	return true
func run() -> void:
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits=["streets_exit_0","streets_exit_1"]
	profile.narrative_slice.settled.Q02=true;profile.narrative_slice.q02.delivered={"medical.field_dressing":2,"material.fabric":2};profile.narrative_slice.q02.message=NarrativeSlice.Q02_MESSAGE
	print("CAMPUS_ROUTE_INPUT: Q02 fixture; AI disabled; normal input/controller/collision, no player teleport or invulnerability")
	await start_world()
	for name in ["CampusRelayOffice","CampusRelayRepair"]:
		var point:=battle.area_root.get_node(name) as CampusAction
		if not await walk_to(point.global_position+Vector3(0,0,1.3)):await finish();return
		check(battle.player.interaction_component._find_nearest_interactable()==point,"Real nearest interaction selects "+name)
		await tap("interact")
		for frame in 750:await get_tree().physics_frame
		if not check(String(point.action_id) in battle.session.campus.relays,"Real elapsed work repairs "+name):await finish();return
	var recorder:=battle.area_root.get_node("ExperimentRecorder") as CampusAction
	var approach: Vector3=recorder.global_position+Vector3(.95,0,.3);approach.y=.1
	if not await walk_to(approach,true):await finish();return
	check(battle.player.interaction_component._find_nearest_interactable()==recorder,"Correct archive desk can be selected rather than nearby ordinary terminal")
	await tap("interact")
	if not check(battle.session.campus.recorder_revealed,"Real interaction input acquires actual recorder"):await finish();return
	# Current sixteen-direction player selects its aim-relative stride, not only legacy Walk.
	var precision_stride := ["Walk","WalkBack","WalkFL","WalkFR","WalkBL","WalkBR"].any(func(state):return precision_states.has(state))
	check(states.has("Run") and precision_stride and battle.player.locomotion_playback.get_current_node()==&"Idle","Actual run, input-held precision stride and stop enter production motion states")
	if not await extract():await finish();return
	check(profile.campus_chapter.recorder_returned,"Walking relay/recorder route settles real milestones")
	await start_world()
	var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
	if not await walk_to(control.global_position+Vector3(1,0,1)):await finish();return
	await tap("interact")
	if not check(is_instance_valid(control.choice_layer),"Actual interaction input opens branch choice"):await finish();return
	check(get_viewport().gui_get_focus_owner().name=="ConfirmBranch","Branch confirmation is keyboard/controller focusable without clicking")
	await tap("ui_accept")
	var encounter:=control._encounter()
	check(encounter.phase==CampusPowerEncounter.Phase.ACTIVE,"Keyboard/controller confirmation starts the real v3 encounter")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false);enemy.collision_layer=0
	for frame in 390:await get_tree().physics_frame
	check(not battle.session.campus.power_cut,"Six seconds of waiting cannot bypass the new field encounter")
	encounter.rammer().take_damage(1000) # Controlled input fixture. Live combat is campus_chapter_run.
	for frame in 4:await get_tree().physics_frame
	check(encounter.phase==CampusPowerEncounter.Phase.CLEARED,"Charger removal exposes the physical control, not a free cut")
	await tap("interact")
	check(battle.session.campus.power_cut,"Actual post-encounter E cuts the correct branch")
	if not await extract():await finish();return
	check(profile.campus_chapter.power_returned,"Real power route returns and persists")
	await finish()
func finish() -> void:
	release_movement();Input.action_release("precision_walk")
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("CAMPUS_ROUTE_INPUT walked_meters=",walked," motion_states=",states," precision_states=",precision_states)
	print("CAMPUS_ROUTE_INPUT_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
