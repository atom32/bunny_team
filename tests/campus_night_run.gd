extends "res://tests/campus_spaces_run.gd"
## Normal-input night mission. No actor placements or damage/state fixtures.
var op: Node3D
var combat_frames:=0
var real_fights:=0

func clear_floor(point: Vector2) -> bool:
	return super.clear_floor(point) and (not op or not op.state.active or op._floor_clear(field.inside,point,.46))

func aim_at(point: Vector3) -> void:
	var direction: Vector3=survey.actor.global_position.direction_to(point)
	for action: String in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
	Input.action_press("aim_left" if direction.x<0 else "aim_right",absf(direction.x))
	Input.action_press("aim_up" if direction.z<0 else "aim_down",absf(direction.z))

func release_fire() -> void:
	Input.action_release("fire")
	for action: String in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)

func check_guidance() -> void:
	var point: Vector3=op.guide_point();var here: Vector3=survey.actor.position
	var path: PackedVector2Array=op.path_between(field.inside,Vector2(here.x,here.z),Vector2(point.x,point.z))
	check(path.size()>1,"Current designed-floor objective has furniture-clear guidance: "+field.inside)

func sight_to(node: Node3D) -> bool:
	var q:=PhysicsRayQueryParameters3D.create(survey.actor.position+Vector3.UP*1.25,node.position+Vector3.UP*1.1,6)
	q.exclude=[survey.actor.get_rid()]
	var hit:=get_viewport().world_3d.direct_space_state.intersect_ray(q)
	return not hit.is_empty() and hit.collider==node

func fight_nearby() -> bool:
	for enemy: Node3D in op.enemies:
		if enemy.dead or enemy.room!=field.inside or enemy.position.distance_to(survey.actor.position)>22 or absf(enemy.position.y-survey.actor.position.y)>.4 or not sight_to(enemy):continue
		release();real_fights+=1
		var timeout:=0
		while not enemy.dead and enemy.position.distance_to(survey.actor.position)<30 and sight_to(enemy):
			aim_at(enemy.position);Input.action_press("fire")
			if op.state.magazine<=0:
				release_fire();await key(KEY_R)
			await get_tree().physics_frame;timeout+=1;combat_frames+=1
			if survey.actor.is_dead or not op.state.active:check(false,"Normal combat traversal survived");release_fire();return false
			if timeout>480:
				print("AIM FAILURE actor=",survey.actor.position," aim=",survey.actor.aim_world_point," enemy=",enemy.id," ",enemy.position," hp=",enemy.health)
				await capture("night_aim_failure");check(false,"Actual firing stops the sentry within a bounded encounter");release_fire();return false
		release_fire();await frames(12)
		if survey.actor.health<160 and op.state.meds>0:await key(KEY_H);await frames(120)
	return true

func follow(path: PackedVector2Array,origin := Vector3.ZERO) -> bool:
	var progress:=0.0;var steps:=0
	for point: Vector2 in path:
		var target:=point+Vector2(origin.x,origin.z)
		while Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(target)>.24:
			if steps%45==0 and op and op.state.active:
				if not await fight_nearby():release();return false
			var before:=Vector2(survey.actor.position.x,survey.actor.position.z)
			var direction:=before.direction_to(target);release()
			var strength:=clampf(before.distance_to(target)*2,.25,1)
			Input.action_press("move_left" if direction.x<0 else "move_right",absf(direction.x)*strength)
			Input.action_press("move_forward" if direction.y<0 else "move_back",absf(direction.y)*strength)
			await get_tree().physics_frame
			var now:=Vector2(survey.actor.position.x,survey.actor.position.z)
			var distance:=now.distance_to(before);walked+=distance;progress+=distance;steps+=1;ticks+=1
			if steps%240==0:
				if progress<.35:check(false,"Blocked actual night movement in %s at %s toward %s"%[field.inside,now,target]);release();return false
				progress=0
			if ticks>120000:check(false,"Night traversal tick budget exceeded");release();return false
		release();await frames(15)
	return true

func to_building(id: String) -> bool:
	if not field.inside.is_empty():
		if Spaces.ground(field.inside)!=field.inside:
			if not await climb_to(Spaces.ground(field.inside)):return false
		build_floor_graph()
		if not await go(Vector2(0,floor_room.extent.y*.5-3)):return false
		await key(KEY_E);await frames(20)
		check(field.inside.is_empty(),"Leave building through actual ground entrance")
	var here:=Vector2(survey.actor.position.x,survey.actor.position.z)
	var path: PackedVector2Array=navigation.find_path(here,field.sites[id].point)
	check(not path.is_empty(),"Connected night mission road route: "+id)
	if path.is_empty() or not await follow(path):return false
	await key(KEY_E);await frames(25)
	check(field.inside==id,"Night objective building reached through source-ground E entrance: "+id)
	if field.inside==id:build_floor_graph()
	if field.inside==id:check_guidance()
	return field.inside==id

