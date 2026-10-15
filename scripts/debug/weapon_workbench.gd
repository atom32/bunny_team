class_name WeaponWorkbench
extends Node3D
## Local presentation sandbox. Definition edits are copies; no profile/session is published.
@export_enum("Pistol", "SMG", "Assault rifle", "Shotgun", "Sniper", "LMG", "RPG") var selected_index := 2
const IDS := [&"weapon.pistol_01", &"weapon.smg_01", &"weapon.assault_rifle_01", &"weapon.shotgun_01", &"weapon.sniper_01", &"weapon.lmg_01", &"weapon.rocket_launcher_01"]
var actor: PlayerController
var definition: WeaponDefinition
var paused := false
var motion := 0
var speed := 1.0
var elapsed := 0.0
var markers := true
var summary: Label
var choices: OptionButton
var damage: SpinBox
var reload_time: SpinBox
var status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_node("ModelPreview").hide()
	actor = load("res://scenes/player/player.tscn").instantiate() as PlayerController
	actor.preview_mode = true
	add_child(actor)
	actor.set_process(false)
	select_weapon(selected_index)
	_build_ui()
	set_camera(0)

func select_weapon(index: int) -> bool:
	if index < 0 or index >= IDS.size(): return false
	var source := ContentDB.get_weapon(IDS[index], false)
	if not source: return false
	selected_index = index
	definition = source.duplicate() as WeaponDefinition
	actor.equip_weapon(definition)
	actor.aim_direction = Vector3.FORWARD
	actor.aim_world_point = Vector3(0,1.25,-8)
	get_node("Target").reset()
	_add_markers()
	if damage:
		damage.set_value_no_signal(definition.damage)
		reload_time.set_value_no_signal(definition.reload_seconds)
	return true

func fire() -> bool:
	return actor.debug_fire_once() if not paused else false

func reload_preview() -> bool:
	if paused or not actor.combat_rig: return false
	actor.combat_rig.reload_duration = definition.reload_seconds
	return actor.combat_rig.start_reload()

func dodge_preview() -> void:
	if not paused: actor._dodge_time = .55

func set_paused(value: bool) -> void:
	paused=value
	actor.process_mode=Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

func advance_preview(delta: float) -> void:
	if paused: return
	var dt := delta * speed
	elapsed += dt
	actor._dodge_time = maxf(0, actor._dodge_time-dt)
	actor.body_visual.rotation.y = 0
	actor.velocity = Vector3.FORWARD * (0.0 if motion == 0 else (3.5 if motion == 1 else 7.8))
	var state: StringName = &"Dodge" if actor._dodge_time > 0 else ([&"Idle", &"Walk", &"Run"][motion])
	if actor.locomotion_playback.get_current_node() != state: actor.locomotion_playback.travel(state)
	actor.animation_tree.advance(dt)
	actor.combat_rig.update_pose(actor.aim_world_point, actor.aim_direction, clampf(actor._dodge_time/.55,0,1), dt, true)
	actor.animation_source_skeleton.advance(dt)
	actor.combat_rig.apply_skeleton_ik(dt)

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	advance_preview(delta)
	if summary:
		summary.text = "%s\nDamage %.1f / Mag %d / Reload %.2fs\n%s\nGrips: cyan / muzzle: red\nCOPY ONLY — edit production data in YARD." % [definition.id, definition.damage, definition.magazine_capacity, definition.reload_seconds, definition.scene.resource_path]
		status.text = "Target hits %d / damage %.1f\nRig %s / clock %.2fs%s" % [get_node("Target").hits, get_node("Target").total_damage, actor.combat_rig.get_upper_body_state_name(), elapsed, " / PAUSED" if paused else ""]

