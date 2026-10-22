extends "res://scripts/world/waterworks/route_map.gd"
var area: Node3D
func point(at: Vector3) -> Vector2:return FRAME.position+Vector2(at.x+26,at.z+42)/Vector2(52,70)*FRAME.size
func _draw() -> void:
 if not is_instance_valid(actor) or not expanded or actor.aim_input_captured:return
 draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(.015,.02,.025,.65));draw_style_box(FieldManualStyle.panel(),Rect2(16,45,508,555))
 text_at(Vector2(30,78),"MAINTENANCE / THE WAY OUT",20);draw_rect(FRAME,Color("52615b"))
 for body in area.find_children("*","StaticBody3D",true,false):
  if body.name=="GroundBody" or body.global_position.y>4:continue
  var shape:=body.get_node_or_null("CollisionShape3D") as CollisionShape3D
  if not shape or not shape.shape is BoxShape3D:continue
  var size: Vector3=shape.shape.size;var at: Vector3=body.global_position
  draw_rect(Rect2(point(at-size/2),Vector2(size.x/52,size.z/70)*FRAME.size),Color("242d2d"))
 var session:=SortieRuntime.get_current_session()
 if session and not session.maintenance.is_empty():
  var zone:=MaintenanceJourney.ZONE
  draw_rect(Rect2(point(Vector3(zone.position.x,0,zone.position.y)),zone.size/Vector2(52,70)*FRAME.size),Color("387f70") if session.maintenance.steam_off else Color("c87442"))
  var valve:=point(area.get_node("SteamValve").global_position);draw_circle(valve,4,FieldManualStyle.ACCENT);text_at(valve+Vector2(6,-5),"STEAM VALVE",12)
 for entry in [[Vector3(-10,0,12),"PRESSURE"],[Vector3(10,0,-2),"WARD"],[Vector3(0,0,-24),"SHUTTER"],[Vector3(0,0,-37),"NORTH EXIT"],[Vector3(0,0,25),"SOUTH RETREAT"]]:
  var at:=point(entry[0]);draw_circle(at,4,FieldManualStyle.ACCENT);text_at(at+Vector2(6,-5),entry[1],12)
 draw_circle(point(area.get_node("Survivor").global_position),6,Color("7df5a6"));draw_circle(point(actor.global_position),5,Color.WHITE)
 text_at(Vector2(30,540),"Green marker: Xu Tang / she waits if you get too far.",13)
 text_at(Vector2(30,569),tr("%s: close / the world keeps moving")%ControlBindings.label("route_map"),13)
