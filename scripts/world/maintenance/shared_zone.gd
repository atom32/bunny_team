extends "res://scripts/world/maintenance/steam_zone.gd"
## v3 toolbox remains; only new v4 sorties replace the original entry guard.
func _ready() -> void:
	var session := SortieRuntime.get_current_session()
	if session and session.maintenance.get("version",0) == 4:
		set_meta("map_revision",4)
		get_node("Enemy0").enemy_definition_id = &"maintenance_alarm_carrier"
	super._ready()

func _process(_delta: float) -> void:
	var battle:=get_parent().get_parent()
	if not "player" in battle or not is_instance_valid(battle.player):return
	for point in [get_node("Supplies"),get_node("WardSupplies")]:
		var tag:=point.get_node_or_null("LootContainer/WorldTag") as Label3D
		if tag:
			tag.font_size=24;tag.pixel_size=.003
			tag.visible=battle.player.global_position.distance_to(point.global_position)>3

func refresh_maintenance() -> void:
	super.refresh_maintenance()
	if has_node("SharedToolbox"): $SharedToolbox._refresh()
