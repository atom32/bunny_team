class_name EnemyCharacterDebug
extends Node3D

const RAGDOLL_SCENE := preload("res://scenes/player/ragdoll_proxy.tscn")

var humanoid_visual: HumanoidRetargetVisual
var camera: Camera3D
var info_label: Label
var pause_button: Button
var speed_button: Button
var ragdoll: RagdollProxy
var locomotion_state := &"Idle"
var paused := false
var slow_motion := false
var direction_lines: Dictionary = {}


func _ready() -> void:
	AudioDirector.set_music_context(&"debug")
	_build_environment()
	_build_character()
	_build_direction_lines()
	_build_camera()
	_build_ui()
	_set_camera_view(&"Front")


func _process(delta: float) -> void:
	if is_instance_valid(humanoid_visual) and humanoid_visual.visible:
		var movement := -humanoid_visual.global_basis.z.normalized() if locomotion_state != &"Idle" else Vector3.ZERO
		var speed := 3.2 if locomotion_state == &"Run" else (1.2 if locomotion_state == &"Walk" else 0.0)
		var aim_point := humanoid_visual.global_position + Vector3(0.0, 1.05, -8.0)
		humanoid_visual.update_visual(aim_point, movement, speed, delta)
		_update_direction_lines()
		_update_info()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("111820")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8cbd1")
	environment.ambient_light_energy = 0.72
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	key_light.light_color = Color("e9f5ff")
	key_light.light_energy = 1.25
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "EnemyFillLight"
	fill_light.position = Vector3(-1.8, 1.8, -1.6)
	fill_light.light_color = Color("ff5268")
	fill_light.light_energy = 4.0
	fill_light.omni_range = 6.0
	add_child(fill_light)

	var floor_body := StaticBody3D.new()
	floor_body.name = "DebugFloor"
	add_child(floor_body)
	VisualFactory.box(floor_body, Vector3(8.0, 0.08, 8.0), Vector3(0.0, -0.08, 0.0), Color("26323a"), "FloorMesh")
	var collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(8.0, 0.16, 8.0)
	collision.shape = floor_shape
	collision.position.y = -0.08
	floor_body.add_child(collision)


func _build_character() -> void:
	humanoid_visual = HumanoidRetargetVisual.new()
	humanoid_visual.name = "EnemyCharacterVisual"
	add_child(humanoid_visual)
	humanoid_visual.set_debug_locomotion(locomotion_state)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "DebugCamera"
	camera.fov = 35.0
	camera.current = true
	add_child(camera)


func _build_direction_lines() -> void:
	for line_name in [&"Forward", &"Movement", &"Aim", &"Muzzle"]:
		var line := MeshInstance3D.new()
		line.name = "%sDirection" % line_name
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(line)
		direction_lines[line_name] = line


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugUI"
	add_child(layer)
	var root := VBoxContainer.new()
	root.name = "Controls"
	root.position = Vector2(24.0, 20.0)
	root.add_theme_constant_override("separation", 8)
	layer.add_child(root)

	var title := Label.new()
	title.text = "ENEMY CHARACTER DEBUG"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)
	root.add_child(_button_row([&"Front", &"Side", &"Back"], _set_camera_view))
	root.add_child(_button_row([&"Idle", &"Walk", &"Run", &"Death / Ragdoll"], _set_animation_view))

	var playback_row := HBoxContainer.new()
	playback_row.add_theme_constant_override("separation", 6)
	root.add_child(playback_row)
	pause_button = _debug_button("Pause")
	pause_button.pressed.connect(_toggle_pause)
	playback_row.add_child(pause_button)
	speed_button = _debug_button("Speed 1.0x")
	speed_button.pressed.connect(_toggle_speed)
	playback_row.add_child(speed_button)

	info_label = Label.new()
	info_label.name = "DirectionInfo"
	info_label.custom_minimum_size = Vector2(430.0, 120.0)
	info_label.add_theme_font_size_override("font_size", 15)
	root.add_child(info_label)

	var legend := Label.new()
	legend.text = "GREEN Forward   CYAN Movement   YELLOW Aim   RED Muzzle"
	legend.add_theme_color_override("font_color", Color("d8e0e4"))
	root.add_child(legend)


