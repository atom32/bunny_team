extends RefCounted
## Read-only water queries for the authored campus scene. No runtime generation.
var lakes: Array = []

func water_blocks(at: Vector2) -> bool:
	for polygon in lakes:
		if Geometry2D.is_point_in_polygon(at, polygon): return true
		for index in polygon.size():
			if Geometry2D.get_closest_point_to_segment(at, polygon[index], polygon[(index+1)%polygon.size()]).distance_to(at) < .85: return true
	return false
