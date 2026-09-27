class_name SliceArenaDistricts
extends RefCounted
## Northward extension, not a rescale. Original core roads / points remain intact.
static func add_navigation(arena: UrbanArena) -> void:
	var xs := [-55.0,-37.0,-27.0,-5.0,5.0,27.0,37.0,55.0]
	var zs := [-111.0,-103.0,-73.0,-63.0,-55.0]
	for x in xs.size()-1:
		for z in zs.size()-1:
			if arena._interval_is_road(xs[x],xs[x+1]) or z == 0 or z == 2:
				arena._add_navigation_quad(xs[x],xs[x+1],zs[z],zs[z+1])

static func build(arena: UrbanArena) -> void:
	var district := Node3D.new()
	district.name = "NorthDistricts"
	arena.add_child(district)
	VisualFactory.static_box(district,Vector3(112,0.2,56),Vector3(0,-0.14,-84),Color("39454b"),"DistrictGround")
	for x in [-32.0,0.0,32.0]:
		VisualFactory.box(district,Vector3(10,0.03,56),Vector3(x,0.01,-84),Color("292f36"),"ConnectorRoad")
		for edge in [-5.8,5.8]:
			VisualFactory.box(district,Vector3(1.1,0.1,56),Vector3(x+edge,0.05,-84),Color("68797e"),"NorthSidewalk")
		for z in range(-108,-55,6):
			VisualFactory.box(district,Vector3(0.15,0.035,2),Vector3(x,0.06,z),Color("bec2b8"),"LaneMark")
	for z in [-68.0,-107.0]:
		VisualFactory.box(district,Vector3(112,0.04,10),Vector3(0,0,z),Color("292f36"),"CrossStreet")
	for z in [-68.0,-107.0]:
		for x in [-32.0,0.0,32.0]:
			arena._add_crosswalk(Vector3(x,0.07,z))
	# Residential: compact courts, warm windows and paired low apartments.
	for x in [-46.0,-16.0]:
		for z in [-81.0,-96.0]:
			arena._add_building(Vector3(x,3.5,z),Vector3(12,7,9),Color("59636b"),Color("f2c17e"))
	# Commercial: narrow frontage, cyan awnings, alley sight-lines.
	for z in [-79.0,-91.0]:
		arena._add_building(Vector3(16,2.4,z),Vector3(14,4.8,7),Color("395e68"),Color("71e5e2"))
		VisualFactory.box(district,Vector3(16,0.2,2.5),Vector3(16,2.4,z+4.6),Color("b98256"),"MarketAwning")
	# Industrial: open parking / service yard rather than another housing block.
	for z in [-80.0,-96.0]:
		arena._add_vehicle(Vector3(43,0,z),PI/2,Color("b68555"))
		SliceUI.prop(district,"res://scenes/presentation/service_props/maintenance_cluster.tscn",Vector3(51,0,z),1.2)
	VisualFactory.box(district,Vector3(0.5,9,0.5),Vector3(49,4.5,-89),Color("d5ab64"),"YardCrane")
	VisualFactory.box(district,Vector3(10,0.4,0.5),Vector3(45,8.7,-89),Color("d5ab64"),"CraneArm")
	for row in [[-42.0,"01 / RESIDENTIAL",Color("f2c17e")],[7.0,"02 / MARKET ALLEY",SliceUI.CYAN],[43.0,"03 / SERVICE YARD",Color("e8a161")]]:
		var sign := SliceUI.sign(district,row[1],Vector3(row[0],2.8,-61),row[2])
		sign.font_size = 48
		VisualFactory.box(district,Vector3(0.1,2.8,0.1),Vector3(row[0],1.4,-61),Color("66767a"),"SignPost")
	for x in [-37.0,-5.0,27.0,53.0]:
		arena._add_street_light(Vector3(x,0,-70))
		arena._add_street_light(Vector3(x,0,-104))
