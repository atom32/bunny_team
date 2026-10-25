extends "res://tests/campus_q02_run.gd"
## Ordinary earned profile, unseeded sorties, live AI and actual inventory UI.
## No progression writes, item grants, teleports or forced focus/pause recovery.
var found: Dictionary = {}
var trial := false
var trial_shots := 0
var trial_reload: Dictionary = {}
var trial_initial_kills := 0

func _deadline_seconds() -> float: return 1200.0

func _run() -> void:
	tree=get_tree(); tree.current_scene=null
	if "--resume-owned-trial" in OS.get_cmdline_user_args():
		await _resume_owned_trial();_finish();return
	var profile:=ProfileRuntime.get_profile()
	evidence["method"]="Unedited earned preview save; ordinary BOOT/Continue, unseeded campus sorties and actual E/TAKE/return, warehouse double-click, paid ammo if needed, another live sortie. Synthetic input, NOT human fun or playtime proof."
	evidence["profile_before"]=profile.to_dict()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.first_mission_completed and profile.ar_damage_upgraded and profile.sortie_checkpoint.is_empty(),"actual earned base profile, no suspended or fabricated world")
	if not failures.is_empty():_finish();return
	if "--english" in OS.get_cmdline_user_args():check(GameLanguage.set_language("en",true)==OK,"save isolated English preference")
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	if "--read-find" in OS.get_cmdline_user_args():
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://recovered_run_expected.json"))
		var expected_item:=ItemInstance.from_dict(expected.get("find",{}))
		check(expected_item!=null,"expected find record decodes through real item schema")
		if expected_item==null:_finish();return
		found=expected_item.to_dict()
		check(profile.inventory.contains(found.instance_id) and profile.inventory.get_item(found.instance_id).to_dict()==found,"ordinary independent BOOT retains exact recovered gun")
		check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)==found.instance_id and profile.successful_sorties==expected.successful_sorties and profile.failed_sorties==expected.failed_sorties,"independent BOOT retains equipped find and actual return counts")
		if expected.has("field_outgoing"):
			check(not profile.inventory.contains(expected.field_outgoing),"independent BOOT does not duplicate the original gun left in the field cache")
		var before: Dictionary=evidence.profile_before.duplicate(true)
		var after:=profile.to_dict()
		# Normal BOOT initializes missing display cells for returned loose rounds.
		# Compare every other field, including whole inventory and exact loadout.
		evidence["boot_layout_initialization"]={"before":before.stash_layout.duplicate(true),"after":after.stash_layout.duplicate(true)}
		before.erase("stash_layout");after.erase("stash_layout")
		check(before==after,"reading from ordinary base changes no gameplay field; only stash display initialization allowed")
		evidence["read_completed"]=true;evidence["profile_after"]=profile.to_dict();_finish();return
	evidence["outings"]=[]
	if "--field-swap" in OS.get_cmdline_user_args():
		evidence["method"]="Unedited earned base save; ordinary BOOT, unseeded campus, real E and field-swap UI, existing compatible finite ammo, normal R, live combat and retreat. Unusable-caliber finds may be left behind after a real sortie, never seed-filtered or reset. Synthetic input, not human fun/playtime proof."
		for outing in 6:
			if not await _search_outing(outing+1):_finish();return
			if not found.is_empty():break
		check(not found.is_empty(),"natural archive search found a gun with genuinely carried compatible ammunition")
		_finish();return
	if "--retry-owned-find" in OS.get_cmdline_user_args():
		var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://recovered_run_expected.json"))
		var prior_item:=ItemInstance.from_dict(prior.get("find",{}))
		check(prior_item!=null,"continuation record decodes through real item schema")
		if prior_item==null:_finish();return
		found=prior_item.to_dict()
		check(profile.inventory.contains(found.instance_id) and profile.inventory.get_item(found.instance_id).to_dict()==found and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)==found.instance_id,"continue original genuinely earned and equipped find, without replaying or granting it")
		evidence["continuation"]="Retry actual owned find after prior observation-only QA failure; original search, returns, file and failure preserved. No reset or grant."
		if not failures.is_empty():_finish();return
	else:
		# Natural dry cases still require a real return; never reset or preselect a seed.
		for outing in 6:
			if not await _search_outing(outing+1):_finish();return
			if not found.is_empty():break
	check(not found.is_empty(),"natural archive search actually discovered a modified gun within six safe sorties")
	if found.is_empty():_finish();return
	var gun:=profile.inventory.get_item(found.instance_id)
	check(gun!=null and gun.to_dict()==found,"safe return banks exact physical find")
	var ammo:=ContentDB.get_weapon(gun.definition_id).get_runtime_ammo_definition_id()
	if not await _buy_ammo_if_needed(ammo):_finish();return
	await _click(tree.current_scene.find_child("NavHanger",true,false))
	var ui: HangerUI=tree.current_scene.hanger.hanger_ui
	if profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)!=gun.instance_id:
		var tile:StashTile
		for child in ui.stash_grid.get_children():
			if child is StashTile and child.instance_id==gun.instance_id:tile=child;break
		check(tile!=null,"normal warehouse presents recovered concrete instance")
		if tile==null:_finish();return
		await _scroll(tile)
		await _capture("03_recovered_at_base")
		var wallet:=profile.credits;var stock:=profile.inventory.to_dict()
		var event:=InputEventMouseButton.new();event.position=tile.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.double_click=true
		if DisplayServer.get_name()=="headless":tile._gui_input(event)
		else:tree.root.push_input(event)
		await _frames()
		event=InputEventMouseButton.new();event.position=ui.weapon_option.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false;tree.root.push_input(event)
		await _frames()
		check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)==gun.instance_id and profile.inventory.to_dict()==stock and profile.credits==wallet,"actual warehouse double-click equips find without fee, duplication or another kit")
	else:
		check("--retry-owned-find" in OS.get_cmdline_user_args(),"only explicit continuation may start with the find already equipped")
	await _capture("04_recovered_equipped")
	if not failures.is_empty():_finish();return
	if not await _deploy():_finish();return
	await _try_recovered_outing()
	_finish()

