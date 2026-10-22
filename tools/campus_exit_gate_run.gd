extends "res://tests/campus_q01_run.gd"
## Ordinary continuation/input/live AI; no grants, teleport, layout seed or damage calls.
const EXPECTED:="user://campus_exit_gate_run_expected.json"
var operating:=false
var gate_report: Dictionary={}

func _ready() -> void:
	# Persist the requested QA preference inside this isolated user:// so BOOT's
	# new-player Chinese default cannot silently replace the English route.
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN")
	super._ready()

func _run() -> void:
	if "--read" not in OS.get_cmdline_user_args():
		await super._run();return
	tree=get_tree();tree.current_scene=null
	var profile:=ProfileRuntime.get_profile()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and FileAccess.file_exists(EXPECTED),"independent BOOT loads actual north-gate return and expected original profile")
	if not failures.is_empty():_finish();return
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(EXPECTED))
	var actual:=profile.to_dict();var wanted: Dictionary=ProfileState.from_dict(expected.profile).to_dict()
	for data in [actual,wanted]:data.erase("stash_layout")
	check(actual==wanted,"entire gameplay profile survives independent read; display stash layout excluded only")
	check(profile.successful_sorties==2 and profile.narrative_slice.settled.Q01 and not profile.narrative_slice.settled.Q02 and profile.sortie_checkpoint.is_empty(),"only actual returned Q01 is durably earned")
	gate_report=expected.gate
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("gate_06_independent_q02")
	evidence["profile_after"]=profile.to_dict();_finish()

func _walk(at: Vector3,tolerance:=.4) -> bool:
	if not operating and battle.area_root.has_node("CampusExitGate"):
		var gate: CampusExitGate=battle.area_root.get_node("CampusExitGate")
		var plaque: Node3D=battle.area_root.get_node("Exit2/ExitPlaque")
		if not gate.is_open() and at.distance_to(plaque.global_position)<.1:
			operating=true
			if not await operate_gate(gate):return false
	return await super._walk(at,tolerance)

func operate_gate(gate: CampusExitGate) -> bool:
	check(int(battle.area_root.get_meta("map_revision"))==8 and gate.mode==0,"fresh normal Q01 actually contains bolted north gate")
	if not await super._walk(gate.to_global(Vector3(0,0,-3.5)),.5):return false
	_release();await _frames()
	var before_shots:=shots;var before_kills: int=battle.session.enemies_defeated
	var observations: Array=battle.session.exit_observations.duplicate()
	gate_report={"method":"loud" if "--loud" in OS.get_cmdline_user_args() else "quiet","before_shots":shots,"before_kills":before_kills,"before_observations":observations,"inside":str(battle.player.global_position),"task_index":battle.area_root.task_index}
	await _capture("gate_00_bolted")
	if "--loud" in OS.get_cmdline_user_args():
		# Controller aim is a direction, not a pixel snap. A normal navigation
		# stop may be .5m sideways from the narrow chain; line up through actual
		# movement first instead of firing fourteen parallel misses from that spot.
		Input.action_press("precision_walk");Input.action_press("aim_up")
		for tick in 180:
			var dx: float=gate.global_position.x-battle.player.global_position.x
			Input.action_release("move_left");Input.action_release("move_right")
			if absf(dx)<.025:break
			_axis("move_left","move_right",signf(dx)*.35)
			await tree.physics_frame
		Input.action_release("move_left");Input.action_release("move_right");Input.action_release("precision_walk")
		gate_report["lined_up_position"]=str(battle.player.global_position)
		Input.action_press("fire")
		for tick in 120:
			await tree.physics_frame
			if gate.is_open() or battle.player.is_dead:break
		_release();await _frames()
		check(gate.mode==2 and gate.get_node("Chain").destroyed and shots>before_shots,"actual paid ammunition breaks red chain and opens physical gate")
		check(gate.get_node("Guard0").has_spawned and gate.get_node("Guard1").has_spawned,"shot chain actually spawns exactly two authored guards once")
	else:
		if not await super._walk(gate.to_global(Vector3(0,0,2.4)),.5):return false
		_release();await _frames()
		gate_report["outside"]=str(battle.player.global_position)
		var component: InteractionComponent=battle.player.interaction_component
		check(component._current_target==gate.get_node("OutsideLatch"),"normal collision/navigation detour reaches physical outside bolt")
		await _capture("gate_01_outside_bolt")
		await _tap("interact")
		check(gate.mode==1 and not gate.get_node("Chain").destroyed and not gate.get_node("Guard0").has_spawned and not gate.get_node("Guard1").has_spawned,"actual outside E opens quietly, no finite guard spawn")
	check(battle.session.exit_observations==observations and not ProfileRuntime.get_profile().narrative_slice.settled.Q01,"neither route auto-reads plaque or settles Q01")
	check(gate.is_open(),"door is actually open before approaching plaque")
	gate_report["gate_mode"]=gate.mode;gate_report["opening_shots"]=shots-before_shots
	if "local_motion_usage" in battle.player:gate_report["pose_usage"]=battle.player.local_motion_usage.duplicate()
	await _capture("gate_02_opened")
	return failures.is_empty()

func _finish() -> void:
	evidence["gate"]=gate_report
	if failures.is_empty() and "--read" not in OS.get_cmdline_user_args():
		var file:=FileAccess.open(EXPECTED,FileAccess.WRITE)
		file.store_string(JSON.stringify({"profile":ProfileRuntime.get_profile().to_dict(),"gate":gate_report}));file.close()
	super._finish()
