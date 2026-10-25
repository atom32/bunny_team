class_name CampusGeodata
extends RefCounted
## Shared, offline metric source for the 3D world, map and inspection UI.
const PATH := "res://assets/geography/weijin/campus.json"
var data: Dictionary
var boundary: PackedVector2Array
var water: Array[PackedVector2Array] = []
var water_bounds: Array[Rect2] = []
var buildings: Array[PackedVector2Array] = []
var building_bounds: Array[Rect2] = []
var road_segments: Array[Dictionary] = []
var pitches: Array[PackedVector2Array] = []
var pitch_bounds: Array[Rect2] = []

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	boundary = polygon(data.boundary)
	for entry: Dictionary in data.water:
		var poly := polygon(entry.points)
		water.append(poly)
		water_bounds.append(rect(poly))
	for entry: Dictionary in data.buildings:
		var poly := polygon(entry.points)
		buildings.append(poly)
		building_bounds.append(rect(poly))
	for entry: Dictionary in data.roads:
		var path:=polygon(entry.points)
		for i in range(path.size()-1):
			road_segments.append({"a":path[i],"b":path[i+1],"width":entry.width,"rect":Rect2(path[i],Vector2.ZERO).expand(path[i+1]).grow(float(entry.width)*.5)})
	for entry: Dictionary in data.pitches:
		var poly:=polygon(entry.points)
		pitches.append(poly);pitch_bounds.append(rect(poly))

static func polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p: Array in points: result.append(Vector2(p[0], p[1]))
	return result

static func rect(poly: PackedVector2Array) -> Rect2:
	var result := Rect2(poly[0], Vector2.ZERO)
	for p: Vector2 in poly: result = result.expand(p)
	return result

func height_at(at: Vector2) -> float:
	var dem: Dictionary = data.dem
	var x := clampf((at.x - float(dem.origin[0])) / float(dem.step_m), 0, int(dem.columns) - 1.001)
	var z := clampf((at.y - float(dem.origin[1])) / float(dem.step_m), 0, int(dem.rows) - 1.001)
	var ix := int(x)
	var iz := int(z)
	var columns := int(dem.columns)
	var values: Array = dem.heights_m
	return lerpf(lerpf(values[iz*columns+ix], values[iz*columns+ix+1], x-ix), lerpf(values[(iz+1)*columns+ix], values[(iz+1)*columns+ix+1], x-ix), z-iz) - float(dem.datum_m)

func at3(at: Vector2, offset := 0.0) -> Vector3:
	return Vector3(at.x, height_at(at) + offset, at.y)

func mesh_height_at(at: Vector2) -> float:
	# The baked terrain uses 12m cells with diagonal [3,0,1] / [1,2,3].
	# Drape art onto that actual triangle surface, not onto an intersecting
	# bilinear sheet. Original DEM and terrain collision remain unchanged.
	var cell:=Vector2(floorf(at.x/12)*12,floorf(at.y/12)*12)
	var uv: Vector2=(at-cell)/12
	var h00:=height_at(cell)
	var h10:=height_at(cell+Vector2(12,0))
	var h01:=height_at(cell+Vector2(0,12))
	var h11:=height_at(cell+Vector2(12,12))
	if uv.x+uv.y<=1:return h00+(h10-h00)*uv.x+(h01-h00)*uv.y
	return h11+(h01-h11)*(1-uv.x)+(h10-h11)*(1-uv.y)

func mesh_at3(at: Vector2, offset := 0.0) -> Vector3:
	return Vector3(at.x,mesh_height_at(at)+offset,at.y)

func is_water(at: Vector2, margin := 0.0) -> bool:
	for i in water.size():
		if not water_bounds[i].grow(margin).has_point(at): continue
		if Geometry2D.is_point_in_polygon(at, water[i]): return true
		if margin > 0.0:
			for j in water[i].size():
				if Geometry2D.get_closest_point_to_segment(at, water[i][j], water[i][(j+1)%water[i].size()]).distance_to(at) < margin: return true
	return false

func is_building(at: Vector2, margin := 0.0) -> bool:
	for i in buildings.size():
		if not building_bounds[i].grow(margin).has_point(at): continue
		if Geometry2D.is_point_in_polygon(at, buildings[i]): return true
		if margin > 0.0:
			for j in buildings[i].size():
				if Geometry2D.get_closest_point_to_segment(at, buildings[i][j], buildings[i][(j+1)%buildings[i].size()]).distance_to(at) < margin: return true
	return false

func safe_walk_point(at: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(at, boundary) and not is_water(at, 1.0) and not is_building(at, 1.0)

func road_blocks(at: Vector2, margin := 0.0) -> bool:
	for segment: Dictionary in road_segments:
		if not segment.rect.grow(margin).has_point(at):continue
		if Geometry2D.get_closest_point_to_segment(at,segment.a,segment.b).distance_to(at)<float(segment.width)*.5+margin:return true
	return false

func sports_blocks(at: Vector2, margin := 0.0) -> bool:
	for i in pitches.size():
		if not pitch_bounds[i].grow(margin).has_point(at):continue
		if Geometry2D.is_point_in_polygon(at,pitches[i]):return true
		if margin>0:
			for j in pitches[i].size():
				if Geometry2D.get_closest_point_to_segment(at,pitches[i][j],pitches[i][(j+1)%pitches[i].size()]).distance_to(at)<margin:return true
	return false

func project(lon: float, lat: float) -> Vector2:
	return Vector2((lon - float(data.origin_wgs84[0])) * float(data.metres_per_degree[0]), (float(data.origin_wgs84[1]) - lat) * float(data.metres_per_degree[1]))
