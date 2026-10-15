extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var module := load("res://scenes/modules/service_room.tscn").instantiate() as Node3D
	check(module.has_node("Art") and module.has_node("GameplayGeometry") and module.has_node("Markers"), "Reusable room keeps art/gameplay/anchors separate")
	check(module.find_children("*", "MeshInstance3D", true, false).size() >= 10, "CC0 imported assets are saved native scene instances")
	check(module.find_children("*", "CollisionShape3D", true, false).size() >= 8, "Room has real world collision and the existing Door prefab")
	check(module.get_node("Markers/SupplyPoint").loot_table_id == &"street_repair_loot", "Supply marker uses existing content")
	add_child(module)
	await get_tree().physics_frame
	var door := module.get_node("GameplayGeometry/EntryDoor") as Door
	check(door != null and door.is_in_group("interactable"), "Door retains production interaction behavior")
	check(not module.get_node("Markers/SupplyPoint").has_rolled, "Opening a module sample never rolls rewards")
	module.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("MODULE_SCENE_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
