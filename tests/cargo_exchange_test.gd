extends Node
var failures: Array[String] = []
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)
func _ready() -> void:
	await get_tree().process_frame
	var inventory := InventoryState.new(6)
	var session := SortieSession.new(inventory,LoadoutState.new())
	session.status = SortieSession.Status.ACTIVE
	var core := ItemInstance.new(&"loot.salvage_core_01")
	inventory.add_item_preserving_instance(core)
	var pickup := LootPickup.new()
	var drive := ItemInstance.new(&"material.data_drive",2)
	pickup.setup(drive)
	check(pickup.try_pickup(session)==LootPickup.PickupResult.CAPACITY_FULL,"normal pickup rejects full cargo")
	check(pickup.exchange_cargo(session,core.instance_id)==LootPickup.PickupResult.SUCCESS,"full cargo exchanges lower priority stack")
	check(inventory.get_item(drive.instance_id)==drive and drive.quantity==2,"incoming exact instance and quantity retained")
	check(pickup.item_instance==core and not pickup.consumed,"outgoing item remains recoverable in same cache slot")
	check(not inventory.contains(core.instance_id) and inventory.validate(),"one owner per item and valid carrying weight")
	check(pickup.exchange_cargo(session,drive.instance_id)==LootPickup.PickupResult.SUCCESS,"exchange can be reversed without deletion or duplication")
	inventory.reserved_weight=0.1
	var before := inventory.to_dict()
	# Incoming 2 drives fit after removal; reverse exchange then rejects core
	check(pickup.exchange_cargo(session,core.instance_id)==LootPickup.PickupResult.SUCCESS,"reserved magazine weight retained")
	before=inventory.to_dict()
	check(pickup.exchange_cargo(session,drive.instance_id)==LootPickup.PickupResult.CAPACITY_FULL,"loaded rounds counted in exchange capacity")
	check(inventory.to_dict()==before and pickup.item_instance==core,"failed capacity exchange changes neither side")
	check(pickup.exchange_cargo(session,"missing")==LootPickup.PickupResult.INVALID_ITEM,"stale selected cargo rejected")
	var med := ItemInstance.new(&"medical.medkit")
	inventory.add_item_preserving_instance(med)
	check(pickup.exchange_cargo(session,med.instance_id)==LootPickup.PickupResult.INVALID_ITEM,"medical state cannot be exchanged away")
	var ammo := ItemInstance.new(&"ammo.556_standard",1)
	inventory.add_item_preserving_instance(ammo)
	check(pickup.exchange_cargo(session,ammo.instance_id)==LootPickup.PickupResult.INVALID_ITEM,"weapon ammunition cannot be exchanged away")
	session.status=SortieSession.Status.COMPLETED
	check(pickup.exchange_cargo(session,drive.instance_id)==LootPickup.PickupResult.INVALID_SESSION,"settled sortie cannot exchange")
	session.status=SortieSession.Status.ACTIVE
	pickup.consumed=true
	check(pickup.exchange_cargo(session,drive.instance_id)==LootPickup.PickupResult.INVALID_SESSION,"consumed world slot cannot exchange")
	pickup.free()
	_contract_stock()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error(failure)
	print("CARGO_EXCHANGE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _contract_stock() -> void:
	var presentation = preload("res://scripts/presentation/slice/battle_presentation.gd")
	var profile := ProfileState.create_new()
	profile.first_mission_completed = true
	profile.campaign.stage = 1
	var fabric := ItemInstance.new(&"material.fabric",3)
	profile.inventory.add_item_preserving_instance(fabric)
	var session := SortieSession.new(InventoryState.new(18),LoadoutState.new())
	var before := profile.to_dict()
	check(presentation.contract_stock(profile,session,&"material.fabric") == {"base":3,"cargo":0,"required":4,"missing":1},"contract hint shows base deficit before pickup")
	var found := ItemInstance.new(&"material.fabric",2)
	session.inventory.add_item_preserving_instance(found)
	check(presentation.contract_stock(profile,session,&"material.fabric").missing == 0,"current cargo closes projected deficit without completing contract")
	check(not CampaignService.ready(profile),"loot hint never awards or submits a contract")
	session.inventory.remove_item(found.instance_id)
	check(presentation.contract_stock(profile,session,&"material.fabric").missing == 1,"exchanged-away cargo restores deficit immediately")
	var carried_ids: Array[String] = [fabric.instance_id]
	var carried_session := SortieSession.new(InventoryState.new(18),LoadoutState.new(),&"",&"","",carried_ids)
	carried_session.inventory.add_item_preserving_instance(ItemInstance.from_dict(fabric.to_dict()))
	check(presentation.contract_stock(profile,carried_session,&"material.fabric") == {"base":0,"cargo":3,"required":4,"missing":1},"pre-sortie carried material counted only once")
	carried_session.inventory.remove_item(fabric.instance_id)
	check(presentation.contract_stock(profile,carried_session,&"material.fabric").missing == 4,"original carried material left behind is not falsely considered safe at base")
	check(presentation.contract_stock(profile,session,&"material.electronics").is_empty(),"future contract materials not labelled current")
	check(profile.to_dict()==before,"presentation inspection does not mutate wallet/inventory/progression")
	profile.campaign.stage=5
	check(presentation.contract_stock(profile,session,&"material.fabric").is_empty(),"completed campaign has no stale material demand")
