extends "res://tests/maintenance_test.gd"
## Controlled hazard/escort fixtures. Ordinary input completion is maintenance_run.
const JOURNEY_PATH:="user://maintenance_journey_test.json"

func _alarm_carrier_read() -> void:
	# Independent disk continuation of a frozen controlled actor fixture, not an
	# earned deployment or an ordinary rescue route.
	check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process resumes the caller warning from disk")
	get_tree().paused=true;await load_battle()
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://caller_expected.json"))
	var caller: MaintenanceAlarmCarrier
	var listener: EnemyController
	for candidate in battle.enemy_container.get_children():
		if candidate.get_meta("spawn_key")=="Enemy0":caller=candidate as MaintenanceAlarmCarrier
		if candidate.get_meta("spawn_key")=="Enemy1":listener=candidate as EnemyController
	check(caller!=null and listener!=null and battle.session.maintenance.version==4,"disk continuation retains the v4 caller and original eastern enemy")
	if not caller or not listener:return
	var saved:=SortieCheckpoint.capture_world(battle)
	check(caller.definition_id==StringName(expected.definition) and caller.call_phase==1 and is_equal_approx(caller.call_remaining,expected.call.remaining) and caller.call_remaining<1,"disk continuation preserves the actual partial warning, not a fresh full second")
	check(SortieCheckpoint.validate_world(saved,battle) and is_equal_approx(saved.enemies.Enemy0.shot_remaining,expected.shot_remaining) and saved.enemies.Enemy0.shot_remaining<=.38 and saved.enemies.Enemy0._is_telegraphing==expected.melee_telegraph,"resumed call stays separate from the unchanged ordinary 0.38-second melee timer fields")
	check(caller.calls_emitted==0,"restoring a partial warning does not emit a call during construction")
	listener.set_physics_process(true);get_tree().paused=false
	var origin:=caller.global_position
	caller._physics_process(caller.call_remaining+.001)
	check(caller.calls_emitted==1 and caller.call_phase==2 and is_equal_approx(caller.call_remaining,7),"consuming only the saved warning remainder completes exactly one call")
	check(listener.awareness.state==EnemyAwareness.State.INVESTIGATE and listener.awareness.last_known.is_equal_approx(origin) and not listener.awareness.last_known.is_equal_approx(battle.player.global_position),"resumed call uses real local hearing at the source rather than broadcasting the player")
	caller._physics_process(.5)
	check(caller.calls_emitted==1 and caller.call_phase==2 and is_equal_approx(caller.call_remaining,6.5),"continued cooldown neither calls twice nor resets to seven seconds")
	listener.set_physics_process(false)

