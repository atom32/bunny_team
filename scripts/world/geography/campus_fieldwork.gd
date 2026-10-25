extends Node3D
## Campus task/portal owner. Explicit E interactions, independent journal and
## authored interiors; no legacy session initialization, grants or profile edits.
const Journal := preload("res://scripts/world/geography/campus_fieldwork_journal.gd")
const Interior := preload("res://scripts/world/geography/campus_interior.gd")
const Route := preload("res://scripts/world/geography/campus_fieldwork_route.gd")
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
const SITES := Spaces.SITES
var survey: Node3D
var journal: CampusFieldworkJournal
var sites: Dictionary={}
var rooms: Dictionary={}
var outdoor: Node3D
var stations: Array[Dictionary]=[]
var inside := ""
var outside_return := Vector3.ZERO
var tracker: Label
var prompt: Label
var notice: Label
var progress: ProgressBar
var panel: Control
var panel_body: Control
var journal_button: Button
var choice := ""
var work: Dictionary={}
var remaining := 0.0
var notice_left := 0.0
var route: RefCounted
var route_points:=PackedVector2Array()
var route_from:=Vector2(INF,INF)
var route_target:=Vector2(INF,INF)
var interior_environment: Environment
var materials: Dictionary={}
var save_error: Error=OK
var tracked_site := ""
var spaces_button: Button

func setup(owner_survey: Node3D, path: String) -> void:
	survey=owner_survey;name="CampusFieldwork"
	journal=Journal.new(path);journal.load_progress()
	for pair: Array in [["metal","45534e"],["paper","d5d2bb"],["signal","d5df7c"],["wood","887454"],["glass","597e73"],["stone","a6a793"]]:
		var material:=StandardMaterial3D.new();material.albedo_color=Color(pair[1]);material.roughness=.78;materials[pair[0]]=material
	outdoor=Node3D.new();outdoor.name="CampusMissionFacilities";add_child(outdoor)
	_build_sites();_build_outdoor();_build_ui()
	interior_environment=Environment.new();interior_environment.background_mode=Environment.BG_COLOR;interior_environment.background_color=Color("283b35")
	interior_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;interior_environment.ambient_light_color=Color("c4d4c7");interior_environment.ambient_light_energy=.52
	interior_environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;interior_environment.ssao_enabled=true;interior_environment.ssao_radius=.65
	_refresh()
	if not journal.load_error.is_empty():message(journal.load_error,12)

func _safe_near(point: Vector2) -> Vector2:
	for r: float in [0,2,4,6,9,12]:
		for step in 16:
			var candidate:=point+Vector2.from_angle(step*TAU/16)*r
			if survey.geo.safe_walk_point(candidate):return candidate
	return Vector2(INF,INF)

