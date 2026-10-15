extends Node3D
## Authored old-campus district: lakeside avenues, teaching courts and a western service quarter.
@export_enum("day", "night") var lighting_variant := "day"
const HALF := 58
var ROOMS: Array[Vector3] = [Vector3(24,0,17),Vector3(-18,0,-20),Vector3(-31,0,22),Vector3(-37,0,-31)]
var SPAWNS: Array[Vector3] = [Vector3(-47,.1,49),Vector3(-8,.1,53),Vector3(-48,.1,-48),Vector3(47,.1,-48),Vector3(-53,.1,-14),Vector3(53,.1,4)]
var EXITS: Array[Vector3] = [Vector3(52,0,4),Vector3(-8,0,54),Vector3(-8,0,-52),Vector3(-52,0,-14)]
var obstacles: Array[Rect2] = []
var terminals: Array[Vector3] = []
var selected_spawn := -1
var task_index := 0
var route_map: Control
var active_exit_names: Array[String] = []
const REGIONAL_LOOT := [&"street_office_loot", &"street_pharmacy_loot", &"street_apartment_loot", &"street_repair_loot"]
var district_names := ["ARCHIVE READING ROOM","CAMPUS CLINIC","STUDENT DORMITORY","MAINTENANCE YARD"]
var brick: Material
var plaster: Material
var concrete: ShaderMaterial
var loot_points: Array[LootSpawnPoint] = []
var enemy_points: Array[EnemySpawnPoint] = []
var campus_layout: RefCounted
var campus_roads: Array = []
var campus_lakes: Array = []
var campus_buildings: Array = []

func _ready() -> void:
	# Fixed geometry, colliders, navigation and authored points live in the scene.
	# Only the current sortie's choices and lighting are configured at runtime.
	set_meta("lighting", lighting_variant)
	ROOMS.clear()
	for point in get_node("RoomAnchors").get_children(): ROOMS.append(point.position)
	SPAWNS.clear()
	for index in 6: SPAWNS.append(get_node("StreetSpawn%d" % index).position)
	EXITS.clear()
	for index in 4: EXITS.append(get_node("Exit%d" % index).position)
	terminals.clear()
	for point in get_node("RecordSites").get_children(): terminals.append(point.position)
	obstacles.assign(get_meta("obstacles"))
	campus_roads = get_meta("campus_roads").duplicate(true)
	campus_lakes = get_meta("campus_lakes").duplicate(true)
	campus_buildings = get_meta("campus_buildings").duplicate(true)
	campus_layout = preload("res://scripts/world/streets/campus_layout.gd").new()
	campus_layout.lakes = campus_lakes
	for point in find_children("*", "LootSpawnPoint", true, false): loot_points.append(point)
	for point in find_children("*", "EnemySpawnPoint", true, false): enemy_points.append(point)
	var terminal := get_node("StreetTerminal") as RecordsTerminal
	var alarm := terminal.get_node("RecordsAlarm") as RecordsAlarm
	terminal.objective_interacted.connect(func(_id: StringName): alarm.arm(SortieRuntime.get_current_session()))
	var session := SortieRuntime.get_current_session()
	if session and session.mission_id == &"streets_relay":
		get_node("StreetSurvey").hide()
		for entry in [["Office", "RelayOffice", &"relay_office"], ["Repair", "RelayRepair", &"relay_repair"]]:
			var relay := RelayStation.new()
			relay.name = entry[1]
			relay.objective_id = entry[2]
			relay.position = get_node("RelaySites/" + entry[0]).position
			add_child(relay)
			if not session.campus.is_empty() and session.campus.stage=="relay":
				relay.objective_interacted.connect(_campus_relay_completed)
				relay.get_node("WorldLabel").text="L-02A / RELAY" if entry[2]==&"relay_office" else "L-02B / RELAY"
	_setup_campus_actions(session)
	_apply_lighting_variant()
	GameLanguage.language_changed.connect(_refresh_language)

func _apply_lighting_variant() -> void:
	get_node("NightLighting").visible = lighting_variant == "night"
	if lighting_variant != "night": return
	var world := find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment
	world.environment = world.environment.duplicate(true)
	var environment := world.environment
	environment.ambient_light_color = Color("8daacc")
	environment.ambient_light_energy = .22
	environment.glow_enabled = true
	environment.glow_intensity = .45
	var sky_material := environment.sky.sky_material as ProceduralSkyMaterial
	sky_material.sky_top_color = Color("091426")
	sky_material.sky_horizon_color = Color("344963")
	sky_material.ground_horizon_color = Color("233041")
	sky_material.ground_bottom_color = Color("101a29")
	var sun := find_children("*", "DirectionalLight3D", true, false)[0] as DirectionalLight3D
	sun.rotation_degrees = Vector3(-32,35,0)
	sun.light_color = Color("a7c8ed")
	sun.light_energy = .45

