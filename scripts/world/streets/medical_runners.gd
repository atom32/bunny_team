class_name CampusMedicalRunners
extends Node3D
## One finite, physical medical-supply carrier. No quest credit or offscreen timer.
enum Phase { PACKING, LEAVING, DROPPED, ESCAPED }
var phase := Phase.PACKING
var route_index := 0
var introduced := false
var drop_position := Vector3.ZERO
var carrier: EnemyController
var escort: EnemyController
const INTRO := "Su Mi: Two leaving the clinic. White bag, heading for the service lane.\nTang Kui: The man by our window is still waiting for those dressings.\nShen: Then watch her back. Not the bag.\nTang Kui: I can watch two things!\n\nOptional: intercept the carrier for two dressings and two clean fabric. Ordinary clinic and dormitory supplies remain available."
const DROPPED := "Tang Kui: The white bag!\nShen: Behind the wall first.\nTang Kui: ...Behind the wall first. Then the bag."
const ESCAPED := "Su Mi: They got through the service gate.\nTang Kui: Damn it.\nShen: She is still here.\nTang Kui: I know. Check the clinic shelves. We are not going home empty-handed."

func _ready() -> void:
	add_to_group("campus_medical_runners");refresh_visual()
	GameLanguage.language_changed.connect(refresh_visual)

func _battle() -> Node3D:return get_parent().get_parent().get_parent()

func bind_enemy(enemy: EnemyController) -> void:
	var key: String=enemy.get_meta("spawn_key","")
	var prefix:=String(get_parent().get_path_to(self))+"/"
	if key==prefix+"Carrier":
		carrier=enemy;enemy.movement_duty=_carrier_goal
		if not enemy.died.is_connected(_carrier_died):enemy.died.connect(_carrier_died)
		# Under the observed presentation, never on the always-visible gameplay root.
		VisualFactory.box(enemy.presentation.model,Vector3(.75,.65,.38),Vector3(0,1.1,-.38),Color("f2ecdf"),"MedicalBag")
		VisualFactory.box(enemy.presentation.model,Vector3(.16,.55,.025),Vector3(0,1.1,-.585),Color("bb682e"),"BagStripe")
		var tag:=Label3D.new();tag.name="MedicalBagTag";tag.font=UIFactory.FONT;tag.text=tr("MED BAG")
		tag.position.y=3.35;tag.font_size=24;tag.pixel_size=.012;tag.outline_size=5;tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		enemy.presentation.add_child(tag)
	elif key==prefix+"Escort":
		escort=enemy;enemy.movement_duty=_escort_goal

func _carrier_goal() -> Vector3:
	return $Carrier.global_position if phase==Phase.PACKING else $Route.get_child(route_index).global_position

func _escort_goal() -> Vector3:
	return carrier.global_position+Vector3(3,0,0) if is_instance_valid(carrier) and not carrier.is_dead else $Route/WestGate.global_position

func _physics_process(_delta: float) -> void:
	var battle:=_battle()
	if not is_instance_valid(battle.player) or battle.session.status!=SortieSession.Status.ACTIVE:return
	if phase==Phase.PACKING and battle.player.global_position.distance_to($Carrier.global_position)<30:
		phase=Phase.LEAVING;introduced=true
		battle.player.interaction_component.information_read.emit(tr(INTRO));SortieRuntime.request_checkpoint()
	if phase==Phase.LEAVING and is_instance_valid(carrier) and not carrier.is_dead:
		if carrier.global_position.distance_to(_carrier_goal())<1.2:
			if route_index<$Route.get_child_count()-1:route_index+=1
			elif carrier.awareness.state in [EnemyAwareness.State.PATROL,EnemyAwareness.State.RETURN]:
				phase=Phase.ESCAPED;_depart(carrier)
				battle.player.interaction_component.information_read.emit(tr(ESCAPED));SortieRuntime.request_checkpoint()
	if phase in [Phase.DROPPED,Phase.ESCAPED] and is_instance_valid(escort) and not escort.is_dead:
		if escort.global_position.distance_to($Route/WestGate.global_position)<1.2 and escort.awareness.state in [EnemyAwareness.State.PATROL,EnemyAwareness.State.RETURN]:_depart(escort)

