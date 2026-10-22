extends "res://scripts/world/waterworks/delivery_district.gd"

func refresh_waterworks() -> void:
	super.refresh_waterworks()
	if geometry_ready:$Market.apply_progress()

func refresh_waterworks_labels() -> void:
	for entry in [["MarketBreaker","BELL DISCONNECTED" if $Market.isolated else "WEST STALLS / DEPOT BELL WIRE"],["MarketShutter","DEPOT / OPEN" if $Market.progress==1 else ("DEPOT / QUIET OPENING" if $Market.mode==1 else ("DEPOT / ALARM" if $Market.mode==2 else "OPTIONAL DEPOT / 6kg SALVAGE"))],["MarketBackBar","NORTH BAR / OPEN" if $Market.back_open else "NORTH BAR / OPEN FROM INSIDE"]]:
		get_node(entry[0]+"/WorldLabel").text=tr(entry[1])

	for entry in [["MarketSign","SOUTH MARKET / WATER TOWER NORTH"],["WestLaneSign","WEST / STALL COVER / BELL WIRE"],["EastLaneSign","EAST / OPEN ROAD / REPAIR DEPOT"],["DepotCoreSign","SALVAGE CORE / 6kg / OPTIONAL"]]:
		get_node(entry[0]).text=tr(entry[1])
