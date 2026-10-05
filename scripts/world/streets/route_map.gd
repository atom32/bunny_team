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
	status_panel.add_theme_stylebox_override("panel",UIFactory.panel_style(Color("141c22ef"),Color("736e5d")))
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
		label.add_theme_color_override("font_color",Color("ead7a5") if index == 0 else Color("e5b47a"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(label)
		if index == 0: map_hint = label
		else: alarm_hint = label

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("route_map") and not event.is_echo():
		expanded = not expanded
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if is_instance_valid(district):
		map_hint.text = tr("OLD TOWN / %s : ROUTE MAP") % ControlBindings.label("route_map")
		alarm_hint.text = district.get_node("StreetTerminal/RecordsAlarm").caption()
	queue_redraw()

func _point(at: Vector3) -> Vector2:
	return MAP_RECT.position + Vector2(at.x + 58, at.z + 58) / 116.0 * MAP_RECT.size

func _text(at: Vector2, text: String, color := Color("d2cbbb"), font_size := 15) -> void:
	draw_string(UIFactory.FONT, at, tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if not is_instance_valid(actor) or not is_instance_valid(district): return
	var terminal: Node3D = district.get_node("StreetTerminal")
	var survey: Node3D = district.get_node("StreetSurvey")
	var width := get_viewport_rect().size.x
	if expanded: draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.02,0.025,0.03,0.65))
	if not expanded: return
	var repair := district.has_node("RelayOffice")
	draw_style_box(UIFactory.panel_style(Color("141c22ef"), Color("736e5d")), Rect2(width-500,190,476,140))
	_text(Vector2(width-480,216), tr("RELAYS: OFFICE + REPAIR SHOP") if repair else tr("RECORDS: ") + tr(district.district_names[district.task_index]))
	_text(Vector2(width-480,244), tr("12s each / damage or leaving cancels / local noise") if repair else tr("SURVEY: ") + tr(district.district_names[(district.task_index+2)%4]),Color("d2cbbb"),13 if repair else 15)
	var exit_row := 0
	for exit in district.find_children("*", "ExtractionPoint",true,false):
		if not exit.available: continue
		var names := ["SOUTH SERVICE GATE","SOUTH TRAM CHECKPOINT","NORTH ARCHWAY","NORTH LOADING GATE"]
		var index: int = district.EXITS.find(exit.position)
		var state := "OPEN / RETREAT" if exit.required_objective_id.is_empty() else ("OPEN / RECORDS VERIFIED" if exit.can_extract(SortieRuntime.get_current_session()) else "LOCKED / RECOVER RECORDS FIRST")
		_text(Vector2(width-480,274+exit_row*26), tr(names[index])+" / "+tr(state), Color("94c7a8") if exit.can_extract(SortieRuntime.get_current_session()) else Color("e5b47a"), 12)
		exit_row += 1
	# Public resource tendencies, never live loot rolls or enemy coordinates.
	draw_style_box(UIFactory.panel_style(Color("141c22ef"),Color("736e5d")),Rect2(width-500,344,476,182))
	_text(Vector2(width-480,370), "RESOURCE INTEL / NOT GUARANTEED", Color("ead7a5"), 16)
	for index in 4:
		_text(Vector2(width-480,398+index*26), ["OFFICE / Electronics, wiring, data", "PHARMACY / Dressings, medkits, fabric", "APARTMENTS / Fabric, household salvage", "REPAIR SHOP / Parts, wiring, propellant"][index], Color("c5d0c8"), 14)
	draw_style_box(UIFactory.panel_style(Color("252925fc"),Color("918570")),Rect2(12,42,528,626))
	_text(Vector2(26,74), tr("OLD TOWN  /  N ↑    %s : CLOSE") % ControlBindings.label("route_map"), Color("ead7a5"), 20)
	draw_rect(MAP_RECT, Color("50534a"))
	for x in [-43,0,43]:
		draw_line(_point(Vector3(x,0,-57)),_point(Vector3(x,0,57)),Color("303632"),43)
	for z in [-43,4,43]:
		draw_line(_point(Vector3(-57,0,z)),_point(Vector3(57,0,z)),Color("303632"),34)
	for x in [-31,-9,10,32]:
		for z in [-32,34]:
			draw_rect(Rect2(_point(Vector3(x,0,z))-Vector2(23,19),Vector2(46,38)),Color("797966"))
	for index in district.ROOMS.size():
		var at: Vector2 = _point(district.ROOMS[index])
		draw_rect(Rect2(at-Vector2(34,30),Vector2(68,60)), Color("a09983"))
		_text(at+Vector2(-48,4), district.district_names[index], Color("222b25"), 11)
	for exit in district.find_children("*", "ExtractionPoint",true,false):
		if not exit.available: continue
		var at := _point(exit.position)
		draw_rect(Rect2(at-Vector2(6,6),Vector2(12,12)),Color("8ce3ad") if exit.can_extract(SortieRuntime.get_current_session()) else Color("e5b47a"))
		var names := ["SERVICE GATE","TRAM CHECKPOINT","ARCHWAY","LOADING GATE"]
		var index: int = district.EXITS.find(exit.position)
		_text(at+Vector2(-35, -12 if exit.position.z>0 else 24),names[index],Color("a1e6b7"),11)
	draw_circle(_point(terminal.position),6,Color("f0c276"))
	if repair:
		for name in ["RelayOffice","RelayRepair"]:
			var relay: RelayStation = district.get_node(name)
			var state := SortieRuntime.get_current_session().get_objective_state(relay.objective_id)
			var color := Color("8ce3ad") if state.status == ObjectiveState.Status.COMPLETED else Color("f0c276")
			draw_arc(_point(relay.position),8,0,TAU,24,color,2,true)
			_text(_point(relay.position)+Vector2(-24,-13),"RELAY ONLINE" if state.status == ObjectiveState.Status.COMPLETED else "RELAY / 12s",color,11)
	else: draw_arc(_point(survey.position),7,0,TAU,24,Color("f0c276"),2,true)
	draw_circle(_point(actor.global_position),5,Color("a6e3ef"))
	var aim: Vector3 = actor.aim_direction
	draw_line(_point(actor.global_position),_point(actor.global_position+aim*4),Color("a6e3ef"),2,true)
	_text(Vector2(26,626), "● YOU    ● RECORDS    ○ RELAY    ■ ASSIGNED EXITS" if repair else "● YOU    ● RECORDS    ○ SURVEY    ■ ASSIGNED EXITS",Color("d2cbbb"),14)
	_text(Vector2(26,650), "Shops connect streets and courtyards. Raid continues while map is open.",Color("b4b19f"),12)
