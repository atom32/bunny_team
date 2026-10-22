class_name CampusPowerEncounter
extends Node3D
## Fresh v3 power sorties only. No added collision geometry in an old campus save.
enum Phase { IDLE, ACTIVE, CLEARED }
const GROUP:=&"campus_power_charge"
const INTRO:="Su Mi: Wait. That noise is not the relay.\nShen: Away from the console. Now.\nTang Kui: It is wearing a DOOR!\nSu Mi: That is a shield!\nTang Kui: Tell it!"
const CLEAR:="Su Mi: There. Back to the console. L-02B only.\nTang Kui: Shen, your voice cracked.\nShen: Bad radio.\nSu Mi: Mine was very clear."
const CHOICE:="L-02A / Shelter: stays ON\nL-02B / Experimental branch: still ON\n\nStart isolation. A shielded charger and two followers will approach. Its orange charge lane is committed: step aside, bait a wall impact or flank its shield. After the charger is down, return to this console and cut L-02B. No six-second work timer on this new route."
var phase:=Phase.IDLE

func _ready() -> void:
	add_to_group("campus_power_encounter")
	for entry in [["Ram",Vector3(-37,0,-35),&"campus_rammer"],["Follower0",Vector3(-37,0,-42),&"campus_infected"],["Follower1",Vector3(-47,0,-29),&"campus_infected"]]:
		var point:=EnemySpawnPoint.new();point.name=entry[0];point.position=entry[1];point.rotation.y=PI;point.enemy_definition_id=entry[2];point.initial_spawn=false;point.activation_group_id=GROUP;add_child(point)

func rammer() -> CampusRammer:
	var battle:=get_parent().get_parent().get_parent()
	if not battle or not "enemy_container" in battle or not is_instance_valid(battle.enemy_container):return null
	for enemy in battle.enemy_container.get_children():
		if enemy is CampusRammer and not enemy.is_dead:return enemy
	return null

func begin(actor: PlayerController) -> bool:
	var session:=SortieRuntime.get_current_session()
	if phase!=Phase.IDLE or not session or session.campus.is_empty() or session.campus.power_cut:return false
	phase=Phase.ACTIVE
	var battle:=get_parent().get_parent().get_parent()
	battle.spawn_reinforcement_group(GROUP)
	if not rammer():
		# Fail closed: never grant a cut because an encounter could not spawn.
		phase=Phase.IDLE;return false
	actor.interaction_component.interaction_finished.emit(tr("Charge incoming. Step out of the orange lane; L-02B is still on."),true)
	actor.interaction_component.information_read.emit(tr(INTRO));get_parent().refresh_campus_power();battle._sync_objective_hud();SortieRuntime.request_checkpoint()
	return true

func _physics_process(_delta: float) -> void:
	if phase!=Phase.ACTIVE or rammer()!=null:return
	phase=Phase.CLEARED
	get_parent().refresh_campus_power()
	var battle:=get_parent().get_parent().get_parent()
	if is_instance_valid(battle.player):battle.player.interaction_component.information_read.emit(tr(CLEAR))
	battle._sync_objective_hud();SortieRuntime.request_checkpoint()

func valid_checkpoint(entry: Dictionary,session: SortieSession,world: Dictionary) -> bool:
	if not SortieCheckpoint.integer(entry.get("phase"),0,2):return false
	if session.campus.is_empty() or session.campus.version<3 or session.campus.stage!="power":return false
	var prefix:=String(get_parent().get_path_to(self))+"/"
	for name in ["Ram","Follower0","Follower1"]:
		var data: Variant=world.nodes.get(prefix+name)
		if typeof(data)!=TYPE_DICTIONARY or data.get("has_spawned")!=(entry.phase!=Phase.IDLE):return false
	if entry.phase==Phase.CLEARED and world.enemies.has(prefix+"Ram"):return false
	if entry.phase==Phase.ACTIVE and session.campus.power_cut:return false
	if entry.phase==Phase.IDLE and session.campus.power_cut and not ProfileRuntime.get_profile().campus_chapter.branch_disconnected:return false
	return true
