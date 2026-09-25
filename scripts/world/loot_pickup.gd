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
			return {"success": true, "result": result, "message": "Picked up: %s" % definition.display_name}
		PickupResult.CAPACITY_FULL:
			return {"success": false, "result": result, "message": "Inventory Full"}
		PickupResult.INVALID_SESSION:
			return {"success": false, "result": result, "message": "No active sortie"}
	return {"success": false, "result": result, "message": "Invalid item"}


func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	return "E  PICK UP  %s" % definition.display_name.to_upper() if definition and not consumed and session and session.status == SortieSession.Status.ACTIVE else ""


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
	_name_label.position = Vector3(0.0, 1.05, 0.0)
	_name_label.font_size = 28
	_name_label.outline_size = 8
	_name_label.modulate = Color("bffdf6")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _update_label() -> void:
	if not _name_label:
		return
	var definition := ContentDB.get_item(item_instance.definition_id, false) if item_instance else null
	_name_label.text = definition.display_name if definition else "UNKNOWN LOOT"
