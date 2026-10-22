extends Control
var actor: Node3D
var expanded := false
const FRAME := Rect2(30,100,480,408)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if actor.aim_input_captured: return
	if event.is_action_pressed("route_map") and not event.is_echo(): expanded = not expanded; get_viewport().set_input_as_handled()

func _process(_delta: float) -> void: queue_redraw()

func point(at: Vector3) -> Vector2:
	var session:=SortieRuntime.get_current_session()
	if session and session.waterworks.get("version",0)==3:return FRAME.position+Vector2(at.x+48,at.z+46)/Vector2(96,142)*FRAME.size
	return FRAME.position + (Vector2(at.x+48,at.z+46)/Vector2(96,80) if session and not session.waterworks.is_empty() else Vector2(at.x+40,at.z+34)/Vector2(80,68)) * FRAME.size

func text_at(at: Vector2, value: String, size := 15, color := FieldManualStyle.INK) -> void:
	draw_string(UIFactory.FONT, at, tr(value), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if not is_instance_valid(actor) or actor.aim_input_captured: return
	if not expanded: return
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(0.015,.02,.025,.65))
	draw_style_box(FieldManualStyle.panel(),Rect2(16,45,508,555))
	text_at(Vector2(30,78),tr("WATER TOWER STREET / %s: CLOSE") % ControlBindings.label("route_map"),20)
	draw_rect(FRAME,Color("52615b"))
	draw_line(point(Vector3(0,0,32)),point(Vector3(0,0,-32)),Color("b1af96"),28)
	draw_line(point(Vector3(-32,0,22)),point(Vector3(-32,0,-22)),Color("b1af96"),14)
	for entry in [[Vector3(-26,0,15),"GARAGE / 8kg BATTERY"],[Vector3(25,0,-13),"PUMP / 8s"],[Vector3(-20,0,-17),"COURTYARD / DRESSINGS"],[Vector3(26,0,-26),"TANKER / AMMUNITION"],[Vector3(-28,0,3),"LOUDSPEAKER SWITCH"],[Vector3(0,0,30),"SOUTH / MARKET"]]:
		var at := point(entry[0])
		draw_circle(at,5,FieldManualStyle.ACCENT)
		if entry[1]=="SOUTH / MARKET" and SortieRuntime.get_current_session().waterworks.get("version",0)!=3:entry[1]="SOUTH / RETREAT"
		text_at(at + Vector2(7,-5), entry[1],12)
	var session:=SortieRuntime.get_current_session()
	if session and not session.waterworks.is_empty():
		for entry in [[Vector3(-30,0,-8),"BYPASS / NO AMMO NEEDED"],[Vector3(28,0,-32),"LOADING GATE / LEVER"],[Vector3(-42,0,-24),"WEST / COURTYARD EXIT"],[Vector3(29,0,-40),"NORTH / LOADING EXIT"]]:
			var at:=point(entry[0]);draw_circle(at,4,FieldManualStyle.ACCENT);text_at(at+Vector2(5,-5),entry[1],11)
		if session.waterworks.get("version",0)==3:
			for x in [-27,17]:draw_line(point(Vector3(x,0,84)),point(Vector3(x,0,34)),Color("b1af96"),14)
			for entry in [[Vector3(-31,0,57),"BELL WIRE"],[Vector3(33,0,66),"OPTIONAL DEPOT / 6kg"],[Vector3(0,0,92),"SOUTH / RETREAT"]]:
				var at:=point(entry[0]);draw_circle(at,4,FieldManualStyle.ACCENT);text_at(at+Vector2(5,-5),entry[1],11)
		var truck:=get_parent().get_parent().get_node("Tanker") as WaterTanker
		draw_rect(Rect2(point(truck.global_position)-Vector2(4,7),Vector2(8,14)),Color("e8c48f"))
	draw_circle(point(actor.global_position),6,Color("b7ffea"))
	text_at(Vector2(30,540),"West alley: cover / Main street: exposed crossing",13)
	text_at(Vector2(30,569),"One delivery per sortie. South retreat is always open.",13)