func _build_sites() -> void:
	var architecture:=preload("res://scripts/world/geography/campus_architecture.gd").new()
	for key: String in SITES:
		for i in survey.geo.data.buildings.size():
			var entry: Dictionary=survey.geo.data.buildings[i]
			if entry.osm_id!=SITES[key].osm:continue
			var edge: Dictionary=architecture._front(survey.geo.buildings[i])
			var front: Vector2=(edge.p+edge.q)*.5
			var approach: Vector2=front+edge.normal*4.5
			if not survey.geo.safe_walk_point(approach):
				# A new entrance may use another accessible face of the SAME
				# source building. Never shift it to an arbitrary empty field.
				var poly: PackedVector2Array=survey.geo.buildings[i]
				for j in poly.size():
					var p:=poly[j];var q:=poly[(j+1)%poly.size()]
					var normal: Vector2=architecture._outward(poly,p,q)
					var candidate: Vector2=(p+q)*.5+normal*4.5
					if p.distance_to(q)>4 and survey.geo.safe_walk_point(candidate):
						edge={"p":p,"q":q,"normal":normal,"tangent":(q-p).normalized()};front=(p+q)*.5;approach=candidate;break
			# Use the same facade as the existing landmark art. A bad portal
			# must be fixed at its source, not silently moved to another building.
			assert(survey.geo.safe_walk_point(approach),"Occupied campus entrance: "+key)
			sites[key]={"point":approach,"front":front,"normal":edge.normal,"tangent":edge.tangent,"name":SITES[key].name,"osm":entry.osm_id}
			_station("door_"+key,SITES[key].name+" / 进入",survey.geo.mesh_at3(approach,.05),"",0)
	var gate: Vector2=survey.geo.project(117.1724566,39.1070776)
	var dispatch:=_safe_near(gate+Vector2(-14,-10))
	assert(is_finite(dispatch.x),"No safe east dispatch placement")
	sites.dispatch={"point":dispatch,"name":"东门值守台"}
	_station("dispatch","东门值守台 / 雨前接力",survey.geo.mesh_at3(dispatch,.05),"",0)
	for lake: Dictionary in survey.geo.data.water:
		var id: String="youth_sample" if String(lake.name)=="青年湖" else ("jingye_sample" if String(lake.name)=="敬业湖" else "")
		if id.is_empty():continue
		var poly:=CampusGeodata.polygon(lake.points)
		var anchor:=Vector2(INF,INF);var best:=INF
		for i in poly.size():
			var mid: Vector2=(poly[i]+poly[(i+1)%poly.size()])*.5
			var normal:=Vector2(-(poly[(i+1)%poly.size()]-poly[i]).y,(poly[(i+1)%poly.size()]-poly[i]).x).normalized()
			if Geometry2D.is_point_in_polygon(mid+normal*.2,poly):normal=-normal
			var candidate:=mid+normal*3.5
			if not survey.geo.safe_walk_point(candidate):continue
			for road: Dictionary in survey.geo.road_segments:
				var score: float=candidate.distance_to(Geometry2D.get_closest_point_to_segment(candidate,road.a,road.b))
				if score<best:best=score;anchor=candidate
		if is_finite(anchor.x):
			sites[id]={"point":anchor,"name":Journal.TITLES[id]}
			_station(id,Journal.TITLES[id],survey.geo.mesh_at3(anchor,.05),"",2)

