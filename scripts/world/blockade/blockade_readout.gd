extends Control
## Observed encounter state only. Never changes phase, acquisition, damage or objectives.
var van: BlockadeVan
var card: PanelContainer
var title: Label
var state_label: Label
var power_label: Label
var health: ProgressBar
var phase_bar: ProgressBar
var hit_label: Label
var hit_remaining := 0.0

func _ready() -> void:
	name = "BlockadeReadout"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = FieldManualStyle.theme()
	card = PanelContainer.new();card.name = "ObservedVanState";card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	add_child(card)
	var body := VBoxContainer.new();body.add_theme_constant_override("separation",5);body.mouse_filter = Control.MOUSE_FILTER_IGNORE;card.add_child(body)
	title = _label(body,16)
	health = _bar(body,7)
	state_label = _label(body,18)
	phase_bar = _bar(body,4)
	power_label = _label(body,12)
	hit_label = _label(body,14)
	van.damage_observed.connect(_hit)
	update_readout(0)

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new();label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size);label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label);return label

func _bar(parent: Node, height: int) -> ProgressBar:
	var bar := ProgressBar.new();bar.custom_minimum_size.y = height;bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background",FieldManualStyle.bar(FieldManualStyle.LINE))
	bar.add_theme_stylebox_override("fill",FieldManualStyle.bar(FieldManualStyle.ACCENT))
	parent.add_child(bar);return bar

func _hit(applied: float, exposed: bool) -> void:
	if not van.observed(): return
	hit_remaining = .65
	hit_label.text = tr("VENT HIT / -%d" if exposed else "ARMOR HIT / -%d / WAIT FOR BLUE VENTS") % ceili(applied)
	hit_label.add_theme_color_override("font_color",FieldManualStyle.SUCCESS if exposed else FieldManualStyle.ACCENT)

func _process(delta: float) -> void: update_readout(delta)

func update_readout(delta: float) -> void:
	if not is_node_ready() or not is_instance_valid(van): return
	hit_remaining = maxf(0, hit_remaining-delta)
	var viewport_size := get_viewport_rect().size
	var width := clampf(viewport_size.x * .28,280,360)
	card.position = Vector2(viewport_size.x-width-24,72)
	card.custom_minimum_size.x = width;card.size.x = width
	card.visible = van.observed()
	if not card.visible:
		hit_remaining = 0;return
	var accent := FieldManualStyle.SUCCESS if van.phase in [BlockadeVan.Phase.VENT,BlockadeVan.Phase.WRECK] else FieldManualStyle.ACCENT
	title.text = tr("BLOCKADE VAN / %d / %d") % [ceili(van.current_structure_health),ceili(van.max_structure_health)]
	health.max_value = van.max_structure_health;health.value = van.current_structure_health
	(health.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = accent
	state_label.add_theme_color_override("font_color",accent)
	var phase_name: String = ["ARMORED", "LOCKED / MOVE", "BURST / KEEP COVER", "VENT OPEN / FIRE", "DISABLED"][van.phase]
	state_label.text = tr(phase_name)
	if van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.VENT]:state_label.text += "  %.1fs" % van.phase_remaining
	elif van.phase == BlockadeVan.Phase.BURST:state_label.text += "  %d / 4" % van.burst_shots
	phase_bar.visible = van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.VENT]
	phase_bar.max_value = maxf(.01,BlockadeVan.DURATIONS[van.phase]);phase_bar.value = van.phase_remaining
	(phase_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = accent
	power_label.text = tr("NORTH TRAFFIC BARRIER OPEN" if van.destroyed else ("PA ON / WEST ALLEY CUTS BROADCASTS" if van.speaker_enabled else "PA OFF / GUN RETAINS POWER"))
	var session:=SortieRuntime.get_current_session()
	if van.destroyed and session and not session.blockade.is_empty():power_label.text=tr("NORTH ROAD OPEN" if session.blockade.escape_open else "VAN DOWN / EAST BOOTH COUNTERWEIGHT")
	hit_label.visible = hit_remaining > 0
	card.reset_size()
