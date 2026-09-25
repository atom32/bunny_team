class_name BattleHUD
extends CanvasLayer

var enemy_label: Label
var objective_label: Label
var health_bar: ProgressBar
var health_label: Label
var weapon_label: Label
var ammo_label: Label
var secondary_weapon_label: Label
var secondary_ammo_label: Label
var active_weapon_label: Label
var capacity_label: Label
var threat_label: Label
var banner: Label
var reticle: Label
var interaction_prompt: Label
var interaction_feedback: Label
var damage_flash: ColorRect
var health_fill: StyleBoxFlat
var _damage_flash_tween: Tween
var _feedback_tween: Tween


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

	var objective_panel := PanelContainer.new()
	objective_panel.position = Vector2(24, 24)
	objective_panel.size = Vector2(430, 190)
	objective_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("111a26d9"), Color("4f718b")))
	root.add_child(objective_panel)
	var objective_box := VBoxContainer.new()
	objective_panel.add_child(objective_box)
	objective_label = Label.new()
	objective_label.text = "OBJECTIVE  /  INITIALIZING"
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", Color("76deea"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_box.add_child(objective_label)
	threat_label = Label.new()
	threat_label.text = "THREAT  NORMAL"
	threat_label.add_theme_font_size_override("font_size", 16)
	threat_label.add_theme_color_override("font_color", Color("79f1e7"))
	objective_box.add_child(threat_label)
	enemy_label = Label.new()
	enemy_label.text = "HOSTILES REMAINING  10"
	enemy_label.add_theme_font_size_override("font_size", 22)
	objective_box.add_child(enemy_label)

	var status_panel := PanelContainer.new()
	status_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	status_panel.position = Vector2(24, -222)
	status_panel.size = Vector2(420, 198)
	status_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("111a26e8"), Color("4f718b")))
	root.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_panel.add_child(status_box)
	health_label = Label.new()
	health_label.text = "CHASSIS  260 / 260"
	health_label.add_theme_font_size_override("font_size", 15)
	status_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.max_value = 260.0
	health_bar.value = 260.0
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(320, 14)
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color("202a35")
	health_background.corner_radius_top_left = 2
	health_background.corner_radius_top_right = 2
	health_background.corner_radius_bottom_left = 2
	health_background.corner_radius_bottom_right = 2
	health_fill = StyleBoxFlat.new()
	health_fill.bg_color = Color("67e6e2")
	health_fill.corner_radius_top_left = 2
	health_fill.corner_radius_top_right = 2
	health_fill.corner_radius_bottom_left = 2
	health_fill.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	status_box.add_child(health_bar)
	weapon_label = Label.new()
	weapon_label.text = "PRIMARY  ASSAULT RIFLE"
	weapon_label.add_theme_color_override("font_color", Color("70edf2"))
	status_box.add_child(weapon_label)
	ammo_label = Label.new()
	ammo_label.text = "MAG  0 / 0    RESERVE  0"
	ammo_label.add_theme_color_override("font_color", Color("f1d98a"))
	status_box.add_child(ammo_label)
	secondary_weapon_label = Label.new()
	secondary_weapon_label.text = "SECONDARY  UNARMED"
	secondary_weapon_label.add_theme_color_override("font_color", Color("8da8bb"))
	status_box.add_child(secondary_weapon_label)
	secondary_ammo_label = Label.new()
	secondary_ammo_label.text = "MAG  0 / 0    RESERVE  0"
	secondary_ammo_label.add_theme_color_override("font_color", Color("a9c4d4"))
	status_box.add_child(secondary_ammo_label)
	active_weapon_label = Label.new()
	active_weapon_label.text = "ACTIVE  PRIMARY"
	active_weapon_label.add_theme_color_override("font_color", Color("70edf2"))
	status_box.add_child(active_weapon_label)
	capacity_label = Label.new()
	capacity_label.text = "CARGO  0.0 / 0.0"
	capacity_label.add_theme_color_override("font_color", Color("a9c4d4"))
	status_box.add_child(capacity_label)

	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-300, 70)
	banner.size = Vector2(600, 80)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 42)
	banner.add_theme_color_override("font_color", Color("79f1e7"))
	banner.visible = false
	root.add_child(banner)

	reticle = Label.new()
	reticle.text = "+"
	reticle.size = Vector2(28.0, 36.0)
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reticle.add_theme_font_size_override("font_size", 28)
	reticle.add_theme_color_override("font_color", Color("dffaffb8"))
	root.add_child(reticle)

	interaction_prompt = Label.new()
	interaction_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_prompt.position = Vector2(-260, -86)
	interaction_prompt.size = Vector2(520, 34)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 18)
	interaction_prompt.add_theme_color_override("font_color", Color("c9fbff"))
	root.add_child(interaction_prompt)

	interaction_feedback = Label.new()
	interaction_feedback.set_anchors_preset(Control.PRESET_CENTER)
	interaction_feedback.position = Vector2(-260, 112)
	interaction_feedback.size = Vector2(520, 38)
	interaction_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_feedback.add_theme_font_size_override("font_size", 20)
	interaction_feedback.visible = false
	root.add_child(interaction_feedback)


