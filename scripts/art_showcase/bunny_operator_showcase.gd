extends Node3D
## Isolated art review only. No PlayerController, inventory, combat or save calls.
@export var model_path := "res://assets/characters/bunny_operator_v1/bunny_operator.glb"
var model: Node3D
var camera: Camera3D
var status: Label
var yaw := 0.0
var rotating := false
var review_fixture := false

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--model="):
			model_path = argument.trim_prefix("--model=")
			review_fixture = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("151923")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c6d5e6")
	environment.environment.ambient_light_energy = .55
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -28, 0)
	key.light_energy = 1.65
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 132, 0)
	fill.light_color = Color("b9cae0")
	fill.light_energy = .65
	add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "ReviewGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40,40)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("363a44")
	material.roughness = .85
	floor_mesh.material_override = material
	add_child(floor_mesh)
	camera = Camera3D.new()
	camera.name = "ReviewCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.near = .01
	add_child(camera)
	_build_controls()
	if not ResourceLoader.exists(model_path):
		status.text = "BLOCKED / UNIFIED GENERATED MODEL NOT AVAILABLE\nNo existing character is substituted."
		push_warning(status.text)
		return
	var packed := load(model_path) as PackedScene
	if not packed:
		status.text = "FAILED / Input is not an imported model scene"
		push_error(status.text)
		return
	model = packed.instantiate() as Node3D
	model.name = "ReviewedModel"
	add_child(model)
	status.text = "PIPELINE FIXTURE / EXISTING CHARACTER — NOT THE NEW OPERATOR" if review_fixture else "BUNNY OPERATOR / VISUAL REVIEW REQUIRED"
	view("FRONT")

func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var surface := Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(surface)
	status = Label.new()
	status.position = Vector2(24,20)
	status.add_theme_font_size_override("font_size",18)
	surface.add_child(status)
	var hint := Label.new()
	hint.text = "Front / Right / Back / Actual battle camera   •   RMB: orbit   •   Wheel: zoom"
	hint.position = Vector2(24,52)
	hint.add_theme_font_size_override("font_size",14)
	surface.add_child(hint)
	var controls := HBoxContainer.new()
	controls.position = Vector2(24,84)
	surface.add_child(controls)
	for title in ["FRONT", "RIGHT", "BACK", "GAME"]:
		var button := Button.new()
		button.text = title
		button.custom_minimum_size = Vector2(112,38)
		button.pressed.connect(view.bind(title))
		controls.add_child(button)

func view(title: String) -> void:
	camera.size = 2.7
	match title:
		"FRONT": camera.position = Vector3(0,1.025,-4); yaw = PI
		"RIGHT": camera.position = Vector3(4,1.025,0); yaw = PI*.5
		"BACK": camera.position = Vector3(0,1.025,4); yaw = 0
		"GAME":
			camera.size = 19.5
			camera.position = Vector3(0,.85,0) + Vector3(0,18.2,13.7)
			camera.look_at(Vector3(0,.85,0))
			return
	camera.look_at(Vector3(0,1.025,0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT: rotating = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			camera.size = clampf(camera.size + (-.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else .2), 1.2, 24)
	elif event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x*.008
		camera.position = Vector3(sin(yaw)*4,1.025,cos(yaw)*4)
		camera.look_at(Vector3(0,1.025,0))
