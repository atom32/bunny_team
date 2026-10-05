extends Node
const PATH := "user://ammo_packing.json"
const AMMO := &"ammo.556_standard"
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func fresh() -> ProfileState:
	SortieRuntime.clear_session()
	var p := ProfileRuntime.new_profile()
	p.first_mission_completed = true
	return p
func rounds(session: SortieSession, id: StringName) -> int:
	var count := 0
	for item in session.inventory.get_items():
		if item.definition_id == id: count += item.quantity
	for state in session._weapon_runtime_states.values():
		if state.ammo_definition_id == id: count += state.magazine_ammo
	return count
func source(p: ProfileState) -> ItemInstance:
	for item in p.inventory.get_items():
		if item.definition_id == AMMO: return item
	return null
func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		_read()
	else:
		_preferences()
		_transactions()
		_limits()
		_backpack_capacity()
		await _ui()
		_write()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("AMMO_PACKING: " + failure)
	print("AMMO_PACKING_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
func _preferences() -> void:
	var p := fresh()
	var old := p.to_dict();old.erase("ammo_pack")
	check(ProfileState.from_dict(old).ammo_pack.is_empty(), "old profile uses finite three-magazine default")
	for bad in [[],{str(AMMO):-1},{str(AMMO):1.5},{str(AMMO):1001},{str(AMMO):INF},{"fake":30},{"medical.medkit":2}]:
		var raw := p.to_dict();raw.ammo_pack=bad
		check(ProfileState.from_dict(raw)==null,"malformed packing rejected")
	var inventory := p.inventory
	check(DeploymentPlan.set_ammo_count(str(AMMO),37,PATH)==OK and p.inventory==inventory,"saved preference does not split warehouse")
	check(DeploymentPlan.set_ammo_count(str(AMMO),80,"user://missing_pack_dir/profile.json")!=OK and p.ammo_pack[str(AMMO)]==37,"failed preference save preserves previous count")
	var before := p.to_dict()
	var prepared := DeploymentPlan.prepare(p,&"street_district",&"streets_recon")
	check(prepared.error==OK and p.to_dict()==before,"preview/materialization candidate does not mutate source")
	check(source(prepared.candidate).quantity==83 and source(prepared.candidate).instance_id==source(p).instance_id,"base remainder retains original stack identity")
	check(prepared.request.validate(prepared.candidate.inventory),"split IDs belong to candidate inventory")
	check(SupplyService.count(prepared.candidate,AMMO)==120,"split conserves total rounds")
	check(DeploymentPlan.set_ammo_count(str(AMMO),0,PATH)==OK,"zero rounds is a real packing choice")
	var plan := DeploymentPlan.build(p)
	check(not plan.ammo_ids.has(source(p).instance_id),"zero rounds leaves rifle ammunition at base")
	DeploymentPlan.set_ammo_count(str(AMMO),1000,PATH)
	var all := DeploymentPlan.prepare(p,&"street_district",&"streets_recon")
	check(all.request.carried_item_instance_ids.has(source(p).instance_id) and all.candidate.inventory.get_item(source(p).instance_id).quantity==120 and SupplyService.count(all.candidate,AMMO)==120,"insufficient stock packs owned quantity only; full stack keeps ID")
	# Shared caliber has one total, not a separate duplicated reserve for each gun.
	p=fresh()
	var pistol:=ItemInstance.new(&"weapon.pistol_01")
	check(p.inventory.add_item(pistol),"shared-caliber pistol fixture owned")
	var smg:=p.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
	p.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	p.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,smg,p.inventory)
	p.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY,pistol.instance_id,p.inventory)
	check(DeploymentPlan.default_ammo_counts(p).size()==1,"two same-caliber guns show one packing control")
	DeploymentPlan.set_ammo_count("ammo.9mm_standard",37,PATH)
	var shared:=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(shared.error==OK and rounds(shared.session,&"ammo.9mm_standard")==37,"shared magazines draw from chosen total without duplication")
	SortieRuntime.clear_session()