func break_crate(id: String) -> bool:
	var prop: Node3D
	for node: Node3D in op.props:
		if node.id==id:prop=node
	build_floor_graph()
	var local: Vector3=prop.position-floor_room.position
	if not await go(Vector2(local.x,local.z+2.2)):return false
	if not await fight_nearby():return false
	var timeout:=0
	while not prop.destroyed:
		aim_at(prop.position);Input.action_press("fire")
		if op.state.magazine<=0:release_fire();await key(KEY_R)
		await get_tree().physics_frame;timeout+=1
		if timeout>360:check(false,"Physical firearm breaks marked crate: "+id);release_fire();return false
	release_fire();await frames(20)
	check(prop.collider.disabled,"Breaking crate releases its physical collision: "+id)
	await key(KEY_E);await frames(15)
	return true

func finish_night(before: String) -> void:
	release();release_fire()
	check(op.state.extractions==1 and climbs==6,"Complete mission plus optional plant returns through three upper-floor pairs")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==before,"Normal-input night run leaves entire legacy profile unchanged")
	print("CAMPUS NIGHT RUN: ",checks," checks / ",failures.size()," failures / ",snappedf(walked,.1)," m / fights ",real_fights," / bullets ",op.shots_fired)
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("night_run.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"walked_m":walked,"ticks":ticks,"combat_frames":combat_frames,"climbs":climbs,"encounters":real_fights,"bullets":op.shots_fired,"bank":op.state.bank,"extractions":op.state.extractions,"native":DisplayServer.get_name()!="headless","method":"Normal movement, aiming/fire/reload/E/H inputs and actual directory buttons; no placements, damage packets or mission flags injected"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)

func _ready() -> void:
	await get_tree().process_frame
	var before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	survey.fieldwork_path="user://night_run_%s.chapter"%Time.get_ticks_usec();survey.night_ledger_path=survey.fieldwork_path+".ledger";add_child(survey)
	field=survey.fieldwork;op=survey.night_operation;navigation=preload("res://scripts/world/geography/campus_fieldwork_route.gd").new(survey.geo)
	survey.toggle_walking();await frames(35)
	var here:=Vector2(survey.actor.position.x,survey.actor.position.z)
	if not await follow(navigation.find_path(here,field.sites.dispatch.point)):finish_night(before);return
	await key(KEY_N);await capture("night_run_briefing");await click(field.panel.find_child("BeginCampusNight",true,false));await frames(15)
	check(op.state.active,"Actual N briefing and button accept a night operation at dispatch")
	await key(KEY_M);await frames(12);check(field.route_points.size()>1,"Night mission uses real road guidance before rain-relay acceptance");await capture("night_run_route");await key(KEY_M)
	if not await to_building("canteen_north") or not await climb_to("canteen_prep"):finish_night(before);return
	if not await break_crate("relay_crate"):finish_night(before);return
	check(op.state.stage==1 and op.state.bag.parts==2,"Normal shooting and E pickup recover fuse and loot")
	check_guidance()
	await key(KEY_M);await capture("night_run_floorplan");await key(KEY_M)
	await capture("night_run_relay")
	if not await to_building("network") or not await climb_to("network_control"):finish_night(before);return
	build_floor_graph()
	var terminal: Dictionary={}
	for entry: Dictionary in op.stations:
		if entry.id=="terminal":terminal=entry
	var local: Vector3=terminal.point-floor_room.position
	if not await go(Vector2(local.x,local.z)) or not await fight_nearby():finish_night(before);return
	await key(KEY_E);await frames(205);check(op.state.powered,"Normal E stay operation restores network lighting")
	await capture("night_run_power")
	await key(KEY_E);await frames(270);check(op.state.stage==2,"Normal E stay operation retrieves offline record")
	if not await to_building("swim") or not await climb_to("swim_plant"):finish_night(before);return
	if not await break_crate("plant_rare"):finish_night(before);return
	check(op.state.bag.drive>0,"Optional guarded plant cache supplies high-value loot")
	await key(KEY_N);await capture("night_run_bag");await key(KEY_N)
	if not await to_building("activity"):finish_night(before);return
	build_floor_graph()
	var handover: Dictionary={}
	for entry: Dictionary in op.stations:
		if entry.id=="handover":handover=entry
	local=handover.point-floor_room.position
	if not await go(Vector2(local.x,local.z)):finish_night(before);return
	await key(KEY_E);await frames(150);check(op.state.stage==3,"Normal-input night handover unlocks east extraction")
	build_floor_graph()
	if not await go(Vector2(0,floor_room.extent.y*.5-3)):finish_night(before);return
	await key(KEY_E);await frames(20)
	here=Vector2(survey.actor.position.x,survey.actor.position.z)
	var target: Vector3=op.stations[0].point
	if not await follow(navigation.find_path(here,Vector2(target.x,target.z))):finish_night(before);return
	await key(KEY_E);await frames(280)
	check(not op.state.active and op.state.extractions==1,"Whole normal-input night mission extracts loot to independent ledger")
	check(op.state.bank.parts>0 and op.state.bank.drive>0,"Actual recovered loot, not a scripted reward, is banked")
	check(not field.journal.flags.accepted,"Night mission does not mutate peaceful relay progress")
	await capture("night_run_complete");finish_night(before)
