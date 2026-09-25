class_name UrbanArena
extends Node3D

const MAP_SIZE := 112.0
const MAP_HALF := MAP_SIZE * 0.5
const ROAD_CENTERS := [-32.0, 0.0, 32.0]

var _navigation_vertices := PackedVector3Array()
var _navigation_polygons: Array[PackedInt32Array] = []
var _navigation_vertex_lookup: Dictionary = {}


func _ready() -> void:
	_build_navigation_region()
	_build_ground_and_roads()
	_build_city_blocks()
	_build_combat_spaces()
	_build_street_props()
	_build_boundaries()


func _build_navigation_region() -> void:
	var coordinates := [-55.0, -37.0, -27.0, -5.0, 5.0, 27.0, 37.0, 55.0]
	for x_index in range(coordinates.size() - 1):
		for z_index in range(coordinates.size() - 1):
			var x_min: float = coordinates[x_index]
			var x_max: float = coordinates[x_index + 1]
			var z_min: float = coordinates[z_index]
			var z_max: float = coordinates[z_index + 1]
			if _interval_is_road(x_min, x_max) or _interval_is_road(z_min, z_max):
				_add_navigation_quad(x_min, x_max, z_min, z_max)

	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.vertices = _navigation_vertices
	for polygon in _navigation_polygons:
		navigation_mesh.add_polygon(polygon)
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion3D"
	region.navigation_mesh = navigation_mesh
	add_child(region)


func _interval_is_road(minimum: float, maximum: float) -> bool:
	var midpoint := (minimum + maximum) * 0.5
	for road_center in ROAD_CENTERS:
		if is_equal_approx(midpoint, road_center):
			return true
	return false


func _add_navigation_quad(x_min: float, x_max: float, z_min: float, z_max: float) -> void:
	_navigation_polygons.append(PackedInt32Array([
		_navigation_vertex(Vector3(x_min, 0.03, z_min)),
		_navigation_vertex(Vector3(x_max, 0.03, z_min)),
		_navigation_vertex(Vector3(x_max, 0.03, z_max)),
		_navigation_vertex(Vector3(x_min, 0.03, z_max)),
	]))


func _navigation_vertex(vertex: Vector3) -> int:
	var key := "%0.2f:%0.2f" % [vertex.x, vertex.z]
	if _navigation_vertex_lookup.has(key):
		return _navigation_vertex_lookup[key]
	var index := _navigation_vertices.size()
	_navigation_vertices.append(vertex)
	_navigation_vertex_lookup[key] = index
	return index


func _build_ground_and_roads() -> void:
	VisualFactory.static_box(self, Vector3(MAP_SIZE, 0.24, MAP_SIZE), Vector3(0.0, -0.14, 0.0), Color("4a4540"), "Ground")
	for road_center in ROAD_CENTERS:
		VisualFactory.box(self, Vector3(10.0, 0.03, MAP_SIZE), Vector3(road_center, 0.01, 0.0), Color("282a2c"), "Avenue")
		VisualFactory.box(self, Vector3(MAP_SIZE, 0.032, 10.0), Vector3(0.0, 0.012, road_center), Color("282a2c"), "Avenue")
		for edge in [-5.8, 5.8]:
			VisualFactory.box(self, Vector3(1.1, 0.1, MAP_SIZE), Vector3(road_center + edge, 0.05, 0.0), Color("77736c"), "Sidewalk")
			VisualFactory.box(self, Vector3(MAP_SIZE, 0.105, 1.1), Vector3(0.0, 0.052, road_center + edge), Color("77736c"), "Sidewalk")

	for road_center in ROAD_CENTERS:
		for step in range(-9, 10):
			var along := float(step) * 5.6
			VisualFactory.box(self, Vector3(0.12, 0.035, 2.25), Vector3(road_center, 0.038, along), Color("d1c89d"), "LaneMark")
			VisualFactory.box(self, Vector3(2.25, 0.035, 0.12), Vector3(along, 0.04, road_center), Color("d1c89d"), "LaneMark")

	for x in ROAD_CENTERS:
		for z in ROAD_CENTERS:
			_add_crosswalk(Vector3(x, 0.045, z))


