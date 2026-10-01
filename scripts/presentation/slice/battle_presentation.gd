extends Node
## Read-only battle observations plus UI calls into the existing pickup contract.
var battle: Node3D
var screen: Control
var panel: Panel
var container: SliceLootContainer
var crates := {}
var notice: Label
var arrival_camera: Camera3D
var arrival_time := 0.0
var exit_started := false

func _ready() -> void:
	_setup.call_deferred()

func _setup() -> void:
	battle = get_parent()
	if not is_instance_valid(battle.get("player")): return
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	screen = SliceUI.root(layer)
	GameLanguage.language_changed.connect(func():
		if is_instance_valid(panel): _show_loot()
	)
	notice = SliceUI.label(screen,"",Vector2.ZERO,15,SliceUI.CYAN)
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.offset_left = -240
	notice.offset_right = 240
	notice.offset_top = 82
	notice.offset_bottom = 130
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for point in battle.area_root.find_children("*","LootSpawnPoint",true,false):
		if not point.enabled: continue
		var crate := SliceLootContainer.new()
		point.add_child(crate)
		crates[point.get_instance_id()] = crate
	if GameState.arrival_pending:
		GameState.arrival_pending = false
		arrival_time = 1.8
		arrival_camera = Camera3D.new()
		arrival_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		arrival_camera.size = 30
		battle.add_child(arrival_camera)
		arrival_camera.current = true
		notice.text = "DISTRICT 07 / SOUTH ACCESS\nWASD MOVE   •   E INTERACT   •   Q SWITCH"
		AudioDirector.play_sfx(&"ui_confirm",-3)

func _process(delta: float) -> void:
	if not is_instance_valid(battle) or not is_instance_valid(battle.get("player")) or not screen: return
	if arrival_time > 0:
		arrival_time = maxf(0,arrival_time-delta)
		arrival_camera.global_transform = battle.camera.global_transform
		arrival_camera.size = lerpf(24.5,30,arrival_time/1.8)
		if arrival_time == 0:
			battle.camera.current = true
			arrival_camera.queue_free()
			notice.text = ""
	if battle.ending and not exit_started:
		exit_started = true
		_close_loot()
		var surviving: bool = not battle.player.is_dead
		notice.text = "EXTRACTION CONFIRMED / RETURN LINK OPEN" if surviving else "SIGNAL LOST / FLIGHT RECORDER RECOVERED"
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = battle.camera.size
		battle.add_child(camera)
		camera.global_transform = battle.camera.global_transform
		camera.current = true
		create_tween().tween_property(camera,"size",19.5,2.2)
	if is_instance_valid(panel):
		# Loot UI never pauses AI or grants safety. Walking away closes the case.
		if battle.ending or not is_instance_valid(container) or battle.player.global_position.distance_to(container.global_position) > battle.player.interaction_component.interaction_radius:
			_close_loot()
		else:
			Input.action_release("fire")
	elif not battle.ending:
		var target = battle.player.interaction_component._current_target
		if is_instance_valid(target) and target is LootPickup:
			battle.hud.set_interaction_prompt("E  OPEN SUPPLY CASE")

func _input(event: InputEvent) -> void:
	if not screen or not is_instance_valid(battle) or battle.ending: return
	if is_instance_valid(panel):
		if event is InputEventMouseButton:
			Input.action_release("fire") # UI focus, not weapon state/timing.
			if not panel.get_global_rect().has_point(event.position): get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			_close_loot()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var target = battle.player.interaction_component._current_target
		if is_instance_valid(target) and target is LootPickup and crates.has(target.get_parent().get_instance_id()):
			container = crates[target.get_parent().get_instance_id()]
			container.set_open(true)
			_show_loot()
			get_viewport().set_input_as_handled()

func _show_loot(feedback: String = "Inspect contents. Combat remains live.") -> void:
	if is_instance_valid(panel):
		screen.remove_child(panel)
		panel.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel = SliceUI.panel(screen,Vector2(790,174),Vector2(450,410))
	SliceUI.label(panel,"SUPPLY CACHE / CONTENTS",Vector2(22,20),23,SliceUI.CYAN)
	var used: float = battle.session.inventory.get_used_capacity()
	SliceUI.label(panel,tr("CARGO  %.1f / %.1f kg") % [used,battle.session.inventory.capacity],Vector2(22,66),18)
	var index := 0
	for pickup in container.contents():
		var definition := ContentDB.get_item(pickup.item_instance.definition_id)
		SliceUI.label(panel,tr("%s × %d") % [GameLanguage.item_name(definition.display_name),pickup.item_instance.quantity],Vector2(22,126+index*70),17)
		SliceUI.button(panel,"TAKE",Vector2(326,112+index*70),Vector2(100,48),func(): _take(pickup))
		index += 1
	if index == 0: SliceUI.label(panel,"CACHE SECURED / EMPTY",Vector2(22,126),18,SliceUI.CYAN)
	SliceUI.label(panel,feedback,Vector2(22,282),15,SliceUI.MUTED)
	SliceUI.button(panel,"CLOSE  /  E or ESC",Vector2(22,336),Vector2(404,52),_close_loot)

func _take(pickup: LootPickup) -> void:
	if not is_instance_valid(pickup) or battle.ending: return
	if battle.player.global_position.distance_to(pickup.global_position) > battle.player.interaction_component.interaction_radius:
		_close_loot()
		return
	var result := pickup.interact(battle.player,battle.session)
	battle.player.interaction_component.interaction_finished.emit(result.message,result.success)
	AudioDirector.play_sfx(&"ui_confirm" if result.success else &"ui_click",-3)
	_show_loot(result.message)

func _close_loot() -> void:
	if is_instance_valid(panel):
		panel.queue_free()
		panel = null
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if is_instance_valid(container) and container.opened: container.set_open(false)
