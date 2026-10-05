extends Node
## One authored first sortie. Progress follows gameplay events, never elapsed tutorial cards.
enum Stage { MOVE, AIM, FIRE, PMC, RELOAD, LOOT, TERMINAL, CHOICE, SALVAGE, EXTRACT }
var stage := Stage.MOVE
var battle: Node3D
var start_position: Vector3
var start_aim: Vector3
var moved_distance := 0.0
var last_position: Vector3
var guide: Label
var _controls_revision := -1
var destination: Label
var elapsed := 0.0
var reload_seen := false
var fired := false
var patrol_looted := false
var bonus_looted := false
var reinforcements_remaining := -1.0
var choice_buttons: Control
var marker: Label3D
var patrol: EnemyController

func _ready() -> void:
	add_to_group("first_mission_director")
	battle = get_parent()
	start_position = battle.player.global_position
	last_position = start_position
	start_aim = battle.player.aim_direction
	patrol = battle.enemy_container.get_child(0)
	patrol.set_physics_process(false)
	patrol.hide()
	patrol.collision_layer = 0
	patrol.collision_mask = 0
	patrol.died.connect(_patrol_defeated)
	battle.player.weapon_fired.connect(func(_recoil: float): fired = true)
	for point in battle.area_root.find_children("*", "LootSpawnPoint", true, false):
		_set_loot_enabled(point, false)
		for pickup in point.get_children():
			if pickup is LootPickup:
				pickup.picked_up.connect(_on_pickup.bind(point.name == "HighValueLootSpawn"))
	var terminal := battle.area_root.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	terminal.objective_interacted.connect(_terminal_investigated)
	var layer := CanvasLayer.new()
	layer.layer = 26
	add_child(layer)
	var screen := SliceUI.root(layer)
	var panel := SliceUI.panel(screen, Vector2(18, 140), Vector2(350, 114))
	panel.name = "TutorialCard"
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("111a2699"), Color("4f718b44")))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide = SliceUI.label(panel, "", Vector2(12, 10), 15, SliceUI.CYAN)
	guide.size = Vector2(326, 64)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination = SliceUI.label(panel, "", Vector2(12, 86), 11, SliceUI.MUTED)
	destination.size = Vector2(326, 26)
	destination.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_buttons = VBoxContainer.new()
	choice_buttons.position = Vector2(18, 262)
	choice_buttons.add_theme_constant_override("separation", 6)
	screen.add_child(choice_buttons)
	SliceUI.button(choice_buttons, "CONTINUE / SALVAGE", Vector2.ZERO, Vector2(350, 40), func(): choose_route(true))
	SliceUI.button(choice_buttons, "EXTRACT / KEEP CARGO", Vector2.ZERO, Vector2(350, 40), func(): choose_route(false))
	for button in choice_buttons.get_children():
		button.custom_minimum_size = Vector2(350, 40)
		button.add_theme_font_size_override("font_size", 14)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := UIFactory.panel_style(Color("26364b"), Color("4d7194"))
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			button.add_theme_stylebox_override(state, style)
	choice_buttons.hide()
	marker = Label3D.new()
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.font_size = 20
	marker.modulate = SliceUI.CYAN
	battle.add_child(marker)
	_refresh_guide()
	GameLanguage.language_changed.connect(func(): _refresh_guide(); _refresh_destination())

func _process(delta: float) -> void:
	if _controls_revision != ControlBindings.revision: _refresh_guide()
	if battle.ending: return
	elapsed += delta
	var current: Vector3 = battle.player.global_position
	moved_distance += current.distance_to(last_position)
	last_position = current
	if battle.player.get_reload_remaining() > 0.0: reload_seen = true
	match stage:
		Stage.MOVE:
			if moved_distance >= 3.0: _advance(Stage.AIM)
		Stage.AIM:
			if start_aim.dot(battle.player.aim_direction) < 0.92: _advance(Stage.FIRE)
		Stage.FIRE:
			if fired:
				patrol.show()
				patrol.collision_layer = 2
				patrol.collision_mask = 5
				patrol.set_physics_process(true)
				_advance(Stage.PMC)
		Stage.RELOAD:
			if reload_seen and battle.player.get_reload_remaining() <= 0.0:
				_advance(Stage.TERMINAL if patrol_looted else Stage.LOOT)
		Stage.LOOT:
			if patrol_looted: _advance(Stage.TERMINAL)
		Stage.SALVAGE:
			if bonus_looted: _advance(Stage.EXTRACT)
	if reinforcements_remaining > 0:
		reinforcements_remaining = maxf(0.0, reinforcements_remaining - delta)
		if reinforcements_remaining == 0:
			battle.area_root.find_child("LocalAlertEvent", true, false).trigger()
			battle.hud.show_banner("PMC RESPONSE TEAM ARRIVED", Color("ff6b7f"))
	_refresh_destination()

func _advance(next: Stage) -> void:
	stage = next
	_refresh_guide()
	_refresh_destination()
	AudioDirector.play_sfx(&"ui_confirm", -6)

func _patrol_defeated(_enemy: EnemyController) -> void:
	var supplies := battle.area_root.find_child("PatrolSalvage", true, false) as Node3D
	supplies.global_position = _enemy.global_position
	_set_loot_enabled(supplies, true)
	_advance(Stage.RELOAD)

func _on_pickup(_item: ItemInstance, bonus: bool) -> void:
	if bonus: bonus_looted = true
	else: patrol_looted = true

