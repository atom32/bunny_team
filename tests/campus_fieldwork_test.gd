extends Node
## State, persistence, portal safety and real interior collision fixtures.
var failures: Array[String]=[]
var checks:=0
var survey: Node3D
var evidence:=OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures.append(text);push_error(text)

func frames(count := 8) -> void:
	for i in count:await get_tree().process_frame

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;get_viewport().push_input(event)
		await get_tree().process_frame

func capture(label: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(15);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))

func click(button: Button) -> void:
	check(button!=null and not button.disabled and get_viewport().get_visible_rect().encloses(button.get_global_rect()),"Chapter control is visible and enabled")
	if DisplayServer.get_name()=="headless":button.pressed.emit()
	else:
		for pressed: bool in [true,false]:
			var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
			get_viewport().push_input(event);await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	var profile_before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var path: String="user://campus_fieldwork_unit_%s.json"%Time.get_ticks_usec()
	var journal:=CampusFieldworkJournal.new(path)
	check(journal.load_progress() and not FileAccess.file_exists(path),"Pure survey does not create a chapter save")
	for action: String in ["catalogue","archive_power","archive","relay","isolate","deliver","report","youth_sample"]:check(not journal.perform(action),"Unaccepted task rejects "+action)
	check(journal.perform("dispatch"),"Dispatch accepts the independent chapter")
	check(not journal.perform("archive") and not journal.perform("relay") and not journal.perform("deliver") and not journal.perform("report"),"Required tasks cannot be skipped")
	check(journal.perform("catalogue") and not journal.perform("catalogue"),"Catalogue/key is idempotent")
	check(journal.perform("archive_power") and journal.perform("archive"),"Archive requires key and power")
	check(not journal.perform("archive"),"No duplicate quest item pickup")
	check(journal.perform("diagram") and journal.perform("relay"),"Workshop data and physical repair have separate states")
	check(journal.perform("isolate") and journal.flags.shelter_power,"Branch isolation preserves emergency power")
	check(journal.perform("blackout") and journal.blackout and not journal.flags.shelter_power and not journal.perform("deliver"),"Wrong master choice has an actual reversible consequence")
	check(journal.save_progress()==OK,"Interrupted/wrong-choice state saves independently")
	var loaded:=CampusFieldworkJournal.new(path)
	check(loaded.load_progress() and loaded.blackout and loaded.flags.archive and loaded.flags.relay,"Restart restores wrong choice and actual task progress")
	check(loaded.perform("restore") and not loaded.perform("deliver") and loaded.perform("isolate"),"Restoring master does not silently substitute for isolating B")
	check(loaded.perform("deliver") and loaded.perform("report") and not loaded.perform("report"),"Delivery then report completes once")
	check(not loaded.perform("blackout"),"Signed-off emergency power cannot be accidentally cut after delivery")
	check(loaded.perform("youth_sample") and loaded.perform("jingye_sample"),"Optional investigation remains available after completion")
	check(loaded.save_progress()==OK,"Verified save replacement works on this platform")
	var corrupt_path: String=path+".corrupt"
	var file:=FileAccess.open(corrupt_path,FileAccess.WRITE);file.store_string("{broken source");file.close()
	var digest:=FileAccess.get_sha256(corrupt_path)
	var corrupt:=CampusFieldworkJournal.new(corrupt_path)
	check(not corrupt.load_progress() and corrupt.save_progress()==ERR_FILE_CORRUPT and FileAccess.get_sha256(corrupt_path)==digest,"Corrupt task log is preserved, not overwritten")
	var impossible: Dictionary={"version":1,"flags":loaded.flags.duplicate(),"blackout":false,"history":[]}
	impossible.flags.archive=false
	check(not loaded._valid(impossible),"Impossible persisted prerequisites are rejected")
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate();survey.fieldwork_path=path+".scene";add_child(survey)
	await frames(12)
	var field: Node3D=survey.fieldwork
	check(field.sites.size()==15,"Twelve source building entries, east dispatch and both lake investigations exist")
	for site: Dictionary in field.sites.values():check(survey.geo.safe_walk_point(site.point),"Every outdoor task approach respects real ground/water/buildings")
	survey.toggle_walking();await frames(35)
	field.enter_room("library")
	check(field.inside.is_empty(),"Calling a remote portal cannot teleport the actor")
	await key(KEY_J)
	check(field.panel.visible and not survey.actor.is_physics_processing(),"Actual J pauses control and opens the task journal")
	var paused: Vector3=survey.actor.position
	Input.action_press("move_left");await frames(20);Input.action_release("move_left")
	check(survey.actor.position.distance_to(paused)<.01,"Journal cannot move an unseen character")
	await capture("journal_unaccepted")
	await key(KEY_ESCAPE)
	check(not field.panel.visible and survey.actor.is_physics_processing(),"Escape returns normal controller ownership")
	# Explicit camera/physics fixtures, not claimed as normal traversal.
	for id: String in ["library","main_hall","activity"]:
		var site: Dictionary=field.sites[id]
		survey.actor.position=survey.geo.mesh_at3(site.point,.12);survey.actor.velocity=Vector3.ZERO;await frames(25)
		var outside: Vector3=survey.actor.position
		await key(KEY_E);await frames(25)
		check(field.inside==id,"Actual E enters the matching source building: "+id)
		if field.inside!=id:continue
		var room: Node3D=field.rooms[id]
		check(survey.actor.is_on_floor() and survey.actor.position.y<-110,"Room has a real collidable floor: "+id)
		check(room.plan.size()>10 and room.stations.size()>=2,"Room contains walls, solid furniture and usable stations: "+id)
		var query:=PhysicsRayQueryParameters3D.create(room.position+Vector3(-15,1,6),room.position+Vector3(-18,1,6),4)
		check(not survey.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"Full-height boundary collision retained behind the visual cutaway: "+id)
		if id=="library":
			var gate_query:=PhysicsRayQueryParameters3D.create(room.position+Vector3(1,1,-6),room.position+Vector3(5,1,-6),4)
			check(not survey.get_world_3d().direct_space_state.intersect_ray(gate_query).is_empty(),"Unaccepted archive key gate really blocks traversal")
			# Explicit through-wall interaction fixture, not traversal evidence.
			survey.actor.position=room.position+Vector3(1.8,.12,-6);survey.actor.velocity=Vector3.ZERO;await frames(20)
			field._station("fixture","behind locked gate",room.position+Vector3(4.1,.05,-6),"library",0)
			check(field.nearest().is_empty(),"A nearby station behind a real wall is not offered as usable")
			await key(KEY_E);check(not field.journal.flags.accepted,"Through-wall E cannot grant task progress")
			field.stations.pop_back();survey.actor.position=room.position+room.SPAWN;survey.actor.velocity=Vector3.ZERO;await frames(15)
		await capture("interior_"+id)
		await key(KEY_M);check(survey.route_map.visible and not survey.actor.is_physics_processing(),"Indoor map pauses physics: "+id)
		await capture("floorplan_"+id);await key(KEY_M)
		await key(KEY_E);await frames(25)
		check(field.inside.is_empty() and Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(Vector2(outside.x,outside.z))<.15,"Exit E returns to actual approach without jumping across campus: "+id)
	check(not FileAccess.file_exists(survey.fieldwork_path),"Exploring all rooms without accepting a task does not write progress")
	var site_records: Dictionary=field.sites.duplicate(true)
	survey.queue_free();await frames(4)
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate();survey.fieldwork_path=path;add_child(survey);await frames(12);field=survey.fieldwork
	check(field.journal.flags==loaded.flags and not survey.walking and field.inside.is_empty(),"Fresh scene restores completed chapter, but starts safely outside all rooms")
	survey.toggle_walking();survey.actor.position=survey.geo.mesh_at3(field.sites.main_hall.point,.12);survey.actor.velocity=Vector3.ZERO;await frames(30);await key(KEY_E);await frames(20)
	check(field.inside=="main_hall","Resumed chapter can re-enter the actual workshop")
	var indicators_ok:=true
	for lamp: MeshInstance3D in field.rooms.main_hall.power_lamps:
		var online: bool=lamp.material_override.emission_enabled
		if online!=(lamp.get_meta("role")=="MasterBreaker"):indicators_ok=false
	check(indicators_ok,"Rebuilt workshop restores B isolated / A on in actual rendered hardware")
	await capture("resumed_workshop")
	field.journal.space_notes.append("library") # Explicit state fixture for reset ownership.
	field.reset_chapter();check(field.journal.flags.reported,"Reset without confirmation is ignored")
	await key(KEY_J)
	await click(field.panel.find_child("ResetCampusChapter",true,false));check(field.choice=="reset","Reset requires a separate confirmation panel")
	await click(field.panel.find_child("CancelCampusReset",true,false));check(field.journal.flags.reported,"Cancelling reset preserves progress")
	await key(KEY_J);await click(field.panel.find_child("ResetCampusChapter",true,false));await click(field.panel.find_child("ConfirmCampusReset",true,false))
	check(not field.journal.flags.accepted and not field.journal.flags.reported,"Confirmed reset clears only this chapter")
	var restarted:=CampusFieldworkJournal.new(path);check(restarted.load_progress() and not restarted.flags.accepted and restarted.space_notes==["library"],"Confirmed task reset persists while retaining independent exploration notes")
	field.exit_room();await frames(20)
	survey.actor.position=survey.geo.mesh_at3(field.sites.dispatch.point,.12);survey.actor.velocity=Vector3.ZERO;await frames(25)
	field.journal.path=path+".missing_directory/progress.json"
	await key(KEY_E)
	check(field.journal.flags.accepted and field.save_error!=OK and "保存失败" in field.notice.text,"Actual save failure is visible while keeping in-memory progress")
	await key(KEY_J);check(field.panel.visible,"Unsaved task still exposes the journal and persistent error indicator");await capture("save_failure_journal")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==profile_before,"Interior, UI and chapter fixtures preserve complete legacy Profile")
	print("CAMPUS FIELDWORK TEST: ",checks," checks / ",failures.size()," failures")
	if not evidence.is_empty():
		var result:=FileAccess.open(evidence.path_join("fieldwork_unit.json"),FileAccess.WRITE);result.store_string(JSON.stringify({"checks":checks,"failures":failures,"sites":site_records,"native":DisplayServer.get_name()!="headless"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)
