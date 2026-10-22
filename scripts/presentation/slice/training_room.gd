extends Node3D
## A disposable preview scene: no profile mutation, sortie, rewards or save fields.
const MOTION := preload("res://scripts/presentation/slice/training_motion.gd")
const TITLES := {"idle": "READY / OFF DUTY", "stretch": "MAT / OVERHEAD SIDE STRETCH", "treadmill": "TREADMILL / BRISK WALK", "bench": "BENCH / SIT TO STAND", "rest": "BENCH / TAKE A BREATHER"}
const LINES := {
	"idle": "Su Mi: The equipment stays here. The excuses can leave.",
	"stretch": "Tang Kui: Nobody counts that as surrender. Put your hands up.",
	"treadmill": "Shen: We finally found a road with no ambushes. It goes nowhere.",
	"bench": "Su Mi: Sit. Stand. See? A chair can give orders too.",
	"rest": "Tang Kui: Saved you a seat. No, I am not asking you to get up.",
}
var actor: PlayerController
var motion: Node
var camera: Camera3D
var screen: Control
var status: Label
var dialogue: Label
var pause_button: Button
var station_buttons := {}
var yaw := 0.0
var elevation := 0.18
var distance := 4.4
var auto_orbit := false
var dragging := false
var belt_travel := 0.0
var camera_focus := Vector3(-2.5, 1.0, 0)
var leaving := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_music_context(&"hideout")
	actor = preload("res://scenes/player/player.tscn").instantiate()
	actor.preview_mode = true
	add_child(actor)
	motion = MOTION.new()
	add_child(motion)
	motion.initialize(actor)
	camera = $Camera3D
	_build_ui()
	_update_camera(0.0)
	GameLanguage.language_changed.connect(_refresh_language)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	screen = SliceUI.root(layer)
	screen.theme = SliceUI.menu_theme()
	SliceUI.panel(screen, Vector2(24, 16), Vector2(1232, 94))
	SliceUI.label(screen, tr("BASTION 07 / OFF-DUTY TRAINING"), Vector2(44, 32), 27)
	SliceUI.label(screen, tr("No supplies spent. No stat bonuses. Just a little time at home."), Vector2(44, 74), 16, SliceUI.CYAN)
	var panel := SliceUI.panel(screen, Vector2(24, 130), Vector2(304, 426))
	SliceUI.label(panel, tr("CHOOSE A STATION"), Vector2(18, 18), 20)
	var ids := ["stretch", "treadmill", "bench", "rest"]
	for index in ids.size():
		var id: String = ids[index]
		var button := SliceUI.button(panel, tr(TITLES[id]), Vector2(16, 60 + index * 56), Vector2(272, 48), func(): select_station(id))
		button.name = "Station" + id.capitalize()
		button.add_theme_font_size_override("font_size", 15)
		station_buttons[id] = button
	pause_button = SliceUI.button(panel, tr("PAUSE MOTION"), Vector2(16, 294), Vector2(132, 42), toggle_pause)
	pause_button.name = "PauseMotion"
	pause_button.add_theme_font_size_override("font_size", 14)
	var finish := SliceUI.button(panel, tr("FINISH SET"), Vector2(156, 294), Vector2(132, 42), func(): select_station("idle"))
	finish.name = "FinishSet"
	finish.add_theme_font_size_override("font_size", 14)
	var speed := OptionButton.new()
	speed.name = "PlaybackSpeed"
	speed.position = Vector2(16, 350)
	speed.size = Vector2(272, 44)
	for value in ["0.5× / SLOW", "1.0× / NORMAL", "1.25× / QUICK"]: speed.add_item(tr(value))
	speed.select([0.5, 1.0, 1.25].find(motion.playback_speed))
	speed.item_selected.connect(func(index: int): motion.playback_speed = [0.5, 1.0, 1.25][index])
	panel.add_child(speed)
	var bottom := SliceUI.panel(screen, Vector2(348, 624), Vector2(908, 80))
	status = SliceUI.label(bottom, "", Vector2(18, 9), 16, SliceUI.CYAN)
	status.name = "TrainingStatus"
	dialogue = SliceUI.label(bottom, tr(LINES.idle), Vector2(18, 34), 16)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.size = Vector2(866, 40)
	SliceUI.panel(screen, Vector2(870, 118), Vector2(386, 230))
	SliceUI.button(screen, tr("FULL BODY"), Vector2(886, 130), Vector2(132, 40), reset_camera).name = "FullBodyCamera"
	SliceUI.button(screen, tr("ORBIT / ON-OFF"), Vector2(1030, 130), Vector2(208, 40), func(): auto_orbit = not auto_orbit).name = "OrbitCamera"
	SliceUI.button(screen, "↶", Vector2(1130, 182), Vector2(48, 40), func(): yaw -= PI / 8.0)
	SliceUI.button(screen, "↷", Vector2(1190, 182), Vector2(48, 40), func(): yaw += PI / 8.0)
	var hint := SliceUI.label(screen, tr("Right-drag: orbit   /   Wheel: distance   /   Esc: pause"), Vector2(886, 238), 14, SliceUI.CYAN)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size = Vector2(350, 56)
	SliceUI.label(screen, tr("Tab: show / hide interface"), Vector2(886, 300), 14, SliceUI.CYAN)
	SliceUI.button(screen, tr("RETURN TO QUARTERS"), Vector2(1004, 38), Vector2(232, 48), return_to_quarters).name = "ReturnToQuarters"
	station_buttons.stretch.grab_focus()