func _add_crosswalk(center: Vector3) -> void:
	for stripe in range(-3, 4):
		VisualFactory.box(self, Vector3(0.55, 0.035, 4.0), center + Vector3(float(stripe) * 0.92, 0.0, -3.0), Color("d7d7d1"), "Crosswalk")


func _build_city_blocks() -> void:
	_add_building(Vector3(-46.0, 4.0, -46.0), Vector3(15.0, 8.0, 15.0), Color("5a5651"), Color("e8b35c"))
	_add_building(Vector3(-16.0, 3.0, -46.0), Vector3(16.0, 6.0, 14.0), Color("555e61"), Color("77c7c9"))
	_add_building(Vector3(16.0, 4.8, -46.0), Vector3(15.0, 9.6, 15.0), Color("6a5a50"), Color("d88455"))
	_add_building(Vector3(46.0, 3.6, -46.0), Vector3(15.0, 7.2, 16.0), Color("4e575d"), Color("8ed5d8"))

	_add_building(Vector3(-46.0, 3.3, -16.0), Vector3(15.0, 6.6, 16.0), Color("59605b"), Color("a8c473"))
	_add_building(Vector3(-21.0, 3.4, -16.0), Vector3(7.0, 6.8, 17.0), Color("4e515a"), Color("ba8ad1"))
	_add_building(Vector3(-11.5, 2.7, -16.0), Vector3(7.0, 5.4, 17.0), Color("60554e"), Color("d69a5d"))
	_add_building(Vector3(46.0, 4.1, -16.0), Vector3(16.0, 8.2, 15.0), Color("59515e"), Color("bd82cc"))

	_add_building(Vector3(-46.0, 4.7, 16.0), Vector3(15.0, 9.4, 16.0), Color("4a5b5c"), Color("6dd1c8"))
	_add_building(Vector3(16.0, 3.8, 16.0), Vector3(15.0, 7.6, 15.0), Color("655c50"), Color("e2b458"))
	_add_building(Vector3(43.0, 3.0, 13.0), Vector3(9.0, 6.0, 9.0), Color("505b64"), Color("6fbde3"))
	_add_building(Vector3(49.0, 4.0, 21.0), Vector3(8.0, 8.0, 7.0), Color("665552"), Color("dc795f"))

	_add_building(Vector3(-46.0, 3.8, 46.0), Vector3(15.0, 7.6, 15.0), Color("62584d"), Color("e0a652"))
	_add_building(Vector3(-16.0, 5.0, 46.0), Vector3(16.0, 10.0, 15.0), Color("4b565d"), Color("73cad7"))
	_add_building(Vector3(16.0, 3.2, 46.0), Vector3(15.0, 6.4, 15.0), Color("5c555f"), Color("b989d3"))
	_add_building(Vector3(46.0, 4.4, 46.0), Vector3(16.0, 8.8, 16.0), Color("4d5d59"), Color("82ccb0"))


