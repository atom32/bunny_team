class_name LootPickup
extends Node3D

signal picked_up(item: ItemInstance)

enum PickupResult {
	SUCCESS,
	CAPACITY_FULL,
	INVALID_ITEM,
	INVALID_SESSION,
}

var item_instance: ItemInstance
var consumed := false
var _name_label: Label3D
var _visual_id: StringName


func setup(item: ItemInstance) -> void:
	item_instance = item
	if is_node_ready():
		_update_label()


func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	_update_label()
	GameLanguage.language_changed.connect(_update_label)


func try_pickup(session: SortieSession) -> PickupResult:
	if consumed or not session or session.status != SortieSession.Status.ACTIVE:
		return PickupResult.INVALID_SESSION
	if not _item_is_valid() or session.inventory.contains(item_instance.instance_id):
		return PickupResult.INVALID_ITEM
	if session.inventory.current_weight + item_instance.total_weight() > session.inventory.capacity + 0.0001:
		return PickupResult.CAPACITY_FULL
	if not session.inventory.add_item(item_instance):
		return PickupResult.INVALID_ITEM
	consumed = true
	picked_up.emit(item_instance)
	if is_inside_tree():
		queue_free()
	return PickupResult.SUCCESS


func interact(_actor: Node3D, session: SortieSession) -> Dictionary:
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	var result := try_pickup(session)
	match result:
		PickupResult.SUCCESS:
			return {"success": true, "result": result, "message": tr("Picked up: %s") % GameLanguage.item_name(definition.display_name)}
		PickupResult.CAPACITY_FULL:
			return {"success": false, "result": result, "message": tr("Overweight: stack %.2f kg / free %.2f kg.\nWhole stacks only. Exchange carried loot to free weight.") % [item_instance.total_weight(), session.inventory.get_remaining_capacity()]}
		PickupResult.INVALID_SESSION:
			return {"success": false, "result": result, "message": "No active sortie"}
	return {"success": false, "result": result, "message": "Invalid item"}


func exchange_cargo(session: SortieSession, outgoing_id: String) -> PickupResult:
	# Exchange whole salvage stacks. Keep the outgoing item in this existing world
	# slot so checkpoint persistence needs neither a new node type nor a schema.
	if consumed or not session or session.status != SortieSession.Status.ACTIVE:
		return PickupResult.INVALID_SESSION
	if not _item_is_valid() or session.inventory.contains(item_instance.instance_id):
		return PickupResult.INVALID_ITEM
	var outgoing := session.inventory.get_item(outgoing_id)
	var definition := ContentDB.get_item(outgoing.definition_id, false) if outgoing else null
	if not definition or not definition.has_tag(&"loot") or session.loadout.is_equipped(outgoing_id):
		return PickupResult.INVALID_ITEM
	# Validate a detached candidate before changing either side; preserve IDs,
	# stack quantities, loaded-round weight and existing inventory references.
	var candidate := InventoryState.from_dict(session.inventory.to_dict())
	candidate.reserved_weight = session.inventory.reserved_weight
	candidate.remove_item(outgoing_id)
	if not candidate.add_item_preserving_instance(ItemInstance.from_dict(item_instance.to_dict())):
		return PickupResult.CAPACITY_FULL
	if not candidate.validate():
		return PickupResult.INVALID_ITEM
	var incoming := item_instance
	session.inventory.remove_item(outgoing_id)
	if not session.inventory.add_item_preserving_instance(incoming):
		session.inventory.add_item_preserving_instance(outgoing)
		return PickupResult.INVALID_ITEM
	item_instance = outgoing
	_update_label()
	picked_up.emit(incoming)
	return PickupResult.SUCCESS


func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	return tr("%s  PICK UP  %s") % [ControlBindings.label("interact"), GameLanguage.item_name(definition.display_name).to_upper()] if definition and not consumed and session and session.status == SortieSession.Status.ACTIVE else ""


func _item_is_valid() -> bool:
	if not item_instance or item_instance.instance_id.is_empty() or item_instance.quantity <= 0:
		return false
	var definition := ContentDB.get_item(item_instance.definition_id, false)
	return definition != null and WeaponFitting.valid(item_instance) and (definition.stackable or item_instance.quantity == 1) and is_finite(item_instance.durability) and item_instance.durability >= 0.0 and item_instance.durability <= 100.0


func _build_visual() -> void:
	var campus := get_parent().has_meta("campus_storage")
	_visual_id=item_instance.definition_id if item_instance else &""
	var art:=ItemPresentation.create(_visual_id)
	if art:
		add_child(art);ItemPresentation.fit_pickup(art)
		var base:=VisualFactory.cylinder(self,.42,.04,Vector3(0,.1,0),Color("344448"),"LootBase")
		base.material_override=VisualFactory.material(Color("344448"),.15,.8)
	elif campus:
		var kind := int(get_parent().get_meta("campus_storage"))
		var colors := [Color("9a8b70"),Color("d0cbb8"),Color("827a66"),Color("70806d")]
		VisualFactory.box(self,Vector3(.65,.42,.5),Vector3(0,.32,0),colors[kind],"SupplyPackage")
		VisualFactory.box(self,Vector3(.68,.055,.53),Vector3(0,.55,0),colors[kind].lightened(.1),"PackageLid")
		if kind==1:
			VisualFactory.box(self,Vector3(.11,.015,.34),Vector3(0,.587,0),Color("658570"),"MedicalMark")
			VisualFactory.box(self,Vector3(.34,.015,.11),Vector3(0,.59,0),Color("658570"),"MedicalCross")
		else:
			VisualFactory.box(self,Vector3(.14,.014,.53),Vector3(0,.59,0),Color("b7af91"),"PackageTape")
		VisualFactory.box(self,Vector3(.2,.016,.12),Vector3(.19,.60,.12),Color("d4cdb6"),"PackageLabel")
	else:
		var base := VisualFactory.cylinder(self, 0.42, 0.18, Vector3(0.0, 0.1, 0.0), Color("263a45"), "LootBase")
		base.material_override = VisualFactory.material(Color("263a45"), 0.7, 0.3, Color("3be2d0"), 1.5)
		var core := VisualFactory.box(self, Vector3(0.46, 0.46, 0.46), Vector3(0.0, 0.43, 0.0), Color("65d8c7"), "LootCore")
		core.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		core.material_override = VisualFactory.material(Color("2b6e70"), 0.55, 0.25, Color("65f2df"), 3.0)
	_name_label = Label3D.new()
	_name_label.font = UIFactory.FONT
	_name_label.position = Vector3(0.0, 1.05, 0.0)
	_name_label.font_size = 28 if campus else 48
	_name_label.pixel_size = 0.006 if campus else 0.012
	_name_label.outline_size = 4
	_name_label.modulate = Color("e3dcc3") if campus else Color("bffdf6")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _update_label() -> void:
	if not is_inside_tree():return
	# setup/exchange/checkpoint restore can replace the item in this world slot.
	if item_instance and item_instance.definition_id!=_visual_id:
		for child in get_children():
			if child is Node3D:child.free()
		_name_label=null
		_build_visual()
	if not _name_label:
		return
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	_name_label.text = GameLanguage.item_name(definition.display_name) if definition else "UNKNOWN LOOT"
