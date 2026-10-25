extends Node
## End-to-end input-driven campus chapter. Actor relocation is ONLY the actual
## door transition; neither the test nor the route guide teleports the player.
var survey: Node3D
var field: Node3D
var failures: Array[String]=[]
var checks:=0
var ticks:=0
var walked:=0.0
var evidence:=OS.get_environment("BUNNY_EVIDENCE")
var actions: Array[String]=[]

func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures.append(text);push_error(text)

func frames(count := 10) -> void:
	for i in count:await get_tree().physics_frame

func release() -> void:
	for action: String in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)

func move(direction: Vector2) -> void:
	release()
	Input.action_press("move_left" if direction.x<0 else "move_right",absf(direction.x))
	Input.action_press("move_forward" if direction.y<0 else "move_back",absf(direction.y))

func follow(points: PackedVector2Array, room := "") -> bool:
	var origin: Vector3=field.rooms[room].position if not room.is_empty() else Vector3.ZERO
	var progress:=0.0;var segment_ticks:=0
	for point: Vector2 in points:
		var target:=point+Vector2(origin.x,origin.z)
		while Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(target)>.35:
			var before:=Vector2(survey.actor.position.x,survey.actor.position.z)
			move(before.direction_to(target));await get_tree().physics_frame
			var now:=Vector2(survey.actor.position.x,survey.actor.position.z)
			var step:=now.distance_to(before);walked+=step;progress+=step;ticks+=1;segment_ticks+=1
			if segment_ticks%180==0:
				if progress<.35:
					check(false,"Normal controller blocked in %s at %s aiming for %s"%[room,now,target]);release();return false
				progress=0
			if ticks>42000:check(false,"Chapter traversal exceeded bounded tick budget");release();return false
	release();await frames(18)
	return true

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;get_viewport().push_input(event);await get_tree().process_frame

func click(button: Button) -> void:
	check(button!=null and not button.disabled and get_viewport().get_visible_rect().encloses(button.get_global_rect()),"Actual task decision button is visible and enabled")
	if DisplayServer.get_name()=="headless":button.pressed.emit()
	else:
		for pressed: bool in [true,false]:
			var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
			get_viewport().push_input(event);await get_tree().process_frame

func capture(name: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	for i in 16:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(name+".png"))

func outdoor(id: String) -> bool:
	var navigation:=preload("res://scripts/world/geography/campus_fieldwork_route.gd").new(survey.geo)
	var target: Vector2=field.sites[id].point
	var path: PackedVector2Array=navigation.find_path(Vector2(survey.actor.position.x,survey.actor.position.z),target)
	check(path.size()>=2,"Connected, visibility-checked campus route exists: "+id)
	if path.is_empty():return false
	return await follow(path)

func operate(id: String, seconds := 0.0) -> void:
	var station: Dictionary=field.nearest()
	check(not station.is_empty() and field._action(station)==id,"Normal input reaches actual station: "+id)
	await key(KEY_E)
	await frames(ceili(seconds*60)+8)
	check(field.journal.history.has(id),"Interaction/timer commits chapter step: "+id)
	actions.append(id);print("CAMPUS CHAPTER STEP ",id," / walked ",snappedf(walked,.1)," m")

func enter(id: String) -> bool:
	if not await outdoor(id):return false
	await capture("entry_"+id)
	await key(KEY_E);await frames(30)
	check(field.inside==id and survey.actor.is_on_floor(),"Real entrance input transitions onto the correct interior floor: "+id)
	return field.inside==id

func exit_via(points: PackedVector2Array,id: String) -> bool:
	if not await follow(points,id):return false
	var expected: Vector3=field.outside_return
	await key(KEY_E);await frames(25)
	check(field.inside.is_empty() and survey.actor.position.distance_to(expected)<.3,"Exit returns to the same outdoor doorway: "+id)
	return field.inside.is_empty()