func _alarm_carrier() -> void:
	# Independent controlled v4 fixture. Never runs inside the preserved v2 steam,
	# ordinary rescue, trap-write or trap-read routes below.
	check(DeploymentPlan.deploy(fixture(),MaintenanceStory.AREA,MaintenanceStory.MISSION,JOURNEY_PATH).error==OK,"caller fixture deploys through the normal battle constructor")
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var caller: MaintenanceAlarmCarrier
	var listener: EnemyController
	for candidate in battle.enemy_container.get_children():
		if candidate.get_meta("spawn_key")=="Enemy0":caller=candidate as MaintenanceAlarmCarrier
		if candidate.get_meta("spawn_key")=="Enemy1":listener=candidate as EnemyController
	check(session.maintenance.version==4 and int(world.get_meta("map_revision"))==4 and caller!=null and listener!=null,"fresh v4 replaces Enemy0 with an actual alarm carrier and retains the eastern listener")
	if not caller or not listener:return
	check(battle.enemy_container.get_child_count()==4 and world.find_children("*","EnemySpawnPoint",true,false).size()==8,"caller replaces one original actor without adding live enemies or spawn points")
	for entry in [["Enemy1",Vector3(7,0,11),&"campus_infected"],["Enemy2",Vector3(0,0,-18),&"prototype_basic_enemy"],["Enemy3",Vector3(15,0,-14),&"campus_infected"]]:
		var point:=world.get_node(String(entry[0])) as EnemySpawnPoint
		check(point.position.is_equal_approx(entry[1]) and point.enemy_definition_id==entry[2],"unrelated authored spawn retained: "+String(entry[0]))
	check(caller.global_position.is_equal_approx(Vector3(-10,0,18)),"caller retains the original western approach spawn")
	# Place only the test player in the caller's unobstructed front cone. The
	# real perception query acquires her; no direct COMBAT/last_known assignment.
	battle.player.position=Vector3(-10,0,11)
	await frames()
	for tick in 12:
		caller._physics_process(.1)
		if caller.call_phase==1:break
	check(caller.awareness.target_visible and caller.awareness.state==EnemyAwareness.State.COMBAT and caller.call_phase==1,"actual sight acquisition starts the one-second call warning")
	if caller.call_phase!=1:return
	if "--caller-write" in OS.get_cmdline_user_args():
		caller._physics_process(.4) # Consume a real portion of the warning; do not assign its phase/remainder.
		var durable:=SortieCheckpoint.capture_world(battle)
		check(caller.call_phase==1 and caller.call_remaining>0 and caller.call_remaining<1 and SortieCheckpoint.validate_world(durable,battle),"actual sight-triggered warning advances to a legal partial durable instant")
		check(SortieRuntime.save_checkpoint()==OK,"frozen v4 warning fixture commits through the normal checkpoint writer")
		var file:=FileAccess.open("user://caller_expected.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"definition":String(caller.definition_id),"call":caller.call_snapshot(),"shot_remaining":durable.enemies.Enemy0.shot_remaining,"melee_telegraph":durable.enemies.Enemy0._is_telegraphing}));file.close()
		return
	var windup: Dictionary=caller.call_snapshot()
	check(MaintenanceAlarmCarrier.valid_call(windup) and windup.remaining>0 and windup.remaining<=1,"partial warning has a legal bounded snapshot")
	var saved:=SortieCheckpoint.capture_world(battle)
	check(saved.enemies.Enemy0.get("call",{})==windup and SortieCheckpoint.validate_world(saved,battle),"full battle snapshot includes the legal partial warning")
	var overlapping:=saved.duplicate(true)
	overlapping.enemies.Enemy0._is_telegraphing=true;overlapping.enemies.Enemy0.shot_remaining=.2
	check(not SortieCheckpoint.validate_world(overlapping,battle),"warning cannot restore alongside an active melee telegraph")
	caller.restore_call({"phase":2,"remaining":3.0})
	check(SortieCheckpoint.restore_world(saved,battle) and caller.call_snapshot()==windup,"full world restoration reinstates the exact warning rather than granting a call")
	for bad in [{},{"phase":3,"remaining":0},{"phase":1.5,"remaining":.5},{"phase":0,"remaining":.1},{"phase":1,"remaining":1.01},{"phase":2,"remaining":7.01},{"phase":1,"remaining":-.1},{"phase":true,"remaining":0},{"phase":1,"remaining":"0.5"},{"phase":0,"remaining":0,"extra":0}]:
		var invalid:=saved.duplicate(true);invalid.enemies.Enemy0.call=bad
		check(not MaintenanceAlarmCarrier.valid_call(bad) and not SortieCheckpoint.validate_world(invalid,battle),"invalid caller snapshot rejected: "+str(bad))
	listener.awareness=EnemyAwareness.new();listener.ensure_awareness();listener.set_physics_process(true)
	var untouched:=listener.awareness.last_known
	var before_health: float=caller.health
	var applied: float=caller.receive_damage(DamagePacket.new(1,0,0,battle.player,&"test.caller_interrupt",&"player",caller.global_position))
	check(applied>0 and caller.health<before_health and caller.call_phase==2 and is_equal_approx(caller.call_remaining,2.5),"real damage interrupts the warning into its short recovery")
	for tick in 3:caller._physics_process(.8)
	check(caller.call_phase==2 and caller.call_remaining>0 and listener.awareness.last_known.is_equal_approx(untouched) and listener.awareness.state==EnemyAwareness.State.PATROL,"interrupted call stays silent throughout recovery; no delayed ghost alarm")
	caller._physics_process(.11)
	for tick in 12:
		if caller.call_phase==1:break
		caller._physics_process(.1)
	check(caller.call_phase==1,"caller can warn again only after interruption recovery expires")
	# Pausing exercises ordinary SceneTree scheduling, not a manual delta call.
	var paused: Dictionary=caller.call_snapshot()
	get_tree().paused=true;caller.set_physics_process(true)
	await frames(6)
	caller.set_physics_process(false);get_tree().paused=false
	check(caller.call_snapshot()==paused and listener.awareness.last_known.is_equal_approx(untouched),"pause freezes the live warning and cannot emit an alarm")
	var origin:=caller.global_position
	caller._physics_process(1.0)
	check(caller.call_phase==2 and is_equal_approx(caller.call_remaining,7.0),"completed warning enters the seven-second call cooldown")
	check(listener.awareness.state==EnemyAwareness.State.INVESTIGATE and listener.awareness.last_known.is_equal_approx(origin) and not listener.awareness.last_known.is_equal_approx(battle.player.global_position),"real CombatNoise attracts the existing eastern enemy to the caller, not to hidden player coordinates")
	check(battle.enemy_container.get_child_count()==4 and not MaintenanceStory.done(session,&"maintenance_bypass"),"calling neither spawns enemies nor advances the service bulkhead objective")
	caller._physics_process(1.25)
	var cooldown: Dictionary=caller.call_snapshot()
	saved=SortieCheckpoint.capture_world(battle)
	check(MaintenanceAlarmCarrier.valid_call(cooldown) and cooldown.remaining>0 and cooldown.remaining<7 and SortieCheckpoint.validate_world(saved,battle),"partly elapsed cooldown remains a valid full-world snapshot")
	caller.restore_call({"phase":0,"remaining":0.0})
	check(SortieCheckpoint.restore_world(saved,battle) and caller.call_snapshot()==cooldown,"partial cooldown roundtrips without resetting the ability")
	listener.awareness=EnemyAwareness.new();listener.ensure_awareness()
	untouched=listener.awareness.last_known
	caller.restore_call({"phase":1,"remaining":.1})
	session.status=SortieSession.Status.FAILED
	caller._physics_process(1.0)
	check(listener.awareness.last_known.is_equal_approx(untouched) and listener.awareness.state==EnemyAwareness.State.PATROL,"ended sortie cannot complete a pending call")
	session.status=SortieSession.Status.ACTIVE
	caller.restore_call({"phase":1,"remaining":.1})
	caller.receive_damage(DamagePacket.new(10000,0,0,battle.player,&"test.caller_death",&"player",caller.global_position))
	caller._physics_process(1.0)
	check(caller.is_dead and listener.awareness.last_known.is_equal_approx(untouched) and listener.awareness.state==EnemyAwareness.State.PATROL,"actual death during a warning cannot ring a posthumous alarm")
	listener.set_physics_process(false)

func _steam_enemies() -> void:
	var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
	var enemies: Array[Node]=battle.enemy_container.get_children()
	var positions: Array[Vector3]=[]
	for enemy in enemies:positions.append(enemy.position)
	battle.player.position=Vector3(0,0,-13)
	enemies[0].position=Vector3(-1,0,-13);enemies[1].position=Vector3(1,0,-13);enemies[2].position=Vector3(5,0,-13)
	var hp: float=battle.player.health
	var a: float=enemies[0].health;var b: float=enemies[1].health;var outside: float=enemies[2].health
	steam.hit_cooldown=0;steam.cycle_time=0;steam._physics_process(0)
	steam.cycle_time=2.5;steam._physics_process(0)
	check(enemies[0].health==a and enemies[1].health==b,"clear and warning phases do not hurt enemies")
	steam.cycle_time=3.3;steam._physics_process(0)
	var da:=maxf(6-enemies[0].armor,0);var db:=maxf(6-enemies[1].armor,0)
	check(is_equal_approx(enemies[0].health,a-da) and is_equal_approx(enemies[1].health,b-db),"same steam pulse damages both exposed enemies through real DamagePackets")
	check(is_equal_approx(battle.player.health,hp-6*(1-battle.player.get_protection())) and steam.hit_cooldown==.5,"player and enemies receive the same pulse before shared cooldown starts")
	check(enemies[2].health==outside,"enemy beyond the marked steam corridor remains unharmed")
	var world:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle) and SortieCheckpoint.restore_world(world,battle),"partial enemy damage and existing pulse timer survive full world restoration")
	steam._physics_process(.2)
	check(is_equal_approx(enemies[0].health,a-da) and is_equal_approx(enemies[1].health,b-db),"restoring inside a hot pulse cannot immediately double-hit enemies")
	if "--trap-write" in OS.get_cmdline_user_args():
		check(SortieRuntime.save_checkpoint()==OK,"partial heat damage and pulse cooldown commit to disk without new schema fields")
		var file:=FileAccess.open("user://steam_trap_expected.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"a":enemies[0].health,"b":enemies[1].health,"cooldown":steam.hit_cooldown}));file.close()
		return
	steam._physics_process(.31)
	check(is_equal_approx(enemies[0].health,a-2*da) and is_equal_approx(enemies[1].health,b-2*db),"next pressure pulse resumes normal enemy damage")
	var after_a: float=enemies[0].health;var after_b: float=enemies[1].health
	check(steam.close_valve(battle.player),"existing valve operation closes the shared hazard")
	steam._physics_process(.5)
	check(enemies[0].health==after_a and enemies[1].health==after_b and steam.hit_cooldown==0,"isolating the line stops enemy damage as well as player damage")
	for index in enemies.size():enemies[index].position=positions[index]
	battle.player.position=Vector3(0,0,-8)
	steam.cycle_time=0;steam.hit_cooldown=0

func _steam_pursuit() -> void:
	# Controlled player start only. Enemy2 stays at its authored north-side spawn;
	# its original AI, navigation, hearing and weapon remain active, not puppeted.
	var enemy: EnemyController
	for candidate in battle.enemy_container.get_children():
		if candidate.get_meta("spawn_key")=="Enemy2":enemy=candidate
	check(enemy!=null,"authored north-side pursuer exists")
	if not enemy:return
	var start:=enemy.global_position;var health:=enemy.health
	var heat_hits: Array[float]=[]
	enemy.damage_received.connect(func(_who,packet: DamagePacket,amount: float):
		if packet.source_weapon==&"maintenance_steam":heat_hits.append(amount))
	battle.player.position=Vector3(0,0,-5)
	enemy.set_physics_process(true)
	var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
	steam.cycle_time=0;steam.hit_cooldown=0;steam.set_physics_process(true)
	CombatNoise.emit_at(battle.player,battle.player.global_position,40,&"gunshot")
	for tick in 600:
		await get_tree().physics_frame
		if not heat_hits.is_empty() or battle.player.is_dead:break
	steam.set_physics_process(false);enemy.set_physics_process(false)
	check(enemy.global_position.distance_to(start)>1 and not heat_hits.is_empty() and enemy.health<health,"authored pursuer actually navigates into live steam and receives environmental damage")
	check(not battle.player.is_dead and not steam.isolated(),"lure works with live enemy attacks before closing the valve")
	print("STEAM_PURSUIT / start=",start," end=",enemy.global_position," heat_hits=",heat_hits," player_health=",battle.player.health)

func load_battle() -> void:
	await super.load_battle()
	if battle.area_root.has_node("Steam"):battle.area_root.get_node("Steam").set_physics_process(false)

func finish_journey() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();get_tree().paused=false
	await frames();AudioDirector.shutdown_for_test()
	print("MAINTENANCE_JOURNEY_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",false)
	if "--caller-read" in args:
		await _alarm_carrier_read();await finish_journey();return
	if "--caller" in args or "--caller-write" in args:
		await _alarm_carrier();await finish_journey();return
	if "--legacy-read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"new code accepts genuine old-code maintenance checkpoint")
		get_tree().paused=true;await load_battle()
		check(not FlowMenu.is_open() and battle.session.maintenance.is_empty() and int(battle.area_root.get_meta("map_revision"))==1 and not battle.area_root.has_node("Steam"),"genuine signed v1 retains original map, not new chamber")
		check(is_equal_approx(battle.area_root.get_node("NorthControl").remaining,5) and battle.area_root.get_node("Survivor").waiting,"old five-second work remainder and companion wait survive")
		battle.area_root.get_node("NorthControl")._process(5)
		check(MaintenanceStory.done(battle.session,&"maintenance_gate") and battle.area_root.get_node("NorthGate").position.y==5,"old timed control still completes under old rules")
		await finish_journey();return
	if "--trap-read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process resumes actual partial steam damage")
		get_tree().paused=true;await load_battle()
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://steam_trap_expected.json"))
		var enemies: Array[Node]=battle.enemy_container.get_children()
		var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
		check(is_equal_approx(enemies[0].health,expected.a) and is_equal_approx(enemies[1].health,expected.b) and is_equal_approx(steam.hit_cooldown,expected.cooldown),"enemy health and shared cooldown retain exact durable values")
		steam._physics_process(0)
		check(is_equal_approx(enemies[0].health,expected.a) and is_equal_approx(enemies[1].health,expected.b),"independent hot-state resume does not grant an extra damage pulse")
		await finish_journey();return
	if "--read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process resumes signed steam corridor")
		get_tree().paused=true
		await load_battle()
		var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
		check(not FlowMenu.is_open() and int(battle.area_root.get_meta("map_revision"))==2,"v2 snapshot restores v2 geometry")
		check(is_equal_approx(steam.cycle_time,3.4) and is_equal_approx(steam.hit_cooldown,.3),"exact hot-cycle phase and hit cooldown survive disk")
		check(steam.warned and not steam.followed and not steam.isolated(),"one-shot warning persists without falsely closing steam")
		check(battle.area_root.get_node("Survivor").waiting and battle.area_root.get_node("Survivor").position.z> -9.65,"actual wait command and safe position persist")
		check(battle.area_root.get_node("Steam/Jets").visible,"hot-state visuals reconstituted, not stale serialized nodes")
		await finish_journey();return
	check(DeploymentPlan.deploy(fixture(),MaintenanceStory.AREA,MaintenanceStory.MISSION,JOURNEY_PATH).error==OK,"normal v2 deployment accepts explicit campus fixture")
	SortieRuntime.get_current_session().maintenance.version=2 # Explicit preserved v2 journey fixture.
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var steam: MaintenanceSteam=world.get_node("Steam")
	var survivor: MaintenanceSurvivor=world.get_node("Survivor")
	check(session.maintenance=={"version":2,"steam_off":false} and session.validate(),"fresh mission uses typed optional v2 facts")
	check(int(world.get_meta("map_revision"))==2 and world.get_node("ChamberWall0Body").collision_layer==4,"new corridor has real blocking geometry")
	check(world.get_node("Bypass/TerminalPedestal").mesh!=world.get_node("WardControl/TerminalPedestal").mesh,"same child names have distinct authored mesh resources")
	check(not world.get_node("NorthControl").interact(battle.player,session).success,"north shutter cannot skip bypass, ward or isolation")
	check(not world.get_node("SteamValve").interact(battle.player,session).success,"valve cannot be operated remotely")
	check((await use("Bypass")).success and MaintenanceStory.done(session,&"maintenance_bypass") and world.get_node("Bypass").remaining==0,"new bypass opens instantly; no replacement long work timer")
	check(world.get_node("ServiceGate").position.y==5 and world.get_node("ServiceGateLink").enabled,"instant unlatch opens the real collider and nav link")
	if "--pursuit" in args:
		await _steam_pursuit();await finish_journey();return
	if "--trap" in args or "--trap-write" in args:
		_steam_enemies();await finish_journey();return
	battle.player.position=Vector3(0,0,-13);await frames()
	var query:=PhysicsRayQueryParameters3D.create(Vector3(0,1,-13),Vector3(9,1,-13),4)
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"player cannot sidestep through east steam wall")
	var hp: float=battle.player.health
	steam.cycle_time=0;steam._physics_process(0)
	check(battle.player.health==hp and world.get_node("Steam/Safe").visible and not world.get_node("Steam/Jets").visible,"clear window gives visible safe crossing without damage")
	steam.cycle_time=2.5;steam._physics_process(0)
	check(battle.player.health==hp and world.get_node("Steam/Warning").visible,"pressure warning precedes heat without damage")
	await capture("maintenance_steam_warning")
	steam.cycle_time=3.3;steam._physics_process(0)
	var hit: float=6*(1-battle.player.get_protection())
	check(is_equal_approx(battle.player.health,hp-hit) and world.get_node("Steam/Jets").visible,"hot steam applies actual armor-adjusted six-base damage")
	await capture("maintenance_steam_hot")
	steam._physics_process(.2)
	check(is_equal_approx(battle.player.health,hp-hit),"hot damage is rate limited, not applied every frame")
	battle.player.position=Vector3(0,0,-8);await frames()
	steam.hit_cooldown=0;steam._physics_process(0)
	check(is_equal_approx(battle.player.health,hp-hit),"outside the marked chamber no steam damage is applied")
	check((await use("WardControl")).success and MaintenanceStory.done(session,&"maintenance_release") and world.get_node("WardControl").remaining==0,"ward release is also immediate")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(battle.enemy_container.get_child_count()==6 and not (await use("WardControl")).success,"ward release spawns exactly two once")
	# Controlled starting position; movement to the safety line is real follower physics.
	survivor.position=Vector3(0,0,-8);survivor.velocity=Vector3.ZERO;survivor.traversing_link=false;survivor.link_goal=Vector3.ZERO;survivor.repath=0
	battle.player.position=Vector3(0,0,-18)
	await frames(180)
	check(survivor.position.z> -9.65 and survivor.position.z< -9.2 and survivor.steam_blocked,"real follower stops before hot corridor, even during clear window")
	check(steam.warned and not survivor.waiting and survivor.collision_layer==0,"safety stop is not a manual wait or shootable escort-health mechanic")
	var at: Vector3=survivor.position
	await frames(40)
	check(survivor.position.distance_to(at)<.04,"follower does not creep across the safety line")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and survivor.waiting,"explicit wait still works at safety line")
	steam.cycle_time=3.4;steam.hit_cooldown=.3;steam.refresh()
	get_tree().paused=true
	check(SortieRuntime.save_checkpoint()==OK,"hot-cycle and waiting-survivor checkpoint commits")
	var saved:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"legitimate full steam world validates")
	for patch in [{"cycle_time":4.8},{"cycle_time":-1},{"hit_cooldown":.6},{"warned":7},{"followed":true}]:
		var invalid:=saved.duplicate(true);invalid.nodes.Steam.merge(patch,true)
		check(not SortieCheckpoint.validate_world(invalid,battle),"forged steam state refused: "+str(patch))
	var invalid:=saved.duplicate(true);invalid.nodes.Survivor.position=[0,0,-13]
	check(not SortieCheckpoint.validate_world(invalid,battle),"cannot restore escort inside an unisolated hazard")
	invalid=saved.duplicate(true);invalid.nodes.Bypass.remaining=1
	check(not SortieCheckpoint.validate_world(invalid,battle),"new immediate controls reject forged remaining work")
	if "--write" in args:await finish_journey();return
	get_tree().paused=false
	battle.player.position=world.get_node("SteamValve").position+Vector3.RIGHT;await frames()
	check(world.get_node("SteamValve").interact(battle.player,session).success and steam.isolated(),"actual nearby far-side valve permanently isolates steam")
	steam.cycle_time=3.3;hp=battle.player.health;steam._physics_process(0)
	check(steam.hit_cooldown==0 and not world.get_node("Steam/Jets").visible and battle.player.health==hp,"isolated pipe stops all heat visuals and damage")
	check(survivor.waiting and not steam.followed,"closing valve does not cancel explicit wait or teleport companion")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and not survivor.waiting,"player must return and call waiting survivor")
	battle.player.position=Vector3(0,0,-18);await frames(180)
	check(survivor.position.z< -15.5 and steam.followed,"real follower traverses isolated corridor and emits one follow beat")
	check((await use("NorthControl")).success and MaintenanceStory.done(session,&"maintenance_gate") and world.get_node("NorthControl").remaining==0,"isolated route unlocks instantaneous north shutter")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(battle.enemy_container.get_child_count()==8 and not session.is_mission_completed(),"finite final pair activates but gates alone do not rescue")
	var data:=SortieCheckpoint.session_data(session);data.maintenance.steam_off=false
	check(SortieCheckpoint.restore_session(data)==null,"north-open session cannot claim steam still live")
	check(world.get_node("Retreat").can_extract(session),"south retreat remains open after every step")
	await capture("maintenance_steam_isolated")
	await finish_journey()
