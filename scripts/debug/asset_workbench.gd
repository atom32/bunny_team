@tool
class_name AssetWorkbench
extends Node3D
## Runs inside an editor-owned SubViewport or an isolated F6 scene, never a game actor.
const REVIEW := preload("res://addons/neon_content/asset_review.gd")
var model: Node3D
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var report: Dictionary = {}
var profile: PresentationProfile
var paused := true
var speed := 1.0
var looping := true
var current_clip: StringName
var preview_time := 0.0
var clip_picker: OptionButton
var preset_picker: OptionButton
var camera_picker: OptionButton
var bone_checkbox: CheckBox
var timeline: HSlider
var clock: Label
var details: TextEdit
var bone_picker: OptionButton
var bone_mesh: MeshInstance3D
var root_mesh: MeshInstance3D
var motion_points := PackedVector3Array()
var show_bones := false:
	set(value):
		show_bones = value
		if bone_checkbox: bone_checkbox.set_pressed_no_signal(value)
var picker: FileDialog
var picker_mode := "model"

func _ready() -> void:
	# An edited scene is not a preview. Only the plugin's isolated viewport runs it.
	if Engine.is_editor_hint() and not get_meta("neon_asset_preview",false): return
	_build_ui()
	load_profile("res://resources/presentation/subjects/campus_subject_profile.tres")

func load_profile(path: String) -> bool:
	var candidate := load(path) as PresentationProfile
	if not candidate or not candidate.validate_profile(): return false
	if not load_model(candidate.model): return false
	profile = candidate
	if preset_picker:
		preset_picker.select(1 if profile.target_demographic == "adult female" else (0 if profile.target_demographic == "adult male" else -1))
	get_node("Mount").rotation.y = profile.forward_yaw
	get_node("Mount").scale = Vector3.ONE * profile.model_scale
	attach_library(profile.animation_library)
	_refresh_details()
	set_camera(0)
	return true

func load_model(scene: PackedScene) -> bool:
	var analysis: Dictionary = REVIEW.inspect(scene)
	if not analysis.pass:
		if details: details.text = "REJECTED\n" + "\n".join(analysis.errors)
		return false
	if is_instance_valid(model): model.free()
	profile = null; report = analysis
	model = scene.instantiate() as Node3D
	get_node("Mount").scale = Vector3.ONE
	get_node("Mount").rotation.y = PI
	var skeletons := model.find_children("*","Skeleton3D",true,false)
	skeleton = model if model is Skeleton3D else (skeletons[0] as Skeleton3D if not skeletons.is_empty() else null)
	var players := model.find_children("*","AnimationPlayer",true,false)
	animation_player = players[0] as AnimationPlayer if not players.is_empty() else null
	if not animation_player:
		animation_player = AnimationPlayer.new(); model.add_child(animation_player)
	# Sanitize every embedded player before entering the tree, not just the first.
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
		player.autoplay = ""
		player.stop()
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for name in player.get_animation_library_list():
			var library := player.get_animation_library(name)
			player.remove_animation_library(name)
			player.add_animation_library(name, _safe_library(library))
	for tree: AnimationTree in model.find_children("*","AnimationTree",true,false): tree.active = false
	get_node("Mount").add_child(model)
	_refresh_clips(); _refresh_bones(); _refresh_details(); set_camera(0)
	return true

func attach_library(library: AnimationLibrary) -> void:
	if not library or not animation_player: return
	for name in animation_player.get_animation_library_list(): animation_player.remove_animation_library(name)
	animation_player.add_animation_library("", _safe_library(library))
	_refresh_clips()

func _safe_library(source: AnimationLibrary) -> AnimationLibrary:
	var result := AnimationLibrary.new()
	for name in source.get_animation_list(): result.add_animation(name, REVIEW.safe_copy(source.get_animation(name)))
	return result

func select_clip(name: StringName) -> bool:
	if not animation_player or not animation_player.has_animation(name): return false
	current_clip = name
	preview_time = 0.0
	for index in clip_picker.item_count:
		if clip_picker.get_item_text(index) == String(name): clip_picker.select(index); break
	animation_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	animation_player.play(name); animation_player.seek(0, true); animation_player.advance(0)
	timeline.max_value = animation_player.get_animation(name).length
	motion_points.clear()
	_refresh_details()
	return true

func seek(at: float) -> void:
	if current_clip.is_empty(): return
	preview_time = clampf(at, 0, timeline.max_value)
	if animation_player.current_animation.is_empty(): animation_player.play(current_clip)
	animation_player.seek(preview_time, true); animation_player.advance(0)
	_update_lines()

