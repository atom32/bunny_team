class_name CampusAction
extends Node3D
## Authored Batch 2 point. No damage events, evidence-counter graph or power-grid simulation.
@export var kind: StringName = &"relay"
@export var action_id: StringName
@export var work_seconds := 12.0
var remaining := 0.0
var actor: PlayerController
var session: SortieSession
var observed_health := 0.0
var choice_layer: CanvasLayer
var previous_mouse_mode: int

func _ready() -> void:
	add_to_group("interactable")
	_refresh_visual()
	GameLanguage.language_changed.connect(_refresh_visual)

func _exit_tree() -> void: _close_choice()

func bind_actor(player: PlayerController,current: SortieSession) -> void:
	actor=player;session=current;observed_health=actor.health
	if not actor.health_changed.is_connected(_health_changed):actor.health_changed.connect(_health_changed)

func _health_changed(health: float,_maximum: float) -> void:
	if health<observed_health:
		_cancel_work(tr("L-02 work interrupted by damage. Press %s to restart.") % ControlBindings.label("interact"))
		if is_instance_valid(choice_layer):
			_close_choice();SortieRuntime.request_checkpoint()
	observed_health=health

func _cancel_work(message: String) -> void:
	if remaining<=0:return
	remaining=0.0
	if is_instance_valid(actor) and session and session.status==SortieSession.Status.ACTIVE and not actor.is_dead:
		actor.interaction_component.interaction_finished.emit(message,false)
	SortieRuntime.request_checkpoint()

func _near() -> bool:
	return is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_dead and session and session.status==SortieSession.Status.ACTIVE and actor.global_position.distance_to(global_position)<=actor.interaction_component.interaction_radius

func _available(current: SortieSession) -> bool:
	if not current or current.status!=SortieSession.Status.ACTIVE or current.campus.is_empty():return false
	match kind:
		&"relay":return current.campus.stage=="relay" and String(action_id) not in current.campus.relays
		&"recorder":return CampusChapter.recorder_available(current.campus)
		&"power":return current.campus.stage=="power" and not current.campus.power_cut
	return false

func interact(player: Node3D,current: SortieSession) -> Dictionary:
	if not player is PlayerController or not _available(current):return {"success":false,"message":"Campus action unavailable or already completed."}
	bind_actor(player,current)
	if not _near():return {"success":false,"message":"Move closer to the campus equipment."}
	if kind==&"recorder":
		var item:=ItemInstance.new(CampusChapter.RECORDER_ID)
		if not current.inventory.add_item_preserving_instance(item):return {"success":false,"message":"Inventory Full"}
		current.campus.recorder_instance=item.instance_id;current.campus.recorder_revealed=true
		_refresh_visual();SortieRuntime.request_checkpoint()
		return {"success":true,"message":"Experiment recorder recovered / read the log now; bring it home.","information":tr(CampusChapter.RECORD)}
	if remaining>0:return {"success":false,"message":"Work already active."}
	if kind==&"power":
		_open_choice()
		return {"success":true,"message":"Confirm L-02B OFF / preserve L-02A ON, or leave without changing power."}
	_start_work()
	return {"success":true,"message":"L-02 REPAIR / 12s nearby; damage or leaving cancels."}

func _start_work() -> void:
	remaining=work_seconds;observed_health=actor.health
	CombatNoise.emit_at(self,global_position,18.0,&"repair")
	AudioDirector.play_sfx(&"ui_click");SortieRuntime.request_checkpoint()

func confirm_power() -> bool:
	if not is_instance_valid(choice_layer):return false
	if kind!=&"power" or not _near() or not _available(session):_close_choice();return false
	_close_choice();_start_work();return true

func _open_choice() -> void:
	if is_instance_valid(choice_layer):return
	previous_mouse_mode=Input.mouse_mode;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;actor.aim_input_captured=true
	choice_layer=CanvasLayer.new();choice_layer.name="L02BranchChoice";add_child(choice_layer)
	var panel:=PanelContainer.new();panel.name="PowerChoice";panel.position=Vector2(300,190);panel.custom_minimum_size=Vector2(620,240)
	panel.theme=SliceUI.menu_theme();choice_layer.add_child(panel)
	var body:=VBoxContainer.new();panel.add_child(body)
	var text:=Label.new();text.text=tr("L-02A / Shelter communications and lighting: ON\nL-02B / Experimental equipment: ON\nDisconnect only L-02B. Shelter power will remain ON. Work takes 6s and can be interrupted.")
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(text)
	var confirm:=Button.new();confirm.name="ConfirmBranch";confirm.text=tr("DISCONNECT L-02B / KEEP L-02A")
	confirm.pressed.connect(confirm_power);body.add_child(confirm)
	var cancel:=Button.new();cancel.name="CancelBranch";cancel.text=tr("NOT NOW / NO CHANGE");cancel.pressed.connect(_close_choice);body.add_child(cancel)
	confirm.grab_focus()