func _depart(enemy: EnemyController) -> void:
	# Departure is not a kill and never rerolls or grants salvage.
	var battle:=_battle()
	enemy.remove_from_group("enemies");enemy.queue_free()
	battle.enemies_remaining=maxi(0,battle.enemies_remaining-1);battle.hud.set_enemy_count(battle.enemies_remaining)
	SortieRuntime.request_checkpoint()

func _carrier_died(enemy: EnemyController) -> void:
	if phase in [Phase.DROPPED,Phase.ESCAPED]:return
	# Humanoid death reparents its presentation before emitting died. The bag
	# leaves that body, and its live-carrier marker must not float over a corpse.
	var tag:=enemy.presentation.get_node_or_null("MedicalBagTag") as Label3D
	if tag:tag.free()
	for name in ["MedicalBag","BagStripe"]:
		var part:=enemy.presentation.model.get_node_or_null(name) as MeshInstance3D
		if part:part.free()
	phase=Phase.DROPPED;drop_position=enemy.global_position;drop_position.y=0
	for entry in [["Dressings",&"medical.field_dressing",.45],["Linen",&"material.fabric",-.45]]:
		var cache:=get_node(entry[0]) as LootSpawnPoint
		cache.position=drop_position+Vector3(entry[2],0,0);cache.enabled=true;cache.has_rolled=true
		var definition:=ContentDB.get_item(entry[1],false)
		for index in (1 if definition.stackable else 2):
			var pickup:=LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
			pickup.setup(ItemInstance.new(entry[1],2 if definition.stackable else 1));cache.add_child(pickup)
		var view:=_battle().get_node_or_null("SlicePresentation")
		if view:view.register_loot_cache(cache)
	var battle:=_battle()
	battle.player.interaction_component.information_read.emit(tr(DROPPED));refresh_visual();SortieRuntime.request_checkpoint()

func refresh_visual() -> void:
	# Loot remains a normal physical pickup, including capacity/exchange rules.
	for name in ["Dressings","Linen"]:get_node(name).visible=phase==Phase.DROPPED
	if is_instance_valid(carrier) and not carrier.is_dead:
		var tag:=carrier.presentation.get_node_or_null("MedicalBagTag") as Label3D
		if tag:tag.text=tr("MED BAG")

func valid_checkpoint(entry: Dictionary,current: SortieSession,world: Dictionary) -> bool:
	if not current.q02_active or world.map_revision!=6 or not SortieCheckpoint.integer(entry.phase,0,3) or not SortieCheckpoint.integer(entry.route_index,0,$Route.get_child_count()-1):return false
	if entry.drop_position[1]!=0 or absf(entry.drop_position[0])>58 or absf(entry.drop_position[2])>58:return false
	if entry.phase!=Phase.DROPPED and entry.drop_position!=[0.0,0.0,0.0]:return false
	if entry.phase==Phase.PACKING and (entry.route_index!=0 or entry.introduced):return false
	if entry.phase in [Phase.LEAVING,Phase.ESCAPED] and not entry.introduced:return false
	if entry.phase==Phase.ESCAPED and entry.route_index!=$Route.get_child_count()-1:return false
	var prefix:=String(get_parent().get_path_to(self))+"/"
	for name in ["Carrier","Escort"]:
		if world.nodes.get(prefix+name,{}).get("has_spawned")!=true:return false
	# JSON numbers are floats before apply_fields converts the enum to int.
	if world.enemies.has(prefix+"Carrier")!=(int(entry.phase) in [Phase.PACKING,Phase.LEAVING]):return false
	for pair in [["Dressings",.45],["Linen",-.45]]:
		var cache: Dictionary=world.nodes.get(prefix+pair[0],{})
		if cache.get("enabled")!=(entry.phase==Phase.DROPPED) or cache.get("has_rolled")!=(entry.phase==Phase.DROPPED):return false
		if cache.get("visible")!=(entry.phase==Phase.DROPPED):return false
		if entry.phase!=Phase.DROPPED and not cache.get("items",[]).is_empty():return false
		if entry.phase==Phase.DROPPED:
			var expected:=Vector3(entry.drop_position[0]+pair[1],0,entry.drop_position[2])
			var saved: Array=cache.get("position",[])
			if saved.size()!=3 or Vector3(saved[0],saved[1],saved[2]).distance_to(expected)>.00001:return false
	return true
