extends RefCounted
## Campus-wide architectural art. Source footprints/collision remain in builder.
## Details and inferred roofs are design estimates, not architectural survey.
var b: RefCounted
var geo: CampusGeodata
var windows: Array[Transform3D] = []
var conditioners: Array[Transform3D] = []
var roof_records: Array[Dictionary] = []
var closed_entries := 0
var hero_count := 0
var pitched_count := 0
var flat_count := 0

static func family(entry: Dictionary) -> int:
	var type: String=entry.tags.get("building","yes")
	var label: String=entry.name
	if type in ["dormitory","residential","apartments"] or "斋" in label or "宿舍" in label:return 0
	if type in ["university","school","office"] or "图书馆" in label:return 1
	if "馆" in label or "中心" in label:return 2
	return 3

func build(builder: RefCounted) -> void:
	b=builder
	geo=b.geo
	for i in geo.data.buildings.size():
		var entry: Dictionary=geo.data.buildings[i]
		var poly: PackedVector2Array=geo.buildings[i]
		var base: float=-INF
		for p: Vector2 in poly:base=maxf(base,geo.height_at(p))
		var top: float=base+float(entry.height)
		_details(entry,poly,base,top)
		_roof(entry,poly,top)
		if entry.osm_id in ["way/891012808","way/891012679","way/925596040","way/891012774"]:
			_landmark(entry,poly,base,top)
		elif entry.inside_campus and CampusGeodata.rect(poly).get_area()>120:
			_closed_entry(poly,base)
	var shapes: Array=[]
	b._module_box(shapes,Vector3(1.72,1.92,.07),Vector3.ZERO,"reveal")
	b._module_box(shapes,Vector3(1.55,1.75,.04),Vector3(0,0,.045),"glass")
	for x: float in [-.815,.815,0.0]:
		b._module_box(shapes,Vector3(.065,1.88,.13),Vector3(x,0,.095),"trim")
	for y: float in [-.925,.925,.24]:
		b._module_box(shapes,Vector3(1.69,.065,.13),Vector3(0,y,.095),"trim")
	b._module_box(shapes,Vector3(1.88,.10,.34),Vector3(0,-1.0,.12),"stone")
	var mesh: ArrayMesh=b._module(shapes)
	b._instances("ArchitecturalWindows",mesh,windows,0,190)
	shapes=[]
	b._module_box(shapes,Vector3(.78,.48,.36),Vector3(0,0,.20),"stone")
	for y: float in [-.15,-.075,0,.075,.15]:
		b._module_box(shapes,Vector3(.59,.018,.018),Vector3(0,y,.39),"metal")
	b._module_box(shapes,Vector3(.9,.055,.43),Vector3(0,-.29,.19),"metal")
	b._instances("ArchitecturalAirConditioners",b._module(shapes),conditioners,0,130)
	b.stats.window_modules=windows.size()
	b.stats.air_conditioners=conditioners.size()
	b.stats.closed_facade_entries=closed_entries
	b.stats.pitched_roofs=pitched_count
	b.stats.flat_roofs=flat_count
	b.stats.landmark_facades=hero_count
	b.world.set_meta("roof_art_records",roof_records)
	b=null

func _outward(poly: PackedVector2Array, p: Vector2, q: Vector2) -> Vector2:
	var tangent: Vector2=(q-p).normalized()
	var normal:=Vector2(-tangent.y,tangent.x)
	if Geometry2D.is_point_in_polygon((p+q)*.5+normal*.1,poly):normal=-normal
	return normal

