extends "res://tests/maintenance_test.gd"
## Controlled component fixtures: placements, frozen AI, forced-capacity negative case.
## Not normal combat/escort, native visuals, playtime or source integration proof.
const CACHE_PATH := "user://maintenance_shared_test.json"
const IDS_PATH := "user://maintenance_shared_expected.json"
const PENDING_PATH := "user://maintenance_shared_pending_test.json"

func _ready() -> void:
	get_tree().create_timer(60,true).timeout.connect(func():check(false,"component deadline");get_tree().quit(1))
	super._ready()

func finish_shared() -> void:
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session()
	get_tree().paused=false
	await frames()
	AudioDirector.shutdown_for_test()
	print("MAINTENANCE_SHARED_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",false)
	check(TranslationServer.get_locale()==("en" if "--english" in args else "zh_CN"),"actual requested locale is active, not inferred from flag")
	check(MaintenanceJourney.valid({"version":3.0,"steam_off":false},MaintenanceStory.AREA,MaintenanceStory.MISSION,[]),"JSON numeric v3 accepted without strict Array membership")
	for version in [1,3.5,4,"3"]:
		check(not MaintenanceJourney.valid({"version":version,"steam_off":false},MaintenanceStory.AREA,MaintenanceStory.MISSION,[]),"invalid non-v2/v3 version refused: "+str(version))
	if "--read" in args or "--pending-read" in args or "--legacy-v2" in args or "--legacy-v1" in args:
		var read_path:=PENDING_PATH if "--pending-read" in args else CACHE_PATH
		var loaded_ok := ProfileRuntime.load_profile(read_path) and SortieRuntime.resume_saved(read_path)==OK
		check(loaded_ok,"independent signed checkpoint is accepted")
		if not loaded_ok: await finish_shared();return
		get_tree().paused=true
		await load_battle()
		check(not FlowMenu.is_open(),"no invalid-checkpoint fallback")
		if "--pending-read" in args:
			var cache: MaintenanceSharedCache=battle.area_root.get_node("SharedToolbox")
			var helper: SharedMaintenanceSurvivor=battle.area_root.get_node("Survivor")
			check(not cache.has_rolled and not cache.enabled and cache.closed_case.visible,"mid-assist save restores locked toolbox, not a reward")
			check(not is_instance_valid(helper.helping_cache) and helper.waiting,"temporary request safely resets after restart, preserving saved wait command")
			var items:=0
			for child in cache.get_children():
				if child is LootPickup:items+=1
			check(items==0 and SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"interrupted pending task has no generated items and legitimate saved positions")
			await finish_shared();return
		if "--legacy-v2" in args or "--legacy-v1" in args:
			var expected := 2 if "--legacy-v2" in args else 1
			check(int(battle.area_root.get_meta("map_revision"))==expected and not battle.area_root.has_node("SharedToolbox"),"old checkpoint keeps its original map; no retroactive box")
			check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"legacy world still validates under new loader")
			await finish_shared();return
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(IDS_PATH))
		var cache: MaintenanceSharedCache=battle.area_root.get_node("SharedToolbox")
		check(int(battle.area_root.get_meta("map_revision"))==3 and cache.has_rolled and cache.enabled,"actual unlocked v3 toolbox restores")
		check(not cache.closed_case.visible,"restore refreshes unlocked furniture even while paused")
		check(battle.session.inventory.contains(expected.taken),"actual taken item survives signed disk roundtrip")
		var remaining: Array[String]=[]
		for node in cache.get_children():
			if node is LootPickup:remaining.append(node.item_instance.instance_id)
		check(remaining==expected.remaining,"untaken real pickup IDs survive; no reroll or duplicate")
		check(battle.area_root.get_node("Survivor").waiting,"unlatch never silently changed wait/follow command")
		await finish_shared();return
	check(DeploymentPlan.deploy(fixture(),MaintenanceStory.AREA,MaintenanceStory.MISSION,CACHE_PATH).error==OK,"normal deployment transaction accepts completed-campus fixture")
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var cache: MaintenanceSharedCache=world.get_node("SharedToolbox")
	var helper: MaintenanceSurvivor=world.get_node("Survivor")
	helper.set_physics_process(false);world.get_node("Steam").set_physics_process(false)
	check(session.maintenance.version==3 and int(world.get_meta("map_revision"))==3 and session.validate(),"fresh session chooses typed v3, not old geometry")
	check(not cache.enabled and not cache.has_rolled,"toolbox starts latched and unrolled")
	check(world.get_node("Supplies").has_rolled and world.get_node("WardSupplies").has_rolled,"both original ordinary caches remain untouched")
	var original_loot := []
	for name in ["Supplies","WardSupplies"]:
		for node in world.get_node(name).get_children():
			if node is LootPickup:original_loot.append(node.item_instance.to_dict())
	var inventory_before := session.inventory.to_dict()
	battle.player.position=cache.player_position()
	helper.position=cache.position+Vector3.LEFT*2
	await frames()
	check(not cache.interact(battle.player,session).success,"cannot enlist an unreleased survivor through the ward")
	helper.position=Vector3(15,0,-11);await frames()
	var forged:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(forged,battle),"unmodified pre-release world validates before forgery")
	var phantom := ItemInstance.new(&"material.parts",1)
	var injected := forged.duplicate(true)
	injected.nodes.SharedToolbox.items=[{"item":phantom.to_dict(),"interactable":true}]
	check(not SortieCheckpoint.validate_world(injected,battle),"unrolled toolbox refuses unique forged pickup, not just duplicate IDs")
	forged.nodes.SharedToolbox.enabled=true;forged.nodes.SharedToolbox.has_rolled=true
	check(not SortieCheckpoint.validate_world(forged,battle),"forged pre-release unlocked toolbox is refused")
	check((await use("Bypass")).success and (await use("WardControl")).success,"ordinary control methods earn actual release objective")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.position=cache.player_position();helper.position=Vector3(15,0,-11)
	await frames()
	check(cache.interact(battle.player,session).success and not cache.has_rolled,"explicit request sends helper toward handle but does not remotely open box")
	helper.waiting=true;helper.set_physics_process(true)
	await frames(8)
	check(not cache.has_rolled and SortieRuntime.save_checkpoint()==OK,"mid-walk assistance checkpoint saves without rolling loot")
	var pending_file:=FileAccess.open(PENDING_PATH,FileAccess.WRITE)
	pending_file.store_string(FileAccess.get_file_as_string(CACHE_PATH));pending_file.close()
	battle.player.position=Vector3(0,0,24)
	await frames(4)
	check(not is_instance_valid((helper as SharedMaintenanceSurvivor).helping_cache) and helper.waiting and not cache.has_rolled,"walking away cancels temporary assistance and preserves wait/loot state")
	helper.set_physics_process(false)
	battle.player.position=cache.player_position()

	helper.position=Vector3(22,0,cache.position.z);await frames()
	check(helper.position.distance_to(cache.position)<8 and not cache.interact(battle.player,session).success,"nearby helper behind actual ward wall cannot assist")
	helper.position=cache.helper_position();helper.waiting=true
	battle.player.position=cache.position+Vector3.RIGHT*4;await frames()
	check(not cache.interact(battle.player,session).success,"player outside interaction range/behind wall cannot pull handle")
	battle.player.position=cache.player_position();await frames()
	check(cache.interact(battle.player,session).success and not cache.has_rolled,"request can be restarted after cancellation without free opening")
	helper.set_physics_process(true)
	for _tick in 120:
		await frames(1)
		if (helper as SharedMaintenanceSurvivor).is_bracing(cache):break
	check((helper as SharedMaintenanceSurvivor).is_bracing(cache),"helper reaches real grip contacts, not merely an Interact clip near the box")
	var reach=(helper as SharedMaintenanceSurvivor).handle_reach
	var skeleton:=helper.model.get_node(helper.PROFILE.skeleton_path) as Skeleton3D
	var original_positions: Array[Vector3]=[]
	var original_scales: Array[Vector3]=[]
	var probe:={"scope":"controlled real-skeleton contact/rotation-only, not native visuals or earned combat","samples":[],"max_palm_error_m":0.0,"max_segment_length_change_m":0.0}
	var lengths: Array[Vector2]=[]
	for chain in reach.arms:
		lengths.append(Vector2(skeleton.get_bone_global_pose(chain[0]).origin.distance_to(skeleton.get_bone_global_pose(chain[1]).origin),skeleton.get_bone_global_pose(chain[1]).origin.distance_to(skeleton.get_bone_global_pose(chain[2]).origin)))
	for bone in skeleton.get_bone_count():
		original_positions.append(skeleton.get_bone_pose_position(bone));original_scales.append(skeleton.get_bone_pose_scale(bone))
	for _tick in 60:
		await frames(1)
		check(reach.last_grips.size()==2 and reach.contact_ready,"both actual palms stay on the grip across authored animation frames")
		var sample:=[]
		for index in reach.last_grips.size():
			var error: float=reach.last_grips[index].distance_to(cache.helper_grip(index))
			probe.max_palm_error_m=maxf(probe.max_palm_error_m,error)
			check(error<.045,"actual palm remains within grip contact tolerance")
			sample.append({"actual":str(reach.last_grips[index]),"goal":str(cache.helper_grip(index)),"error_m":error})
		probe.samples.append(sample)
		# The authored clip legitimately animates the pelvis translation. Check
		# all affected arm-chain bones, not unrelated animated root/hip tracks.
		for chain in reach.arms:
			for bone in chain:
				check(skeleton.get_bone_pose_position(bone).is_equal_approx(original_positions[bone]) and skeleton.get_bone_pose_scale(bone).is_equal_approx(original_scales[bone]),"arm reach preserves every affected bone translation and scale")
		for index in reach.arms.size():
			var chain: Array=reach.arms[index]
			var measured:=Vector2(skeleton.get_bone_global_pose(chain[0]).origin.distance_to(skeleton.get_bone_global_pose(chain[1]).origin),skeleton.get_bone_global_pose(chain[1]).origin.distance_to(skeleton.get_bone_global_pose(chain[2]).origin))
			var error: float=maxf(absf(measured.x-lengths[index].x),absf(measured.y-lengths[index].y))
			probe.max_segment_length_change_m=maxf(probe.max_segment_length_change_m,error)
			check(error<.00001,"both measured arm segment lengths are preserved across clip frames")
	check(not cache.closed_case.get_node("WorldLabel").visible,"nearby help uses readable HUD prompt, not a billboard over the actors")
	battle.player.position=Vector3(0,0,24);await frames(4)
	check(not is_instance_valid((helper as SharedMaintenanceSurvivor).helping_cache) and not reach.contact_ready and reach.influence==0 and not cache.has_rolled,"walking away after actual contact clears both task and arm pose without opening the box")
	battle.player.position=cache.player_position();await frames(2)
	check(cache.interact(battle.player,session).success and not cache.has_rolled,"cancelled real contact can be requested again without a free opening")
	for _tick in 120:
		await frames(1)
		if (helper as SharedMaintenanceSurvivor).is_bracing(cache):break
	# Explicit controlled miniature-rig negative case: unreachable targets must not
	# stretch bones or advertise ready. This is not an earned route/model change.
	helper.model.scale*=.5
	await frames(30)
	check(not (helper as SharedMaintenanceSurvivor).is_bracing(cache) and not reach.contact_ready,"unreachable handles cannot become ready by stretching the arm")
	probe.unreachable_rejected=not (helper as SharedMaintenanceSurvivor).is_bracing(cache)
	check(cache.interact(battle.player,session).success and not cache.has_rolled,"unreachable request remains pending rather than awarding contents")
	helper.model.scale*=2
	for _tick in 120:
		await frames(1)
		if (helper as SharedMaintenanceSurvivor).is_bracing(cache):break
	check((helper as SharedMaintenanceSurvivor).is_bracing(cache),"normal rig can re-establish contact after unreachable controlled negative")
	var probe_file:=FileAccess.open("user://maintenance_contact_probe.json",FileAccess.WRITE)
	probe_file.store_string(JSON.stringify(probe,"\t"));probe_file.close()
	helper.set_physics_process(false)
	var result:=cache.interact(battle.player,session)
	check(result.success and result.information==tr(MaintenanceSharedCache.EXCHANGE),"two nearby visible actors unlatch with authored banter")
	check(helper.waiting and session.inventory.to_dict()==inventory_before,"help preserves companion command and never auto-grants contents")
	var pickups: Array[LootPickup]=[]
	for node in cache.get_children():
		if node is LootPickup:pickups.append(node)
	check(cache.enabled and cache.has_rolled and pickups.size()==2,"one successful action rolls one medical supply and one intact fitting kit")
	await frames(2)
	check(pickups.all(func(item):return not item._name_label.visible),"toolbox contents have no stacked item-name billboards; inspection UI retains real names")
	check(pickups.filter(func(item):return WeaponFitting.KITS.has(item.item_instance.definition_id)).size()==1,"assisted discovery guarantees one existing useful kit, not only sale-value scrap")
	var before_ids: Array[String]=[]
	for pickup in pickups:before_ids.append(pickup.item_instance.instance_id)
	check(not cache.interact(battle.player,session).success,"repeat interaction cannot generate more loot")
	var again := cache.spawn(RandomNumberGenerator.new())
	check(again.is_empty(),"normal loot-spawn guard also prevents reroll")
	var original_after := []
	for name in ["Supplies","WardSupplies"]:
		for node in world.get_node(name).get_children():
			if node is LootPickup:original_after.append(node.item_instance.to_dict())
	check(original_loot==original_after,"optional repair rolls never displace or rewrite original medical contents")
	var capacity: float=session.inventory.capacity
	session.inventory.capacity=session.inventory.current_weight
	check(pickups[0].try_pickup(session)==LootPickup.PickupResult.CAPACITY_FULL and not pickups[0].consumed,"overweight real loot stays in world")
	session.inventory.capacity=capacity
	var taken := pickups[0].item_instance.instance_id
	check(pickups[0].try_pickup(session)==LootPickup.PickupResult.SUCCESS,"normal pickup path transfers actual instance")
	await frames()
	var exchange_source:=ItemInstance.new(&"material.parts",1)
	check(session.inventory.add_item(exchange_source),"explicit controlled cargo fixture supplies a legal loot-tagged exchange stack")
	var incoming_id := pickups[1].item_instance.instance_id
	check(pickups[1].exchange_cargo(session,exchange_source.instance_id)==LootPickup.PickupResult.SUCCESS,"legitimate whole-stack cargo exchange stays in same world slot")
	check(session.inventory.contains(incoming_id) and not session.inventory.contains(exchange_source.instance_id) and pickups[1].item_instance.instance_id==exchange_source.instance_id,"exchange conserves both actual instance IDs")
	before_ids[1]=exchange_source.instance_id
	var snapshot:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(snapshot,battle),"legitimate mixed carried/untaken toolbox world validates")
	forged=snapshot.duplicate(true)
	for _extra in 2:
		forged.nodes.SharedToolbox.items.append({"item":ItemInstance.new(&"material.parts",1).to_dict(),"interactable":true})
	check(not SortieCheckpoint.validate_world(forged,battle),"toolbox refuses more physical slots than its authored roll count")

	forged=snapshot.duplicate(true);forged.nodes.SharedToolbox.enabled=false
	check(not SortieCheckpoint.validate_world(forged,battle),"inconsistent relocked but rolled toolbox is refused")
	check(SortieRuntime.save_checkpoint()==OK,"normal signed checkpoint persists helper, taken cargo and remaining items")
	var expected_file:=FileAccess.open(IDS_PATH,FileAccess.WRITE)
	expected_file.store_string(JSON.stringify({"taken":taken,"remaining":[before_ids[1]]}));expected_file.close()
	await finish_shared()
