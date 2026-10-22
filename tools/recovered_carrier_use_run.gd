extends "res://tools/recovered_carrier_run.gd"
## Earned pack followed by an ordinary further sortie. No fixture equipment/state.
var carrier_trial_active := false
var carrier_peak_speed := 0.0

func controls(destination: Vector3) -> void:
	super.controls(destination)
	if carrier_trial_active:
		carrier_peak_speed=maxf(carrier_peak_speed,Vector2(battle.player.velocity.x,battle.player.velocity.z).length())

func return_home(exit: ExtractionPoint,ending:=false) -> bool:
	if not await super.return_home(exit,ending):return false
	return await _use_pack()

func _use_pack() -> bool:
	var profile:=ProfileRuntime.get_profile()
	check(profile.successful_sorties==_expected_returns(8) and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)==rebuilt_id,"same earned rebuilt pack is ready for the next ordinary outing")
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return false
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	var choice:=tree.current_scene.find_child("MissionChoice",true,false) as OptionButton
	var index:=DeploymentPlan.STREET_MISSIONS.find(&"streets_recon")
	check(choice!=null and index>=0,"existing public sortie selector offers optional campus trip")
	if choice==null or index<0:return false
	choice.select(index);choice.item_selected.emit(index);await _frames()
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):return false
	battle=tree.current_scene;carrier_trial_active=true
	battle.player.weapon_fired.connect(func(_recoil:float):fired+=1)
	var shots_before:=fired
	var item:=profile.inventory.get_item(rebuilt_id)
	var capacity:=47.0 if item.definition_id==RecoveredCarrier.FREIGHT else 27.0
	var speed:float=battle.player.get_movement_speed()
	check(battle.player.backpack_instance.instance_id==rebuilt_id and battle.session.inventory.capacity==capacity,"next live player carries exact earned pack and its actual cargo limit")
	var target:LootSpawnPoint
	for point in battle.area_root.find_children("*","LootSpawnPoint",true,false):
		if point.enabled and point.loot_table_id==&"prototype_high_value_loot":target=point;break
	check(target!=null,"ordinary authored high-value cache exists; no fabricated trial target")
	if target==null or not await walk(target.global_position):return false
	release();await _frames()
	for down in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=down;Input.parse_input_event(event);await _frames()
	var ui:Node=battle.get_node("SlicePresentation")
	check(is_instance_valid(ui.panel) and ui.container.get_parent()==target,"ordinary E inspects an actual second-sortie cache with the new pack")
	if not is_instance_valid(ui.panel):return false
	var row:Dictionary=ui._cache_rows[0]
	var cargo_id:String=row.pickup.item_instance.instance_id
	await _scroll_to(row.take);await _click(row.take)
	check(battle.session.inventory.contains(cargo_id),"real cache TAKE uses new pack's capacity, not a free inventory assignment")
	await _capture("carrier_04_next_sortie_cargo")
	await _click(ui.panel.find_child("CloseCache",true,false))
	var retreat:ExtractionPoint
	for number in 4:
		var candidate:ExtractionPoint=battle.area_root.get_node("Exit%d"%number)
		if candidate.available and candidate.required_objective_id.is_empty():retreat=candidate;break
	if retreat==null or not await walk(retreat.global_position):return false
	release()
	evidence["pack_trial"]={"pack_id":rebuilt_id,"capacity":battle.session.inventory.capacity,"expected_speed":speed,"peak_observed_speed":carrier_peak_speed,"shots":fired-shots_before,"kills":battle.session.enemies_defeated,"cargo_id":cargo_id,"health":battle.player.health}
	check(is_equal_approx(carrier_peak_speed,speed),"ordinary movement actually reaches the selected pack's speed during live outing")
	check(retreat.interact(battle.player,battle.session).success,"actual nearby retreat interaction ends second outing")
	if not await _wait_scene("res://scenes/result/result.tscn"):return false
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):return false
	carrier_trial_active=false
	check(profile.successful_sorties==_expected_returns(9) and profile.sortie_checkpoint.is_empty() and profile.inventory.contains(cargo_id) and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK)==rebuilt_id,"ninth safe return banks actual trial cargo and keeps the exact earned pack")
	await _capture("carrier_05_trial_returned")
	await _click(_button("MENU"))
	if not await _wait_scene("res://scenes/presentation/slice/boot.tscn"):return false
	evidence["profile_after"]=profile.to_dict()
	var file:=FileAccess.open("user://carrier_run_expected.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"carrier":carrier,"rebuilt_id":rebuilt_id,"profile":profile.to_dict(),"pack_trial":evidence.pack_trial}));file.close()
	return failures.is_empty()

func finish() -> void:
	if "--read" not in OS.get_cmdline_user_args():
		check(evidence.has("pack_trial") and evidence.get("profile_after",{}).get("successful_sorties",0)==9,"full next-sortie use and safe ninth return required; no partial PASS")
	super.finish()