func _box(parent: Node3D, size: Vector3, at: Vector3, material: String, yaw := 0.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;mesh.material=materials[material];node.mesh=mesh;node.position=at;node.rotation.y=yaw;parent.add_child(node);return node

func _label(parent: Node3D,text: String,at: Vector3,scale_m := .006) -> void:
	var node:=Label3D.new();node.text=text;node.font=UIFactory.FONT;node.font_size=48;node.pixel_size=scale_m;node.position=at
	node.modulate=Color("e2e2cb");node.outline_size=3;node.outline_modulate=Color("263a33");node.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.visibility_range_end=70;parent.add_child(node)

func _station(id: String, label: String, point: Vector3, room: String, seconds: float) -> void:
	stations.append({"id":id,"label":label,"point":point,"room":room,"seconds":seconds})

func _build_outdoor() -> void:
	for id: String in SITES:
		var site: Dictionary=sites[id]
		var p: Vector3=survey.geo.mesh_at3(site.point)
		var tangent: Vector2=site.tangent;var normal: Vector2=site.normal
		var yaw:=atan2(normal.x,normal.y)
		var sign:=Node3D.new();sign.name="Entrance_"+id;outdoor.add_child(sign)
		if id not in ["library","main_hall","activity"]:
			var door: Vector3=survey.geo.mesh_at3(site.front)+Vector3(normal.x,0,normal.y)*.3
			_box(sign,Vector3(2.6,3.05,.16),door+Vector3.UP*1.525,"stone",yaw)
			_box(sign,Vector3(2.25,2.8,.08),door+Vector3.UP*1.43+Vector3(normal.x,0,normal.y)*.13,"glass",yaw)
			_box(sign,Vector3(.065,2.8,.10),door+Vector3.UP*1.43+Vector3(normal.x,0,normal.y)*.20,"metal",yaw)
		var at: Vector3=p+Vector3(tangent.x,0,tangent.y)*2.5
		_box(sign,Vector3(.12,2.1,.12),at+Vector3.UP*1.05,"metal",yaw)
		_box(sign,Vector3(1.7,.95,.12),at+Vector3.UP*1.9,"metal",yaw)
		_box(sign,Vector3(1.7,.10,.15),at+Vector3.UP*2.4,"signal",yaw)
		_label(sign,SITES[id].number+" / "+site.name+"\n开放楼层 · E进入",at+Vector3.UP*2.0,.005)
		for step in 3:
			var trail: Vector2=site.point+normal*(1.2+step*.9)
			_box(sign,Vector3(.30,.025,.20),survey.geo.mesh_at3(trail,.12),"signal",yaw)
	var p: Vector3=survey.geo.mesh_at3(sites.dispatch.point)
	var desk:=Node3D.new();desk.name="EastDispatch";outdoor.add_child(desk)
	_box(desk,Vector3(3.7,.16,1.3),p+Vector3(0,.92,-1),"wood")
	for x: float in [-1.5,1.5]:_box(desk,Vector3(.12,.9,1.0),p+Vector3(x,.45,-1),"metal")
	_box(desk,Vector3(1.0,.08,.7),p+Vector3(-.7,1.05,-1),"paper")
	_box(desk,Vector3(.55,.45,.35),p+Vector3(.9,1.23,-1),"metal")
	_box(desk,Vector3(.04,.6,.04),p+Vector3(.9,1.7,-1),"metal")
	for x: float in [-2.0,2.0]:_box(desk,Vector3(.10,3,.10),p+Vector3(x,1.5,-1.5),"metal")
	_box(desk,Vector3(4.4,.15,3.1),p+Vector3(0,3.05,-1.2),"glass")
	_label(desk,"东门值守 / 雨前接力\n独立校园任务 · E 接取 / J 日志",p+Vector3(0,3.6,-1),.008)
	for id: String in ["youth_sample","jingye_sample"]:
		if not sites.has(id):continue
		var point: Vector3=survey.geo.mesh_at3(sites[id].point)
		_box(outdoor,Vector3(.12,1.7,.12),point+Vector3(.8,.85,0),"metal")
		_box(outdoor,Vector3(.65,.85,.12),point+Vector3(.8,1.5,0),"paper")
		for y in 6:_box(outdoor,Vector3(.5 if y%2==0 else .3,.025,.14),point+Vector3(.8,1.18+y*.12,.03),"metal")
		_label(outdoor,"调查点 / "+sites[id].name,point+Vector3.UP*2.4,.005)

func _build_ui() -> void:
	var hud:=OperationUI.block(survey.screen,Vector2(18,104),Vector2(430,116),Color("191d1ee8"));hud.name="CampusTaskTracker"
	OperationUI.eyebrow(hud,"FIELDWORK / 雨前接力",Vector2(14,8),true).name="CampusTrackerTag"
	tracker=OperationUI.text(hud,"",Vector2(14,31),16,Color("efeedb"));tracker.size=Vector2(402,77);tracker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	journal_button=OperationUI.action(survey.screen,"任务 / J",Vector2(812,31),Vector2(164,44),toggle_journal);journal_button.name="OpenCampusJournal"
	spaces_button=OperationUI.action(survey.screen,"开放空间 / O",Vector2(18,226),Vector2(222,39),toggle_spaces);spaces_button.name="OpenCampusSpaces"
	var prompt_block:=OperationUI.block(survey.screen,Vector2(300,524),Vector2(680,61),Color("191d1ee8"));prompt_block.name="CampusInteraction"
	prompt=OperationUI.text(prompt_block,"",Vector2(14,8),16,Color("f0f1d4"));prompt.size=Vector2(650,48);prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	progress=ProgressBar.new();progress.position=Vector2(300,514);progress.size=Vector2(680,7);progress.show_percentage=false;progress.max_value=1;survey.screen.add_child(progress);progress.hide()
	var toast:=OperationUI.block(survey.screen,Vector2(470,104),Vector2(792,80),FieldManualStyle.PAPER);toast.name="CampusTaskNotice"
	notice=OperationUI.text(toast,"",Vector2(14,10),14,FieldManualStyle.INK);notice.size=Vector2(764,64);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast.hide()
	panel=Control.new();panel.name="CampusFieldworkPanel";panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_STOP;survey.screen.add_child(panel);panel.hide()
	OperationUI.block(panel,Vector2.ZERO,Vector2(1280,720),Color(0,0,0,.7))
	panel_body=OperationUI.block(panel,Vector2(210,102),Vector2(860,518),FieldManualStyle.PAPER)

func message(text: String, seconds := 7.0) -> void:
	notice.text=text;notice_left=seconds;notice.get_parent().show()

func _pause(value: bool) -> void:
	survey.actor.velocity=Vector3.ZERO
	survey.actor.set_physics_process(survey.walking and not value and not survey.route_map.visible)
	survey.actor.aim_input_captured=value or survey.route_map.visible or not survey.walking
	for action: String in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)