func set_paused(value: bool) -> void:
	if not value and current_clip.is_empty() and clip_picker and clip_picker.item_count > 0:
		select_clip(clip_picker.get_item_text(maxi(clip_picker.selected,0)))
	paused = value

func _process(delta: float) -> void:
	if not is_instance_valid(animation_player): return
	if not paused and not current_clip.is_empty():
		animation_player.advance(delta * speed)
		preview_time = animation_player.current_animation_position if not animation_player.current_animation.is_empty() else timeline.max_value
	if timeline: timeline.set_value_no_signal(preview_time)
	if clock: clock.text = "%.2f / %.2fs   %s   %.2fx" % [preview_time, timeline.max_value, "PAUSED" if paused else "PLAY", speed]
	_update_lines()

func _update_lines() -> void:
	if not skeleton or not skeleton.is_inside_tree(): return
	var mesh := ImmediateMesh.new()
	if show_bones:
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for index in skeleton.get_bone_count():
			var parent := skeleton.get_bone_parent(index)
			if parent < 0: continue
			mesh.surface_add_vertex(to_local(skeleton.to_global(skeleton.get_bone_global_pose(parent).origin)))
			mesh.surface_add_vertex(to_local(skeleton.to_global(skeleton.get_bone_global_pose(index).origin)))
		mesh.surface_end()
	bone_mesh.mesh = mesh
	var root_index := bone_picker.selected
	if root_index >= 0 and root_index < skeleton.get_bone_count():
		var at := to_local(skeleton.to_global(skeleton.get_bone_global_pose(root_index).origin))
		if motion_points.is_empty() or motion_points[-1].distance_to(at) > .002:
			motion_points.append(at)
			if motion_points.size() > 600: motion_points.remove_at(0)
	var trace := ImmediateMesh.new()
	if motion_points.size() > 1:
		trace.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for point in motion_points: trace.surface_add_vertex(point)
		trace.surface_end()
	root_mesh.mesh = trace

func set_camera(index: int) -> void:
	if camera_picker: camera_picker.select(index)
	var camera := get_node("Camera") as Camera3D
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var bounds: Dictionary = report.get("bounds", {"position": [0,0,0], "size": [1,2,1]})
	var size: Array = bounds.size
	var origin: Array = bounds.position
	var focus: Vector3 = get_node("Mount").transform * (Vector3(origin[0],origin[1],origin[2]) + Vector3(size[0],size[1],size[2]) * .5)
	var height := maxf(float(size[1]) * get_node("Mount").scale.y, .5)
	if index == 3:
		camera.size = 19.5; camera.position = Vector3(0,19.05,13.7); camera.look_at(Vector3.UP*.85)
	else:
		camera.size = height * 1.65
		camera.position = focus + [Vector3(0,height*.1,-5), Vector3(5,height*.1,0), Vector3(0,height*.1,5)][index]
		camera.look_at(focus)

func _refresh_clips() -> void:
	clip_picker.clear(); current_clip = &""
	for name in animation_player.get_animation_list(): clip_picker.add_item(name)
	if clip_picker.item_count > 0:
		select_clip(profile.semantic_clips[&"idle"] if profile else (&"Idle" if animation_player.has_animation("Idle") else StringName(clip_picker.get_item_text(0))))

func _refresh_bones() -> void:
	bone_picker.clear()
	if skeleton:
		for index in skeleton.get_bone_count(): bone_picker.add_item(skeleton.get_bone_name(index))
		var hip := skeleton.find_bone("pelvis")
		bone_picker.select(hip if hip >= 0 else 0)
	motion_points.clear()

func _refresh_details() -> void:
	if not details: return
	var lines := PackedStringArray(["REST AABB / model-local, not animated envelope", JSON.stringify(report.get("bounds", {})), "%s meshes / %s surfaces / %s triangles" % [report.get("meshes",0),report.get("surfaces",0),report.get("triangles",0)], "Origin/scale/facing and foot/hand contact require visual review."])
	if profile:
		lines.append("PROFILE: " + String(profile.id))
		lines.append("Source: " + profile.source_url)
		lines.append("Licence: " + profile.license_ref)
		for semantic in profile.semantic_clips: lines.append("%s -> %s" % [semantic, profile.semantic_clips[semantic]])
	if not current_clip.is_empty():
		var clip: Dictionary = REVIEW.clip_report(animation_player.get_animation(current_clip), current_clip)
		lines.append("\nCLIP %.2fs / %d tracks" % [clip.duration, clip.tracks.size()])
		lines.append("Loop gap (source tracks): %.3fm / %.2fdeg" % [clip.max_position_loop_gap, clip.max_rotation_loop_gap_degrees])
		for track in clip.tracks:
			if track.has("delta"): lines.append("Local displacement " + track.path + " " + JSON.stringify(track.delta))
	for sk in report.get("skeletons", []):
		lines.append("\nSKELETON " + sk.path)
		for bone in sk.bones: lines.append("%s / parent %d / rest %s" % [bone.name, bone.parent, JSON.stringify(bone.rest_position)])
	details.text = "\n".join(lines)

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new(); button.text=text; button.pressed.connect(action); parent.add_child(button)

