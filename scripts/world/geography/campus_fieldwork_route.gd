extends RefCounted
## Walkable source-road graph with visibility-checked endpoint connections.
## The yellow route is guidance, never a teleport or a navigation collision bypass.
var geo: CampusGeodata
var graph:=AStar2D.new()
var ids: Dictionary={}
var access_nodes: Array[int]=[]

func _init(source: CampusGeodata) -> void:
	geo=source
	for entry: Dictionary in geo.data.roads:
		var points:=CampusGeodata.polygon(entry.points)
		for i in range(points.size()-1):
			var a:=points[i];var b:=points[i+1]
			if a.distance_to(b)<.1 or not clear(a,b):continue
			# OSM ways may have a long straight segment with no vertex beside
			# an entrance. Subdivide the SAME road line so a valid perpendicular
			# approach is not rejected merely because both remote endpoints hide
			# behind buildings. No source shape or physical route is changed.
			var divisions:=maxi(1,ceili(a.distance_to(b)/12.0))
			for part in divisions:graph.connect_points(_id(a.lerp(b,float(part)/divisions)),_id(a.lerp(b,float(part+1)/divisions)))

func _id(point: Vector2) -> int:
	var key:=Vector2i(roundi(point.x*1000),roundi(point.y*1000))
	if not ids.has(key):ids[key]=ids.size();graph.add_point(ids[key],point)
	return ids[key]

func clear(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/1.5))
	for i in range(steps+1):
		var p:=a.lerp(b,float(i)/steps)
		if not Geometry2D.is_point_in_polygon(p,geo.boundary) or geo.is_water(p,.65) or geo.is_building(p,.65):return false
	return true

func _connect_roads(id: int, point: Vector2) -> int:
	var candidates: Array=[]
	for node: int in graph.get_point_ids():
		if node<ids.size():candidates.append(node)
	candidates.sort_custom(func(a: int,b: int)->bool:return point.distance_squared_to(graph.get_point_position(a))<point.distance_squared_to(graph.get_point_position(b)))
	var count:=0
	for node: int in candidates:
		var other:=graph.get_point_position(node)
		if point.distance_to(other)>110:break
		if clear(point,other):graph.connect_points(id,node);count+=1
		if count>=8:break
	return count

func _attach(id: int, point: Vector2) -> void:
	graph.add_point(id,point)
	if _connect_roads(id,point)>0:return
	# Concave facades can face a court with no line of sight to a road.
	# Route around the actual footprint on a clearance-offset perimeter,
	# rather than inventing a straight line through the building or moving
	# its task entrance. These short access spurs are designed guidance.
	for i in geo.buildings.size():
		if not geo.building_bounds[i].grow(8).has_point(point):continue
		for ring: PackedVector2Array in Geometry2D.offset_polygon(geo.buildings[i],1.6,Geometry2D.JOIN_MITER):
			var nodes: Array[int]=[]
			for corner: Vector2 in ring:
				if not geo.safe_walk_point(corner):continue
				var node: int=ids.size()+2+access_nodes.size()
				graph.add_point(node,corner);access_nodes.append(node);nodes.append(node)
				_connect_roads(node,corner)
				if clear(point,corner):graph.connect_points(id,node)
			for j in nodes.size():
				var next: int=nodes[(j+1)%nodes.size()]
				if clear(graph.get_point_position(nodes[j]),graph.get_point_position(next)):graph.connect_points(nodes[j],next)

func find_path(from: Vector2,to: Vector2) -> PackedVector2Array:
	if clear(from,to):return PackedVector2Array([from,to])
	var first:=ids.size();var last:=first+1
	_attach(first,from);_attach(last,to)
	var result:=graph.get_point_path(first,last)
	graph.remove_point(first);graph.remove_point(last)
	for id: int in access_nodes:graph.remove_point(id)
	access_nodes.clear()
	return result