func _clear_panel() -> void:
	for child: Node in panel_body.get_children():
		panel_body.remove_child(child)
		child.queue_free() # A pressed button can still be emitting its signal.

func close_panel() -> void:
	panel.hide();choice="";_pause(false)

func toggle_journal() -> void:
	if panel.visible:close_panel();return
	cancel_work("查看日志，工作已暂停；返回装置可重新开始。")
	_clear_panel();panel.show();choice="journal";_pause(true)
	OperationUI.eyebrow(panel_body,"CAMPUS CHAPTER / 独立任务日志",Vector2(24,18))
	OperationUI.text(panel_body,"雨前接力",Vector2(24,43),32,FieldManualStyle.INK,true)
	OperationUI.text(panel_body,journal.objective().text,Vector2(24,92),19)
	var list: Array[String]=[]
	for key: String in ["accepted","archive","relay","shelter_power","delivered","reported"]:
		list.append(("✓ " if journal.flags[key] else "— ")+{"accepted":"东门接取","archive":"图书馆档案","relay":"九教熔芯","shelter_power":"保留应急 A","delivered":"补给站签收","reported":"东门回报"}[key])
	OperationUI.text(panel_body,"\n".join(list),Vector2(24,139),17)
	var log:=RichTextLabel.new();log.position=Vector2(262,137);log.size=Vector2(568,270);log.bbcode_enabled=false;log.add_theme_font_size_override("normal_font_size",15);panel_body.add_child(log)
	var notes: Array[String]=[]
	for id: String in journal.history:notes.append(Journal.NOTES[id])
	for id: String in journal.space_notes:notes.append(Spaces.ROOMS[id].title+"\n"+Spaces.ROOMS[id].note)
	log.text="\n\n".join(notes) if not notes.is_empty() else "先进入实走，前往东门值守台，按 E 接取任务。\n\nO 开放空间目录：12栋建筑、21块楼层与功能区均可自由探索。\n接力任务仍围绕图书馆、九教和活动中心。\n楼内平面为游戏设计，不是真实测绘。"
	OperationUI.text(panel_body,journal.cargo_text(),Vector2(24,399),14,FieldManualStyle.INK)
	OperationUI.text(panel_body,"湖岸 %d/2 · 空间记录 %d/21 · O 开放目录 · 独立保存"%[int(journal.flags.youth_sample)+int(journal.flags.jingye_sample),journal.space_notes.size()],Vector2(24,425),14,FieldManualStyle.MUTED)
	if not journal.load_error.is_empty():OperationUI.text(panel_body,"日志损坏：只读保护中；重开将先归档原文件。",Vector2(24,449),14,Color("9b3c30"))
	elif save_error!=OK:OperationUI.text(panel_body,"尚未保存："+error_string(save_error),Vector2(24,449),14,Color("9b3c30"))
	OperationUI.action(panel_body,"继续 / J",Vector2(24,465),Vector2(190,38),close_panel,true).name="CloseCampusJournal"
	var reset_button:=OperationUI.action(panel_body,"重开校园任务…",Vector2(604,465),Vector2(226,38),_confirm_reset);reset_button.name="ResetCampusChapter"
	reset_button.disabled=survey.night_operation and survey.night_operation.state.active

