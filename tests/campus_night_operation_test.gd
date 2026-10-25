extends Node
## Explicit unit/physics/UI fixtures, not a normal-input traversal claim.
const State := preload("res://scripts/world/geography/campus_night_state.gd")
var checks:=0
var failures: Array[String]=[]
var survey: Node3D
var op: Node3D
var evidence:=OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures.append(text);push_error(text)

func frames(count := 8) -> void:
	for i in count:await get_tree().physics_frame

func fixture(room: String,point: Vector3) -> void:
	if survey.fieldwork.panel.visible:survey.fieldwork.close_panel()
	if room.is_empty() and not survey.fieldwork.inside.is_empty():
		while not survey.fieldwork.inside.is_empty():survey.fieldwork.exit_room()
	elif not room.is_empty():survey.fieldwork._show_room(room)
	survey.actor.position=point;survey.actor.velocity=Vector3.ZERO

func capture(label: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	for i in 18:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))

func _ready() -> void:
	await get_tree().process_frame
	var profile:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var path: String="user://night_unit_%s.json"%Time.get_ticks_usec()
	var state:=State.new(path)
	check(state.load_ledger() and state.begin(),"Independent empty ledger starts one sortie")
	check(not state.begin(),"Cannot start a second active sortie")
	check(state.add("drive",4)==4 and state.weight()==12,"Valuable loot consumes real capacity")
	check(state.add("parts",1)==0,"Full bag rejects excess without removing ground loot")
	check(state.discard("drive") and state.weight()==9,"Bag supports discarding one item")
	check(state.add("parts",3)==1 and state.weight()==11,"Partial pickup respects integer weight")
	check(state.add("ammo",300)==150 and state.reserve==240,"Ammunition cap preserves excess")
	check(state.add("med",8)==2 and state.meds==4,"Medical cap preserves excess")
	check(state.commit()!=OK and not FileAccess.file_exists(path),"Cannot bank loot before final extraction stage")
	state.stage=3;check(state.commit()==OK,"Extraction atomically writes the independent bank")
	check(state.commit()!=OK,"Repeated extraction cannot duplicate loot")
	var reload_state:=State.new(path);check(reload_state.load_ledger() and reload_state.extractions==1 and reload_state.bank.drive==3,"Extracted loot survives file reload")
	reload_state.begin();reload_state.add("drive",1);reload_state.abandon()
	check(reload_state.bank.drive==3 and reload_state.weight()==0,"Abandon loses current bag, not extracted bank")
	var bad:=FileAccess.open(path+".bad",FileAccess.WRITE);bad.store_string("{invalid");bad.close()
	var corrupt:=State.new(path+".bad")
	check(not corrupt.load_ledger() and not corrupt.begin() and FileAccess.get_file_as_string(path+".bad")=="{invalid","Corrupt ledgers are read-only, not overwritten")
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate();survey.fieldwork_path=path+".chapter";survey.night_ledger_path=path+".runtime";add_child(survey)
	op=survey.night_operation;survey.toggle_walking();await frames(35)
	var original: Vector3=survey.actor.position
	op.begin();check(not op.state.active,"Cannot start remotely or teleport from N")
	survey.actor.position=survey.geo.mesh_at3(survey.fieldwork.sites.dispatch.point,1);await frames(20)
	var location: Vector3=survey.actor.position
	op.toggle_panel();await capture("night_briefing");op.begin();await frames(20)
	check(op.state.active and survey.actor.position.distance_to(location)<.1,"Accepting at dispatch activates without teleporting")
	check(op.enemies.size()==4 and op.props.size()==2,"Four authored outdoor patrols and two physical supply boxes")
	check(survey.get_node("WeijinGeographicWorld/CampusDaylight").environment==op.night_environment,"Night changes actual environment, not a screen filter")
	check(not survey.fieldwork.journal.flags.accepted,"Night does not auto-accept or clear the rain-relay chapter")
	survey.reset_overview();await frames(3)
	check(survey.walking and survey.fieldwork.panel.visible,"Overview button opens the active-sortie decision, not a stranded aerial state")
	survey.fieldwork.close_panel();survey.select_landmark(survey.landmarks[0]);await frames(3)
	check(survey.walking and survey.actor.visible,"Landmark selection cannot hide the live night actor")
	survey.toggle_walking();await frames(3)
	check(survey.walking and survey.fieldwork.panel.visible,"Return-to-aerial button cannot bypass the active-sortie exit decision")
	survey.fieldwork.close_panel()
	await capture("night_dispatch")
	survey.toggle_map();await frames(12);await capture("night_mission_map");survey.toggle_map()
	for room_id: String in ["canteen_prep","network","network_control","swim_plant","activity"]:
		survey.fieldwork._show_room(room_id);await frames(12)
		check(op.roots.has(room_id),"Encounter authored on first room entry: "+room_id)
		for enemy: Node3D in op.enemies:
			if enemy.room==room_id:
				var local: Vector3=enemy.home-survey.fieldwork.rooms[room_id].position
				check(op._floor_clear(room_id,Vector2(local.x,local.z),.47),"Enemy spawn has real furniture clearance: "+enemy.id)
		await capture("night_"+room_id)
	check(op.enemies.size()==9 and op.props.size()==6,"Finite nine-enemy and six-breakable encounter catalogue")
	survey.fieldwork._show_room("canteen_prep");await frames(10)
	check(op.enemies.size()==9 and op.props.size()==6,"Returning to floors does not respawn enemies or crates")
	var prop: Node3D
	for node: Node3D in op.props:
		if node.id=="relay_crate":prop=node
	fixture("canteen_prep",prop.position+Vector3(0,0,2));await frames(15)
	var packet:=DamagePacket.new(20,0,5,survey.actor,&"weapon.assault_rifle_01",&"player")
	check(prop.receive_damage(packet)==5 and not prop.destroyed,"Breakable structure health is damaged independently")
	prop.receive_damage(packet);prop.receive_damage(packet);await frames()
	check(prop.destroyed and prop.collider.disabled and op.broken==1,"Three structural hits release collision and create debris")
	var drops: int=op.pickups.size();prop.receive_damage(packet)
	check(op.pickups.size()==drops,"Destroyed crates never duplicate contents")
	check(op.interact() and op.state.stage==1,"Physical nearby E loot takes guaranteed task item into separate mission pouch")
	check(op.state.bag.parts==2 and op.state.reserve==114,"Crate loot updates backpack and real reserve ammunition")
	op.state.add("drive",4)
	op._drop("capacity_fixture","canteen_prep",survey.actor.position,{"parts":2})
	var limited: Dictionary=op.pickups[-1]
	op.interact()
	check(op.state.weight()==12 and limited.contents.get("parts")==1,"Near-field production pickup takes only fitting loot and retains the remainder")
	op.state.discard("drive");op.interact()
	check(limited.contents.is_empty() and not limited.node.visible,"Discarding frees capacity to collect the actual remaining ground loot")
	var target: Node3D=op.enemies[4]
	var death_packet:=DamagePacket.new(100,0,0,survey.actor,&"weapon.assault_rifle_01",&"player")
	check(target.receive_damage(death_packet)==60 and target.dead and op.killed==1,"Enemy damage/death emits finite field loot")
	target.receive_damage(death_packet);check(op.killed==1,"Enemy corpses cannot farm duplicate loot")
	var count: int=op.enemies.size();survey.fieldwork._show_room("network_control");await frames(12)
	check(op.enemies.size()==count,"Room change retains enemy deaths elsewhere")
	var terminal: Dictionary={}
	for entry: Dictionary in op.stations:
		if entry.id=="terminal":terminal=entry
	fixture("network_control",terminal.point);await frames(90)
	check(survey.camera.environment==op.indoor_environment,"Re-entering the same room cannot replace night lighting with the survey's daylight environment")
	op.interact();survey.actor.velocity.x=2;await frames(2)
	check(op.work.is_empty() and not op.state.powered,"Moving cancels terminal work without granting power or progress")
	survey.actor.position=terminal.point;survey.actor.velocity=Vector3.ZERO;await frames(90)
	await capture("night_network_dark")
	op.interact();await frames(200)
	check(op.state.powered and op.state.stage==1,"Near-field timed terminal operation restores actual power before download")
	check(is_equal_approx(survey.fieldwork.rooms.network_control.room_lights[0].light_energy,op.POWERED_LIGHT),"Power changes room illumination")
	await capture("night_network_powered")
	op.interact();await frames(270)
	check(op.state.stage==2,"Second timed terminal action downloads the mission record")
	fixture("activity",survey.fieldwork.rooms.activity.position+Vector3(0,.08,5));await frames(10)
	var handover: Dictionary={}
	for entry: Dictionary in op.stations:
		if entry.id=="handover":handover=entry
	survey.actor.position=handover.point;await frames(10);op.interact();await frames(145)
	check(op.state.stage==3,"Activity-centre handover advances to extraction, not automatic banking")
	check(op.state.extractions==0,"No loot is banked merely by completing mission stations")
	fixture("",op.stations[0].point);await frames(10)
	var good_path: String=op.state.path
	op.state.path="user://missing_night_%s/ledger.json"%Time.get_ticks_usec()
	op.interact();await frames(270)
	check(op.state.active and op.state.extractions==0 and op.state.weight()>0,"Failed extraction write keeps the current sortie and bag recoverable")
	op.state.path=good_path
	op.interact();await frames(270)
	check(not op.state.active and op.state.extractions==1,"Timed physical east extraction banks loot and ends combat")
	check(survey.camera.environment==null,"Daylight environment is restored after extraction")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==profile,"Entire legacy profile is unchanged by combat, loot and extraction")
	check(not survey.fieldwork.journal.flags.accepted,"Existing independent rain mission remains unchanged after extraction")
	await capture("night_extraction")
	# A second production operation tests actual enemy perception, timed fire,
	# player reload/healing and failure ownership using explicit test placements.
	survey.fieldwork.close_panel();survey.actor.position=survey.geo.mesh_at3(survey.fieldwork.sites.dispatch.point,.1);await frames(20)
	op.begin();await frames(10)
	check(op.state.active and op.enemies.size()==4,"A new run rebuilds finite encounters after extraction")
	var enemy: Node3D=op.enemies[0]
	enemy.position=op._safe_outdoor("dispatch",8,0);enemy.home=enemy.position;enemy.patrol=PackedVector3Array([enemy.position,enemy.position]);enemy.last_seen=enemy.position;enemy.age=3
	enemy.rotation.y=atan2(enemy.position.x-survey.actor.position.x,enemy.position.z-survey.actor.position.z)
	await frames(5)
	var obstruction:=StaticBody3D.new();obstruction.collision_layer=4;obstruction.collision_mask=0
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(2,3,3);collision.shape=box;obstruction.add_child(collision)
	add_child(obstruction);obstruction.position=(enemy.position+survey.actor.position)*.5+Vector3.UP
	await frames(10)
	check(not enemy.can_see(),"World cover blocks sentry perception; no through-wall acquisition")
	await frames(180);check(enemy.shots==0,"Covered player is not shot through a wall")
	obstruction.queue_free();await frames(12)
	check(enemy.can_see(),"Sentry sees the exposed player in its authored cone")
	var health: float=survey.actor.health
	var warning_wait:=0
	while enemy.telegraph<=0 and warning_wait<240:await frames(1);warning_wait+=1
	await capture("night_sentry_warning")
	await frames(240)
	check(enemy.shots>0 and survey.actor.health<health,"Telegraphed physical enemy ray deals actual player damage")
	var bullets: int=op.state.magazine
	survey.actor.aim_world_point=enemy.position+Vector3.UP;survey.actor.aim_direction=survey.actor.position.direction_to(enemy.position)
	check(survey.actor._try_fire() and op.state.magazine==bullets-1,"Physical player firing consumes real independent ammunition")
	op.state.magazine=10;op.state.reserve=90
	check(survey.actor.reload_weapon(),"R reload can start with a partial magazine")
	check(op.state.magazine==10 and op.state.reserve==90,"Ammo is not credited before reload completion")
	await frames(115)
	check(op.state.magazine==30 and op.state.reserve==70,"Completed reload transfers exact reserve rounds")
	var meds: int=op.state.meds
	op.heal();survey.actor.velocity.x=2;await frames(2)
	check(op.heal_remaining==0 and op.state.meds==meds,"Movement cancels medical work without consuming a kit")
	survey.actor.velocity=Vector3.ZERO
	# A dead sentry no longer interferes with the controlled medical timing.
	enemy.receive_damage(DamagePacket.new(100,0,0,survey.actor,&"test.fixture",&"player"));await frames(5)
	health=survey.actor.health;op.heal();await frames(120)
	check(survey.actor.health>health and op.state.meds==meds-1,"Completed medical work restores health and consumes exactly one kit")
	op.state.add("drive",1)
	var bank_before: Dictionary=op.state.bank.duplicate()
	survey.actor.receive_damage(DamagePacket.new(999,0,0,enemy,&"test.fixture",&"enemy"));await frames(15)
	check(not op.state.active and op.state.weight()==0 and op.state.bank==bank_before,"Actual player death loses unextracted loot but preserves bank")
	check(not survey.actor.is_dead and survey.actor.body_visual.visible and survey.fieldwork.panel.visible,"Failure report leaves a recoverable visible actor, not a soft lock")
	check(survey.actor.position.distance_to(survey.geo.mesh_at3(survey.fieldwork.sites.dispatch.point,.1))<2,"Failure returns through the explicit east recovery path")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==profile,"Failure/retry also preserves the complete old profile")
	print("CAMPUS NIGHT TEST: ",checks," checks / ",failures.size()," failures; explicit unit and physics fixtures")
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("night_unit.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Explicit unit/physics fixtures; not traversal evidence"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)