func _try_recovered_outing() -> void:
	var profile:=ProfileRuntime.get_profile()
	trial=true
	check(battle.player.weapon_instance.instance_id==found.instance_id and battle.player.weapon_instance.fitting==found.fitting,"actual player carries exact recovered conversion for the combat trial")
	trial_initial_kills=battle.session.enemies_defeated
	var destinations: Array[Vector3]=[_archive().global_position]
	# An unseeded room can legitimately be quiet. Follow public supply landmarks,
	# not enemy coordinates, and observe the whole outing including the retreat.
	for district in [1,2,3]:
		var landmark: LootSpawnPoint
		for point in battle.area_root.loot_points:
			if point.enabled and int(point.get_meta("campus_storage",-1))==district and String(point.name).begins_with("Indoor"):
				landmark=point;break
		check(landmark!=null,"public authored supply landmark resolves from real district metadata")
		if landmark==null:return
		destinations.append(landmark.global_position)
	for destination in destinations:
		if not await _walk(destination,2.2):return
		for tick in 180:
			await tree.physics_frame
			if battle.player.is_dead:failures.append("Died trying recovered gun");_finish();return
			_controls(battle.player.global_position)
			if trial_shots>0 and battle.session.enemies_defeated>trial_initial_kills and not trial_reload.is_empty() and battle.player.get_reload_remaining()<=0:break
		if trial_shots>0 and battle.session.enemies_defeated>trial_initial_kills and not trial_reload.is_empty():break
	_release()
	if not await _return_to_base():return
	var observed: Dictionary=evidence.get("trial",{})
	check(observed.get("shots",0)>0 and observed.get("kills",0)>0,"recovered gun fired and ordinary live combat defeated an enemy")
	check(not observed.get("reload",{}).is_empty() and is_equal_approx(observed.reload.observed,observed.reload.expected),"normal reload input uses recovered conversion duration")
	check(profile.inventory.get_item(found.instance_id).fitting==found.fitting and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)==found.instance_id,"second actual return keeps recovered configuration")
	evidence["trial_returned"]=true;evidence["find"]=found;evidence["profile_after"]=profile.to_dict()
	var expected:={"find":found,"successful_sorties":profile.successful_sorties,"failed_sorties":profile.failed_sorties}
	if evidence.has("field_swap"):expected["field_outgoing"]=evidence.field_swap.outgoing.instance_id
	var f:=FileAccess.open("user://recovered_run_expected.json",FileAccess.WRITE);f.store_string(JSON.stringify(expected));f.close()
	await _capture("06_recovered_returned")

func _archive() -> LootSpawnPoint:
	for point in battle.area_root.loot_points:
		if point.loot_table_id==&"prototype_high_value_loot":return point
	return null

func _deploy() -> bool:
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):return false
	await _bind_current_battle()
	return true

