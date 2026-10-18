extends Control
## In-raid paper map: known assignments and landmarks, with no loot/enemy disclosure.
var district: Node3D
var actor: Node3D
var expanded := false
var status_panel: PanelContainer
var map_hint: Label
var alarm_hint: Label
const MAP_RECT := Rect2(26, 100, 500, 500)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_panel = PanelContainer.new()
	status_panel.name = "RouteStatus"
	status_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status_panel.position = Vector2(-360,64)
	status_panel.size = Vector2(342,0)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	add_child(status_panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(margin)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation",6)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(lines)
	for index in 2:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font",UIFactory.FONT)
		label.add_theme_font_size_override("font_size",13 if index == 0 else 12)
		label.add_theme_color_override("font_color",FieldManualStyle.INK if index == 0 else FieldManualStyle.ACCENT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(label)
		if index == 0: map_hint = label
		else: alarm_hint = label

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(actor) and actor.aim_input_captured: return
	if event.is_action_pressed("route_map") and not event.is_echo():
		expanded = not expanded
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	status_panel.visible = not (is_instance_valid(actor) and actor.aim_input_captured)
	if is_instance_valid(district):
		map_hint.text = tr("OLD CAMPUS / %s : ROUTE MAP") % ControlBindings.label("route_map")
		alarm_hint.text = district.get_node("StreetTerminal/RecordsAlarm").caption()
	queue_redraw()

func _point(at: Vector3) -> Vector2:
	return MAP_RECT.position + Vector2(at.x + 58, at.z + 58) / 116.0 * MAP_RECT.size

func _text(at: Vector2, text: String, color := FieldManualStyle.INK, font_size := 15) -> void:
	draw_string(UIFactory.FONT, at, tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _mission_brief() -> Array:
	var session:=SortieRuntime.get_current_session()
	if session and not session.campus.is_empty():
		var facts:=session.campus
		if not facts.recorder_instance.is_empty():return [tr("CAMPUS / EXPERIMENT RECORDER"),tr("Experiment recorder / bring it home")]
		if facts.version==1 and facts.stage in ["relay","recorder"]:
			return [tr("CAMPUS / LEGACY SORTIE"),tr("Legacy sortie / recorder at dormitory registration desk")]
		match facts.stage:
			"relay":
				if facts.relays.size()==2:return [tr("CAMPUS / EXPERIMENT RECORDER"),tr("Archive reading hall / take the device and extract.")]
				return [tr("CAMPUS / L-02 RELAYS"),tr("Repair both relays; take the archive recorder, or extract first.")]
			"recorder":return [tr("CAMPUS / EXPERIMENT RECORDER"),tr("Archive reading hall / take the device and extract.")]
			"power":return [tr("CAMPUS / L-02 BRANCH"),tr("L-02B OFF / L-02A ON / Extract") if facts.power_cut else tr("Maintenance control / disconnect L-02B, preserve L-02A.")]
			"supply":return [tr("CAMPUS / EQUIPMENT"),tr("Campus supplies delivered / Extract") if facts.gear_ready else tr("Deliver spare armor and 60 standard 5.56 rounds at base")]
			"complete":return [tr("CAMPUS / COMPLETE"),tr("Campus chapter complete / free sorties remain available")]
	var repair:=district.has_node("RelayOffice")
	return [tr("RELAYS: READING HALL + MAINTENANCE YARD") if repair else tr("RECORDS: ")+tr(district.district_names[district.task_index]),tr("12s each / damage or leaving cancels / local noise") if repair else tr("SURVEY: ")+tr(district.district_names[(district.task_index+2)%4])]

func _campus_map_points() -> Array:
	var session:=SortieRuntime.get_current_session()
	if not session or session.campus.is_empty():return []
	var points:=[]
	for name in ["CampusRelayOffice","CampusRelayRepair","ExperimentRecorder","L02BranchControl"]:
		var point:=district.get_node_or_null(name) as CampusAction
		if not point:continue
		if point.kind==&"recorder" and not session.campus.recorder_instance.is_empty():continue
		var label: String={"CampusRelayOffice":"L-02A RELAY","CampusRelayRepair":"L-02B RELAY","ExperimentRecorder":"EXPERIMENT RECORDER","L02BranchControl":"L-02 CONTROL"}[name]
		var color:=Color("85d5cf")
		if point.kind==&"recorder" and not point._available(session):
			label="RECORDER / REPAIR BOTH RELAYS FIRST";color=Color("465146")
		elif point.kind==&"relay" and String(point.action_id) in session.campus.relays:
			label="RELAY ONLINE";color=Color("8ce3ad")
		elif point.kind==&"power" and session.campus.power_cut:
			label="L-02B OFF / L-02A ON";color=Color("8ce3ad")
		points.append({"point":point,"label":label,"color":color})
	return points

func _draw() -> void:
	if not is_instance_valid(actor) or not is_instance_valid(district): return
	if actor.aim_input_captured: return
	var terminal: Node3D = district.get_node("StreetTerminal")
	var survey: Node3D = district.get_node("StreetSurvey")
	var width := get_viewport_rect().size.x
	if expanded: draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.02,0.025,0.03,0.65))
	if not expanded: return
	var repair := district.has_node("RelayOffice")
	draw_style_box(FieldManualStyle.panel(), Rect2(width-500,190,476,140))
	var brief:=_mission_brief()
	_text(Vector2(width-480,216),brief[0])
	_text(Vector2(width-480,244),brief[1],FieldManualStyle.MUTED,12)
	var exit_row := 0
	for exit in district.find_children("*", "ExtractionPoint",true,false):
		if not exit.available: continue
		var names := ["EAST CAMPUS GATE","SOUTH CAMPUS GATE","NORTH CAMPUS GATE","WEST SERVICE GATE"]
		var index: int = district.EXITS.find(exit.position)
		var state := "OPEN / RETREAT" if exit.required_objective_id.is_empty() else ("OPEN / RECORDS VERIFIED" if exit.can_extract(SortieRuntime.get_current_session()) else "LOCKED / RECOVER RECORDS FIRST")
		_text(Vector2(width-480,274+exit_row*26), tr(names[index])+" / "+tr(state), FieldManualStyle.SUCCESS if exit.can_extract(SortieRuntime.get_current_session()) else FieldManualStyle.ACCENT, 12)
		exit_row += 1
	# Public resource tendencies, never live loot rolls or enemy coordinates.
	draw_style_box(FieldManualStyle.panel(),Rect2(width-500,344,476,182))
	_text(Vector2(width-480,370), "RESOURCE INTEL / NOT GUARANTEED", FieldManualStyle.INK, 16)
	for index in 4:
		_text(Vector2(width-480,398+index*26), ["ARCHIVE / Electronics, wiring, data", "PHARMACY / Dressings, medkits, fabric", "DORMITORY / Fabric, household salvage", "MAINTENANCE YARD / Parts, wiring, propellant"][index], FieldManualStyle.MUTED, 14)
	draw_style_box(FieldManualStyle.panel(),Rect2(12,42,528,626))
	_text(Vector2(26,74), tr("OLD CAMPUS  /  N ↑    %s : CLOSE") % ControlBindings.label("route_map"), FieldManualStyle.INK, 20)
	draw_rect(MAP_RECT, Color("50534a"))
	for lake in district.campus_lakes:
		var outline:=PackedVector2Array()
		for p in lake: outline.append(_point(Vector3(p.x,0,p.y)))
		draw_colored_polygon(outline,Color("3d6f6b"))
	for road in district.campus_roads:
		var line:=PackedVector2Array()
		for p in road[0]: line.append(_point(Vector3(p.x,0,p.y)))
		draw_polyline(line,Color("a3a28b"),(road[1]+1.8)*500.0/116.0,true)
		draw_polyline(line,Color("686f68"),road[1]*500.0/116.0,true)
	_text(_point(Vector3(4,0,-22))+Vector2(-18,0),"YOUTH LAKE",Color("c5d8c4"),12)
	_text(_point(Vector3(8,0,39))+Vector2(-18,2),"JINGYE LAKES",Color("c5d8c4"),10)
	_text(_point(Vector3(2,0,4))+Vector2(0,-6),"MINGDE AVENUE",Color("ddd4b6"),10)
	_text(_point(Vector3(8,0,47))+Vector2(-15,4),"BEIYANG AVENUE",Color("ddd4b6"),10)
	for entry in district.campus_buildings:
		var at:=_point(Vector3(entry[0].x,0,entry[0].y))
		var extent: Vector2=entry[1]*500.0/116.0
		draw_rect(Rect2(at-extent*.5,extent),Color("96917a"))
	for index in district.ROOMS.size():
		var at: Vector2 = _point(district.ROOMS[index])
		draw_rect(Rect2(at-Vector2(34,30),Vector2(68,60)), Color("a09983"))
		_text(at+Vector2(-48,4), district.district_names[index], Color("222b25"), 11)
	for exit in district.find_children("*", "ExtractionPoint",true,false):
		if not exit.available: continue
		var at := _point(exit.position)
		draw_rect(Rect2(at-Vector2(6,6),Vector2(12,12)),Color("8ce3ad") if exit.can_extract(SortieRuntime.get_current_session()) else Color("e5b47a"))
		var names := ["EAST GATE","SOUTH GATE","NORTH GATE","WEST SERVICE"]
		var index: int = district.EXITS.find(exit.position)
		_text(at+Vector2(-35, -12 if exit.position.z>0 else 24),names[index],Color("a1e6b7"),11)
	draw_circle(_point(terminal.position),6,Color("f0c276"))
	if repair:
		for name in ["RelayOffice","RelayRepair"]:
			var relay: RelayStation = district.get_node(name)
			var state := SortieRuntime.get_current_session().get_objective_state(relay.objective_id)
			var color := Color("8ce3ad") if state.status == ObjectiveState.Status.COMPLETED else Color("f0c276")
			draw_arc(_point(relay.position),8,0,TAU,24,color,2,true)
			_text(_point(relay.position)+Vector2(-24,24 if name=="RelayOffice" else -13),"RELAY ONLINE" if state.status == ObjectiveState.Status.COMPLETED else "RELAY / 12s",Color("24302a"),11)
	else: draw_arc(_point(survey.position),7,0,TAU,24,Color("f0c276"),2,true)
	for entry in _campus_map_points():
		var point: Node3D=entry.point
		draw_circle(_point(point.position),6,entry.color)
		_text(_point(point.position)+Vector2(-35,24 if point.name=="CampusRelayOffice" else -16),entry.label,Color("24302a"),11)
	draw_circle(_point(actor.global_position),5,Color("a6e3ef"))
	var aim: Vector3 = actor.aim_direction
	draw_line(_point(actor.global_position),_point(actor.global_position+aim*4),Color("a6e3ef"),2,true)
	_text(Vector2(26,626), "● YOU    ● RECORDS    ○ RELAY    ■ ASSIGNED EXITS" if repair else "● YOU    ● RECORDS    ○ SURVEY    ■ ASSIGNED EXITS",FieldManualStyle.INK,14)
	_text(Vector2(26,650), "Lakeside avenues connect courts and service lanes. Raid continues while map is open.",FieldManualStyle.MUTED,12)