func _add_building(position: Vector3, size: Vector3, color: Color, accent: Color) -> void:
	var body := VisualFactory.static_box(self, size, position, color, "Building")
	var floor_count := maxi(2, int(size.y / 1.45))
	for floor_index in range(1, floor_count):
		for column in [-0.28, 0.28]:
			var window_position := Vector3(column * size.x, -size.y * 0.5 + float(floor_index) * 1.42, -size.z * 0.5 - 0.025)
			var window := VisualFactory.box(body, Vector3(0.82, 0.42, 0.045), window_position, accent, "Window")
			window.material_override = VisualFactory.material(accent.darkened(0.45), 0.1, 0.38, accent, 1.25)
	var roof := VisualFactory.box(body, Vector3(size.x + 0.32, 0.22, size.z + 0.32), Vector3(0.0, size.y * 0.5 + 0.11, 0.0), Color("24282a"), "Roof")
	roof.material_override = VisualFactory.material(Color("24282a"), 0.25, 0.68)
	var roof_mark := VisualFactory.box(body, Vector3(size.x * 0.42, 0.04, 0.38), Vector3(-size.x * 0.18, size.y * 0.5 + 0.24, -size.z * 0.18), accent.darkened(0.25), "RoofMark")
	roof_mark.material_override = VisualFactory.material(accent.darkened(0.5), 0.1, 0.45, accent, 0.75)
	VisualFactory.box(body, Vector3(1.25, 0.58, 1.05), Vector3(size.x * 0.2, size.y * 0.5 + 0.4, -size.z * 0.15), Color("73766f"), "RoofUnit")
	VisualFactory.box(body, Vector3(0.9, 0.42, 0.75), Vector3(-size.x * 0.1, size.y * 0.5 + 0.32, size.z * 0.2), Color("656862"), "RoofUnit")
	VisualFactory.cylinder(body, 0.2, 1.25, Vector3(-size.x * 0.2, size.y * 0.5 + 0.72, size.z * 0.12), Color("85837a"), "Vent")


func _build_combat_spaces() -> void:
	# Construction yard in the south-east inner block.
	for wall in [
		[Vector3(9.0, 0.7, -25.5), Vector3(16.0, 1.4, 0.35)],
		[Vector3(23.5, 0.7, -16.0), Vector3(0.35, 1.4, 19.0)],
		[Vector3(12.0, 0.7, -6.5), Vector3(7.0, 1.4, 0.35)],
	]:
		VisualFactory.static_box(self, wall[1], wall[0], Color("8b7454"), "ConstructionFence")
	VisualFactory.static_box(self, Vector3(4.4, 1.35, 1.7), Vector3(15.5, 0.68, -18.5), Color("a65c42"), "SiteContainer")
	VisualFactory.static_box(self, Vector3(4.4, 1.35, 1.7), Vector3(15.5, 2.03, -18.5), Color("536f73"), "SiteContainer")
	VisualFactory.box(self, Vector3(0.42, 7.0, 0.42), Vector3(20.5, 3.5, -11.0), Color("c7a23e"), "CraneMast")
	VisualFactory.box(self, Vector3(8.0, 0.35, 0.35), Vector3(17.0, 6.65, -11.0), Color("c7a23e"), "CraneArm")

	# A low-walled courtyard with several entries in the north-west inner block.
	VisualFactory.static_box(self, Vector3(16.0, 1.15, 0.38), Vector3(-16.0, 0.58, 7.2), Color("6c6860"), "CourtyardWall")
	VisualFactory.static_box(self, Vector3(0.38, 1.15, 9.0), Vector3(-24.0, 0.58, 13.5), Color("6c6860"), "CourtyardWall")
	VisualFactory.static_box(self, Vector3(6.0, 1.15, 0.38), Vector3(-21.0, 0.58, 24.8), Color("6c6860"), "CourtyardWall")
	VisualFactory.static_box(self, Vector3(4.0, 0.85, 0.7), Vector3(-13.0, 0.43, 17.5), Color("7d807a"), "CourtyardCover")