func _bind_current_battle() -> void:
	await tree.create_timer(3.0).timeout
	battle=tree.current_scene
	battle.player.weapon_fired.connect(func(_r:float):
		shots+=1
		if trial and battle.player.weapon_instance.instance_id==found.get("instance_id",""):trial_shots+=1)
	for tick in 120:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(battle.area_root.get_node("StreetNavigation").get_navigation_map())>0:break

func _resume_owned_trial() -> void:
	var profile:=ProfileRuntime.get_profile()
	var prior:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://recovered_run_expected.json"))
	var item:=ItemInstance.from_dict(prior.get("find",{}))
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and item!=null and profile.sortie_checkpoint.get("phase")=="battle","resume actual saved QA-crash outing, never reset the earned profile")
	if item==null or not failures.is_empty():return
	found=item.to_dict();trial=true
	evidence["method"]="Ordinary BOOT/RESUME original crashed QA outing; actual earned gun, player, enemies, ammunition and pickups restored. No file edits, fresh seed, grants or teleports."
	evidence["profile_before"]=profile.to_dict()
	evidence["resumed_input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	check(profile.inventory.contains(found.instance_id) and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)==found.instance_id,"same earned find remains equipped in the crashed outing")
	if not failures.is_empty():return
	if "--english" in OS.get_cmdline_user_args():check(GameLanguage.set_language("en",true)==OK,"persist isolated English preference for resume")
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("RESUME SORTIE"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):return
	await _bind_current_battle()
	await _try_recovered_outing()

func _search_outing(number:int) -> bool:
	if not await _buy_ammo_if_needed(&"ammo.556_standard"):return false
	var profile:=ProfileRuntime.get_profile();var count:=profile.successful_sorties
	if not await _deploy():return false
	var archive:=_archive()
	check(archive!=null,"original high-value archive exists")
	if archive==null:return false
	if not await _walk(archive.global_position,.6):return false
	_release();await _frames();await _tap("interact")
	var ui:Node=battle.get_node("SlicePresentation")
	check(is_instance_valid(ui.panel) and ui.container.get_parent()==archive,"actual nearby E opens the original archive case")
	if not is_instance_valid(ui.panel):return false
	var rows:=[]
	for row in ui._cache_rows:
		rows.append(row.pickup.item_instance.to_dict())
		if row.pickup.item_instance.fitting.is_empty():continue
		if "--field-swap" in OS.get_cmdline_user_args():
			if battle.player.compatible_field_ammo(row.pickup.item_instance)<=0:continue
			return await _field_find(row,rows,number,count)
		found=row.pickup.item_instance.to_dict()
		var base:=profile.inventory.to_dict()
		await _scroll(row.take);await _click(row.take)
		check(battle.session.inventory.contains(found.instance_id) and profile.inventory.to_dict()==base,"real TAKE owns exact find only in carried inventory, not base")
		break
	evidence.outings.append({"number":number,"actual_contents":rows,"found":not found.is_empty(),"shots":shots,"health":battle.player.health})
	await _capture("01_search_%d_actual_case"%number)
	await _click(ui.panel.find_child("CloseCache",true,false))
	if not await _return_to_base():return false
	check(profile.successful_sorties==count+1,"each searched case is followed by one real safe return")
	await _capture("02_search_%d_returned"%number)
	return failures.is_empty()

func _field_find(row: Dictionary, contents: Array, number: int, returns: int) -> bool:
	var profile:=ProfileRuntime.get_profile()
	var player: PlayerController=battle.player
	var ui: Node=battle.get_node("SlicePresentation")
	found=row.pickup.item_instance.to_dict()
	var original:=player.weapon_instance.to_dict()
	var base:=profile.inventory.to_dict()
	var initial_ids: Array=battle.session.get_initial_carried_instance_ids()
	check(row.field!=null and row.field_hint.text.contains(str(player.compatible_field_ammo(row.pickup.item_instance))),"actual cache offers field swap with real compatible-round hint")
	await _scroll(row.field);await _capture("01_field_swap_offer");await _click(row.field)
	check(player.weapon_instance.instance_id==found.instance_id and player.weapon_instance.fitting==found.fitting,"real field-swap button equips the exact discovered gun in this outing")
	check(not battle.session.inventory.contains(original.instance_id) and row.pickup.item_instance.to_dict()==original,"original gun remains a concrete pickup in the same archive")
	check(battle.session.get_initial_carried_instance_ids()==initial_ids and profile.inventory.to_dict()==base,"field swap leaves deployed-risk IDs and warehouse untouched")
	var state: Variant=battle.session.get_weapon_runtime_state(found.instance_id)
	check(state!=null and state.magazine_ammo==0,"discovered gun starts with an empty magazine")
	evidence["field_swap"]={"outgoing":original,"incoming":found.duplicate(true),"initial_ids":initial_ids,"compatible_rounds":player.compatible_field_ammo(player.weapon_instance)}
	evidence.outings.append({"number":number,"actual_contents":contents,"found":true,"field_swap":true,"shots_before_find":shots,"health":player.health})
	if not failures.is_empty():return false
	await _click(ui.panel.find_child("CloseCache",true,false))
	await _tap("reload")
	check(player.get_reload_remaining()>0,"ordinary R input starts a real empty-magazine reload")
	trial_reload={"observed":player.combat_rig.reload_duration,"expected":player.weapon_data.reload_seconds*WeaponFitting.reload_factor(player.weapon_instance),"remaining":player.get_reload_remaining()}
	for tick in 600:
		await tree.physics_frame
		if player.get_reload_remaining()<=0:break
	check(state.magazine_ammo>0 and player.get_reload_remaining()<=0,"finite compatible reserves actually load the discovered gun")
	if not failures.is_empty():return false
	await _try_recovered_outing()
	check(profile.successful_sorties==returns+1 and not profile.inventory.contains(original.instance_id),"same-outing return retains new gun, never banks the old gun left behind")
	return failures.is_empty()

func _return_to_base() -> bool:
	var exit:ExtractionPoint
	for i in 4:
		var candidate:ExtractionPoint=battle.area_root.get_node("Exit%d"%i)
		if candidate.available and candidate.required_objective_id.is_empty():exit=candidate
	if not await _walk(exit.global_position,.4):return false
	_release();await _frames()
	if trial:
		evidence["trial"]={"shots":trial_shots,"reload":trial_reload.duplicate(true),"kills":battle.session.enemies_defeated-trial_initial_kills,"health":battle.player.health,"find":found.duplicate(true)}
		await _capture("05_actual_recovered_trial")
	await _tap("interact")
	check(battle.session.status==SortieSession.Status.COMPLETED,"ordinary E uses available retreat, no fabricated extraction")
	if not await _wait_scene("res://scenes/result/result.tscn"):return false
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	return await _wait_scene("res://scenes/presentation/slice/hideout.tscn")

func _buy_ammo_if_needed(id:StringName) -> bool:
	var profile:=ProfileRuntime.get_profile()
	if SupplyService.count(profile,id)>=30:return true
	await _click(tree.current_scene.find_child("NavWorkshop",true,false))
	var contact=tree.current_scene.screen.get_node("ContactPanel")
	await _click(contact.find_child("Contact_shen_yanshuang",true,false))
	var before:=SupplyService.count(profile,id);var wallet:=profile.credits
	var definition:=ContentDB.get_item(id);var price:=30*SupplyService.buy_price(definition,profile)
	var button:Button=contact.find_child("Supply_buy_"+String(id).replace(".","_"),true,false)
	check(button!=null and not button.disabled and wallet>=price,"ordinary shop can supply next gun caliber")
	if button==null or button.disabled:return false
	await _scroll(button);await _click(button)
	check(SupplyService.count(profile,id)==before+30 and profile.credits==wallet-price,"actual 30-round purchase charges exact displayed price")
	return failures.is_empty()

func _controls(destination:Vector3) -> void:
	super._controls(destination)
	var player: PlayerController=battle.player
	if Input.is_action_pressed("fire") and player.weapon_data.fire_mode!=&"automatic":
		_action("fire") # Semi-auto needs real press events, not a held action flag.
	if trial and trial_shots>0 and trial_reload.is_empty():
		# parse_input_event is consumed on the next input pass. Observe the real
		# started reload on a later tick, never assume the send was synchronous.
		if player.get_reload_remaining()>0:
			trial_reload={"observed":player.combat_rig.reload_duration,"expected":player.weapon_data.reload_seconds*WeaponFitting.reload_factor(player.weapon_instance),"remaining":player.get_reload_remaining()}
		elif player.can_reload():
			_action("reload")

func _action(action:String) -> void:
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action=action;event.pressed=pressed;Input.parse_input_event(event)

func _finish() -> void:
	check(evidence.has("profile_after") and (evidence.get("trial_returned",false) or evidence.get("read_completed",false)),"run reached a complete earned find/equip/trial/return or independent read; partial routes never PASS")
	evidence["language"]=TranslationServer.get_locale()
	if "--english" in OS.get_cmdline_user_args():check(TranslationServer.get_locale()=="en","actual post-BOOT route uses English")
	super._finish()
