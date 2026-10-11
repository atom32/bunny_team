extends Node3D
var elapsed := 0.0
var launched := false
var screen: Control
var status: Label
var camera: Camera3D
var transit_started := false

func _ready() -> void:
	if not SortieRuntime.get_current_session():
		launched = true
		FlowMenu.show_error("Deployment has no session. Return to base and retry.", true)
		return
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	hideout.name = "DeploymentHideout"
	hideout.menu_backdrop = true
	add_child(hideout)
	hideout._process(0.0)
	hideout.set_process(false)
	camera = hideout.camera
	camera.position = Vector3(0.35,1.6,1.65)
	camera.look_at(Vector3(-0.85,1.05,-0.45))
	var layer := CanvasLayer.new()
	add_child(layer)
	screen = SliceUI.root(layer)
	SliceUI.panel(screen, Vector2(0,528), Vector2(1280,192))
	var destination := SliceUI.label(screen, tr("BASTION 07 → %s") % _destination(), Vector2(50,554), 16, SliceUI.CYAN)
	destination.name = "DeploymentDestination"
	status = SliceUI.label(screen, "LOADOUT LOCKED / FRAME READY", Vector2(50,590), 32)
	SliceUI.button(screen, "SKIP  /  ENTER", Vector2(1030,644), Vector2(210,42), _launch)
	AudioDirector.play_sfx(&"reload", -3)
	AudioDirector.set_music_context(&"deployment")

func _process(delta: float) -> void:
	if launched: return
	elapsed += delta
	camera.position.z = lerpf(1.65,1.82,clampf(elapsed/5.0,0,1))
	camera.look_at(Vector3(-0.85,1.05,-0.45))
	if elapsed > 2.2 and not transit_started:
		transit_started = true
		status.text = tr("TRANSIT LINK OPEN / DEPLOYING")
		AudioDirector.play_sfx(&"dodge", -3)
	if elapsed > 5.0: _launch()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): _launch()

func _launch() -> void:
	if launched: return
	var error := GameState.present_scene("res://scenes/battle/battle.tscn", tr("%s / ARRIVAL") % _destination())
	if error != OK:
		if error != ERR_BUSY:
			launched = true
			FlowMenu.show_error("Could not open the mission. Return to base and retry.", true)
		return
	launched = true
	GameState.arrival_pending = true

func _destination() -> String:
	var session := SortieRuntime.get_current_session()
	if not session: return ""
	if session.area_id == &"first_mission_area":
		return tr("TUTORIAL / UNREFURBISHED")
	var area := ContentDB.get_area_definition(session.area_id)
	var caption := tr(area.display_name) if area else String(session.area_id)
	if session.area_id == &"street_district":
		caption += " · " + tr("NIGHT" if session.lighting_variant == "night" else "DAY")
	return caption
