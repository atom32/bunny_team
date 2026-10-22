class_name BlockadeSearchlight
extends Node3D
const PERIOD:=8.0
const RANGE:=24.0
const HALF_ANGLE:=deg_to_rad(18.0)
var sweep_time:=0.0
var exposure:=0.0
var visual_remaining:=0.0
var footprint: MeshInstance3D

func direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP,PI+sin(sweep_time*TAU/PERIOD)*deg_to_rad(50))

func sees(actor: PlayerController) -> bool:
	if not actor or actor.is_dead:return false
	var gap:=actor.global_position-global_position;gap.y=0
	if gap.length()>RANGE or gap.normalized().dot(direction())<cos(HALF_ANGLE):return false
	var query:=PhysicsRayQueryParameters3D.create(global_position,actor.global_position+Vector3.UP*1.1,5)
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider==actor

func _ready() -> void:
	footprint=MeshInstance3D.new();footprint.name="VisibleSweep";footprint.mesh=ImmediateMesh.new()
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.albedo_color=Color(1,.86,.42,.3);footprint.material_override=material;footprint.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(footprint);footprint.top_level=true

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session()
	if not session or session.status!=SortieSession.Status.ACTIVE or session.blockade.is_empty():return
	if session.blockade.van_down:exposure=0;refresh_visual();return
	sweep_time=fmod(sweep_time+delta,PERIOD)
	var actor:=get_tree().get_first_node_in_group("player") as PlayerController
	if not session.blockade.alarm and not session.blockade.van_down:
		exposure=minf(.4,exposure+delta) if sees(actor) else 0
		if exposure>=.4:get_parent().get_node("Passage").alarm();exposure=0
	else:exposure=0
	$Head.rotation.y=atan2(-direction().x,-direction().z)
	visual_remaining-=delta
	if visual_remaining<=0:refresh_visual();visual_remaining=.1

func refresh_visual() -> void:
	$Head.rotation.y=atan2(-direction().x,-direction().z)
	var session:=SortieRuntime.get_current_session()
	if not session or session.blockade.is_empty() or session.blockade.van_down:
		footprint.hide();$Head/Beam.hide();return
	footprint.show();$Head/Beam.show()
	$Head/Beam.light_color=Color(1,.2,.08) if session.blockade.alarm else Color(1,.86,.42)
	var material:=footprint.material_override as StandardMaterial3D
	material.albedo_color=Color(1,.2,.08,.28) if session.blockade.alarm else Color(1,.86,.42,.3)
	footprint.global_transform=Transform3D(Basis.IDENTITY,Vector3(global_position.x,.06,global_position.z))
	var vertices:=PackedVector3Array()
	for sector in 12:
		var a:=direction().rotated(Vector3.UP,lerpf(-HALF_ANGLE,HALF_ANGLE,float(sector)/12))
		var b:=direction().rotated(Vector3.UP,lerpf(-HALF_ANGLE,HALF_ANGLE,float(sector+1)/12))
		for step in 8:
			var r0:=RANGE*float(step)/8;var r1:=RANGE*float(step+1)/8
			var points:=[a*r0,b*r0,b*r1,a*r1]
			if not points.all(func(point):return PlayerVisibility.point_visible(self,footprint.global_position+point)):continue
			var center: Vector3=footprint.global_position+(a+b)*.5*((r0+r1)*.5)+Vector3.UP*1.05
			if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position,center,4)).is_empty():continue
			for index in [0,1,2,0,2,3]:vertices.append(points[index])
	var mesh:=footprint.mesh as ImmediateMesh;mesh.clear_surfaces()
	if vertices.is_empty():return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in vertices:mesh.surface_add_vertex(point)
	mesh.surface_end()

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	return not session.blockade.is_empty() and entry.sweep_time>=0 and entry.sweep_time<PERIOD and entry.exposure>=0 and entry.exposure<.4 and (not session.blockade.alarm or entry.exposure==0) and (not session.blockade.van_down or entry.exposure==0)