func _process(_delta: float) -> void:
	if reticle:
		reticle.position = get_viewport().get_mouse_position() - reticle.size * 0.5


func set_health(current: float, maximum: float) -> void:
	var took_damage := current < health_bar.value
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "CHASSIS  %d / %d" % [roundi(current), roundi(maximum)]
	var ratio := current / maximum
	health_fill.bg_color = Color("ff586d") if ratio < 0.3 else Color("67e6e2")
	if took_damage:
		if _damage_flash_tween and _damage_flash_tween.is_valid():
			_damage_flash_tween.kill()
		damage_flash.color = Color("ff30402e")
		_damage_flash_tween = create_tween()
		_damage_flash_tween.tween_property(damage_flash, "color", Color("ff304000"), 0.2)


func set_enemy_count(count: int) -> void:
	enemy_label.text = "HOSTILES REMAINING  %02d" % count


func set_threat_level(level: int) -> void:
	var is_alert := level == SortieSession.ThreatLevel.ALERT
	threat_label.text = "THREAT  %s" % ("ALERT" if is_alert else "NORMAL")
	threat_label.add_theme_color_override("font_color", Color("ff6b7f") if is_alert else Color("79f1e7"))


func set_objective_progress(display_name: String, progress: int, target: int, completed: bool) -> void:
	set_objectives([{
		"display_name": display_name,
		"progress": progress,
		"target": target,
		"completed": completed,
	}])


func set_objectives(objectives: Array[Dictionary]) -> void:
	var lines: Array[String] = ["OBJECTIVES"]
	for objective in objectives:
		var state_text := "COMPLETE" if bool(objective.get("completed", false)) else "%d / %d" % [
			int(objective.get("progress", 0)),
			int(objective.get("target", 1)),
		]
		lines.append("%s  %s" % [str(objective.get("display_name", "Unknown")).to_upper(), state_text])
	objective_label.text = "\n".join(lines)


func set_weapon(display_name: String) -> void:
	weapon_label.text = display_name.to_upper()


func set_ammo(magazine: int, magazine_capacity: int, reserve: int) -> void:
	ammo_label.text = "MAG  %d / %d    RESERVE  %d" % [magazine, magazine_capacity, reserve]


func set_weapon_slots(primary: Dictionary, secondary: Dictionary, active_slot: StringName) -> void:
	var primary_active := active_slot == LoadoutState.SLOT_WEAPON_PRIMARY
	weapon_label.text = "PRIMARY  %s" % str(primary.get("display_name", "UNARMED")).to_upper()
	ammo_label.text = "MAG  %d / %d    RESERVE  %d" % [
		int(primary.get("magazine", 0)),
		int(primary.get("magazine_capacity", 0)),
		int(primary.get("reserve", 0)),
	]
	secondary_weapon_label.text = "SECONDARY  %s" % str(secondary.get("display_name", "UNARMED")).to_upper()
	secondary_ammo_label.text = "MAG  %d / %d    RESERVE  %d" % [
		int(secondary.get("magazine", 0)),
		int(secondary.get("magazine_capacity", 0)),
		int(secondary.get("reserve", 0)),
	]
	active_weapon_label.text = "ACTIVE  %s" % ("PRIMARY" if primary_active else "SECONDARY")
	weapon_label.add_theme_color_override("font_color", Color("70edf2") if primary_active else Color("8da8bb"))
	ammo_label.add_theme_color_override("font_color", Color("f1d98a") if primary_active else Color("a9c4d4"))
	secondary_weapon_label.add_theme_color_override("font_color", Color("8da8bb") if primary_active else Color("70edf2"))
	secondary_ammo_label.add_theme_color_override("font_color", Color("a9c4d4") if primary_active else Color("f1d98a"))


func set_inventory_capacity(used: float, maximum: float) -> void:
	capacity_label.text = "CARGO  %.1f / %.1f" % [used, maximum]


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