func _build_street_props() -> void:
	for definition in [
		[Vector3(-38.5, 0.68, -7.0), Color("496e72")], [Vector3(38.5, 0.68, 7.0), Color("9c5848")],
		[Vector3(-7.0, 0.68, 39.0), Color("6b5a82")], [Vector3(7.0, 0.68, -39.0), Color("756b4f")],
	]:
		VisualFactory.static_box(self, Vector3(4.2, 1.35, 1.65), definition[0], definition[1], "CargoContainer")

	_add_vehicle(Vector3(-29.5, 0.0, -12.0), 0.0, Color("a35045"))
	_add_vehicle(Vector3(2.4, 0.0, -34.0), PI * 0.5, Color("596f79"))
	_add_vehicle(Vector3(34.0, 0.0, 18.0), 0.0, Color("7b7554"))
	_add_vehicle(Vector3(-1.8, 0.0, 29.0), PI * 0.5, Color("5d6678"))
	_add_vehicle(Vector3(-34.0, 0.0, 42.0), 0.0, Color("77515d"))

	for cover_position in [
		Vector3(-28.5, 0.45, -25.0), Vector3(-4.8, 0.45, -28.0), Vector3(28.0, 0.45, -4.8),
		Vector3(37.0, 0.45, 28.5), Vector3(4.8, 0.45, 36.0), Vector3(-28.0, 0.45, 4.8),
		Vector3(-4.8, 0.45, 4.0), Vector3(4.8, 0.45, -4.0),
	]:
		VisualFactory.static_box(self, Vector3(2.8, 0.9, 0.58), cover_position, Color("85847d"), "Barrier")

	for light_position in [
		Vector3(-37.5, 0.0, -24.0), Vector3(-26.5, 0.0, -6.0), Vector3(-5.8, 0.0, -38.0),
		Vector3(5.8, 0.0, -22.0), Vector3(26.5, 0.0, -6.0), Vector3(37.5, 0.0, -24.0),
		Vector3(-37.5, 0.0, 24.0), Vector3(-26.5, 0.0, 6.0), Vector3(-5.8, 0.0, 38.0),
		Vector3(5.8, 0.0, 22.0), Vector3(26.5, 0.0, 6.0), Vector3(37.5, 0.0, 24.0),
	]:
		_add_street_light(light_position)

	for rubble_position in [Vector3(-24.0, 0.12, -38.0), Vector3(22.0, 0.12, 37.0), Vector3(38.0, 0.12, -24.0), Vector3(-10.0, 0.12, 6.0)]:
		_add_rubble(rubble_position)


func _add_vehicle(position: Vector3, rotation_y: float, color: Color) -> void:
	var vehicle := VisualFactory.static_box(self, Vector3(1.45, 0.65, 2.9), position + Vector3.UP * 0.42, color, "ParkedVehicle")
	vehicle.rotation.y = rotation_y
	VisualFactory.box(vehicle, Vector3(1.25, 0.42, 1.25), Vector3(0.0, 0.48, 0.05), Color("343d40"), "Cabin")
	var windshield := VisualFactory.box(vehicle, Vector3(1.05, 0.28, 0.05), Vector3(0.0, 0.5, -0.62), Color("78a4aa"), "Windshield")
	windshield.material_override = VisualFactory.material(Color("466a70"), 0.15, 0.2, Color("7ac5ce"), 0.8)


func _add_street_light(position: Vector3) -> void:
	VisualFactory.cylinder(self, 0.075, 3.8, position + Vector3.UP * 1.9, Color("70736f"), "StreetLight")
	var lamp := VisualFactory.sphere(self, 0.14, position + Vector3.UP * 3.75, Color("ffd38a"), "Lamp")
	lamp.material_override = VisualFactory.material(Color("8e7043"), 0.1, 0.2, Color("ffd38a"), 2.8)


func _add_rubble(position: Vector3) -> void:
	for index in range(5):
		var offset := Vector3(float(index % 3) * 0.42, float(index % 2) * 0.1, float(index / 3) * 0.45)
		var piece := VisualFactory.box(self, Vector3(0.45, 0.25, 0.38), position + offset, Color("514d48"), "Rubble")
		piece.rotation_degrees.y = float(index) * 27.0


func _build_boundaries() -> void:
	VisualFactory.static_box(self, Vector3(MAP_SIZE, 2.2, 0.4), Vector3(0.0, 1.1, -MAP_HALF), Color("302e2c"), "NorthWall")
	VisualFactory.static_box(self, Vector3(MAP_SIZE, 2.2, 0.4), Vector3(0.0, 1.1, MAP_HALF), Color("302e2c"), "SouthWall")
	VisualFactory.static_box(self, Vector3(0.4, 2.2, MAP_SIZE), Vector3(-MAP_HALF, 1.1, 0.0), Color("302e2c"), "WestWall")
	VisualFactory.static_box(self, Vector3(0.4, 2.2, MAP_SIZE), Vector3(MAP_HALF, 1.1, 0.0), Color("302e2c"), "EastWall")
