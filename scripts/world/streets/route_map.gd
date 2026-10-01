extends Control
## In-raid paper map: known assignments and landmarks, with no loot/enemy disclosure.
var district: Node3D
var actor: Node3D
var expanded := false
const MAP_RECT := Rect2(26, 100, 500, 500)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		expanded = not expanded
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
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
	# A persistent compact assignment remains readable after transient combat banners.
	_text(Vector2(width-228,76), "OLD TOWN / M : ROUTE MAP", Color("ead7a5"), 13)
	if not expanded: return
	draw_style_box(UIFactory.panel_style(Color("141c22ef"), Color("736e5d")), Rect2(width-500,100,476,112))
	_text(Vector2(width-480,126), tr("RECORDS: ") + tr(district.district_names[district.task_index]))
	_text(Vector2(width-480,154), tr("SURVEY: ") + tr(district.district_names[(district.task_index+2)%4]))
	var exits: Array[String] = []
	for exit_name in district.active_exit_names: exits.append(tr(exit_name))
	_text(Vector2(width-480,184), tr("EXITS: ") + " / ".join(exits), Color("94c7a8"), 12)
	draw_style_box(UIFactory.panel_style(Color("252925fc"),Color("918570")),Rect2(12,42,528,626))
	_text(Vector2(26,74), "OLD TOWN  /  N ↑    M : CLOSE", Color("ead7a5"), 20)
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
		draw_rect(Rect2(at-Vector2(6,6),Vector2(12,12)),Color("8ce3ad"))
		var names := ["SERVICE GATE","TRAM CHECKPOINT","ARCHWAY","LOADING GATE"]
		var index: int = district.EXITS.find(exit.position)
		_text(at+Vector2(-35, -12 if exit.position.z>0 else 24),names[index],Color("a1e6b7"),11)
	draw_circle(_point(terminal.position),6,Color("f0c276"))
	draw_arc(_point(survey.position),7,0,TAU,24,Color("f0c276"),2,true)
	draw_circle(_point(actor.global_position),5,Color("a6e3ef"))
	var aim: Vector3 = actor.aim_direction
	draw_line(_point(actor.global_position),_point(actor.global_position+aim*4),Color("a6e3ef"),2,true)
	_text(Vector2(26,626), "● YOU    ● RECORDS    ○ SURVEY    ■ ASSIGNED EXITS",Color("d2cbbb"),14)
	_text(Vector2(26,650), "Shops connect streets and courtyards. Raid continues while map is open.",Color("b4b19f"),12)
