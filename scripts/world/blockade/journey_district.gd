extends "res://scripts/world/blockade/blockade_checkpoint.gd"
var geometry_ready:=false

func _ready() -> void:
	super._ready()
	geometry_ready=true # No collider movement before Battle signs authored geometry.

func refresh_blockade() -> void:
	super.refresh_blockade()
	if geometry_ready:
		$Passage.refresh_hardware();$Searchlight.refresh_visual()
	refresh_route_labels()

func refresh_route_labels() -> void:
	var route: BlockadePassage=$Passage
	var entries:={"ServiceLever":"SERVICE SHUTTER OPEN" if route.service_open else "OPEN SERVICE SHUTTER / QUIET ENTRY","EscapeLever":"NORTH GATE OPEN" if route.escape_progress==1 else "NORTH GATE RISING" if route.escape_started else "RELEASE COUNTERWEIGHT / NORTH GATE","StreetChain":"STREET SHUTTER OPEN" if $StreetChain.destroyed else "SHOOT RED CHAIN / LOUD ENTRY"}
	for name in entries:
		var label:=get_node(String(name)+"/WorldLabel") as Label3D
		label.text=tr(entries[name]);label.font_size=30;label.pixel_size=.012
	$ExitYardSign.text=tr("NORTH SHUTTER / EAST BOOTH");$ExitYardSign.pixel_size=.012

func van_disabled() -> void:$Passage.van_disabled()
