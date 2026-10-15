extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var scene := load("res://scenes/areas/street_district.tscn") as PackedScene
	var area := scene.instantiate() as Node3D
	var before := area.find_children("*", "MeshInstance3D", true, false).size()
	check(before >= 2042, "Campus geometry is saved and visible before runtime _ready")
	check(area.find_children("*", "CollisionShape3D", true, false).size() == 161, "All authored collision shapes are saved")
	check(area.has_node("RoomAnchors/Clinic") and area.has_node("RecordSites/Site0"), "Authored task anchors are editable markers")
	check(area.get_node("StreetSpawn0").is_in_group("player_spawn_point"), "Spawn membership persists without running its builder")
	add_child(area)
	await get_tree().process_frame
	check(area.find_children("*", "MeshInstance3D", true, false).size() == before, "Starting the saved map does not duplicate art")
	check(SortieCheckpoint.layout_signature(area) == area.get_meta("legacy_layout_signature"), "Collision/navigation signature is identical to the previous generated map")
	check(area.loot_points.size() == 18 and area.enemy_points.size() == 12, "Existing loot/enemy points bind, no duplicate spawning")
	check(area.SPAWNS.size() == 6 and area.EXITS.size() == 4, "Editable saved point inventory is complete")
	var open_door := area.get_node("ShopDoor0") as Door
	check(open_door.state == Door.State.OPEN, "Door runtime state restores authored open entrance")
	area.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("CAMPUS_EDITOR_SCENE_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
