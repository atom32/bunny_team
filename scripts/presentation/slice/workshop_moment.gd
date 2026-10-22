extends Node3D
## A replayable homecoming, after the existing upgrade transaction has saved.
## Props, gestures and dialogue are presentation only: no rewards or new save fields.
const IDLE := preload("res://scripts/presentation/slice/hideout_idle.gd")
const INTRO := [
	"Tang Kui, on the radio: Not the big wrench. Put it down. The little one.",
	"Shen, outside: She just got home. Let her have some water first.",
	"Tang Kui: It is one screw.\nSu Mi: Then why are there two on the bench?",
]
const ENDING := "Shen: If it is fixed, come and eat.\nTang Kui: Give her another minute.\nSu Mi: You have packed the tools away twice.\nTang Kui: ...She came back. Let me fuss a little."
const BENCH := Vector3(-1.38, 0, -0.6)
const WORK_HAND := Vector3(-1.29, 1.08, -0.94)
const BRACE_HAND := Vector3(-1.62, 1.03, -0.95)
const SPARE := Vector3(-1.22, 0.83, -0.98)
const TRAY := Vector3(-1.48,0.83,-0.96)
var actor: PlayerController
var motion: Node
var camera: Camera3D
var screen: Control
var dialogue: Label
var status: Label
var choices: Control
var exits: Control
var next_button: Button
var tool: Node3D
var bolt: Node3D
var lamp: MeshInstance3D
var phase := "approach"
var phase_elapsed := 0.0
var line_index := 0
var branch := ""
var leaving := false
var eligible := false
var right_target := WORK_HAND
var reach_weight := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_music_context(&"hideout")
	eligible = ProfileRuntime.get_profile().ar_damage_upgraded
	actor = preload("res://scenes/player/player.tscn").instantiate()
	actor.preview_mode = true
	add_child(actor)
	motion = IDLE.new()
	add_child(motion)
	motion.bind(actor)
	motion.set_relaxed(true)
	motion.destination_section = "Workshop"
	actor.position = Vector3(-0.8, 0, 0.8)
	actor.body_visual.rotation.y = 0.0
	motion.route.assign([Vector3(-1.38, 0, 0.8), BENCH])
	motion._begin_walk()
	motion.set_process(false) # This scene advances motion before its hand-contact layer.
	camera = $Camera3D
	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.2,1.65,0.2)
	fill.light_energy = 0.6 if RenderingServer.get_current_rendering_method() == "forward_plus" else 0.15
	fill.omni_range = 3.0
	add_child(fill)
	_build_props()
	_build_ui()
	if not eligible:
		phase = "locked"
		motion.route.clear()
		motion.phase = "idle"
	_refresh_language()
	GameLanguage.language_changed.connect(_refresh_language)
	_update_camera(0.0)

