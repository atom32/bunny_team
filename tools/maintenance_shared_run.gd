extends "res://tools/maintenance_run.gd"
## Ordinary BOOT, live AI, paid ammo, real escort and real E/TAKE. No grants/teleport.
const SHARED_EXPECTED := "user://maintenance_shared_run_expected.json"
var recovered: Dictionary = {}
var shared_contents: Array = []

func work(name: String) -> bool:
	if not await super.work(name): return false
	if name != "WardControl": return true
	var cache: MaintenanceSharedCache=battle.area_root.get_node("SharedToolbox")
	var companion: MaintenanceSurvivor=battle.area_root.get_node("Survivor")
	check(int(battle.area_root.get_meta("map_revision"))==3 and not cache.has_rolled,"ordinary fresh sortie has optional v3 toolbox, not preopened reward")
	if not await walk(cache.player_position(),true):return false
	var component: InteractionComponent=battle.player.interaction_component
	component._physics_process(0)
	check(component._current_target==cache,"ordinary navigation reaches the actual player handle")
	if component._current_target!=cache:return false
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed;Input.parse_input_event(event)
		await _frames(4)
	for tick in 600:
		await tree.physics_frame;controls(battle.player.global_position)
		if (companion as SharedMaintenanceSurvivor).is_bracing(cache):break
	release();await _frames(3)
	check((companion as SharedMaintenanceSurvivor).is_bracing(cache),"requested helper actually walks to the second handle, no teleport")
	var grips: Array=[]
	for index in (companion as SharedMaintenanceSurvivor).handle_reach.last_grips.size():
		var palm: Vector3=(companion as SharedMaintenanceSurvivor).handle_reach.last_grips[index]
		check(palm.distance_to(cache.helper_grip(index))<.045,"ordinary walking helper makes actual palm contact before claiming ready")
		grips.append({"actual":str(palm),"goal":str(cache.helper_grip(index)),"error_m":palm.distance_to(cache.helper_grip(index))})
	check(grips.size()==2,"both physical palms are sampled from actual post-animation skeleton")
	evidence["actual_handle_grips"]=grips
	evidence["shared_unlatch_positions"]={"player":str(battle.player.global_position),"helper":str(companion.global_position),"cache":str(cache.global_position),"helper_goal":str(cache.helper_position()),"clip":companion.animation.current_animation}
	await _capture("shared_00_helper_ready")
	component._physics_process(0)
	check(component._current_target==cache,"ready-helper prompt leaves physical handle targeted, not companion toggle")
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed;Input.parse_input_event(event)
		await _frames(4)
	check(cache.has_rolled and cache.enabled,"actual nearby E unlatches toolbox with no direct objective or item assignment")
	if not cache.has_rolled:return false
	await _capture("shared_01_unlatched")
	component._physics_process(0)
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed;Input.parse_input_event(event)
		await _frames(4)
	var ui: Node=battle.get_node("SlicePresentation")
	check(is_instance_valid(ui.panel) and ui.container.get_parent()==cache,"second normal E inspects real toolbox contents")
	if not is_instance_valid(ui.panel):return false
	for row in ui._cache_rows:shared_contents.append(row.pickup.item_instance.to_dict())
	check(shared_contents.size()==2,"optional case has a medical supply and one intact kit")
	for row in ui._cache_rows:
		if row.take.disabled or not WeaponFitting.KITS.has(row.pickup.item_instance.definition_id):continue
		recovered=row.pickup.item_instance.to_dict()
		var scroller: Node=row.take.get_parent()
		while scroller and not scroller is ScrollContainer:scroller=scroller.get_parent()
		if scroller:scroller.ensure_control_visible(row.take)
		await _frames(4);await _click(row.take);break
	check(not recovered.is_empty() and WeaponFitting.KITS.has(StringName(recovered.get("definition_id",""))) and battle.session.inventory.contains(recovered.instance_id) and not ProfileRuntime.get_profile().inventory.contains(recovered.instance_id),"TAKE puts exact found instance in field cargo, not warehouse")
	await _capture("shared_02_actual_take")
	await _click(ui.panel.find_child("CloseCache",true,false))
	evidence["shared_contents"]=shared_contents;evidence["recovered"]=recovered
	return failures.is_empty()

func return_from_debrief() -> bool:
	if not await super.return_from_debrief():return false
	var profile:=ProfileRuntime.get_profile()
	check(not recovered.is_empty() and profile.inventory.contains(recovered.instance_id) and profile.inventory.get_item(recovered.instance_id).to_dict()==recovered,"normal safe return banks exact assisted pickup")
	if failures.is_empty():
		var f:=FileAccess.open(SHARED_EXPECTED,FileAccess.WRITE)
		f.store_string(JSON.stringify({"item":recovered,"contents":shared_contents,"profile":profile.to_dict()}));f.close()
	return failures.is_empty()

func finish() -> void:
	var profile:=ProfileRuntime.get_profile()
	if "--read" in OS.get_cmdline_user_args() and FileAccess.file_exists(SHARED_EXPECTED):
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SHARED_EXPECTED))
		recovered=expected.item;shared_contents=expected.contents
		var wanted:=ProfileState.from_dict(expected.profile).to_dict()
		var actual:=profile.to_dict()
		for data in [wanted,actual]:data.erase("stash_layout")
		check(actual==wanted,"independent BOOT retains every gameplay field after actual assisted rescue")
	check(not recovered.is_empty() and profile.inventory.contains(recovered.get("instance_id","")) and profile.successful_sorties==_expected_returns(7) and profile.maintenance_rescued and profile.sortie_checkpoint.is_empty(),"full assisted cargo and actual rescue return required; partial route is failure")
	evidence["recovered"]=recovered;evidence["shared_contents"]=shared_contents;evidence["profile_after"]=profile.to_dict();evidence["checks"]=checks;evidence["failures"]=failures
	var f:=FileAccess.open(out.path_join("maintenance_shared_run.json"),FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"\t"));f.close()
	super.finish()
