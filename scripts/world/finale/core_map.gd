extends "res://scripts/world/waterworks/route_map.gd"
var area: Node3D
func point(at: Vector3) -> Vector2:return FRAME.position+Vector2(at.x+21,at.z+35)/Vector2(42,62)*FRAME.size
func _draw() -> void:
	if not is_instance_valid(actor) or not expanded or actor.aim_input_captured:return
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(.015,.02,.025,.65));draw_style_box(FieldManualStyle.panel(),Rect2(16,45,508,555))
	text_at(Vector2(30,78),"BACKUP POWER / KEEP THE GREEN LINE",18);draw_rect(FRAME,Color("5c6260"))
	for body in area.find_children("*","StaticBody3D",true,false):
		if body.name=="GroundBody" or body.global_position.y>4:continue
		var shape:=body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if not shape or not shape.shape is BoxShape3D:continue
		var size: Vector3=shape.shape.size
		draw_rect(Rect2(point(body.global_position-size/2),Vector2(size.x/42,size.z/62)*FRAME.size),Color("252d2d"))
	var sweep: FinaleSweep=area.get_node("Sweep")
	if sweep.phase in [FinaleSweep.Phase.WARNING,FinaleSweep.Phase.SWEEP]:
		var x: float=FinaleSweep.LANES[sweep.lane]
		draw_rect(Rect2(point(Vector3(x-2.5,0,-24)),Vector2(5.0/42,30.0/62)*FRAME.size),Color(1,.5,.12,.5))
	for entry in [[Vector3(0,0,12),"SHELTER BRIDGE"],[Vector3(-14,0,-9),"LEFT FEED"],[Vector3(14,0,-19),"RIGHT FEED"],[Vector3(0,0,-25),"MASTER STOP"],[Vector3(0,0,-32),"NORTH EXIT"],[Vector3(0,0,24),"SOUTH RETREAT"]]:
		var at:=point(entry[0]);draw_circle(at,4,FieldManualStyle.ACCENT);text_at(at+Vector2(6,-5),entry[1],11)
	draw_circle(point(Vector3(-15,0,12)),5,Color("7df5a6"));draw_circle(point(actor.global_position),5,Color.WHITE)
	text_at(Vector2(30,540),"Amber: marked lane / Blue: operate side feeds",13)
	text_at(Vector2(30,569),tr("%s: close / the world keeps moving")%ControlBindings.label("route_map"),13)
