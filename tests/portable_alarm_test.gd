extends Node3D
## Controlled real-Battle fixtures, not earned loot or ordinary-input acceptance.
## Actors are frozen; only the alarm timer and selected real hearing run below.
const PATH := "user://portable_alarm_runtime.json"
const EXPECTED_PATH := "user://portable_alarm_runtime_expected.json"
var checks := 0
var failures: Array[String] = []
var battle: Node3D

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func frames(count := 3) -> void:
	for tick in count: await get_tree().physics_frame

func json_value(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		await _disk(true)
	elif "--write" in OS.get_cmdline_user_args():
		await _disk(false)
	else:
		await _runtime()
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session(); get_tree().paused = false
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("PORTABLE_ALARM: " + failure)
	print("PORTABLE_ALARM_TEST: %s (%d checks; controlled fixtures, not earned play)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _load_battle(read_saved := false) -> bool:
	SortieRuntime.clear_session(); ProfileRuntime.recovery_required = false
	if read_saved:
		var loaded := ProfileRuntime.load_profile(PATH)
		check(loaded,"independent process loads the isolated alarm profile")
		var error := SortieRuntime.resume_saved(PATH) if loaded else ERR_INVALID_DATA
		check(error == OK,"independent process resumes the signed alarm world")
		if error != OK: return false
	else:
		var profile := ProfileRuntime.new_profile(); profile.first_mission_completed = true
		check(profile.inventory.add_item_preserving_instance(ItemInstance.new(PortableAlarm.ITEM_ID)),"controlled fixture owns one complete tool before deployment")
		profile.pack_alarm = true
		var deployed := DeploymentPlan.deploy(profile,&"prototype_arena",&"prototype_combat",PATH)
		check(deployed.error == OK,"normal persisted deployment carries the owned fixture tool")
		if deployed.error != OK: return false
	get_tree().paused = true
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false; add_child(battle)
	if not battle.player or not battle.session: return false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	for alarm in PortableAlarm.live(battle): alarm.set_physics_process(false)
	await frames()
	check(not FlowMenu.is_open() and battle.session == SortieRuntime.get_current_session(),"real authored battle attaches without a checkpoint error")
	return not FlowMenu.is_open()

func _refused(message: String) -> void:
	var inventory: Dictionary = battle.session.inventory.to_dict()
	var initial_ids: Array = battle.session.get_initial_carried_instance_ids()
	var before := PortableAlarm.live(battle).size()
	var result := PortableAlarm.place_for(battle.player)
	check(not result.get("success",false) and not String(result.get("message","")).is_empty() and battle.session.inventory.to_dict() == inventory and battle.session.get_initial_carried_instance_ids() == initial_ids and PortableAlarm.live(battle).size() == before,message + " / refusal consumes nothing")

func _place() -> PortableAlarm:
	var item := PortableAlarm.carried(battle.session)
	check(item != null,"fixture has an actual carried box to place")
	if not item: return null
	var id := item.instance_id
	var before: float = battle.session.inventory.current_weight
	var ids: Array = battle.session.get_initial_carried_instance_ids()
	var warehouse: Dictionary = ProfileRuntime.get_profile().inventory.to_dict()
	var cue: int = AudioDirector._next_sfx_player
	var result := PortableAlarm.place_for(battle.player)
	check(result.get("success",false),"clear nearby authored floor accepts actual placement")
	if not result.get("success",false): return null
	var alarm: PortableAlarm = result.alarm
	alarm.set_physics_process(false) # Explicit timer control, not accelerated real play.
	check(alarm.get_parent() == battle and result.instance_id == id and alarm.instance_id == id and not battle.session.inventory.contains(id),"placement consumes exactly the carried ID and represents it once as a direct Battle node")
	check(is_equal_approx(before-battle.session.inventory.current_weight,1.0) and battle.session.get_initial_carried_instance_ids() == ids and ProfileRuntime.get_profile().inventory.to_dict() == warehouse,"consumption removes one kilogram without changing original risk IDs or warehouse ownership")
	check(alarm.elapsed == 0 and alarm.pulses == 0 and AudioDirector._next_sfx_player == cue and not alarm.is_in_group("interactable"),"arming is silent and supplies no recoverable interaction")
	return alarm

func _block(position: Vector3, size: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new(); wall.collision_layer = 4; wall.collision_mask = 0
	var collider := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
	collider.shape = shape; wall.add_child(collider); battle.add_child(wall); wall.global_position = position
	return wall

func _runtime() -> void:
	if not await _load_battle(): return
	var actor: PlayerController = battle.player
	_refused("paused tree")
	get_tree().paused = false
	actor.is_dead = true; _refused("dead actor"); actor.is_dead = false
	var health: float = actor.health; actor.health = 0; _refused("zero health"); actor.health = health
	actor.preview_mode = true; _refused("preview actor"); actor.preview_mode = false
	battle.ending = true; _refused("ending battle"); battle.ending = false
	for status in [SortieSession.Status.PREPARING,SortieSession.Status.COMPLETED,SortieSession.Status.FAILED,SortieSession.Status.ABANDONED]:
		battle.session.status = status; _refused("inactive sortie")
	battle.session.status = SortieSession.Status.ACTIVE
	SortieRuntime._current_session = null; _refused("different current session"); SortieRuntime._current_session = battle.session
	actor.aim_input_captured = true; _refused("open interaction captures aim"); actor.aim_input_captured = false
	actor.velocity = Vector3.RIGHT; _refused("moving velocity"); actor.velocity = Vector3.ZERO
	actor._dodge_time = .1; _refused("dodge in progress"); actor._dodge_time = 0
	actor._fire_queued = true; _refused("buffered shot"); actor._fire_queued = false
	actor._reload_remaining_by_weapon[actor.weapon_instance.instance_id] = .5; _refused("reload in progress"); actor._reload_remaining_by_weapon.clear()
	actor.medical.item_id = "controlled_busy_medical"; actor.medical.remaining = .5
	_refused("medical action in progress"); actor.medical.item_id = ""; actor.medical.remaining = 0
	for action in ["move_left","move_right","move_forward","move_back","fire","dodge","reload","switch_weapon","interact"]:
		Input.action_press(action); _refused("held " + action); Input.action_release(action)
	var aim: Vector3 = actor.aim_direction
	actor.aim_direction = Vector3.ZERO; _refused("zero aim")
	actor.aim_direction = Vector3(NAN,0,0); _refused("nonfinite aim"); actor.aim_direction = aim
	var spawn: Vector3 = actor.global_position
	actor.global_position = Vector3(1000,.1,1000); await frames(); _refused("no supporting floor")
	actor.global_position = spawn; actor.aim_direction = Vector3.FORWARD; await frames()
	var target := spawn + Vector3.FORWARD * PortableAlarm.PLACE_DISTANCE
	var wall := _block(spawn+Vector3.FORWARD*.6+Vector3.UP*.6,Vector3(2,2,.15))
	await frames(); _refused("wall blocks placement sight"); wall.free(); await frames()
	var occupied := _block(target+Vector3.UP*.3,Vector3(.4,.5,.4))
	await frames(); _refused("occupied landing footprint"); occupied.free(); await frames()
	var alarm := _place()
	if not alarm: return
	await _checkpoint(alarm)
	# The valid roundtrip replaces the original node; use the surviving instance.
	alarm = PortableAlarm.live(battle)[0]
	var extra := ItemInstance.new(PortableAlarm.ITEM_ID)
	check(battle.session.inventory.add_item_preserving_instance(extra),"second complete tool is an explicit independent guard fixture")
	_refused("another live box occupies this landing point")
	await _sound_and_time(alarm)
	await frames()
	check(not battle.session.inventory.contains(alarm_id) and battle.session.inventory.contains(extra.instance_id),"expired placed ID never returns while unused second box stays carried")
	await _limits_and_lifecycle()

var alarm_id := ""

func _checkpoint(alarm: PortableAlarm) -> void:
	alarm_id = alarm.instance_id
	get_tree().paused = true
	var saved := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.VERSION == 6 and saved.alarms == [alarm.snapshot()] and SortieCheckpoint.validate_world(saved,battle),"version-6 world captures one exact alarm record and validates its existing signature")
	var malformed: Array = [null,{},1,"alarm"]
	for value in malformed:
		var invalid := saved.duplicate(true); invalid.alarms = value
		check(not SortieCheckpoint.validate_world(invalid,battle),"non-array alarm collection is rejected")
	var raw := alarm.snapshot()
	var bad_entries: Array = [null,{},[]]
	for change in [{"id":""},{"id":1},{"id":"x".repeat(129)},{"position":[0,0]},{"position":[0,INF,0]},{"position":[0,"0",0]},{"elapsed":-1},{"elapsed":9},{"elapsed":NAN},{"pulses":1},{"pulses":.5},{"pulses":true}]:
		var entry := raw.duplicate(true); entry.merge(change,true); bad_entries.append(entry)
	var extra := raw.duplicate(true); extra.extra = 1; bad_entries.append(extra)
	var missing := raw.duplicate(true); missing.erase("pulses"); bad_entries.append(missing)
	for entry in bad_entries:
		var invalid := saved.duplicate(true); invalid.alarms = [entry]
		check(not SortieCheckpoint.validate_world(invalid,battle),"malformed individual alarm cannot enter a full world")
	var duplicate := saved.duplicate(true); duplicate.alarms.append(raw.duplicate(true))
	check(not SortieCheckpoint.validate_world(duplicate,battle),"duplicate alarm IDs are rejected")
	var too_many := saved.duplicate(true); too_many.alarms = []
	for index in 9:
		var entry := raw.duplicate(true); entry.id = ItemInstance.new(PortableAlarm.ITEM_ID).instance_id; too_many.alarms.append(entry)
	check(not SortieCheckpoint.validate_world(too_many,battle),"more than eight alarm records are rejected")
	var carried_collision := saved.duplicate(true); carried_collision.alarms[0].id = battle.session.inventory.get_items()[0].instance_id
	check(not SortieCheckpoint.validate_world(carried_collision,battle),"world alarm cannot also exist in carried inventory")
	var cache_id := ""
	for entry in saved.nodes.values():
		if entry.has("items") and not entry.items.is_empty(): cache_id = entry.items[0].item.instance_id; break
	check(not cache_id.is_empty(),"real authored loot cache supplies a collision fixture")
	if not cache_id.is_empty():
		var cache_collision := saved.duplicate(true); cache_collision.alarms[0].id = cache_id
		check(not SortieCheckpoint.validate_world(cache_collision,battle),"world alarm cannot also exist in an authored cache")
	var inventory: Dictionary = battle.session.inventory.to_dict()
	var position: Vector3 = battle.player.position
	check(not SortieCheckpoint.restore_world(duplicate,battle) and is_instance_valid(alarm) and PortableAlarm.live(battle) == [alarm] and battle.session.inventory.to_dict() == inventory and battle.player.position == position,"failed complete-world validation does not free alarms or mutate actor/inventory")
	var cue: int = AudioDirector._next_sfx_player
	check(SortieCheckpoint.restore_world(saved,battle),"valid signed world restores")
	var restored := PortableAlarm.live(battle)
	check(not is_instance_valid(alarm) and restored.size() == 1 and restored[0].snapshot() == raw and battle.session.inventory.to_dict() == inventory and AudioDirector._next_sfx_player == cue,"valid restore replaces old nodes once, preserves identity/timer and remains silent")
	for node in restored: node.set_physics_process(false)
	var legacy := saved.duplicate(true); legacy.erase("alarms")
	check(SortieCheckpoint.validate_world(legacy,battle) and SortieCheckpoint.restore_world(legacy,battle) and PortableAlarm.live(battle).is_empty() and battle.session.inventory.to_dict() == inventory,"explicit legacy missing-field schema fixture restores empty, without refund; not an old-binary claim")
	check(SortieCheckpoint.restore_world(saved,battle) and PortableAlarm.live(battle).size() == 1,"repeated snapshot restoration never duplicates the same alarm")
	for node in PortableAlarm.live(battle): node.set_physics_process(false)
	get_tree().paused = false

func _sound_and_time(alarm: PortableAlarm) -> void:
	var actor: PlayerController = battle.player
	var listener: EnemyController = battle.enemy_container.get_child(0)
	var count: int = battle.enemy_container.get_child_count()
	var kills: int = battle.session.enemies_defeated
	var objectives: Array = battle.session.get_objective_summary()
	listener.global_position = alarm.global_position + Vector3.RIGHT*5
	listener.awareness = EnemyAwareness.new(); listener.ensure_awareness()
	await frames()
	listener.set_physics_process(true)
	alarm._physics_process(2.99)
	check(alarm.pulses == 0 and listener.awareness.state == EnemyAwareness.State.PATROL,"arming delay produces no immediate hearing")
	alarm._physics_process(.02)
	check(alarm.pulses == 1 and listener.awareness.state == EnemyAwareness.State.INVESTIGATE and listener.awareness.last_known.is_equal_approx(alarm.global_position) and not listener.awareness.last_known.is_equal_approx(actor.global_position),"first scheduled pulse uses actual CombatNoise to lead an existing enemy to the box, not hidden player coordinates")
	listener.set_physics_process(false)
	# Explicit confirmed-contact fixture exercises the real awareness priority rule.
	listener.awareness.state = EnemyAwareness.State.COMBAT; listener.awareness.target_visible = true
	listener.awareness.last_known = actor.global_position
	listener.set_physics_process(true); actor.velocity = Vector3.RIGHT
	alarm._physics_process(2.0)
	check(alarm.pulses == 2 and not alarm.is_queued_for_deletion() and listener.awareness.state == EnemyAwareness.State.COMBAT and listener.awareness.last_known.is_equal_approx(actor.global_position),"moving after placement does not delete it and a visible COMBAT target is never forgotten")
	actor.velocity = Vector3.ZERO; listener.set_physics_process(false)
	listener.global_position = alarm.global_position + Vector3.RIGHT*16
	listener.awareness = EnemyAwareness.new(); listener.ensure_awareness()
	var untouched: Vector3 = listener.awareness.last_known
	var wall := _block(alarm.global_position+Vector3.RIGHT*8+Vector3.UP,Vector3(.3,4,4))
	await frames()
	listener.set_physics_process(true); alarm._physics_process(2.0); listener.set_physics_process(false)
	check(alarm.pulses == 3 and listener.awareness.state == EnemyAwareness.State.PATROL and listener.awareness.last_known.is_equal_approx(untouched),"a real intervening world wall attenuates the third pulse below a sixteen-metre listener")
	wall.free()
	get_tree().paused = true
	var snapshot := alarm.snapshot(); alarm._physics_process(10); await frames(4)
	check(alarm.snapshot() == snapshot and not alarm.is_queued_for_deletion(),"paused scheduling and explicit paused tick preserve the exact remaining lifetime")
	get_tree().paused = false; alarm._physics_process(2.0)
	check(alarm.pulses == 3 and alarm.is_queued_for_deletion() and SortieCheckpoint.capture_world(battle).alarms.is_empty(),"nine seconds expires once with no fourth pulse and queued nodes are excluded from saves")
	check(battle.enemy_container.get_child_count() == count and battle.session.enemies_defeated == kills and battle.session.get_objective_summary() == objectives,"ringing spawns no enemies and grants no kills or objective progress")

func _limits_and_lifecycle() -> void:
	var actor: PlayerController = battle.player
	var origin: Vector3 = actor.global_position
	for index in PortableAlarm.MAX_LIVE:
		var raw := {"id":ItemInstance.new(PortableAlarm.ITEM_ID).instance_id,"position":[origin.x+4+index,origin.y,origin.z],"elapsed":0.0,"pulses":0}
		var node := PortableAlarm.restore_node(raw,battle)
		check(node != null,"controlled capacity fixture restores a distinct noncarried ID")
		if node: node.set_physics_process(false)
	_refused("eight live sources")
	for node in PortableAlarm.live(battle): node.free()
	var alarm := _place()
	if not alarm: return
	_refused("no further packed box")
	actor.is_dead = true; alarm._physics_process(4)
	check(alarm.is_queued_for_deletion() and alarm.pulses == 0,"death invalidates a pending source before it can ring")
	actor.is_dead = false; await frames()
	for boundary in ["ending","failed"]:
		var raw := {"id":ItemInstance.new(PortableAlarm.ITEM_ID).instance_id,"position":[origin.x+4,origin.y,origin.z],"elapsed":2.9,"pulses":0}
		var node := PortableAlarm.restore_node(raw,battle); node.set_physics_process(false)
		if boundary == "ending": battle.ending = true
		else: battle.session.status = SortieSession.Status.FAILED
		node._physics_process(1)
		check(node.is_queued_for_deletion() and node.pulses == 0,"pending source cannot ring after " + boundary)
		battle.ending = false; battle.session.status = SortieSession.Status.ACTIVE; await frames()

func _disk(read_saved: bool) -> void:
	if not await _load_battle(read_saved): return
	var session: SortieSession = battle.session
	if not read_saved:
		get_tree().paused = false
		var alarm := _place()
		if not alarm: return
		alarm._physics_process(3.25)
		get_tree().paused = true
		var world := SortieCheckpoint.capture_world(battle)
		check(alarm.pulses == 1 and is_equal_approx(alarm.elapsed,3.25) and SortieCheckpoint.validate_world(world,battle),"actual first pulse advances into a legal partial durable instant")
		check(SortieRuntime.save_checkpoint() == OK,"partial alarm commits through the ordinary atomic world writer")
		var expected := {"alarm":alarm.snapshot(),"session":SortieCheckpoint.session_data(session),"layout":world.layout,"warehouse":ProfileRuntime.get_profile().inventory.to_dict()}
		var file := FileAccess.open(EXPECTED_PATH,FileAccess.WRITE)
		check(file != null,"isolated expected-state file opens")
		if file: file.store_string(JSON.stringify(expected)); file.close()
		print("PORTABLE_ALARM_WORLD_WRITE / elapsed=",alarm.elapsed," pulses=",alarm.pulses," id=",alarm.instance_id)
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED_PATH))
		var sources := PortableAlarm.live(battle)
		check(sources.size() == 1,"independent process restores exactly one source")
		if sources.size() != 1: return
		var alarm := sources[0]
		var world := SortieCheckpoint.capture_world(battle)
		check(json_value(alarm.snapshot()) == expected.alarm and alarm.pulses == 1 and is_equal_approx(alarm.elapsed,3.25),"process continuation retains exact ID, partial timer and emitted-pulse count")
		check(json_value(SortieCheckpoint.session_data(session)) == expected.session and json_value(ProfileRuntime.get_profile().inventory.to_dict()) == expected.warehouse and not session.inventory.contains(alarm.instance_id),"process continuation preserves exact carried and warehouse ownership without returning consumed ID")
		check(SortieCheckpoint.validate_world(world,battle) and world.layout == expected.layout and world.layout == SortieCheckpoint.layout_signature(battle.area_root),"restored authored world still validates its collision signature")
		var cue: int = AudioDirector._next_sfx_player
		get_tree().paused = false; alarm._physics_process(0)
		check(alarm.pulses == 1 and AudioDirector._next_sfx_player == cue,"zero-time resume does not replay a saved pulse")
		alarm._physics_process(1.74)
		check(alarm.pulses == 1,"saved timer does not ring before five seconds")
		alarm._physics_process(.02)
		check(alarm.pulses == 2,"only the second scheduled pulse remains at five seconds")
		alarm._physics_process(2)
		check(alarm.pulses == 3,"only the third scheduled pulse remains at seven seconds")
		alarm._physics_process(2)
		check(alarm.pulses == 3 and alarm.is_queued_for_deletion() and not session.inventory.contains(expected.alarm.id),"resumed nine-second expiry neither repeats nor refunds the consumed tool")
