extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	for entry in [["weapons", 7], ["items", 37], ["enemies", 4]]:
		var registry: Resource = load("res://resources/editor_catalogs/" + entry[0] + ".tres")
		check(registry != null, "Editor catalog exists: " + entry[0])
		if not registry: continue
		check(registry.get_all_string_ids().size() == entry[1], "Catalog count matches registered definitions")
		for id: StringName in registry.get_all_string_ids():
			var definition: Resource = registry.load_entry(id)
			check(definition != null and definition.get("id") == id, "YARD ID equals definition.id, never basename: " + String(id))
			var runtime: Resource = ContentDB.get_enemy_definition(id, false) if entry[0] == "enemies" else ContentDB.get_item(id, false)
			check(runtime == definition, "ContentDB remains the same authoritative definition")
	var source := FileAccess.get_file_as_string("res://addons/yard/plugin.cfg")
	check('version="1.3.1"' in source, "YARD version is pinned")
	AudioDirector.shutdown_for_test()
	print("CONTENT_CATALOG_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
