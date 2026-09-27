extends Node3D
var elapsed := 0.0
var launched := false
var screen: Control
var status: Label
var camera: Camera3D

func _ready() -> void:
	var hanger = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	hanger.hanger_ui.hide()
	camera = hanger.get_node("PreviewCamera")
	camera.position = Vector3(-3.4,1.6,2.8)
	camera.look_at(Vector3(-2.2,1.2,0))
	var layer := CanvasLayer.new()
	add_child(layer)
	screen = SliceUI.root(layer)
	SliceUI.panel(screen, Vector2(0,528), Vector2(1280,192))
	SliceUI.label(screen, "BASTION 07  →  URBAN DISTRICT", Vector2(50,554), 16, SliceUI.CYAN)
	status = SliceUI.label(screen, "LOADOUT LOCKED / FRAME READY", Vector2(50,590), 32)
	SliceUI.button(screen, "SKIP  /  ENTER", Vector2(1030,644), Vector2(210,42), _launch)
	AudioDirector.play_sfx(&"reload", -3)
	AudioDirector.set_music_context(&"deployment")

func _process(delta: float) -> void:
	if launched: return
	elapsed += delta
	camera.position.z = lerpf(2.8,6.0,clampf(elapsed/5.0,0,1))
	camera.look_at(Vector3(-2.2,1.15,0))
	if elapsed > 2.2 and status.text.begins_with("LOADOUT"):
		status.text = "TRANSIT LINK OPEN / DEPLOYING"
		AudioDirector.play_sfx(&"dodge", -3)
	if elapsed > 5.0: _launch()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): _launch()

func _launch() -> void:
	if launched: return
	if GameState.present_scene("res://scenes/battle/battle.tscn", "DISTRICT 07 / ARRIVAL") != OK:
		return # The preceding fade may still own the transition during an early skip.
	launched = true
	GameState.arrival_pending = true
