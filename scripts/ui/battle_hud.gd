class_name BattleHUD
extends CanvasLayer

var inactive_weapon_label: Label
var _banner_remaining := 0.0
var enemy_label: Label
var slice_label: Label
var objective_label: Label
var health_bar: ProgressBar
var health_label: Label
var armor_label: Label
var weapon_label: Label
var ammo_label: Label
var secondary_weapon_label: Label
var secondary_ammo_label: Label
var active_weapon_label: Label
var capacity_label: Label
var medical_label: Label
var medical_progress: ProgressBar
var threat_label: Label
var banner: Label
var reticle: Label
var cover_hint: Label
var impact_dot: Label
var sound_hint: Label
var interaction_prompt: Label
var interaction_feedback: Label
var pharmacy_information: Label
var receipt_information: Label
var damage_flash: ColorRect
var health_fill: StyleBoxFlat
var _damage_flash_tween: Tween
var _feedback_tween: Tween
var _active_weapon_text := "ACTIVE  PRIMARY"
var _inactive_weapon_text := "SWITCH WEAPON"


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIFactory.theme()
	add_child(root)
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.color = Color("ff304000")
	root.add_child(damage_flash)
	var pause_button := Button.new()
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-108, 18)
	pause_button.size = Vector2(90, 28)
	pause_button.text = "ESC / PAUSE"
	pause_button.add_theme_font_size_override("font_size", 12)
	pause_button.pressed.connect(FlowMenu.show_pause)
	root.add_child(pause_button)

	var objectives := _card(root, "Objectives", Control.PRESET_TOP_LEFT, Vector2(18,18), Vector2(310,0))
	objective_label = _line(objectives, "OBJECTIVE", 14, Color("c3d6d9"))
	slice_label = _line(objectives, "", 12, Color("b9d4ff"))
	slice_label.name = "Q01Status"
	slice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slice_label.hide()
	threat_label = _line(objectives, "", 12, Color("ff6b7f"))
	threat_label.hide()
	enemy_label = _line(objectives, "", 12)
	enemy_label.hide()

	var status := _card(root, "Vitals", Control.PRESET_BOTTOM_LEFT, Vector2(18,-120), Vector2(280,102))
	health_label = _line(status, "HP  260 / 260", 13)
	health_bar = ProgressBar.new()
	health_bar.max_value = 260.0
	health_bar.value = 260.0
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(250, 5)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("202a35")
	health_fill = StyleBoxFlat.new()
	health_fill.bg_color = Color("67e6e2")
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	status.add_child(health_bar)
	armor_label = _line(status, "", 11, Color("9badb7"))
	armor_label.name = "ArmorTradeoff"
	capacity_label = _line(status, "", 11, Color("9badb7"))
	medical_label = _line(status, "", 12, Color("92ead7"))
	medical_label.name = "MedicalSupplies"
	medical_progress = ProgressBar.new()
	medical_progress.name = "TreatmentProgress"
	medical_progress.custom_minimum_size = Vector2(250, 6)
	medical_progress.show_percentage = false
	medical_progress.hide()
	status.add_child(medical_progress)

	var weapons := _card(root, "Weapons", Control.PRESET_BOTTOM_RIGHT, Vector2(-318,-130), Vector2(300,112))
	active_weapon_label = _line(weapons, "PRIMARY", 11, Color("9badb7"))
	weapon_label = _line(weapons, "ASSAULT RIFLE", 14, Color("c3d6d9"))
	ammo_label = _line(weapons, "30 / 90", 20, Color("f1d98a"))
	secondary_weapon_label = _line(weapons, "SMG", 14, Color("c3d6d9"))
	secondary_ammo_label = _line(weapons, "", 20, Color("f1d98a"))
	secondary_weapon_label.hide()
	secondary_ammo_label.hide()
	inactive_weapon_label = _line(weapons, "Q / SWITCH WEAPON", 11, Color("9badb7"))

	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-240, 20)
	banner.size = Vector2(480, 52)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_font_size_override("font_size", 18)
	banner.add_theme_color_override("font_outline_color", Color("172125"))
	banner.add_theme_constant_override("outline_size", 3)
	banner.hide()
	root.add_child(banner)

	reticle = Label.new()
	reticle.text = "+"
	reticle.size = Vector2(24,28)
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle.add_theme_font_size_override("font_size", 22)
	reticle.add_theme_color_override("font_color", Color("dffaffb8"))
	root.add_child(reticle)
	cover_hint = _line(root, "MUZZLE / COVER", 12, Color("ffd08a"))
	cover_hint.name = "CoverHint"
	cover_hint.size = Vector2(210, 24)
	cover_hint.hide()
	impact_dot = _line(root, "×", 19, Color("ffd08a"))
	impact_dot.name = "CenterlineImpact"
	impact_dot.size = Vector2(20, 26)
	impact_dot.hide()
	sound_hint = _line(root, "", 13, Color("f0d3a1"))
	sound_hint.name = "SoundBearing"
	sound_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sound_hint.offset_left = -180
	sound_hint.offset_right = 180
	sound_hint.offset_top = 82
	sound_hint.offset_bottom = 110
	sound_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sound_hint.hide()
	interaction_prompt = Label.new()
	interaction_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_prompt.position = Vector2(-260,-58)
	interaction_prompt.size = Vector2(520,28)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 15)
	interaction_prompt.add_theme_color_override("font_color", Color("c9fbff"))
	root.add_child(interaction_prompt)
	interaction_feedback = Label.new()
	interaction_feedback.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_feedback.position = Vector2(-260,-90)
	interaction_feedback.size = Vector2(520,28)
	interaction_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_feedback.add_theme_font_size_override("font_size", 15)
	interaction_feedback.hide()
	root.add_child(interaction_feedback)