func _mesh(parent: Node3D, mesh: Mesh, color: Color, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.55
	material.roughness = 0.45
	node.material_override = material
	parent.add_child(node)
	return node

func _build_props() -> void:
	tool = Node3D.new()
	tool.name = "Driver"
	add_child(tool)
	var handle := CylinderMesh.new()
	handle.top_radius = 0.024; handle.bottom_radius = 0.024; handle.height = 0.105
	_mesh(tool, handle, Color("b65b2c"), Vector3.ZERO)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.006; shaft.bottom_radius = 0.006; shaft.height = 0.12
	_mesh(tool, shaft, Color("a8b8bd"), Vector3(0,-0.11,0))
	tool.position = WORK_HAND
	tool.hide()
	bolt = Node3D.new()
	bolt.name = "SpareBolt"
	add_child(bolt)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.012; stem.bottom_radius = 0.012; stem.height = 0.04
	_mesh(bolt, stem, Color("bdad7e"), Vector3.ZERO)
	var head := CylinderMesh.new()
	head.radial_segments = 6
	head.top_radius = 0.023; head.bottom_radius = 0.023; head.height = 0.012
	_mesh(bolt, head, Color("d7c9a0"), Vector3(0,0.022,0))
	bolt.position = SPARE
	var tray := CylinderMesh.new()
	tray.top_radius = 0.085; tray.bottom_radius = 0.085; tray.height = 0.012
	_mesh(self,tray,Color("50585a"),TRAY-Vector3(0,0.025,0))
	var indicator := SphereMesh.new()
	indicator.radius = 0.018; indicator.height = 0.036
	lamp = _mesh(self, indicator, Color("b65b2c"), Vector3(-1.28,0.93,-1.05))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	screen = SliceUI.root(layer)
	screen.theme = FieldManualStyle.theme()
	var top := SliceUI.panel(screen, Vector2(24,16), Vector2(1232,72))
	top.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	status = SliceUI.label(top, "", Vector2(20,18), 23, FieldManualStyle.INK)
	SliceUI.button(top, "RETURN TO WORKSHOP", Vector2(952,12), Vector2(260,48), func(): return_to_base("Workshop")).name = "SkipWorkshopMoment"
	var bottom := SliceUI.panel(screen, Vector2(24,528), Vector2(1232,176))
	bottom.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	dialogue = SliceUI.label(bottom, "", Vector2(20,12), 19, FieldManualStyle.INK)
	dialogue.size = Vector2(930,152)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_button = SliceUI.button(bottom, "NEXT LINE", Vector2(972,112), Vector2(240,44), advance_line)
	next_button.name = "NextWorkshopLine"
	choices = HBoxContainer.new()
	choices.name = "SpareBoltChoice"
	choices.position = Vector2(24,458)
	choices.add_theme_constant_override("separation",12)
	screen.add_child(choices)
	for id in ["tidy", "tap"]:
		var button := SliceUI.button(choices, "PUT THE SPARE BACK" if id == "tidy" else "TAP THE EXTRA SCREW", Vector2.ZERO, Vector2(350,52), func(): choose_spare(id))
		button.name = "Choice" + id.capitalize()
		button.custom_minimum_size = Vector2(350,52)
	exits = HBoxContainer.new()
	exits.name = "AfterFitting"
	exits.position = Vector2(24,458)
	exits.add_theme_constant_override("separation",12)
	screen.add_child(exits)
	SliceUI.button(exits, "LOOK AT THE NEXT REQUEST", Vector2.ZERO, Vector2(350,52), func(): return_to_base("Operations")).name = "NextRequest"
	SliceUI.button(exits, "TAKE A BREATHER", Vector2.ZERO, Vector2(280,52), func(): return_to_base("Rest")).name = "RestAfterFitting"
	SliceUI.button(exits, "REPLAY THE FITTING", Vector2.ZERO, Vector2(280,52), replay).name = "ReplayFitting"
	for button in exits.get_children(): button.custom_minimum_size = Vector2(320,52)

func _refresh_language() -> void:
	status.text = tr("ONE SPARE SCREW / BACK AT HOME") if eligible else tr("FIRST UPGRADE NOT INSTALLED")
	choices.visible = phase == "choice"
	exits.visible = phase == "done"
	next_button.visible = phase == "intro"
	if phase == "locked": dialogue.text = tr("Bring a core home and install the first upgrade at the workshop. This scene gives no materials or upgrade.")
	elif phase == "approach": dialogue.text = tr("The radio has been calling since you reached the door.")
	elif phase == "intro": dialogue.text = tr(INTRO[line_index])
	elif phase == "choice": dialogue.text = tr("One spare screw. A very quiet radio.")
	elif phase in ["gesture", "fit"]:
		dialogue.text = tr("Tang Kui: Spare. It is a spare!\nSu Mi: You said that last time. Then the cupboard door fell off." if branch == "tap" else "Tang Kui: Thank you. At least somebody is helping.\nSu Mi: I have not even said anything yet.")
	elif phase == "done": dialogue.text = tr(ENDING)
	for button in screen.find_children("*", "Button", true, false):
		var key: String = {"SkipWorkshopMoment":"RETURN TO WORKSHOP", "NextWorkshopLine":"NEXT LINE", "ChoiceTidy":"PUT THE SPARE BACK", "ChoiceTap":"TAP THE EXTRA SCREW", "NextRequest":"LOOK AT THE NEXT REQUEST", "RestAfterFitting":"TAKE A BREATHER", "ReplayFitting":"REPLAY THE FITTING"}.get(button.name, "")
		if not key.is_empty(): button.text = tr(key)

func _enter(value: String) -> void:
	phase = value
	phase_elapsed = 0.0
	_refresh_language()
	if phase == "choice": choices.get_child(0).grab_focus()
	elif phase == "done": exits.get_child(0).grab_focus()

func advance_line() -> void:
	if phase != "intro" or leaving: return
	line_index += 1
	if line_index >= INTRO.size(): _enter("choice")
	else: _enter("intro")

func choose_spare(value: String) -> void:
	if phase != "choice" or value not in ["tidy", "tap"] or leaving: return
	branch = value
	_enter("gesture")

func replay() -> void:
	if phase != "done" or leaving: return
	line_index = 0
	branch = ""
	bolt.position = SPARE
	lamp.material_override.albedo_color = Color("b65b2c")
	_enter("intro")

func return_to_base(section: String) -> void:
	if leaving: return
	GameState.hideout_section = section
	leaving = GameState.present_scene("res://scenes/presentation/slice/hideout.tscn", "BASTION 07 / WELCOME HOME") == OK

func _process(delta: float) -> void:
	if leaving: return
	motion._process(delta)
	phase_elapsed += delta
	if phase == "approach" and motion.phase == "idle": _enter("intro")
	elif phase == "intro" and phase_elapsed >= 4.0: advance_line()
	elif phase == "gesture" and phase_elapsed >= 3.6: _enter("fit")
	elif phase == "fit" and phase_elapsed >= 7.0:
		lamp.material_override.albedo_color = Color("64a98f")
		_enter("done")
	tool.visible = phase == "fit"
	if phase in ["choice", "gesture", "fit"]: _pose_hands()
	_update_camera(delta)

func _pose_hands() -> void:
	var right := WORK_HAND
	var weight := 1.0
	if phase == "gesture":
		weight = smoothstep(0.0,0.5,phase_elapsed) * (1.0-smoothstep(3.0,3.6,phase_elapsed))
		var travel := smoothstep(0.5,3.0,phase_elapsed)
		right = SPARE.lerp(TRAY if branch == "tidy" else SPARE,travel) + Vector3(0,0.19,0)
		right.y += sin(travel*PI) * (0.28 if branch == "tidy" else absf(sin(phase_elapsed*7.0))*0.05)
		if phase_elapsed >= 0.5: bolt.position = right - Vector3(0,0.19,0)
	elif phase == "fit":
		weight = smoothstep(0.0,0.6,phase_elapsed) * (1.0-smoothstep(6.2,7.0,phase_elapsed))
		bolt.position = TRAY if branch == "tidy" else SPARE
		tool.position = right
		tool.rotation.y = sin(phase_elapsed * 5.0) * 0.7
	else: weight = 0.0
	var sk := actor.character_skeleton
	var spine := sk.find_bone("Character1_Spine")
	_set_basis(sk,spine,Basis(Vector3.RIGHT,(-0.5 if phase == "gesture" else -0.32)*weight)*sk.get_bone_global_pose(spine).basis.orthonormalized())
	right_target = right
	reach_weight = weight
	_reach("Right", right, Vector3(1,-0.3,0.3),weight)
	_reach("Left", BRACE_HAND, Vector3(-1,-0.3,0.3),weight)

func _reach(side: String, target: Vector3, pole: Vector3, weight: float) -> void:
	if weight <= 0.0: return
	var sk := actor.character_skeleton
	var upper := sk.find_bone("Character1_"+side+"Arm")
	var elbow := sk.find_bone("Character1_"+side+"ForeArm")
	var hand := sk.find_bone("Character1_"+side+"Hand")
	var root := sk.get_bone_global_pose(upper).origin
	var middle := sk.get_bone_global_pose(elbow).origin
	var tip := sk.get_bone_global_pose(hand).origin
	var goal := tip.lerp(sk.to_local(target),weight)
	var direction := root.direction_to(goal)
	var a := root.distance_to(middle)
	var b := middle.distance_to(tip)
	var d := clampf(root.distance_to(goal),absf(a-b)+0.0001,a+b-0.0001)
	var along := (a*a+d*d-b*b)/(2.0*d)
	var outward := (pole-direction*pole.dot(direction)).normalized()
	var joint := root + direction*along + outward*sqrt(maxf(0,a*a-along*along))
	_rotate_toward(sk,upper,middle-root,joint-root)
	middle = sk.get_bone_global_pose(elbow).origin
	tip = sk.get_bone_global_pose(hand).origin
	_rotate_toward(sk,elbow,tip-middle,goal-middle)

func _rotate_toward(sk: Skeleton3D, index: int, from: Vector3, to: Vector3) -> void:
	var desired := Basis(Quaternion(from.normalized(),to.normalized())) * sk.get_bone_global_pose(index).basis.orthonormalized()
	_set_basis(sk,index,desired)

func _set_basis(sk: Skeleton3D, index: int, desired: Basis) -> void:
	var parent := sk.get_bone_parent(index)
	var local := sk.get_bone_global_pose(parent).basis.inverse()*desired if parent >= 0 else desired
	sk.set_bone_pose_rotation(index,local.get_rotation_quaternion())

func _update_camera(delta: float) -> void:
	var close := phase in ["choice", "gesture", "fit"]
	var destination := Vector3(0.2,1.65,0.55) if close else Vector3(-0.35,1.6,1.5)
	camera.position = camera.position.lerp(destination,1.0-exp(-delta*3.0)) if delta > 0 else destination
	camera.fov = 62.0 if close else 57.0
	camera.look_at(Vector3(-1.42,1.25 if close else 1.08,-0.65))