func _transactions() -> void:
	var p := fresh()
	DeploymentPlan.set_ammo_count(str(AMMO),37,PATH)
	DeploymentPlan.set_ammo_count("ammo.9mm_standard",12,PATH)
	var original := source(p).instance_id
	var before := p.to_dict()
	var disk := FileAccess.get_file_as_string(PATH)
	check(DeploymentPlan.deploy(p,&"street_district",&"streets_recon","user://missing_pack_dir/profile.json").error!=OK,"deployment save failure reported")
	check(p.to_dict()==before and not SortieRuntime.get_current_session() and FileAccess.get_file_as_string(PATH)==disk,"failed deployment leaves inventory/IDs/journal/disk unchanged")
	var plan := DeploymentPlan.build(p)
	var result := DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(result.error==OK,"exact packed deployment succeeds")
	var session: SortieSession=result.session
	check(rounds(session,AMMO)==37 and rounds(session,&"ammo.9mm_standard")==12,"exact totals include both magazines and reserves")
	check(is_equal_approx(session.inventory.current_weight,plan.weight),"preview matches actual loaded-round carry weight")
	check(p.inventory.get_item(original).quantity==83 and original not in session.get_initial_carried_instance_ids(),"unpacked original stack is not in death-loss set")
	check(DeploymentPlan.set_ammo_count(str(AMMO),0,PATH)==ERR_BUSY,"cannot repack after deployment")
	check(DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH).error==ERR_BUSY,"cannot duplicate deployment")
	check(session.fail() and SortieRuntime.finalize_sortie(PATH)==OK,"normal failed sortie settles")
	check(SupplyService.count(p,AMMO)==83 and SupplyService.count(p,&"ammo.9mm_standard")==108,"death loses only exact carried ammunition")
	check(SortieRuntime.finalize_sortie(PATH)==OK and SupplyService.count(p,AMMO)==83,"repeat settlement cannot consume remainder")
	p=fresh()
	DeploymentPlan.set_ammo_count(str(AMMO),37,PATH)
	result=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	session=result.session
	var gun:=p.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	for index in 5: check(session.fire_weapon(gun),"real weapon consumes carried magazine")
	check(session.complete_extraction() and SortieRuntime.finalize_sortie(PATH)==OK,"normal successful extraction settles partial stack")
	check(SupplyService.count(p,AMMO)==115,"return combines surviving carried rounds with untouched base remainder without duplication")
	check(SaveService.load_profile(PATH,false).to_dict()==p.to_dict(),"settled split inventory persists exactly")
func _ui() -> void:
	var p:=fresh()
	FlowMenu.save_path=PATH
	var panel:=MedicalPacking.new()
	panel.position=Vector2(42,206);panel.size=Vector2(548,330)
	add_child(panel)
	await get_tree().process_frame
	var amount:=panel.find_child("PackAmmo_ammo_556_standard",true,false) as SpinBox
	check(amount!=null and int(amount.value)==90,"production packing exposes three-magazine default")
	amount.value=37
	await get_tree().process_frame
	check(p.ammo_pack[str(AMMO)]==37 and SaveService.load_profile(PATH,false).ammo_pack[str(AMMO)]==37,"actual quantity control saves chosen count")
	# Reproduce the observed request-vs-stock ambiguity without changing packing rules.
	GameLanguage.set_language("en", false)
	source(p).quantity = 83
	p.ammo_pack[str(AMMO)] = 90
	var unchanged := p.to_dict()
	panel._refresh()
	await get_tree().process_frame
	var actual := panel.find_child("Packed_ammo_556_standard", true, false) as Label
	check(actual != null and actual.text == "PACKED 83 / SHORT 7", "row exposes exact partial stock and shortage")
	check(int((panel.find_child("PackAmmo_ammo_556_standard",true,false) as SpinBox).value)==90, "shortage does not silently overwrite requested preference")
	var dressing := panel.find_child("Packed_medical_field_dressing", true, false) as Label
	check(dressing != null and dressing.text == "PACKED 0 / SHORT 2", "missing medicine is explicit beside its requested quantity")
	check(p.to_dict()==unchanged, "rendering shortages never mutates inventory or preferences")
	check(actual.has_theme_color_override("font_color") and not actual.tooltip_text.is_empty(), "shortage has textual and visual explanation")
	p.ammo_pack[str(AMMO)] = 0
	panel._refresh()
	check((panel.find_child("Packed_ammo_556_standard",true,false) as Label).text == "NOT REQUESTED / PACKED 0", "intentional zero distinguished from missing stock")
	p.ammo_pack[str(AMMO)] = 90
	panel._refresh()
	if "--capture" in OS.get_cmdline_user_args():
		for locale in ["en","zh_CN"]:
			GameLanguage.set_language(locale,false);panel._refresh()
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("packing_"+locale+".png"))
	panel.free()
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	for locale in ["en", "zh_CN"]:
		GameLanguage.set_language(locale,false)
		hub.show_section("Operations")
		await get_tree().process_frame
		await get_tree().process_frame
		var packing := hub.find_child("MedicalPacking",true,false) as Control
		var risk := hub.find_child("PackingRisk",true,false) as Control
		check(packing != null and risk != null and risk.position.y >= packing.position.y+packing.size.y+8, "production risk notice stays below actual packing panel: "+locale)
		check(risk.position.y + risk.size.y < 644, "production packing notice clears navigation: "+locale)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("operations_"+locale+".png"))
	hub.free()