func configure_sortie_layout(spawn: Node3D, rng: RandomNumberGenerator) -> void:
	selected_spawn=SPAWNS.find(spawn.position)
	active_exit_names.clear()
	var ranked: Array[int] = [0,1,2,3]
	ranked.sort_custom(func(a: int,b: int) -> bool: return EXITS[a].distance_to(spawn.position)>EXITS[b].distance_to(spawn.position))
	for index in EXITS.size():
		var exit := get_node("Exit%d"%index) as ExtractionPoint
		exit.available = index in ranked.slice(0,2)
		# A guaranteed retreat remains possible without mission completion.
		# The second, no-farther assigned route rewards recovering the records.
		exit.required_objective_id = &"streets_terminal" if index == ranked[1] else &""
		exit.visible=exit.available
		var exit_name: String = ["EAST CAMPUS GATE","SOUTH CAMPUS GATE","NORTH CAMPUS GATE","WEST SERVICE GATE"][index]
		for label in exit.find_children("*","Label3D",true,false): label.text = exit_name
		if exit.available: active_exit_names.append(exit_name)
	task_index = rng.randi_range(0,3)
	get_node("StreetTerminal").position=terminals[task_index]
	_refresh_language()
	get_node("StreetSurvey").position=ROOMS[(task_index+2)%4]+Vector3(0,0,11)
	for loot in loot_points:
		loot.enabled = loot.loot_table_id==&"prototype_high_value_loot" or String(loot.name).begins_with("Indoor") or rng.randf()>=.35
	var initial_count := 0
	for point in enemy_points:
		point.initial_spawn=point.position.distance_to(spawn.position)>24 and (point.enemy_definition_id == &"campus_infected" or initial_count<3)
		if point.initial_spawn and point.enemy_definition_id != &"campus_infected": initial_count+=1
	set_meta("sortie_brief", "RECORDS: %s / EXITS: %s"%[district_names[task_index]," + ".join(active_exit_names)])
	var session:=SortieRuntime.get_current_session()
	if session and not session.campus.is_empty():set_meta("sortie_brief",CampusChapter.status_text(ProfileRuntime.get_profile(),session))

func create_route_map(actor: Node3D) -> void:
	var layer := CanvasLayer.new()
	layer.name = "DistrictRouteMap"
	layer.layer = 5
	add_child(layer)
	route_map = preload("res://scripts/world/streets/route_map.gd").new()
	route_map.district = self
	route_map.actor = actor
	layer.add_child(route_map)

func _refresh_language() -> void:
	get_node("StreetTerminal").interaction_prompt = tr("SEARCH %s RECORDS") % tr(district_names[task_index])

func _setup_campus_actions(session: SortieSession) -> void:
	if not session or session.campus.is_empty():return
	if session.campus.stage=="relay" and session.mission_id!=&"streets_relay":
		for entry in [["Office","CampusRelayOffice",&"relay_office"],["Repair","CampusRelayRepair",&"relay_repair"]]:
			var point:=preload("res://scenes/world/campus_actions/relay.tscn").instantiate() as CampusAction
			point.name=entry[1];point.action_id=entry[2];point.position=get_node("RelaySites/"+entry[0]).position;add_child(point)
	if session.campus.stage in ["relay","recorder"]:
		var point:=preload("res://scenes/world/campus_actions/recorder.tscn").instantiate() as CampusAction
		point.name="ExperimentRecorder";point.position=Vector3(-35,.92,19);add_child(point)
	if session.campus.stage in ["power","supply","complete"]:
		var point:=preload("res://scenes/world/campus_actions/power.tscn").instantiate() as CampusAction
		point.name="L02BranchControl";point.position=get_node("RelaySites/Repair").position+Vector3(-4,0,0);add_child(point)
	refresh_campus_power()

func _campus_relay_completed(id: StringName) -> void:
	var session:=SortieRuntime.get_current_session()
	if CampusChapter.record_relay(session,String(id)) and session.campus.relays.size()==2:
		var player:=get_tree().get_first_node_in_group("player") as PlayerController
		if player:player.interaction_component.information_read.emit(tr(CampusChapter.WARNING))
	refresh_campus_power();SortieRuntime.request_checkpoint()

func refresh_campus_power() -> void:
	for point in find_children("*","CampusAction",true,false):point._refresh_visual()