func _close_choice() -> void:
	if not is_instance_valid(choice_layer):return
	if is_instance_valid(actor):actor.aim_input_captured=false
	Input.mouse_mode=previous_mouse_mode as Input.MouseMode
	choice_layer.queue_free();choice_layer=null

func _process(delta: float) -> void:
	if is_instance_valid(choice_layer) and not _near():_close_choice()
	if remaining<=0 or get_tree().paused:return
	if not _near():
		_cancel_work(tr("L-02 work interrupted: left the equipment. Return and press %s to restart.") % ControlBindings.label("interact"));return
	if actor.health<observed_health:
		_cancel_work(tr("L-02 work interrupted by damage. Press %s to restart.") % ControlBindings.label("interact"));return
	if not _available(session):
		remaining=0.0;SortieRuntime.request_checkpoint();return
	remaining=maxf(0,remaining-delta)
	if remaining>0:return
	if kind==&"relay":
		if CampusChapter.record_relay(session,String(action_id)) and session.campus.relays.size()==2:
			actor.interaction_component.information_read.emit(tr(CampusChapter.WARNING))
		get_parent().refresh_campus_power()
	elif kind==&"power":
		session.campus.power_cut=true;session.campus.power_confirmed=true
		actor.interaction_component.information_read.emit(tr(CampusChapter.POWER_REPLY))
		get_parent().refresh_campus_power()
	_refresh_visual();AudioDirector.play_sfx(&"ui_confirm");SortieRuntime.request_checkpoint()

func get_interaction_prompt(_player: Node3D,current: SortieSession) -> String:
	if not current or current.campus.is_empty():return ""
	if remaining>0:return tr("L-02 WORK %.1fs / Stay close; damage cancels") % remaining
	if kind==&"power" and current.campus.power_cut:return tr("L-02B OFF / L-02A ON / Extract")
	if not _available(current):return ""
	return ControlBindings.label("interact")+"  "+tr({&"relay":"REPAIR L-02 RELAY / 12s",&"recorder":"TAKE EXPERIMENT RECORDER",&"power":"OPEN L-02 BRANCH CONTROL"}[kind])

func _refresh_visual() -> void:
	var label:=get_node("WorldLabel") as Label3D
	var current:=SortieRuntime.get_current_session()
	if _available(current):add_to_group("interactable")
	else:remove_from_group("interactable")
	if kind==&"relay":
		var online: bool=current!=null and not current.campus.is_empty() and String(action_id) in current.campus.relays
		label.text=("L-02A" if action_id==&"relay_office" else "L-02B")+" / "+tr("RELAY ONLINE" if online else "RELAY / 12s")
	elif kind==&"recorder":
		label.text=tr("EXPERIMENT RECORDER")
		get_node("Art").visible=not current or current.campus.is_empty() or current.campus.recorder_instance.is_empty()
		label.visible=get_node("Art").visible
	else:
		var cut: bool=current!=null and not current.campus.is_empty() and current.campus.power_cut
		label.text=tr("L-02B OFF / L-02A ON / Extract") if cut else tr("L-02 / BRANCH CONTROL")
		get_node("BranchBLight").light_energy=0.0 if cut else .8
		var indicator:=get_node("BranchBIndicator") as MeshInstance3D
		var material:=indicator.material_override.duplicate() as StandardMaterial3D
		material.emission_enabled=not cut;material.albedo_color=Color("203039") if cut else Color("bf6658")
		indicator.material_override=material
		var display:=get_node("ExperimentDisplay") as MeshInstance3D
		var screen:=display.material_override.duplicate() as StandardMaterial3D
		screen.emission_enabled=not cut;screen.albedo_color=Color("101820") if cut else Color("2e6678")
		display.material_override=screen
		get_node("Art").visible=true # Keep the physical chassis; switch off its display.