func _details(entry: Dictionary, poly: PackedVector2Array, base: float, top: float) -> void:
	var floors:=maxi(1,floori((float(entry.height)+.01)/3.3))
	for i in poly.size():
		var p:=poly[i]
		var q:=poly[(i+1)%poly.size()]
		var length:=p.distance_to(q)
		if length<.15:continue
		var tangent: Vector2=(q-p).normalized()
		var normal:=_outward(poly,p,q)
		var at: Vector2=(p+q)*.5
		var yaw:=atan2(tangent.x,tangent.y)
		b._box(Vector3(.36,.48,length+.03),Vector3(at.x,base+.23,at.y),"foundation",yaw)
		b._box(Vector3(.42,.23,length+.07),Vector3(at.x,top-.12,at.y),"trim",yaw)
		# Floor bands and sills belong to the whole building, not just hero sites.
		for floor_index in range(1,floors):
			b._box(Vector3(.19,.10,length),Vector3(at.x,base+floor_index*3.3,at.y),"stone",yaw)
		if length>=5.0:
			var x_axis:=Vector3(tangent.x,0,tangent.y)
			var z_axis:=Vector3(normal.x,0,normal.y)
			# A right-handed basis is needed even when source rings wind differently.
			if x_axis.cross(Vector3.UP).dot(z_axis)<0:x_axis=-x_axis
			var basis:=Basis(x_axis,Vector3.UP,z_axis)
			var start: Vector2=p if Vector2(x_axis.x,x_axis.z).dot(tangent)>0 else q
			for bay in floori(length/3.4):
				var point: Vector2=start+Vector2(x_axis.x,x_axis.z)*(bay+.5)*3.4+normal*.06
				for floor_index in floors:
					windows.append(Transform3D(basis,Vector3(point.x,base+floor_index*3.3+1.875,point.y)))
					if family(entry)==0 and floor_index>0 and bay%4==2:
						conditioners.append(Transform3D(basis,Vector3(point.x,base+floor_index*3.3+.64,point.y)))
		# Corner downpipes are restrained old-campus hardware, not giant greebles.
		var previous: Vector2=(p-poly[(i-1+poly.size())%poly.size()]).normalized()
		if length>3.0 and absf(previous.dot(tangent))<.94:
			var pipe_point:=p+tangent*.22+normal*.16
			b._beam(Vector3(pipe_point.x,base+.25,pipe_point.y),Vector3(pipe_point.x,top-.24,pipe_point.y),.085,"metal")

func _axes(poly: PackedVector2Array) -> Dictionary:
	var axis:=Vector2.RIGHT
	var longest:=0.0
	for i in poly.size():
		var edge:=poly[(i+1)%poly.size()]-poly[i]
		if edge.length_squared()>longest:longest=edge.length_squared();axis=edge.normalized()
	var normal:=Vector2(-axis.y,axis.x)
	var minimum:=Vector2(INF,INF)
	var maximum:=Vector2(-INF,-INF)
	for p: Vector2 in poly:
		var uv:=Vector2(p.dot(axis),p.dot(normal))
		minimum=minimum.min(uv);maximum=maximum.max(uv)
	return {"axis":axis,"normal":normal,"min":minimum,"max":maximum}

func _roof_y(p: Vector2, axes: Dictionary, top: float, rise: float, hipped: bool) -> float:
	var uv:=Vector2(p.dot(axes.axis),p.dot(axes.normal))
	var half_width: float=(axes.max.y-axes.min.y)*.5
	var height: float=maxf(0,1-absf(uv.y-(axes.min.y+axes.max.y)*.5)/maxf(.01,half_width))
	if hipped:height=minf(height,clampf(minf(uv.x-axes.min.x,axes.max.x-uv.x)/maxf(.01,half_width),0,1))
	return top+rise*height

func _roof_patch(poly: PackedVector2Array, axes: Dictionary, top: float, rise: float, hipped: bool) -> void:
	var indices:=Geometry2D.triangulate_polygon(poly)
	for i in range(0,indices.size(),3):
		var p:=poly[indices[i]]
		var q:=poly[indices[i+1]]
		var r:=poly[indices[i+2]]
		var a:=Vector3(p.x,_roof_y(p,axes,top,rise,hipped),p.y)
		var c:=Vector3(q.x,_roof_y(q,axes,top,rise,hipped),q.y)
		var d:=Vector3(r.x,_roof_y(r,axes,top,rise,hipped),r.y)
		if (c-a).cross(d-a).y<0:b._tri("roof",a,d,c,p/3.0,r/3.0,q/3.0)
		else:b._tri("roof",a,c,d,p/3.0,q/3.0,r/3.0)