func _confirm_reset() -> void:
	_clear_panel();choice="reset"
	OperationUI.heading(panel_body,"RESET / KEEP LEGACY PROFILE","重开本次校园接力？",Vector2(30,35))
	OperationUI.text(panel_body,"仅重开雨前接力，已读取的空间记录保留。原文件先归档；旧主线、背包和装备不变。\n角色返回当前室内入口或保留当前校园位置；不会重发旧奖励。",Vector2(30,132),17)
	OperationUI.action(panel_body,"确认重开",Vector2(30,348),Vector2(220,46),reset_chapter,true).name="ConfirmCampusReset"
	OperationUI.action(panel_body,"取消",Vector2(270,348),Vector2(180,46),close_panel).name="CancelCampusReset"

func reset_chapter() -> void:
	if choice!="reset":return
	var error:=SaveService.archive_save(journal.path)
	if error!=OK:message("无法归档旧任务日志，未重开："+error_string(error));close_panel();return
	var next:=Journal.new(journal.path)
	next.space_notes.assign(journal.space_notes)
	error=next.save_progress()
	if error!=OK:message("任务日志保存失败，未重开："+error_string(error));close_panel();return
	journal=next;save_error=OK
	if not inside.is_empty():
		survey.actor.position=rooms[inside].position+rooms[inside].entry_point;survey.actor.velocity=Vector3.ZERO
		survey.focus=survey.actor.position+Vector3.UP;survey.target_focus=survey.focus
	close_panel();_refresh();message("校园接力已重开；到东门值守台重新接取。")

func _refresh() -> void:
	for room: Node3D in rooms.values():room.refresh(journal)
	route_target=Vector2(INF,INF)

func _action(station: Dictionary) -> String:
	if station.id=="dispatch":return "report" if journal.flags.delivered else "dispatch"
	if station.id=="blackout" and journal.blackout:return "restore"
	return station.id