func _write() -> void:
	var p:=fresh()
	DeploymentPlan.set_ammo_count(str(AMMO),37,PATH)
	var result:=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(result.error==OK,"writer persists actual split deployment checkpoint")
	var f:=FileAccess.open("user://ammo_packing_expected.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(p.to_dict()));f.close()
func _read() -> void:
	var p:=SaveService.load_profile(PATH,false)
	check(p!=null,"second process loads split deployment")
	if not p: return
	var expected:=ProfileState.from_dict(JSON.parse_string(FileAccess.get_file_as_string("user://ammo_packing_expected.json")))
	check(p.to_dict()==expected.to_dict(),"second process preserves exact warehouse IDs and journal")
	ProfileRuntime._profile=p
	check(SortieRuntime.resume_saved(PATH)==OK,"second process resumes durable deployment")
	var session:=SortieRuntime.get_current_session()
	check(session!=null and rounds(session,AMMO)==37,"resumed magazines/reserves retain exactly 37 rounds")
	check(session.fail() and SortieRuntime.finalize_sortie(PATH)==OK,"resumed failure commits normal outcome")
	check(SupplyService.count(p,AMMO)==83,"base remainder survives failure after restart")

func _limits() -> void:
	var p:=fresh()
	p.inventory.add_item(ItemInstance.new(AMMO,120))
	DeploymentPlan.set_ammo_count(str(AMMO),137,PATH)
	var result:=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(result.error==OK and rounds(result.session,AMMO)==137,"packing spans full and partial source stacks")
	check(result.session.fail() and SortieRuntime.finalize_sortie(PATH)==OK and SupplyService.count(p,AMMO)==103,"multi-stack failure preserves exact base remainder")
	p=fresh()
	DeploymentPlan.set_ammo_count(str(AMMO),0,PATH)
	DeploymentPlan.set_ammo_count("ammo.9mm_standard",0,PATH)
	result=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(result.error==OK and rounds(result.session,AMMO)==0 and rounds(result.session,&"ammo.9mm_standard")==0,"zero packing really deploys empty magazines, no free rounds")
	SortieRuntime.clear_session()
	p=fresh()
	p.inventory.capacity=1000
	var launcher:=ItemInstance.new(&"weapon.rocket_launcher_01")
	check(p.inventory.add_item(launcher) and p.inventory.add_item(ItemInstance.new(&"ammo.rocket_standard",200)),"owned heavy ammunition fixture fits warehouse")
	p.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,launcher.instance_id,p.inventory)
	DeploymentPlan.set_ammo_count("ammo.rocket_standard",1000,PATH)
	var plan:=DeploymentPlan.build(p)
	result=DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
	check(result.error==OK and plan.weight<=plan.capacity+.0001 and result.session.inventory.capacity==plan.capacity,"actual deploy clips requested heavy ammunition at equipped carrying capacity")
	check(is_equal_approx(result.session.inventory.current_weight,plan.weight) and rounds(result.session,&"ammo.rocket_standard")<200,"capacity-limited preview equals real loaded plus reserve mass")
	SortieRuntime.clear_session()

func _backpack_capacity() -> void:
	for spec in [["",18.0],["equipment.field_pack_01",35.0],["equipment.thruster_pack_01",25.0]]:
		var p := fresh()
		p.loadout.unequip(LoadoutState.SLOT_BACKPACK)
		if not spec[0].is_empty():
			var pack := ItemInstance.new(StringName(spec[0]))
			p.inventory.add_item_preserving_instance(pack)
			p.loadout.equip(LoadoutState.SLOT_BACKPACK,pack.instance_id,p.inventory)
		var before := p.to_dict()
		var plan := DeploymentPlan.build(p)
		check(plan.capacity==spec[1] and p.to_dict()==before,"Equipped pack defines non-mutating preview: "+spec[0])
		var deployed := DeploymentPlan.deploy(p,&"street_district",&"streets_recon",PATH)
		check(deployed.error==OK and deployed.session.inventory.capacity==plan.capacity,"Production deployment uses preview capacity: "+spec[0])
		if deployed.error != OK: continue
		var session: SortieSession = deployed.session
		var saved := SortieCheckpoint.session_data(session)
		var restored := SortieCheckpoint.restore_session(saved)
		check(restored!=null and restored.inventory.capacity==spec[1],"Checkpoint preserves selected capacity: "+spec[0])
		var count := 0
		while session.inventory.add_item(ItemInstance.new(&"material.scrap",1)):
			count += 1
			if count>1000: break
		check(count>0 and count<1000 and session.inventory.current_weight<=spec[1]+.001,"Real loot is limited by selected capacity: "+spec[0])
		saved.inventory.capacity=100.0
		var legacy := SortieCheckpoint.restore_session(saved)
		check(legacy!=null and legacy.inventory.capacity==100.0,"Legacy suspended sortie keeps recorded 100kg without dropping items")
		SortieRuntime.clear_session()