func _refresh_language() -> void:
	var layer := screen.get_parent()
	remove_child(layer)
	layer.queue_free()
	station_buttons.clear()
	_build_ui()
	dialogue.text = tr(LINES.get(motion.station, LINES.idle))

func select_station(id: String) -> void:
	if leaving: return
	motion.select_station(id)
	dialogue.text = tr(LINES.get(id, LINES.idle))

func toggle_pause() -> void:
	motion.playback_paused = not motion.playback_paused

func reset_camera() -> void:
	yaw = 0.0
	elevation = 0.18
	distance = 4.4
	auto_orbit = false

func return_to_quarters() -> void:
	if leaving: return
	GameState.hideout_section = "Rest"
	leaving = GameState.present_scene("res://scenes/presentation/slice/hideout.tscn", "PERSONAL QUARTERS") == OK

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed: dragging = false
	if FlowMenu.is_open() or leaving: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		screen.visible = not screen.visible
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if FlowMenu.is_open() or leaving: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.2), 3.2, 4.6)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.007
		elevation = clampf(elevation + event.relative.y * 0.004, 0.08, 0.38)
		auto_orbit = false
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_instance_valid(motion): return
	_update_camera(delta)
	var id: String = motion.pending_station if not motion.pending_station.is_empty() else motion.station
	status.text = tr("MOVING TO STATION") if not motion.pending_station.is_empty() else tr(TITLES.get(id, TITLES.idle))
	if id not in ["idle", "rest"] and motion.pending_station.is_empty():
		status.text += "  /  " + tr("%d CYCLES / %ds") % [motion.repetitions, int(motion.exercise_elapsed)]
	pause_button.text = tr("RESUME MOTION" if motion.playback_paused else "PAUSE MOTION")
	for key in station_buttons: station_buttons[key].disabled = key == id
	if motion.station == "treadmill" and not motion.playback_paused:
		belt_travel = fmod(belt_travel + delta * 0.94 * motion.playback_speed, 0.3)
	for stripe in $Environment/Equipment/Treadmill/BeltMarks.get_children():
		stripe.position.z = -0.9 + fmod(float(stripe.get_index()) * 0.3 - belt_travel + 1.8, 1.8)

func _update_camera(delta: float) -> void:
	if auto_orbit and not motion.playback_paused: yaw += delta * 0.18
	# Horizontal floor-level focus prevents seated pelvis displacement from sinking the view.
	var target := Vector3(actor.position.x, 1.0, actor.position.z)
	camera_focus = camera_focus.lerp(target, 1.0 - exp(-delta * 5.0)) if delta > 0.0 else target
	var offset := Vector3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation)) * distance
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var focus := camera_focus - right * 0.52
	camera.position = focus + offset
	camera.look_at(focus)
