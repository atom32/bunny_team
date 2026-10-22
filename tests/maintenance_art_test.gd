extends "res://tests/maintenance_test.gd"
## Explicit placements for art/physics invariants, not an ordinary-play completion.
const ART_PATH:="user://maintenance_art_test.json"

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	check(DeploymentPlan.deploy(fixture(),MaintenanceStory.AREA,MaintenanceStory.MISSION,ART_PATH).error==OK,"art fixture deploys the current steam mission")
	await load_battle()
	var world: Node3D=battle.area_root
	var look:=world.get_node("MaintenanceLook") as MaintenancePresentation
	var steam:=world.get_node("Steam") as MaintenanceSteam
	steam.set_physics_process(false)
	world.get_node("Survivor").set_physics_process(false)
	check(look!=null and look.vapor is CPUParticles3D,"v2 receives render-only dressing and CPU vapor")
	check(look.find_children("*","CollisionObject3D",true,false).is_empty() and look.find_children("*","CollisionShape3D",true,false).is_empty(),"dressing adds no invisible wall, projectile cover or damage volume")
	check(look.find_children("*","NavigationRegion3D",true,false).is_empty() and look.find_children("*","NavigationLink3D",true,false).is_empty(),"art never rewrites navigation")
	# Same immutable authored resource, with only its render-only root hook removed.
	var reference:=load("res://scenes/areas/maintenance_zone_v2.tscn").instantiate() as Node3D
	reference.set_script(null)
	for region: NavigationRegion3D in reference.find_children("*","NavigationRegion3D",true,false):region.enabled=false
	add_child(reference)
	check(SortieCheckpoint.layout_signature(reference)==battle.checkpoint_layout_signature,"all authored collision shapes/transforms and nav vertices match undressed v2 exactly")
	reference.free()
	var legacy:=load("res://scenes/areas/maintenance_zone.tscn").instantiate() as Node3D
	check(not legacy.has_node("MaintenanceLook"),"legacy resource is not rewritten with v2 decoration")
	legacy.free()
	check(world.get_node("Ground").material_override.get_shader_parameter("albedo_map")!=null and world.get_node("Wall0").material_override.normal_texture!=null,"floor and walls reuse actual existing concrete PBR maps")
	check(look.get_node("WardFloor").material_override!=look.get_node("ChamberFloor").material_override,"ward and hot corridor have distinct floor surfaces")
	check(look.get_node("DrainageSlats").multimesh.instance_count==80,"drainage is one multimesh rather than eighty draw surfaces")
	for child in world.get_node("Steam/Jets").get_children():
		if child is MeshInstance3D:check(not child.visible,"old solid jet proxy stays hidden after parent visibility changes")
	check(look.vapor.amount==96 and look.vapor.mesh is QuadMesh and not look.vapor.is_in_group("camera_occluder"),"bounded transparent vapor does not become an opaque camera occluder")
	check(look.vapor.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and look.vapor.material_override.depth_draw_mode==BaseMaterial3D.DEPTH_DRAW_DISABLED,"vapor uses alpha without writing opaque depth")
	var facts:=SortieCheckpoint.session_data(battle.session)
	look.update_steam(2,3.5,false)
	check(look.vapor.emitting and SortieCheckpoint.session_data(battle.session)==facts,"visual pressure update cannot grant objectives or alter gameplay facts")
	look.update_steam(0,0,false)
	check(not look.vapor.emitting,"clear interval stops new vapor emission")
	battle.player.position=Vector3(-9,0,12);await frames(90)
	await capture("maintenance_art_service")
	check((await use("Bypass")).success and (await use("WardControl")).success,"controlled ward preview uses real nearby controls")
	check(world.get_node("ServiceGate").position.y==5 and not world.get_node("ServiceGate/ServiceGatePanel").visible,"opened shutter keeps the physical lift but no floating panel over the doorway")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.position=Vector3(15,0,-10);await frames(90)
	await capture("maintenance_art_ward")
	battle.player.position=Vector3(0,0,-8);steam.cycle_time=3.5;steam.refresh();await frames(90)
	check(world.get_node("Steam/Jets").visible and look.vapor.emitting,"actual hot phase activates transparent vapor")
	await capture("maintenance_art_steam")
	battle.player.position=Vector3(3,0,-23);await frames(90)
	check(world.get_node("SteamValve").interact(battle.player,battle.session).success,"styled valve keeps ordinary range and LOS interaction")
	check(not look.vapor.emitting and is_equal_approx(look.wheel.rotation.z,-PI/2),"isolation stops mist and turns the separate visible wheel")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"fully dressed world still uses the unmodified v2 checkpoint contract")
	await capture("maintenance_art_valve")
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();await frames();AudioDirector.shutdown_for_test()
	print("MAINTENANCE_ART_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