func _add_markers() -> void:
	var weapon := actor.combat_rig.equipped_weapon
	if not is_instance_valid(weapon): return
	for title in ["PrimaryGrip", "SupportGrip", "ReloadGrip", "Muzzle"]:
		var mount := weapon.get_node_or_null(title) as Marker3D
		if not mount: continue
		var dot := MeshInstance3D.new()
		dot.name = "WorkbenchMarker"
		var sphere := SphereMesh.new()
		sphere.radius=.018; sphere.height=.036
		dot.mesh=sphere
		var material := StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color=Color("ff6b63") if title == "Muzzle" else Color("54dfd4")
		dot.material_override=material
		dot.visible=markers
		mount.add_child(dot)

func set_markers(value: bool) -> void:
	markers=value
	for dot in actor.find_children("WorkbenchMarker", "MeshInstance3D", true, false): dot.visible=value

func set_camera(index: int) -> void:
	var camera := get_node("Camera") as Camera3D
	get_node("Target").visible = index == 3
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	var focus := Vector3(0,1.05,0)
	if index == 3:
		camera.size=19.5
		camera.position=Vector3(0,18.2,13.7)+Vector3.UP*.85
		camera.look_at(Vector3.UP*.85)
	else:
		camera.size=3.4
		camera.position=[Vector3(-.4,1.5,-4.5), Vector3(4,1.5,.1), Vector3(.4,1.5,4.5)][index]
		camera.look_at(focus)

func _button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new(); button.text=text; button.pressed.connect(callback); parent.add_child(button)

func _build_ui() -> void:
	var layer := CanvasLayer.new();add_child(layer)
	var panel := PanelContainer.new();panel.position=Vector2(16,16);panel.custom_minimum_size=Vector2(330,0);layer.add_child(panel)
	var margin := MarginContainer.new();panel.add_child(margin)
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	var column := VBoxContainer.new();margin.add_child(column)
	var heading := Label.new();heading.text="NEON / WEAPON WORKBENCH";column.add_child(heading)
	choices=OptionButton.new()
	for id in IDS: choices.add_item(ContentDB.get_weapon(id).display_name)
	choices.select(selected_index);choices.item_selected.connect(select_weapon);column.add_child(choices)
	summary=Label.new();summary.custom_minimum_size=Vector2(300,0);summary.add_theme_font_size_override("font_size",14);summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(summary)
	var views := OptionButton.new()
	for text in ["Front", "Side", "Back", "Actual battle scale"]: views.add_item(text)
	views.item_selected.connect(set_camera);column.add_child(views)
	var animations := OptionButton.new()
	for text in ["Idle", "Walk in place", "Run in place"]: animations.add_item(text)
	animations.item_selected.connect(func(index: int): motion=index);column.add_child(animations)
	var actions := HBoxContainer.new();column.add_child(actions)
	_button(actions,"Fire / real hit",fire)
	_button(actions,"Reload pose",reload_preview)
	var poses := HBoxContainer.new();column.add_child(poses)
	_button(poses,"Dodge pose",dodge_preview)
	_button(poses,"Pause / continue",func(): set_paused(not paused))
	_button(column,"Reset target",func(): get_node("Target").reset())
	var toggle := CheckBox.new();toggle.text="Show grip/muzzle markers";toggle.button_pressed=markers;toggle.toggled.connect(set_markers);column.add_child(toggle)
	var label := Label.new();label.text="Preview damage / reload time (not saved)";column.add_child(label)
	damage=SpinBox.new();damage.min_value=1;damage.max_value=500;damage.step=1;damage.value=definition.damage
	damage.value_changed.connect(func(value: float): definition.damage=value);column.add_child(damage)
	reload_time=SpinBox.new();reload_time.min_value=.1;reload_time.max_value=10;reload_time.step=.1;reload_time.value=definition.reload_seconds
	reload_time.value_changed.connect(func(value: float): definition.reload_seconds=value);column.add_child(reload_time)
	var playback := SpinBox.new();playback.min_value=.1;playback.max_value=2;playback.step=.1;playback.value=speed
	playback.prefix="Playback x ";playback.value_changed.connect(func(value: float): speed=value);column.add_child(playback)
	status=Label.new();column.add_child(status)