func _roof(entry: Dictionary, poly: PackedVector2Array, top: float) -> void:
	var roof_shape: String=entry.tags.get("roof:shape","")
	var axes:=_axes(poly)
	var width: float=axes.max.y-axes.min.y
	var pitched: bool=roof_shape in ["gabled","hipped"] or (roof_shape.is_empty() and family(entry)==0 and width<25 and poly.size()<=12)
	if not pitched:
		b._surface(poly,"flat_roof",0,top)
		for i in poly.size():
			var p:=poly[i]
			var q:=poly[(i+1)%poly.size()]
			var at: Vector2=(p+q)*.5
			b._box(Vector3(.23,.34,p.distance_to(q)+.04),Vector3(at.x,top+.15,at.y),"stone",atan2(q.x-p.x,q.y-p.y))
		flat_count+=1
		roof_records.append({"osm_id":entry.osm_id,"shape":"flat","source":roof_shape if not roof_shape.is_empty() else "inferred_art"})
		# Small, legible service hardware instead of an undifferentiated roof slab.
		for i in range(0,poly.size(),maxi(1,poly.size()/3)):
			var a:=poly[i]
			var c:=poly[(i+1)%poly.size()]
			var normal:=_outward(poly,a,c)
			var point: Vector2=(a+c)*.5-normal*2
			if a.distance_to(c)>18 and Geometry2D.is_point_in_polygon(point,poly):
				b._box(Vector3(.85,.65,1.15),Vector3(point.x,top+.35,point.y),"slate")
				b._box(Vector3(.96,.10,1.26),Vector3(point.x,top+.72,point.y),"metal")
		return
	var rise:=clampf(width*.17,1.1,3.1)
	var middle: float=(axes.min.y+axes.max.y)*.5
	var u0: float=axes.min.x-10
	var u1: float=axes.max.x+10
	var rows: Array[float]=[axes.min.y-10,middle,axes.max.y+10]
	var columns: Array[float]=[u0,u1]
	var hipped: bool=roof_shape=="hipped"
	if hipped:columns=[u0,axes.min.x+width*.5,axes.max.x-width*.5,u1];columns.sort()
	for row in range(rows.size()-1):
		for column in range(columns.size()-1):
			var a: Vector2=axes.axis*columns[column]+axes.normal*rows[row]
			var c: Vector2=axes.axis*columns[column+1]+axes.normal*rows[row]
			var d: Vector2=axes.axis*columns[column+1]+axes.normal*rows[row+1]
			var e: Vector2=axes.axis*columns[column]+axes.normal*rows[row+1]
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly,PackedVector2Array([a,c,d,e])):
				_roof_patch(piece,axes,top,rise,hipped)
	# Close gable ends with masonry; no invented windows in the triangular attic.
	for i in poly.size():
		var p:=poly[i]
		var q:=poly[(i+1)%poly.size()]
		var cuts: Array[Vector2]=[p]
		var p_side: float=p.dot(axes.normal)-middle
		var q_side: float=q.dot(axes.normal)-middle
		if p_side*q_side<0:cuts.append(p.lerp(q,p_side/(p_side-q_side)))
		cuts.append(q)
		for j in range(cuts.size()-1):
			var first:=cuts[j]
			var last:=cuts[j+1]
			var a:=Vector3(first.x,top,first.y)
			var c:=Vector3(last.x,top,last.y)
			var d:=Vector3(last.x,_roof_y(last,axes,top,rise,hipped),last.y)
			var e:=Vector3(first.x,_roof_y(first,axes,top,rise,hipped),first.y)
			var normal:=Vector2(-(last-first).y,(last-first).x).normalized()
			if Geometry2D.is_point_in_polygon((first+last)*.5+normal*.1,poly):
				var bottom:=a;a=c;c=bottom
				var upper:=d;d=e;e=upper
			b._quad("red_brick" if family(entry)==0 else "trim",a,c,d,e,first.distance_to(last),rise)
	pitched_count+=1
	roof_records.append({"osm_id":entry.osm_id,"shape":"hipped" if hipped else "gabled","source":roof_shape if not roof_shape.is_empty() else "inferred_art"})

func _front(poly: PackedVector2Array) -> Dictionary:
	var selected:=0
	var score: float=-INF
	for i in poly.size():
		var p:=poly[i]
		var q:=poly[(i+1)%poly.size()]
		var normal:=_outward(poly,p,q)
		var value: float=p.distance_to(q)*(1+normal.y*.7)
		if value>score:score=value;selected=i
	var p:=poly[selected]
	var q:=poly[(selected+1)%poly.size()]
	return {"p":p,"q":q,"normal":_outward(poly,p,q),"tangent":(q-p).normalized()}

func _closed_entry(poly: PackedVector2Array, base: float) -> void:
	var edge:=_front(poly)
	var normal: Vector2=edge.normal
	var point: Vector2=(edge.p+edge.q)*.5+normal*.12
	var yaw:=atan2(normal.x,normal.y)
	b._box(Vector3(2.0,2.85,.15),Vector3(point.x,base+1.42,point.y),"trim",yaw)
	b._box(Vector3(1.75,2.62,.17),Vector3(point.x,base+1.32,point.y)+Vector3(normal.x,0,normal.y)*.03,"metal",yaw)
	b._box(Vector3(2.35,.10,1.10),Vector3(point.x,base+2.97,point.y)+Vector3(normal.x,0,normal.y)*.4,"stone",yaw)
	var tangent: Vector2=edge.tangent
	var a: Vector2=point-tangent*1.6
	var c: Vector2=point+tangent*1.6
	var d: Vector2=c+normal*4
	var e: Vector2=a+normal*4
	if not geo.is_water((d+e)*.5,1) and not geo.road_blocks((d+e)*.5,1.6):b._drape(PackedVector2Array([a,c,d,e]),"paving",.075)
	closed_entries+=1

