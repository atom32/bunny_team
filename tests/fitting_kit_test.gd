extends Node3D
const PATH := "user://fitting_kit_test.json"
const CROSS_PATH := "user://fitting_kit_cross_profile.json"
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func fresh() -> ProfileState:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	return profile
func primary(profile: ProfileState) -> String: return profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
func kit(profile: ProfileState, definition_id: StringName) -> ItemInstance:
	for item in profile.inventory.get_items():
		if item.definition_id == definition_id: return item
	return null
func _ready() -> void:
	if "--read" in OS.get_cmdline_user_args():
		_read_saved_kits()
		_finish()
		return
	var initial := ProfileState.create_new()
	for id: StringName in WeaponFitting.KITS:
		var definition := ContentDB.get_item(id)
		check(definition != null and definition.icon != null and definition.has_tag(&"fitting_kit") and definition.max_stack == 4, "Registered authored kit with icon and stack limit")
		check(kit(initial,id) == null and definition not in SupplyService.stock(initial), "No kit granted or sold before tutorial completion")
		check(ContactDefinition.owns_stock("su_mi",definition) and not ContactDefinition.owns_stock("tang_kui",definition) and not ContactDefinition.owns_stock("shen_yanshuang",definition), "Kit stock belongs to engineering contact")
		GameLanguage.set_language("zh_CN",false)
		check(GameLanguage.item_name(definition.display_name) != definition.display_name, "Actual Chinese kit name exists")
	GameLanguage.set_language("en",false)
	await _loot_lifecycle()
	await _ui_transaction()
	await _finish()

func _finish() -> void:
	SortieRuntime.clear_session(); AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	print("FITTING_KIT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _read_saved_kits() -> void:
	var profile := SaveService.load_profile(CROSS_PATH,false)
	check(profile != null, "Independent process loads real kit profile envelope")
	if not profile: return
	for id: StringName in WeaponFitting.KITS:
		check(kit(profile,id) != null and kit(profile,id).quantity == 1, "Independent ContentDB/file reader resolves each remaining kit")
	check(profile.inventory.get_item(primary(profile)).fitting == "observation_optic", "New observation enum roundtrips across process boundary")
func _loot_lifecycle() -> void:
	var profile := fresh(); var weapon_id := primary(profile)
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon",plan.ammo_ids),profile)
	check(session != null, "Real finite sortie activated for recovered kits")
	for id: StringName in WeaponFitting.KITS:
		var item := ItemInstance.new(id,2)
		var pickup := LootPickup.new(); pickup.setup(item); add_child(pickup)
		check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "Actual pickup enters carried inventory")
		check(pickup.try_pickup(session) != LootPickup.PickupResult.SUCCESS, "Consumed pickup cannot duplicate kit")
	var restored := SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session))
	check(restored != null and restored.inventory.to_dict() == session.inventory.to_dict(), "All carried kit IDs and quantities survive checkpoint serialization")
	check(session.complete_extraction() and SortieRuntime.finalize_sortie(PATH) == OK, "Successful actual extraction brings kits home")
	for id: StringName in WeaponFitting.KITS:
		var stack := kit(profile,id)
		check(stack != null and stack.quantity == 2, "Recovered kit stack in real warehouse")
		var before := profile.to_dict()
		check(WeaponFitting.install_kit(weapon_id,stack.instance_id,"user://missing_kit_dir/profile.json").error != OK and profile.to_dict() == before, "Failed durable save consumes nothing")
		var weight := profile.inventory.current_weight
		var old_fitting_weight := WeaponFitting.extra_weight(profile.inventory.get_item(weapon_id))
		var fitting: String = WeaponFitting.KITS[id]
		check(WeaponFitting.install_kit(weapon_id,stack.instance_id,PATH).error == OK, "Preassembled kit installs without workbench unlock/material bill")
		check(profile.inventory.get_item(weapon_id).fitting == fitting and kit(profile,id).quantity == 1 and profile.credits == int(before.credits), "Exactly one kit consumed, exact weapon modified, credits unchanged")
		check(is_equal_approx(profile.inventory.current_weight,weight-old_fitting_weight), "Kit mass transfers to fitting; old fitting is discarded")
		before = profile.to_dict()
		check(WeaponFitting.install_kit(weapon_id,kit(profile,id).instance_id,PATH).error == ERR_ALREADY_EXISTS and profile.to_dict() == before, "Double click cannot spend a second kit")
		check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "Real disk reader restores fitted instance and remaining kit")
	check(WeaponFitting.reload_factor(profile.inventory.get_item(weapon_id)) == 1.1 and WeaponFitting.aim_extension(profile.inventory.get_item(weapon_id)) == 3, "Observation fitting has its distinct tradeoff")
	check(SaveService.save_profile(profile,CROSS_PATH)==OK, "Durable cross-process source retains all three physical kit stacks and new optic fitting")
	var carried_kit := kit(profile,&"material.quickloader_kit").instance_id
	session = SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district",&"streets_recon",[carried_kit]),profile)
	check(session != null and WeaponFitting.install_kit(weapon_id,kit(profile,&"material.suppressor_kit").instance_id,PATH).error == ERR_BUSY, "Base installation blocked during sortie")
	check(session.fail() and SortieRuntime.finalize_sortie(PATH) == OK, "Failed sortie committed through original outcome service")
	check(not profile.inventory.contains(weapon_id) and not profile.inventory.contains(carried_kit), "Death loses installed fitting with gun and actually carried loose kit")
	check(kit(profile,&"material.suppressor_kit") != null and kit(profile,&"material.observation_optic_kit") != null, "Uncarried warehouse kits survive death")
	await get_tree().process_frame