func _choose(mode: String) -> void:
	picker_mode = mode; picker.clear_filters()
	if mode == "model": picker.add_filter("*.glb,*.gltf,*.tscn", "Imported model / script-free wrapper")
	else: picker.add_filter("*.tres", "AnimationLibrary / PresentationProfile")
	picker.popup_centered(Vector2i(850, 550))

func _picked(path: String) -> void:
	if picker_mode == "profile": load_profile(path)
	elif picker_mode == "library": attach_library(load(path) as AnimationLibrary)
	else: load_model(load(path) as PackedScene)

func _build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var panel := PanelContainer.new(); panel.position = Vector2(12,12); panel.custom_minimum_size=Vector2(390,0); layer.add_child(panel)
	var margin := MarginContainer.new(); panel.add_child(margin)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,10)
	var column := VBoxContainer.new(); margin.add_child(column)
	var title := Label.new(); title.text="NEON / MODEL + ANIMATION REVIEW"; column.add_child(title)
	preset_picker = OptionButton.new(); column.add_child(preset_picker)
	preset_picker.add_item("Adult male / containment subject")
	preset_picker.add_item("Adult female / motion reference")
	preset_picker.item_selected.connect(func(index:int):load_profile("res://resources/presentation/" + ("subjects" if index == 0 else "subjects_female") + "/campus_subject_profile.tres"))
	var row := HBoxContainer.new(); column.add_child(row)
	_button(row,"Model",func():_choose("model")); _button(row,"Library",func():_choose("library")); _button(row,"Profile",func():_choose("profile"))
	clip_picker=OptionButton.new(); column.add_child(clip_picker); clip_picker.item_selected.connect(func(index:int):select_clip(clip_picker.get_item_text(index)))
	row=HBoxContainer.new(); column.add_child(row)
	_button(row,"Play / pause",func():set_paused(not paused)); _button(row,"Rest pose",_rest_pose)
	var loop:=CheckBox.new(); loop.text="Loop (preview copy only)"; loop.button_pressed=true; column.add_child(loop)
	loop.toggled.connect(_set_loop)
	var rate:=SpinBox.new(); rate.min_value=.1; rate.max_value=3; rate.step=.1; rate.value=1; rate.prefix="Speed "; column.add_child(rate); rate.value_changed.connect(func(value:float):speed=value)
	timeline=HSlider.new(); timeline.step=.01; column.add_child(timeline); timeline.value_changed.connect(seek)
	clock=Label.new(); column.add_child(clock)
	camera_picker=OptionButton.new(); column.add_child(camera_picker)
	for text in ["Front","Side","Back","Production camera / 19.5"]: camera_picker.add_item(text)
	camera_picker.item_selected.connect(set_camera)
	bone_checkbox=CheckBox.new(); bone_checkbox.text="Show bone lines"; column.add_child(bone_checkbox); bone_checkbox.toggled.connect(func(value:bool):show_bones=value)
	bone_picker=OptionButton.new(); column.add_child(bone_picker); bone_picker.item_selected.connect(func(_i:int):motion_points.clear())
	details=TextEdit.new(); details.editable=false; details.custom_minimum_size=Vector2(370,260); details.add_theme_font_size_override("font_size",13); column.add_child(details)
	picker=FileDialog.new(); picker.access=FileDialog.ACCESS_RESOURCES; picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	add_child(picker); picker.file_selected.connect(_picked)
	for entry in [["BoneLines",Color("56dbc7")],["RootMotion",Color("f4c763")]]:
		var mesh:=MeshInstance3D.new(); mesh.name=entry[0]; mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material:=StandardMaterial3D.new(); material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; material.albedo_color=entry[1]; material.no_depth_test=true
		mesh.material_override=material; add_child(mesh)
	bone_mesh=get_node("BoneLines"); root_mesh=get_node("RootMotion")

func _rest_pose() -> void:
	if animation_player: animation_player.stop()
	if skeleton: skeleton.reset_bone_poses()
	current_clip = &""
	preview_time = 0.0
	set_paused(true)
	motion_points.clear()

func _set_loop(value: bool) -> void:
	looping = value
	if animation_player and not current_clip.is_empty():
		animation_player.get_animation(current_clip).loop_mode = Animation.LOOP_LINEAR if value else Animation.LOOP_NONE
