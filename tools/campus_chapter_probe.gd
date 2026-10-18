extends Node3D
## Fixture-driven real runtime captures; not a human route, audio or balance signoff.
var evidence := OS.get_environment("BUNNY_CAMPUS_EVIDENCE")
var battle: Node3D
func capture(name: String) -> void:
	for frame in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(evidence+"/"+name+".png")==OK)
func start_world() -> void:
	assert(DeploymentPlan.deploy(ProfileRuntime.get_profile(),&"street_district",&"streets_recon","user://campus_probe.json").error==OK)
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	await get_tree().process_frame
func _ready() -> void: run.call_deferred()
func run() -> void:
	assert(not evidence.is_empty() and DisplayServer.get_name()!="headless")
	DirAccess.make_dir_recursive_absolute(evidence)
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits=["streets_exit_0","streets_exit_1"]
	profile.narrative_slice.settled.Q02=true;profile.narrative_slice.q02.delivered={"medical.field_dressing":2,"material.fabric":2};profile.narrative_slice.q02.message=NarrativeSlice.Q02_MESSAGE
	await start_world()
	battle.area_root.route_map.expanded=true
	await capture("chapter_map_relay_locked_recorder")
	battle.area_root.route_map.expanded=false
	for name in ["CampusRelayOffice","CampusRelayRepair"]:
		var relay:=battle.area_root.get_node(name) as CampusAction
		battle.player.global_position=relay.global_position+Vector3.RIGHT
		relay.interact(battle.player,battle.session);relay._process(12)
	var recorder:=battle.area_root.get_node("ExperimentRecorder") as CampusAction
	battle.player.global_position=recorder.global_position+Vector3(1,0,1)
	await capture("recorder_site")
	var result:=recorder.interact(battle.player,battle.session)
	battle.hud.show_field_information(result.information)
	await capture("recorder_read_immediately")
	battle.area_root.route_map.expanded=true
	await capture("chapter_map_recorder_removed")
	battle.area_root.route_map.expanded=false
	battle.session.complete_extraction();assert(SortieRuntime.finalize_sortie("user://campus_probe.json")==OK)
	battle.free();await get_tree().process_frame
	await start_world()
	var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
	battle.player.global_position=control.global_position+Vector3(1,0,1)
	await capture("power_before")
	control.interact(battle.player,battle.session)
	await capture("power_explicit_choice")
	assert(control.confirm_power());control._process(6)
	await capture("power_after_a_on_b_off")
	var report:={"fixture_only":true,"branch_a_energy":control.get_node("BranchALight").light_energy,"branch_b_energy":control.get_node("BranchBLight").light_energy,"art_meshes":[]}
	for mesh in control.get_node("Art").find_children("*","MeshInstance3D",true,false):
		report.art_meshes.append({"path":str(control.get_path_to(mesh)),"aabb":str(mesh.get_aabb()),"transform":str(mesh.transform)})
	var file:=FileAccess.open(evidence+"/report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	battle.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("CAMPUS_CHAPTER_PROBE: PASS / fixture captures, not human acceptance")
	get_tree().quit()