func _button_row(labels: Array[StringName], callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for label_text in labels:
		var button := _debug_button(String(label_text))
		button.pressed.connect(callback.bind(label_text))
		row.add_child(button)
	return row


func _debug_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(86.0, 34.0)
	return button


func _set_camera_view(view_name: StringName) -> void:
	match view_name:
		&"Side":
			camera.position = Vector3(3.8, 1.35, 0.0)
		&"Back":
			camera.position = Vector3(0.0, 1.35, 3.8)
		_:
			camera.position = Vector3(0.0, 1.35, -3.8)
	camera.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)


func _set_animation_view(state: StringName) -> void:
	if state == &"Death / Ragdoll":
		_show_ragdoll()
		return
	_reset_ragdoll()
	locomotion_state = state
	humanoid_visual.set_debug_locomotion(state)


func _toggle_pause() -> void:
	paused = not paused
	humanoid_visual.set_animation_paused(paused)
	pause_button.text = "Resume" if paused else "Pause"


func _toggle_speed() -> void:
	slow_motion = not slow_motion
	var speed_scale := 0.25 if slow_motion else 1.0
	humanoid_visual.set_animation_speed(speed_scale)
	speed_button.text = "Speed 0.25x" if slow_motion else "Speed 1.0x"


func _show_ragdoll() -> void:
	if is_instance_valid(ragdoll):
		return
	humanoid_visual.visible = false
	ragdoll = RAGDOLL_SCENE.instantiate() as RagdollProxy
	add_child(ragdoll)
	ragdoll.global_position = humanoid_visual.global_position
	ragdoll.global_rotation.y = humanoid_visual.global_rotation.y
	ragdoll.build(Color("a83448"), Vector3(0.8, 1.8, -1.2))


func _reset_ragdoll() -> void:
	if is_instance_valid(ragdoll):
		ragdoll.queue_free()
	ragdoll = null
	humanoid_visual.visible = true


func _update_direction_lines() -> void:
	var origin := humanoid_visual.global_position + Vector3.UP * 0.05
	_set_direction_line(direction_lines[&"Forward"], origin, -humanoid_visual.global_basis.z, Color("62e686"), 1.2)
	_set_direction_line(direction_lines[&"Movement"], origin + Vector3.UP * 0.04, humanoid_visual.movement_direction, Color("4ed9f5"), 1.05)
	_set_direction_line(direction_lines[&"Aim"], origin + Vector3.UP * 0.08, humanoid_visual.aim_direction, Color("ffd65a"), 1.35)
	_set_direction_line(
		direction_lines[&"Muzzle"],
		humanoid_visual.get_muzzle_position(),
		humanoid_visual.get_muzzle_direction(),
		Color("ff405b"),
		1.1
	)


func _set_direction_line(line: MeshInstance3D, origin: Vector3, direction: Vector3, color: Color, length: float) -> void:
	var mesh := ImmediateMesh.new()
	if direction.length_squared() > 0.001:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.vertex_color_use_as_albedo = true
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(origin)
		mesh.surface_add_vertex(origin + direction.normalized() * length)
		mesh.surface_end()
	line.mesh = mesh


func _update_info() -> void:
	info_label.text = (
		"State: %s\nCharacter Forward: %s\nMovement Direction: %s\nAim Direction: %s\nWeapon Muzzle Direction: %s"
		% [
			locomotion_state,
			_vector_text(-humanoid_visual.global_basis.z),
			_vector_text(humanoid_visual.movement_direction),
			_vector_text(humanoid_visual.aim_direction),
			_vector_text(humanoid_visual.get_muzzle_direction()),
		]
	)


func _vector_text(value: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z]