func _landmark(entry: Dictionary, poly: PackedVector2Array, base: float, top: float) -> void:
	var edge:=_front(poly)
	var p: Vector2=edge.p
	var q: Vector2=edge.q
	var tangent: Vector2=edge.tangent
	var outward: Vector2=edge.normal
	var at: Vector2=(p+q)*.5+outward*.2
	var yaw:=atan2(outward.x,outward.y)
	var center:=Vector3(at.x,base,at.y)
	# Closed facade doors: there are no invented playable interiors.
	b._box(Vector3(3.4,3.25,.22),center+Vector3.UP*1.7,"reveal",yaw)
	b._box(Vector3(2.8,2.8,.17),center+Vector3.UP*1.5+Vector3(outward.x,0,outward.y)*.16,"glass",yaw)
	for side: int in [-1,1]:
		var point: Vector2=at+tangent*side*1.85+outward*.45
		b._box(Vector3(.48,3.55,.48),Vector3(point.x,base+1.8,point.y),"trim",yaw)
	var canopy: Vector2=at+outward*.7
	b._box(Vector3(4.5,.28,1.8),Vector3(canopy.x,base+3.7,canopy.y),"stone",yaw)
	b._box(Vector3(4.1,.10,1.3),Vector3(canopy.x,base+3.5,canopy.y),"metal",yaw)
	var forecourt:=PackedVector2Array([at-tangent*6,at+tangent*6,at+tangent*6+outward*8,at-tangent*6+outward*8])
	b._drape(forecourt,"paving",.08)
	if entry.osm_id=="way/891012808":
		_main_hall_portico(at,tangent,outward,base,yaw)
	var plate: Vector3=Vector3(at.x,base+4.3,at.y)+Vector3(outward.x,0,outward.y)*.13
	b._box(Vector3(4.0,.50,.10),plate,"metal",yaw)
	var plaque:=Label3D.new()
	plaque.name="Landmark_"+String(entry.osm_id).replace("/","_")
	plaque.text="第九教学楼  /  09" if entry.osm_id=="way/891012808" else String(entry.name)
	plaque.font=UIFactory.FONT
	plaque.font_size=44
	plaque.pixel_size=.005
	plaque.modulate=Color("dcdac4")
	plaque.outline_size=0
	plaque.position=Vector3(at.x,base+4.3,at.y)+Vector3(outward.x,0,outward.y)*.23
	plaque.rotation.y=yaw
	plaque.visibility_range_end=150
	b.world.add_child(plaque)
	hero_count+=1

func _main_hall_portico(at: Vector2, tangent: Vector2, normal: Vector2, base: float, yaw: float) -> void:
	for x: float in [-3.7,-1.55,1.55,3.7]:
		var p: Vector2=at+tangent*x+normal*1.7
		b._box(Vector3(.46,4.6,.46),Vector3(p.x,base+2.3,p.y),"trim",yaw)
		b._box(Vector3(.68,.20,.68),Vector3(p.x,base+.11,p.y),"stone",yaw)
		b._box(Vector3(.62,.19,.62),Vector3(p.x,base+4.55,p.y),"stone",yaw)
	var p: Vector2=at+normal*1.25
	b._box(Vector3(9.2,.35,2.1),Vector3(p.x,base+4.85,p.y),"trim",yaw)
	var a:=Vector3(p.x-tangent.x*4.6,base+5.02,p.y-tangent.y*4.6)
	var c:=Vector3(p.x+tangent.x*4.6,base+5.02,p.y+tangent.y*4.6)
	var d:=Vector3(p.x,base+6.45,p.y)
	if (c-a).cross(d-a).dot(Vector3(normal.x,0,normal.y))<0:
		var temp:=a;a=c;c=temp
	b._tri("trim",a,c,d,Vector2.ZERO,Vector2(9.2,0),Vector2(4.6,1.4))
	b._beam(a,d,.18,"stone");b._beam(c,d,.18,"stone")
