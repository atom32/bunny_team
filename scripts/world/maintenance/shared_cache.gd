class_name MaintenanceSharedCache
extends LootSpawnPoint
## Optional two-person unlatch. Existing pickup/capacity/death rules own all cargo.
const EXCHANGE := "Xu Tang: I tried opening it alone.\nTang Kui: Who won?\nXu Tang: The lid.\nSu Mi: Let her take the rematch.\nXu Tang: ...No. This time, together."
var closed_case: Node3D

func _ready() -> void:
	closed_case = Node3D.new()
	closed_case.name = "JammedCase"
	add_child(closed_case)
	VisualFactory.box(closed_case, Vector3(1.15,.9,.7), Vector3(0,.45,0), Color("35515b"), "Case")
	for x in [-.48,.48]:
		# Raised grip rail with two posts anchored to the lid, not a floating target.
		for z in [.32,.48]:
			VisualFactory.box(closed_case,Vector3(.045,.1,.035),Vector3(x,.95,z),Color("d3b479"),"HandlePost")
		VisualFactory.box(closed_case,Vector3(.055,.045,.2),Vector3(x,1,.4),Color("d3b479"),"Handle")
	var tag := SliceUI.sign(closed_case, "JAMMED TOOLBOX / TWO HANDLES", Vector3(0,1.1,0))
	tag.name = "WorldLabel"
	tag.font_size = 24
	tag.pixel_size = .003
	for offset in [Vector3(-.72,.015,.4),Vector3(1.05,.015,.4)]:
		VisualFactory.cylinder(closed_case,.2,.02,offset,Color("70b3b8"),"HandleFooting")
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	if is_instance_valid(closed_case):
		closed_case.visible = not has_rolled
		closed_case.get_node("WorldLabel").text = tr("JAMMED TOOLBOX / TWO HANDLES")
		var helper:=get_parent().get_node_or_null("Survivor") as MaintenanceSurvivor
		closed_case.get_node("WorldLabel").visible=not (helper and is_instance_valid(helper.actor) and helper.actor.global_position.distance_to(global_position)<3)
	# Rolled contents are identified in the normal inspection UI; stacked item
	# name billboards here would overlap each other before the case is registered.
	for child in get_children():
		if child is LootPickup and is_instance_valid(child._name_label):child._name_label.hide()
	var crate:=get_node_or_null("LootContainer/WorldTag")
	if crate:crate.hide()
	if has_rolled: remove_from_group("interactable")
	else: add_to_group("interactable")

func _clear_line(actor: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.2, global_position+Vector3.UP*1.2,4)
	if actor is CollisionObject3D: query.exclude = [actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or session.status != SortieSession.Status.ACTIVE or session.mission_id != MaintenanceStory.MISSION:
		return {"success":false,"message":"No active rescue."}
	if has_rolled: return {"success":false,"message":"The toolbox is already unlatched."}
	if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius or not _clear_line(actor):
		return {"success":false,"message":"Move beside the toolbox handle."}
	if not MaintenanceStory.done(session,&"maintenance_release") or MaintenanceStory.done(session,&"maintenance_rescue"):
		return {"success":false,"message":"Get Xu Tang out first. This toolbox is optional."}
	var helper := get_parent().get_node_or_null("Survivor") as MaintenanceSurvivor
	if not helper or helper.global_position.distance_to(global_position)>8.0 or not _clear_line(helper):
		return {"success":false,"message":"Bring Xu Tang beside the other handle. You can leave the toolbox."}
	if actor.global_position.distance_to(player_position())>.9:
		return {"success":false,"message":"Stand at the right-hand floor marker. You can leave the toolbox."}
	if not helper is SharedMaintenanceSurvivor:return {"success":false,"message":"Bring Xu Tang beside the other handle. You can leave the toolbox."}
	if not helper.is_bracing(self):
		helper.request_help(self,actor)
		return {"success":true,"message":"Xu Tang is coming to the other handle. Keep this side clear; moving away cancels the request."}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	enabled = true
	var pickups := spawn(rng)
	if pickups.is_empty():
		enabled = false
		return {"success":false,"message":"The toolbox did not open."}
	helper.finish_unlatch()
	_refresh()
	CombatNoise.emit_at(self,global_position,24,&"repair")
	AudioDirector.play_sfx(&"blockade_lock",-6)
	SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Toolbox unlatched. Inspect the real contents; combat remains live.","information":tr(EXCHANGE)}

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	if has_rolled or not session or session.status != SortieSession.Status.ACTIVE: return ""
	var helper:=get_parent().get_node_or_null("Survivor") as SharedMaintenanceSurvivor
	var prompt:="UNLATCH TOGETHER / OPTIONAL"
	if helper and helper.helping_cache==self:
		prompt="PULL YOUR HANDLE / XU TANG IS READY" if helper.is_bracing(self) else "XU TANG IS COMING / KEEP THIS SIDE CLEAR"
	return ControlBindings.label("interact")+"  "+tr(prompt)

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	return entry.enabled == entry.has_rolled and (not entry.has_rolled or MaintenanceStory.done(session,&"maintenance_release"))

func valid_pickup_snapshot(entry: Dictionary) -> bool:
	if typeof(entry.get("has_rolled")) != TYPE_BOOL: return false
	var slots:=roll_count+(1 if not bonus_loot_table_id.is_empty() and bonus_chance>0 else 0)
	return entry.items.size() <= slots and (entry.has_rolled or entry.items.is_empty())

func player_position() -> Vector3: return to_global(Vector3(1.05,0,.4))
func helper_position() -> Vector3: return to_global(Vector3(-.72,0,.4))
func helper_grip(index: int) -> Vector3: return to_global(Vector3(-.48,1,.4+(-.055 if index==0 else .055)))
func help_request_active(player: PlayerController,session: SortieSession) -> bool:
	return not has_rolled and is_instance_valid(player) and not player.is_dead and session and session.status==SortieSession.Status.ACTIVE and MaintenanceStory.done(session,&"maintenance_release") and not MaintenanceStory.done(session,&"maintenance_rescue") and player.global_position.distance_to(global_position)<=player.interaction_component.interaction_radius
