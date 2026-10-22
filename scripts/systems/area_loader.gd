class_name AreaLoader
extends RefCounted


static func instantiate_area(definition: AreaDefinition, session: SortieSession = null) -> Node3D:
	if not definition or not definition.validate_definition():
		return null
	var scene:=definition.scene
	if definition.id==WaterworksStory.AREA and session and session.waterworks.is_empty():scene=load("res://scenes/areas/waterworks_district.tscn")
	if definition.id==WaterworksStory.AREA and session and session.waterworks.get("version",0)==2:scene=load("res://scenes/areas/waterworks_district_v2.tscn")
	if definition.id==BlockadeStory.AREA and session and session.blockade.is_empty():scene=load("res://scenes/areas/blockade_checkpoint.tscn")
	if definition.id==MaintenanceStory.AREA and session and session.maintenance.is_empty():scene=load("res://scenes/areas/maintenance_zone.tscn")
	if definition.id==MaintenanceStory.AREA and session and session.maintenance.get("version",0)==2:scene=load("res://scenes/areas/maintenance_zone_v2.tscn")
	var instance := scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return null
	return instance as Node3D