func finish(profile_before: String) -> void:
	release()
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==profile_before,"Complete chapter leaves legacy Profile/gear/economy/checkpoint unchanged")
	print("CAMPUS FIELDWORK RUN: ",checks," checks / ",failures.size()," failures / ",snappedf(walked,.1)," m / ",actions.size()," completed actions")
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("fieldwork_run.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"walked_m":walked,"ticks":ticks,"actions":actions,"history":field.journal.history,"flags":field.journal.flags,"native":DisplayServer.get_name()!="headless","method":"Only normal movement/E/button input; actual portals are the sole room transfers; no direct state grants"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)

func _ready() -> void:
	await get_tree().process_frame
	var profile_before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	survey.fieldwork_path="user://campus_chapter_run_%s.json"%Time.get_ticks_usec();add_child(survey)
	field=survey.fieldwork;survey.toggle_walking();await frames(40)
	await key(KEY_E);check(not field.journal.flags.accepted,"E at the gate spawn does not remotely accept a desk task")
	if not await outdoor("dispatch"):finish(profile_before);return
	await operate("dispatch");await capture("dispatch_accepted")
	await key(KEY_M);await frames(12);check(field.route_points.size()>1,"Task map draws a real source-road guidance route");await capture("campus_task_route");await key(KEY_M)
	if not await enter("library"):finish(profile_before);return
	if not await follow(PackedVector2Array([Vector2(0,7),Vector2(-8,7)]),"library"):finish(profile_before);return
	await operate("catalogue");await capture("library_catalogue")
	if not await follow(PackedVector2Array([Vector2(0,7),Vector2(0,-6),Vector2(5,-6),Vector2(7,-9)]),"library"):finish(profile_before);return
	# Actual input cancellation, not shortening or directly advancing the timer.
	await key(KEY_E);await frames(45);await key(KEY_M);await frames(20)
	check(not field.journal.flags.archive_power and field.work.is_empty(),"Opening map interrupts unfinished physical work without granting progress")
	await key(KEY_M);await frames(12);await operate("archive_power",3)
	if not await follow(PackedVector2Array([Vector2(12.5,-8.7)]),"library"):finish(profile_before);return
	await operate("archive",4);await capture("library_archive_collected")
	var checkpoint:=CampusFieldworkJournal.new(survey.fieldwork_path)
	check(checkpoint.load_progress() and checkpoint.flags.archive and not checkpoint.flags.relay,"Disk restart point contains real partial progress, not a completed quest")
	if not await exit_via(PackedVector2Array([Vector2(6,-6),Vector2(0,-6),Vector2(0,9)]),"library"):finish(profile_before);return
	if not await enter("main_hall"):finish(profile_before);return
	if not await follow(PackedVector2Array([Vector2(0,6.1),Vector2(-7,6.1)]),"main_hall"):finish(profile_before);return
	await operate("diagram")
	if not await follow(PackedVector2Array([Vector2(-10,6.1),Vector2(-10,3),Vector2(-8.5,3),Vector2(-8.5,-4),Vector2(-10,-6.7)]),"main_hall"):finish(profile_before);return
	await operate("relay",6);await capture("workshop_repaired")
	if not await follow(PackedVector2Array([Vector2(-8.5,-4),Vector2(-8.5,3),Vector2(8.5,3),Vector2(8.5,-5),Vector2(13,-8.7)]),"main_hall"):finish(profile_before);return
	await key(KEY_E);check(field.panel.visible and field.choice=="blackout","Master breaker opens an actual consequence confirmation")
	await capture("master_choice")
	await click(field.panel.find_child("ConfirmMasterBlackout",true,false));await frames(195)
	check(field.journal.blackout and not field.journal.flags.shelter_power and not field.journal.unavailable("deliver").is_empty(),"Confirmed wrong branch switches off A and blocks handover")
	actions.append("blackout");await capture("master_blackout")
	await operate("restore",3)
	if not await follow(PackedVector2Array([Vector2(8,-8.7)]),"main_hall"):finish(profile_before);return
	await operate("isolate",3);await capture("emergency_power_preserved")
	if not await exit_via(PackedVector2Array([Vector2(8.5,-5),Vector2(8.5,3),Vector2(0,9)]),"main_hall"):finish(profile_before);return
	if not await outdoor("youth_sample"):finish(profile_before);return
	await operate("youth_sample",2);await capture("youth_investigation")
	if not await enter("activity"):finish(profile_before);return
	if not await follow(PackedVector2Array([Vector2(0,-5),Vector2(9,-5)]),"activity"):finish(profile_before);return
	await operate("deliver",3);await capture("relief_handover")
	if not await exit_via(PackedVector2Array([Vector2(0,-5),Vector2(0,9)]),"activity"):finish(profile_before);return
	if not await outdoor("jingye_sample"):finish(profile_before);return
	await operate("jingye_sample",2);await capture("jingye_investigation")
	if not await outdoor("dispatch"):finish(profile_before);return
	await operate("report");await capture("chapter_complete")
	await key(KEY_J);await capture("completed_journal")
	check(field.journal.flags.reported and field.journal.flags.youth_sample and field.journal.flags.jingye_sample,"Complete outdoor/interior chapter plus both optional investigations reached")
	var reloaded:=CampusFieldworkJournal.new(survey.fieldwork_path)
	check(reloaded.load_progress() and reloaded.flags==field.journal.flags and reloaded.history==field.journal.history,"Completed journal survives actual disk reload")
	check(walked>1500,"Proof covers campus distances, not only room fixtures")
	finish(profile_before)