func nearest() -> Dictionary:
	if not survey.walking or survey.route_map.visible or panel.visible:return {}
	var selected: Dictionary={};var best:=2.6
	for station: Dictionary in stations:
		if station.room!=inside:continue
		var distance: float=survey.actor.global_position.distance_to(station.point)
		if distance>best:continue
		var query:=PhysicsRayQueryParameters3D.create(survey.actor.global_position+Vector3.UP*1.15,station.point+Vector3.UP*1.15,4)
		query.exclude=[survey.actor.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():continue
		best=distance;selected=station
	return selected

func interact() -> void:
	var station:=nearest()
	if station.is_empty():return
	if not work.is_empty():cancel_work("工作已取消，可在装置旁重新开始。");return
	var id: String=_action(station)
	if id.begins_with("door_"):enter_room(id.trim_prefix("door_"));return
	if id.begins_with("stairs_"):transfer_floor(id.trim_prefix("stairs_"));return
	if id=="inspect_space":read_space();return
	if id=="exit":exit_room();return
	if survey.night_operation and survey.night_operation.state.active:
		message("断电夜线进行中，雨前接力的进度保留。N查看夜线任务；撤离或放弃后可继续接力。");return
	var unavailable:=journal.unavailable(id)
	if not unavailable.is_empty():message(unavailable);return
	if id=="blackout":_confirm_blackout();return
	_begin(station,id)

func _confirm_blackout() -> void:
	_clear_panel();choice="blackout";panel.show();_pause(true)
	OperationUI.heading(panel_body,"MASTER BREAKER / A + B","这会切断应急支路 A",Vector2(30,35))
	OperationUI.text(panel_body,"总闸同时控制补给站与试验设备。\n断开后补给站无法签收；必须在这里恢复总闸，再重新隔离 B。\n任务要求是只隔离 B，不是全楼断电。",Vector2(30,145),20)
	OperationUI.action(panel_body,"仍然断开总闸",Vector2(30,348),Vector2(270,46),func():
		close_panel()
		var station:=nearest()
		if not station.is_empty() and station.id=="blackout":_begin(station,"blackout")
	).name="ConfirmMasterBlackout"
	OperationUI.action(panel_body,"取消 / 保留供电",Vector2(330,348),Vector2(270,46),close_panel,true).name="CancelMasterBlackout"

func _begin(station: Dictionary,id: String) -> void:
	work=station.duplicate();work.action=id;remaining=float(station.seconds)
	if remaining<=0:_finish_work()
	else:message("%s / 保持靠近且停留；移动、地图或日志会中断。"%Journal.TITLES[id],4)

func cancel_work(text := "") -> void:
	if work.is_empty():return
	work={};remaining=0;progress.hide()
	if not text.is_empty():message(text)

func _finish_work() -> void:
	var id: String=work.action;work={};remaining=0;progress.hide()
	if not journal.perform(id):message(journal.unavailable(id));return
	var error:=journal.save_progress()
	save_error=error
	_refresh();AudioDirector.play_sfx(&"ui_confirm")
	message(Journal.NOTES[id]+("\n保存失败，本次进度仅在内存中："+error_string(error) if error!=OK else ""),12 if error!=OK else 8)

func enter_room(id: String) -> void:
	if not inside.is_empty() or not SITES.has(id) or not survey.walking:return
	var nearby:=nearest()
	if nearby.is_empty() or nearby.id!="door_"+id:return
	cancel_work();outside_return=survey.actor.position
	tracked_site=""
	_show_room(id)

func _show_room(id: String, landing := false) -> void:
	if not rooms.has(id):
		var room: Node3D=Interior.new() if Spaces.ROOMS[id].layout=="legacy" else preload("res://scripts/world/geography/campus_exploration_interior.gd").new()
		room.position=Vector3(100.0*rooms.size(),-120,0);add_child(room);room.build(id);rooms[id]=room
		var partner:=Spaces.partner(id)
		if not partner.is_empty():room.add_stair(partner,Spaces.stair_x(id))
		if Spaces.ROOMS[id].layout=="legacy":room._station("inspect_space","查看空间记录",Vector3(3 if id=="activity" else -3,.04,8),0)
		for station: Dictionary in room.stations:
			_station(station.id,station.label,room.position+station.point,id,station.seconds)
		room.refresh(journal)
	inside=id
	survey.get_node("WeijinGeographicWorld").hide();outdoor.hide()
	for key: String in rooms:rooms[key].visible=key==id
	var arrival: Vector3=rooms[id].entry_point
	if landing:arrival=Vector3(Spaces.stair_x(id),1.3,rooms[id].extent.y*.5-2.4)
	survey.actor.position=rooms[id].position+arrival;survey.actor.velocity=Vector3.ZERO
	survey.focus=survey.actor.position+Vector3.UP;survey.target_focus=survey.focus
	survey.camera.environment=interior_environment;survey.yaw=0;survey.pitch=1.12;survey.walk_pitch=1.12;survey.distance=21;survey.target_distance=21
	survey.screen.get_node("LeaveCampusSurvey").text="返回校园" if Spaces.ground(id)==id else "返回下层"
	survey.screen.get_node("CampusHeading").text=Spaces.ROOMS[id].title
	survey.screen.get_node("CampusScale").text="游戏设计楼层 / 非真实测绘"
	survey.screen.get_node("GeographicCredit").hide();survey.screen.get_node("GeographicCreditBacking").hide()
	survey.screen.get_node("ToggleSceneDetails").disabled=true
	survey.walk_button.disabled=true;survey.screen.find_child("FullCampusOverview",true,false).disabled=true
	# Save only completed task transitions. A reload starts outdoors, never
	# inside a half-restored room or a portal beneath the terrain.
	message(Spaces.ROOMS[id].title+" / 设计楼层，非真实测绘。E交互与楼梯 · M楼层图 · O开放目录。",6)
	if survey.night_operation and survey.night_operation.state.active:
		survey.night_operation.room_ready(id);survey.night_operation._sync_visibility()

func transfer_floor(id: String) -> void:
	if inside.is_empty() or Spaces.partner(inside)!=id:return
	var station:=nearest()
	if station.is_empty() or station.id!="stairs_"+id:return
	cancel_work();_show_room(id,true)

func read_space() -> void:
	if inside.is_empty():return
	if inside not in journal.space_notes:journal.space_notes.append(inside)
	save_error=journal.save_progress()
	message(Spaces.ROOMS[inside].note+("\n保存失败："+error_string(save_error) if save_error!=OK else ""),12)

func exit_room() -> void:
	if inside.is_empty():return
	cancel_work();close_panel();survey.route_map.hide();survey.screen.get_node("RegionalElevationLayer").hide()
	if Spaces.ground(inside)!=inside:_show_room(Spaces.ground(inside),true);return
	rooms[inside].hide();inside=""
	survey.get_node("WeijinGeographicWorld").show();outdoor.show()
	survey.actor.position=outside_return+Vector3.UP*.08;survey.actor.velocity=Vector3.ZERO
	survey.camera.environment=null;survey.yaw=0;survey.pitch=1.0;survey.walk_pitch=1.0;survey.distance=23;survey.target_distance=23
	survey.focus=survey.actor.position+Vector3.UP;survey.target_focus=survey.focus
	survey.screen.get_node("LeaveCampusSurvey").text="返回";survey.walk_button.disabled=false;survey.screen.find_child("FullCampusOverview",true,false).disabled=false
	survey.screen.get_node("CampusHeading").text="卫津路校区 · 整校园 1:1"
	survey.screen.get_node("CampusScale").text="1,396 × 905 m / WGS84 / N ↑"
	survey.screen.get_node("GeographicCredit").show();survey.screen.get_node("GeographicCreditBacking").show()
	survey.screen.get_node("ToggleSceneDetails").disabled=false
	_pause(false);route_from=Vector2(INF,INF)
	if survey.night_operation and survey.night_operation.state.active:survey.night_operation._sync_visibility()

func handle_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():return false
	if event is InputEventKey and event.physical_keycode==KEY_J:toggle_journal();return true
	if event is InputEventKey and event.physical_keycode==KEY_O:toggle_spaces();return true
	if panel.visible:
		if event is InputEventKey and event.physical_keycode==KEY_ESCAPE:close_panel()
		return event is InputEventKey and event.physical_keycode not in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]
	if event.is_action_pressed("interact"):interact();return true
	if not inside.is_empty() and event is InputEventKey and event.physical_keycode==KEY_ESCAPE:
		if survey.route_map.visible:survey.toggle_map()
		else:exit_room()
		return true
	return false