func _terminal_investigated(_objective_id: StringName) -> void:
	battle._sync_objective_hud()
	reinforcements_remaining = 12.0
	battle.hud.show_banner("ALARM / PMC RESPONSE IN 12s", Color("ff6b7f"))
	_set_loot_enabled(battle.area_root.find_child("HighValueLootSpawn", true, false), true)
	_advance(Stage.CHOICE)
	choice_buttons.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func choose_route(salvage: bool) -> void:
	if stage != Stage.CHOICE: return
	choice_buttons.hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.action_release("fire")
	_advance(Stage.SALVAGE if salvage else Stage.EXTRACT)

func _set_loot_enabled(point: Node3D, enabled: bool) -> void:
	point.visible = enabled
	for child in point.get_children():
		if child is LootPickup:
			if enabled: child.add_to_group("interactable")
			else: child.remove_from_group("interactable")

func _refresh_guide() -> void:
	_controls_revision = ControlBindings.revision
	var lines := [
		"01 / FIND YOUR FEET\n%s / left stick — move 3 metres.",
		"02 / LOOK BEFORE YOU SHOOT\nMouse / right stick — turn your aim.",
		"03 / LIVE FIRE\n%s / right trigger — fire your weapon.",
		"04 / FIRST PMC\nUse cover. Fire at the patrol. %s switches equipped weapons.",
		"05 / A FRESH MAGAZINE\n%s — reload. Then search the fallen patrol's case.",
		"06 / YOUR FIRST SALVAGE\n%s — open the case. TAKE the Salvage Core.",
		"07 / RECOVER THE HOME SIGNAL\nFind the field terminal. %s — investigate for 8s.",
		"08 / THE ALARM IS LIVE\nOne core secured. Extra salvage or a safe return?",
		"09 / SOMETHING WORTH THE RISK\nSearch the north cache. You can still extract anytime.",
		"10 / COME HOME\n%s at the south beacon. Defend for 8s."
	]
	var keys := {Stage.MOVE: "/".join([ControlBindings.label("move_forward"),ControlBindings.label("move_left"),ControlBindings.label("move_back"),ControlBindings.label("move_right")])}
	guide.text = tr(lines[stage])
	var stage_actions := {2:"fire",3:"switch_weapon",4:"reload",5:"interact",6:"interact",9:"interact"}
	if stage == 0: guide.text = guide.text % keys[Stage.MOVE]
	elif stage in stage_actions: guide.text = guide.text % ControlBindings.label(stage_actions[stage])

func _refresh_destination() -> void:
	var target: Node3D
	var name_text := "TRAINING / SOUTH ACCESS"
	match stage:
		Stage.PMC:
			target = patrol
			name_text = "PMC PATROL"
		Stage.RELOAD, Stage.LOOT:
			target = battle.area_root.find_child("PatrolSalvage", true, false)
			name_text = "PATROL SUPPLIES / 1 CORE"
		Stage.TERMINAL:
			target = battle.area_root.find_child("PrototypeTerminal", true, false)
			name_text = "FIELD TERMINAL"
			if not _inside_office():
				var door := battle.area_root.find_child("SouthAccessDoor", true, false) as Node3D
				if door:
					target = door
					name_text = "FIELD OFFICE / SOUTH ENTRANCE"
					guide.text = tr("07 / RECOVER THE HOME SIGNAL\nGo around to the south door. %s opens it; enter the office.") % ControlBindings.label("interact")
			else:
				guide.text = tr("07 / RECOVER THE HOME SIGNAL\nFind the field terminal. %s — investigate for 8s.") % ControlBindings.label("interact")
		Stage.CHOICE, Stage.SALVAGE:
			target = battle.area_root.find_child("HighValueLootSpawn", true, false)
			name_text = "HIGH VALUE SALVAGE / 2 CORES"
		Stage.EXTRACT:
			target = battle.area_root.find_child("ExtractionPoint", true, false)
			name_text = "SOUTH EXTRACTION"
	marker.visible = is_instance_valid(target)
	if target is EnemyController and not PlayerVisibility.enemy_observed(self, target):
		marker.hide()
		name_text = "LISTEN / SEARCH FOR PATROL"
	if marker.visible:
		marker.global_position = target.global_position + Vector3.UP * 2.2
		marker.text = "▼"
		var offset: Vector3 = target.global_position - battle.player.global_position
		var heading := ("N" if offset.z < -2.0 else ("S" if offset.z > 2.0 else "")) + ("W" if offset.x < -2.0 else ("E" if offset.x > 2.0 else ""))
		name_text = tr(name_text)
		name_text += tr(" / %s %.0fm") % [heading, offset.length()]
	destination.text = tr("%02d:%02d  /  %s") % [int(elapsed) / 60, int(elapsed) % 60, tr(name_text)]
	if reinforcements_remaining > 0: destination.text += tr(" / PMC %.0fs") % reinforcements_remaining

# Presentation hint only: use the authored floor footprint, not a new trigger/collision.
func _inside_office() -> bool:
	var building := battle.area_root.find_child("FieldOffice", true, false) as Node3D
	var floor_shape := building.get_node_or_null("InteriorFloor/CollisionShape3D") as CollisionShape3D if building else null
	if not floor_shape or not floor_shape.shape is BoxShape3D: return true
	var local := floor_shape.to_local(battle.player.global_position)
	var half := (floor_shape.shape as BoxShape3D).size * .5
	return absf(local.x) < half.x and absf(local.z) < half.z