func _ui_transaction() -> void:
	var profile := fresh(); var id := primary(profile)
	var panel := SupplyPanel.new(); panel.contact_id="su_mi"; panel.save_path=PATH; panel.selected_tab=3
	panel.position=Vector2(24,120); panel.size=Vector2(900,560); add_child(panel)
	await get_tree().process_frame
	var tabs: TabContainer = panel.find_children("*","TabContainer",true,false)[0]
	tabs.current_tab = 0
	check(not tabs.is_tab_hidden(0), "Engineering kit shop is a visible reachable tab")
	var buy := panel.find_child("Supply_buy_material_quickloader_kit",true,false) as Button
	check(buy != null, "Actual engineering stock UI contains physical kit")
	if buy: buy.pressed.emit()
	await get_tree().process_frame; await get_tree().process_frame
	check(profile.credits == 1200 and kit(profile,&"material.quickloader_kit") != null, "Actual purchase spends exact credits and creates warehouse item")
	tabs = panel.find_children("*","TabContainer",true,false)[0]
	check(tabs.current_tab == 0, "Shop remains open after purchase instead of redirecting to material exchange")
	tabs.current_tab = 3
	var install := panel.find_child("FitKit_"+id,true,false) as Button
	check(install != null and not install.disabled, "Actual kit install row available before material workbench unlock")
	if install: install.pressed.emit()
	await get_tree().process_frame; await get_tree().process_frame
	check(profile.inventory.get_item(id).fitting == "quickloader" and kit(profile,&"material.quickloader_kit") == null, "Actual UI signal installs and consumes purchased kit")
	check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "UI transaction persisted fitting and reconciled stash layout")
	var remove := panel.find_child("RemoveKitFit_"+id,true,false) as Button
	check(remove != null, "Ready fitting can be unmounted without a workbench softlock")
	if remove: remove.pressed.emit()
	await get_tree().process_frame; await get_tree().process_frame
	check(profile.inventory.get_item(id).fitting.is_empty() and kit(profile,&"material.quickloader_kit")==null and profile.credits==1200, "Actual removal restores standard weapon without kit or credit refund")
	panel.queue_free(); await get_tree().process_frame