func objective_point() -> Vector2:
	if not tracked_site.is_empty():return sites[tracked_site].point
	if survey.night_operation and survey.night_operation.state.active:
		var point: Vector3=survey.night_operation.guide_point()
		return Vector2(point.x,point.z)
	var objective:=journal.objective()
	if not sites.has(objective.site):return Vector2(INF,INF)
	return sites[objective.site].point

func update_route() -> void:
	if not survey.walking or not inside.is_empty() or (not journal.flags.accepted and tracked_site.is_empty() and not (survey.night_operation and survey.night_operation.state.active)):return
	var target:=objective_point()
	if not is_finite(target.x):route_points.clear();return
	var here:=Vector2(survey.actor.position.x,survey.actor.position.z)
	if target==route_target and here.distance_to(route_from)<15:return
	if not route:route=Route.new(survey.geo)
	route_points=route.find_path(here,target);route_from=here;route_target=target

func _process(delta: float) -> void:
	if not survey:return
	notice_left=maxf(0,notice_left-delta)
	notice.get_parent().visible=notice_left>0 and not panel.visible and not survey.route_map.visible
	if not work.is_empty():
		var current:=nearest()
		if current.is_empty() or current.id!=work.id or Vector2(survey.actor.velocity.x,survey.actor.velocity.z).length()>.6:
			cancel_work("工作中断；进度未计入，回到装置旁按 E 重试。")
		else:
			remaining=maxf(0,remaining-delta);progress.show();progress.value=1-remaining/float(work.seconds)
			if remaining<=0:_finish_work()
	var objective:=journal.objective()
	var suffix: String=""
	if inside.is_empty():
		var point:=objective_point()
		if survey.walking and is_finite(point.x):suffix="\n直距 %.0f m · M 道路导引 / J 日志"%Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(point)
		elif survey.walking:suffix="\n自由探索 / E 交互 · M 地图 · J 日志"
		elif journal.flags.reported:suffix="\n进入实走继续探索 · J 查看已归档日志"
		else:suffix="\n进入实走接取任务 · J 查看 / 恢复日志"
	else:suffix="\n"+Spaces.ROOMS[inside].title+" · M楼层图 / O目录"
	var heading: String=objective.text if tracked_site.is_empty() or not inside.is_empty() else "探索 / 前往"+SITES[tracked_site].name
	tracker.text=heading+suffix+(" · 未保存" if save_error!=OK else "")
	tracker.get_parent().get_node("CampusTrackerTag").text="// FIELDWORK / 雨前接力"
	if survey.night_operation and survey.night_operation.state.active:
		tracker.text=survey.night_operation.objective().text+suffix
		tracker.get_parent().get_node("CampusTrackerTag").text="// NIGHT LINE / 断电夜线"
	tracker.get_parent().visible=not survey.route_map.visible
	spaces_button.visible=not survey.route_map.visible and not panel.visible
	var station:=nearest()
	prompt.get_parent().visible=not station.is_empty() and not panel.visible
	if not station.is_empty():
		var action:=_action(station)
		var label: String=Journal.TITLES.get(action,station.label)
		prompt.text=("工作中 %.1fs / E 取消"%remaining) if not work.is_empty() else "E  "+label
		if not action.begins_with("door_") and not action.begins_with("stairs_") and action not in ["exit","inspect_space"] and work.is_empty():
			var reason:=journal.unavailable(action)
			if not reason.is_empty():prompt.text+="\n"+reason
	if survey.route_map.visible:update_route()

