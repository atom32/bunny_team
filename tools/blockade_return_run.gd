extends "res://tools/story_finish_run.gd"
## Genuine preceding eight-return profile; ordinary menus, weapons and extraction.
## No progress assignments, actor relocation, damage calls, free items or focus repair.
var rear_closed_hits := 0

func controls(destination: Vector3) -> void:
	super.controls(destination)
	if "--rear-flank" not in OS.get_cmdline_user_args() or not is_instance_valid(battle):return
	var van:=battle.area_root.get_node_or_null("Van") as BlockadeVan
	if not van or van.destroyed:return
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController and not enemy.is_dead and battle.player_visibility.can_see_enemy(enemy) and enemy.global_position.distance_to(battle.player.global_position)<9:return
	var point:=van.to_global(BlockadeVan.REAR_CENTER)
	var query:=PhysicsRayQueryParameters3D.create(battle.player.global_position+Vector3.UP*1.25,point,6);query.exclude=[battle.player.get_rid()]
	var hit: Dictionary=battle.player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider!=van or not van.rear_hit(DamagePacket.new(0,0,0,null,&"",&"player",hit.position,hit.normal)):return
	for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
	var aim: Vector3=battle.player.global_position.direction_to(point)
	_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z);Input.action_press("fire")

func checkpoint() -> bool:
	if "--rear-flank" not in OS.get_cmdline_user_args():return await super.checkpoint()
	if not await deploy_next(BlockadeStory.MISSION):return false
	var world: Node3D=battle.area_root
	var van: BlockadeVan=world.get_node("Van")
	check(van.has_rear_radiator() and battle.session.blockade.version==3,"normal fresh deployment enables the actual rear radiator")
	van.damage_observed.connect(func(_damage: float,exposed: bool):
		if exposed and van.phase!=BlockadeVan.Phase.VENT:rear_closed_hits+=1)
	if not await approach_checkpoint(world):return false
	for target in [world.get_node("PASwitch").position,Vector3(-15,0,-16),Vector3(0,0,-18)]:
		if not await walk(target):return false
		if target==world.get_node("PASwitch").position:check(use_point(world.get_node("PASwitch")).success,"normal PA switch does not disable the gun during a rear flank")
	await _capture("rear_flank")
	for tick in 7200:
		await tree.physics_frame
		if van.destroyed or battle.player.is_dead:break
		var goal:=Vector3(0,0,-18)
		if van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.BURST]:goal.x=-3 if van.aim_point.x>=0 else 3
		controls(goal)
	release()
	evidence["rear_flank"]={"closed_radiator_hits":rear_closed_hits,"van_shots":van.shots_fired,"health":battle.player.health,"player_position":str(battle.player.position)}
	check(rear_closed_hits>0 and van.destroyed and not battle.player.is_dead,"live rifle fire hits the actual rear panel outside blue windows and disables the van")
	if not failures.is_empty() or not await leave_yard(world) or not await walk(world.get_node("NorthExit").position):return false
	if not await return_home(world.get_node("NorthExit")):return false
	return failures.is_empty()

func _ready() -> void:
	get_tree().create_timer(480,true).timeout.connect(func():check(false,"earned checkpoint route deadline");finish())
	_run.call_deferred()

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
	var profile:=ProfileRuntime.get_profile()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.validate(),"load actual earned profile without invented prerequisites")
	if "--read" in OS.get_cmdline_user_args():
		check(profile.successful_sorties==_expected_returns(9) and profile.blockade_cleared and profile.maintenance_rescued and not profile.waterworks_memory.is_empty() and not profile.maintenance_closed and profile.sortie_checkpoint.is_empty(),"new process retains nine real returns and actual checkpoint victory")
		evidence["profile_after"]=profile.to_dict();finish();return
	check(profile.successful_sorties==_expected_returns(8) and profile.maintenance_rescued and not profile.waterworks_memory.is_empty() and not profile.blockade_cleared and not profile.maintenance_closed and profile.sortie_checkpoint.is_empty(),"input is a real water-return save with checkpoint still unearned")
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH);evidence["profile_before"]=profile.to_dict()
	if not failures.is_empty():finish();return
	evidence["method"]="Actual earned water return; normal BOOT/continue/main-story UI, player controls, real chain or timed cover entry, live armored-van fight, real north-yard counterweight and safe extraction. Not human playtest."
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"normal Continue reaches actual base");finish();return
	check(await checkpoint(),"actual two-stage checkpoint mission can return safely")
	check(profile.successful_sorties==_expected_returns(9) and profile.blockade_cleared and not profile.maintenance_closed and profile.sortie_checkpoint.is_empty(),"real ordinary return settles only the checkpoint, not the finale")
	evidence["profile_after"]=profile.to_dict();finish()

func finish() -> void:
	release();evidence["checks"]=checks;evidence["failures"]=failures;evidence["routes"]=route_results;evidence["shots"]=fired
	if "--read" not in OS.get_cmdline_user_args():check(route_results.size()==1,"earned route must actually finish one checkpoint operation")
	evidence["checks"]=checks;evidence["failures"]=failures
	if out.is_empty():out=OS.get_user_data_dir()
	var file:=FileAccess.open(out.path_join("blockade_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("BLOCKADE_EARNED_RUN: %s (%d checks, %d shots)"%["PASS" if failures.is_empty() else "FAIL",checks,fired]);tree.quit(0 if failures.is_empty() else 1)
