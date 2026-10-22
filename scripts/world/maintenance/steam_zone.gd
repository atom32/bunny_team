extends "res://scripts/world/maintenance/maintenance_zone.gd"
func _ready() -> void:
	super._ready()
	set_meta("sortie_brief","SEALED MAINTENANCE / THE YELLOW LINE")
	var look:=MaintenancePresentation.new();look.name="MaintenanceLook";add_child(look);look.build(self)

func refresh_maintenance() -> void:
	super.refresh_maintenance()
	$Steam.refresh()
	$SteamValve/WorldLabel.text=tr("STEAM LINE ISOLATED" if $Steam.isolated() else "CLOSE STEAM VALVE / FAR SIDE")
	$SteamValve/WorldLabel.pixel_size=.011
	for pair in [["Bypass","UNLATCH SERVICE BULKHEAD"],["WardControl","OPEN THE WARD DOOR"],["NorthControl","OPEN NORTH SHUTTER" if $Steam.isolated() else "OPEN NORTH SHUTTER / ISOLATE STEAM FIRST"]]:
		get_node(pair[0]).interaction_prompt=pair[1];get_node(pair[0]).refresh()
		get_node(pair[0]+"/WorldLabel").font_size=24;get_node(pair[0]+"/WorldLabel").pixel_size=.01
	var session:=SortieRuntime.get_current_session()
	for pair in [["Bypass",&"maintenance_bypass","SERVICE BULKHEAD OPEN"],["WardControl",&"maintenance_release","WARD DOOR OPEN"],["NorthControl",&"maintenance_gate","NORTH SHUTTER OPEN"]]:
		if MaintenanceStory.done(session,pair[1]):get_node(pair[0]+"/WorldLabel").text=tr(pair[2])
