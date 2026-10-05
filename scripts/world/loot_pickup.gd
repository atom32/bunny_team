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
	if not session.inventory.can_add_item(item_instance):
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
			return {"success": false, "result": result, "message": "Inventory Full"}
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
	return (
		item_instance != null
		and not item_instance.instance_id.is_empty()
		and not item_instance.definition_id.is_empty()
		and item_instance.quantity > 0
		and ContentDB.has_item(item_instance.definition_id)
	)


func _build_visual() -> void:
	var base := VisualFactory.cylinder(self, 0.42, 0.18, Vector3(0.0, 0.1, 0.0), Color("263a45"), "LootBase")
	base.material_override = VisualFactory.material(Color("263a45"), 0.7, 0.3, Color("3be2d0"), 1.5)
	var core := VisualFactory.box(self, Vector3(0.46, 0.46, 0.46), Vector3(0.0, 0.43, 0.0), Color("65d8c7"), "LootCore")
	core.rotation_degrees = Vector3(0.0, 45.0, 0.0)
	core.material_override = VisualFactory.material(Color("2b6e70"), 0.55, 0.25, Color("65f2df"), 3.0)
	_name_label = Label3D.new()
	_name_label.font = UIFactory.FONT
	_name_label.position = Vector3(0.0, 1.05, 0.0)
	_name_label.font_size = 48
	_name_label.pixel_size = 0.012
	_name_label.outline_size = 4
	_name_label.modulate = Color("bffdf6")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _update_label() -> void:
	if not _name_label:
		return
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	_name_label.text = GameLanguage.item_name(definition.display_name) if definition else "UNKNOWN LOOT"