func _card(root: Control, title: String, anchor: int, at: Vector2, minimum: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = title
	root.add_child(panel)
	panel.set_anchors_preset(anchor)
	panel.offset_left = at.x
	panel.offset_top = at.y
	panel.offset_right = at.x + minimum.x
	panel.offset_bottom = at.y + minimum.y
	panel.custom_minimum_size = minimum
	if anchor in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT]:
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UIFactory.panel_style(Color("111a2699"), Color("4f718b44"))
	for edge in ["left", "right", "top", "bottom"]: style.set("content_margin_"+edge, 10.0)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	return box

func _line(parent: Control, text: String, font_size: int, color := Color("c3d6d9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _process(_delta: float) -> void:
	inactive_weapon_label.text = ControlBindings.label("switch_weapon") + " / " + _inactive_weapon_text
	if _banner_remaining > 0.0:
		_banner_remaining = maxf(0.0, _banner_remaining-_delta)
		if _banner_remaining == 0.0: banner.hide()
	if reticle:
		reticle.position = get_viewport().get_mouse_position() - reticle.size * 0.5


func set_health(current: float, maximum: float) -> void:
	var took_damage := current < health_bar.value
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = tr("HP  %d / %d") % [roundi(current), roundi(maximum)]
	var ratio := current / maximum
	health_fill.bg_color = Color("ff586d") if ratio < 0.3 else Color("67e6e2")
	if took_damage:
		if _damage_flash_tween and _damage_flash_tween.is_valid():
			_damage_flash_tween.kill()
		damage_flash.color = Color("ff30402e")
		_damage_flash_tween = create_tween()
		_damage_flash_tween.tween_property(damage_flash, "color", Color("ff304000"), 0.2)


func set_perception(sensor: PlayerVisibility, camera: Camera3D) -> void:
	var trace := sensor.aim_trace()
	cover_hint.visible = trace.blocked
	cover_hint.position = (reticle.position + Vector2(24, 26)).clamp(Vector2(8, 8), get_viewport().get_visible_rect().size - cover_hint.size - Vector2(8, 8))
	reticle.modulate = Color("ffd08a") if trace.blocked else Color.WHITE
	impact_dot.visible = trace.blocked and not camera.is_position_behind(trace.point)
	if impact_dot.visible:
		impact_dot.position = camera.unproject_position(trace.point) - Vector2(7, 12)
	sound_hint.visible = sensor.heard_remaining > 0.0
	if sound_hint.visible:
		var bearings := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
		var index := posmod(roundi(atan2(sensor.heard_direction.x, sensor.heard_direction.z) / (PI / 4.0)), 8)
		sound_hint.text = tr("HEARD / %s / %s") % [tr("GUNFIRE" if sensor.heard_kind == &"gunfire" else "MOVEMENT"), tr(bearings[index])]
		sound_hint.modulate.a = minf(1.0, sensor.heard_remaining * 2.0)


func set_enemy_count(count: int) -> void:
	enemy_label.text = tr("HOSTILES REMAINING  %02d") % count


func set_threat_level(level: int) -> void:
	var is_alert := level == SortieSession.ThreatLevel.ALERT
	threat_label.visible = is_alert
	threat_label.text = tr("THREAT  %s") % tr("ALERT" if is_alert else "NORMAL")
	threat_label.add_theme_color_override("font_color", Color("ff6b7f") if is_alert else Color("79f1e7"))


func set_objective_progress(display_name: String, progress: int, target: int, completed: bool) -> void:
	set_objectives([{
		"display_name": display_name,
		"progress": progress,
		"target": target,
		"completed": completed,
	}])


func set_objectives(objectives: Array[Dictionary]) -> void:
	var lines: Array[String] = []
	for objective in objectives:
		var state_text := "COMPLETE" if bool(objective.get("completed", false)) else tr("%d / %d") % [
			int(objective.get("progress", 0)),
			int(objective.get("target", 1)),
		]
		if bool(objective.get("completed", false)): continue
		lines.append(tr("%s  %s") % [tr(str(objective.get("display_name", "Unknown"))).to_upper(), tr(state_text)])
	objective_label.text = "\n".join(lines) if not lines.is_empty() else "OBJECTIVE COMPLETE / REACH EXTRACTION"


func set_weapon(display_name: String) -> void:
	weapon_label.text = GameLanguage.item_name(display_name).to_upper()


func set_ammo(magazine: int, magazine_capacity: int, reserve: int) -> void:
	ammo_label.text = tr("%d / %d   ·   %d RESERVE") % [magazine, magazine_capacity, reserve]


func set_weapon_slots(primary: Dictionary, secondary: Dictionary, active_slot: StringName) -> void:
	var primary_active := active_slot == LoadoutState.SLOT_WEAPON_PRIMARY
	weapon_label.text = tr("PRIMARY  %s") % GameLanguage.item_name(str(primary.get("display_name", "UNARMED"))).to_upper()
	ammo_label.text = tr("%d / %d   ·   %d RESERVE") % [
		int(primary.get("magazine", 0)),
		int(primary.get("magazine_capacity", 0)),
		int(primary.get("reserve", 0)),
	]
	secondary_weapon_label.text = tr("SECONDARY  %s") % GameLanguage.item_name(str(secondary.get("display_name", "UNARMED"))).to_upper()
	secondary_ammo_label.text = tr("%d / %d   ·   %d RESERVE") % [
		int(secondary.get("magazine", 0)),
		int(secondary.get("magazine_capacity", 0)),
		int(secondary.get("reserve", 0)),
	]
	weapon_label.visible = primary_active
	ammo_label.visible = primary_active
	secondary_weapon_label.visible = not primary_active
	secondary_ammo_label.visible = not primary_active
	_inactive_weapon_text = GameLanguage.item_name(str((secondary if primary_active else primary).get("display_name", "UNARMED"))).to_upper()
	inactive_weapon_label.text = ControlBindings.label("switch_weapon") + " / " + _inactive_weapon_text
	_active_weapon_text = tr("ACTIVE  %s") % tr("PRIMARY" if primary_active else "SECONDARY")
	active_weapon_label.text = _active_weapon_text
	weapon_label.add_theme_color_override("font_color", Color("70edf2") if primary_active else Color("8da8bb"))
	ammo_label.add_theme_color_override("font_color", Color("f1d98a") if primary_active else Color("a9c4d4"))
	secondary_weapon_label.add_theme_color_override("font_color", Color("8da8bb") if primary_active else Color("70edf2"))
	secondary_ammo_label.add_theme_color_override("font_color", Color("a9c4d4") if primary_active else Color("f1d98a"))


func set_reload_remaining(seconds: float) -> void:
	active_weapon_label.text = _active_weapon_text + (tr(" / RELOADING %.1fs") % seconds if seconds > 0.0 else "")


func set_inventory_capacity(used: float, maximum: float) -> void:
	capacity_label.text = tr("CARGO  %.1f / %.1f") % [used, maximum]


func set_medical(treatment: MedicalTreatment) -> void:
	medical_progress.visible = treatment.is_active()
	var definition := treatment.definition()
	if definition:
		medical_label.text = tr("TREATING / %.1fs / stay still") % treatment.remaining
		medical_progress.max_value = definition.use_seconds
		medical_progress.value = definition.use_seconds - treatment.remaining
	else:
		medical_label.text = tr("%s / DRESSING %d   %s / MEDKIT %d") % [ControlBindings.label("use_dressing"), treatment.count(MedicalTreatment.IDS[0]), ControlBindings.label("use_medkit"), treatment.count(MedicalTreatment.IDS[1])]


func set_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text


func show_interaction_feedback(text: String, success: bool) -> void:
	if text.is_empty():
		return
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()
	interaction_feedback.text = text
	interaction_feedback.modulate = Color.WHITE
	interaction_feedback.add_theme_color_override("font_color", Color("79f1e7") if success else Color("ffbd72"))
	interaction_feedback.visible = true
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(1.5)
	_feedback_tween.tween_property(interaction_feedback, "modulate:a", 0.0, 0.35)
	_feedback_tween.tween_callback(func() -> void: interaction_feedback.visible = false)


func show_banner(text: String, color: Color) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	_banner_remaining = 3.0


func set_armor_stats(mobility: float, protection: float, weight: float) -> void:
	armor_label.text = tr("%.1f m/s  ·  %.0f%% protection  ·  %.1f kg armor") % [mobility, protection * 100.0, weight]