func update_indoor_camera(delta: float) -> void:
	var origin: Vector3=rooms[inside].position
	var local: Vector3=survey.actor.position-origin
	var size: Vector2=rooms[inside].extent
	# Keep the camera inside the floor extent instead of showing half a
	# screen of void at a corner. The actor still walks and collides normally.
	var center: Vector3=origin+Vector3(clampf(local.x,-maxf(2,size.x*.5-14),maxf(2,size.x*.5-14)),.8+local.y*.3,clampf(local.z,-size.y*.5+7,size.y*.5-5.5))
	survey.focus=survey.focus.lerp(center,1-exp(-delta*10))
	survey.camera.position=survey.focus+Vector3(0,sin(1.12),cos(1.12))*21
	survey.camera.look_at(survey.focus)
	survey.coordinates.text="%s / 设计楼层 · 非真实测绘\nWASD 移动 · E 交互/楼梯 · M 楼层图 · O 开放空间 · J 日志"%Spaces.ROOMS[inside].title

func toggle_spaces() -> void:
	if panel.visible:close_panel();return
	cancel_work();_clear_panel();panel.show();choice="spaces";_pause(true)
	OperationUI.heading(panel_body,"OPEN CAMPUS / 12 BUILDINGS · 21 AREAS","开放空间目录",Vector2(24,16))
	OperationUI.text(panel_body,"选择只标记入口或移动航拍镜头，不传送角色；上层需从楼梯进入。",Vector2(24,88),14,FieldManualStyle.MUTED)
	var i:=0
	for id: String in SITES:
		var site: Dictionary=SITES[id]
		var caption: String=site.number+"  "+site.name+"\n"+str(site.floors.size())+"层 / "+("标记入口" if survey.walking else "航拍定位")
		var button:=OperationUI.action(panel_body,caption,Vector2(24+(i%3)*272,120+floori(i/3.0)*77),Vector2(258,68),func():track_space(id))
		button.name="TrackSpace_"+id;button.add_theme_font_size_override("font_size",15);button.disabled=not inside.is_empty();i+=1
	OperationUI.text(panel_body,"已读取空间记录 %d / 21 · 室内平面为游戏设计，非现场测绘"%journal.space_notes.size(),Vector2(24,432),14,FieldManualStyle.MUTED)
	OperationUI.action(panel_body,"继续 / O",Vector2(24,465),Vector2(190,38),close_panel,true)
	OperationUI.action(panel_body,"恢复任务导引",Vector2(604,465),Vector2(226,38),func():tracked_site="";route_target=Vector2(INF,INF);close_panel())

func track_space(id: String) -> void:
	if not SITES.has(id) or not inside.is_empty():return
	tracked_site=id;route_target=Vector2(INF,INF);close_panel()
	if not survey.walking:survey.target_focus=survey.geo.at3(sites[id].point);survey.target_distance=150
