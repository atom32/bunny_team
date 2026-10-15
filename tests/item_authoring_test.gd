extends Node
const AUTHOR := preload("res://addons/neon_content/item_authoring.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var production: ContentManifest = load(AUTHOR.MANIFEST)
	var hash_before := FileAccess.get_sha256(AUTHOR.MANIFEST)
	var profile_before := JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var folder := "user://item_authoring_test"
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder + "/manifest.tres"
	ResourceSaver.save(production.duplicate(), path)
	var original := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ContentManifest
	var options := {"template": "Material", "id": "material.authoring_probe", "name": "Authoring probe", "description": "Disposable template test", "weight": .2, "value": 5}
	var plan: Dictionary = AUTHOR.plan(original, options, path)
	check(plan.pass and original.definitions.size() == production.definitions.size(), "Planning never mutates source arrays")
	check(plan.definition != load(AUTHOR.TEMPLATES.Material) and plan.definition.id == &"material.authoring_probe", "Template clone owns new ID and values")
	check(not FileAccess.file_exists(plan.definition_path), "Preview does not publish any file")
	var conflict := options.duplicate(); conflict.id = "material.fabric"
	check(not AUTHOR.plan(original, conflict, path).pass, "Existing definition ID cannot be reused")
	var escape := options.duplicate(); escape.id = "../outside"
	check(not AUTHOR.plan(original, escape, path).pass, "ID cannot escape target folder")
	var bad := options.duplicate(); bad.weight = -1
	check(not AUTHOR.plan(original, bad, path).pass, "Invalid quantity/weight cannot be staged")
	var result: Dictionary = AUTHOR.publish(plan)
	check(result.error == OK, "Reviewed plan creates resource and registers manifest")
	var reopened := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ContentManifest
	check(reopened.definitions.size() == production.definitions.size() + 1 and reopened.definitions.back().id == &"material.authoring_probe", "New manifest and external resource reopen correctly")
	var published_hash := FileAccess.get_sha256(plan.definition_path)
	check(AUTHOR.publish(plan).error == ERR_ALREADY_EXISTS and FileAccess.get_sha256(plan.definition_path) == published_hash, "Re-running never overwrites or duplicates the new item")
	var stale := options.duplicate(); stale.id = "material.stale_probe"
	var stale_plan: Dictionary = AUTHOR.plan(reopened, stale, path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE); file.seek_end(); file.store_string("\n"); file.close()
	check(AUTHOR.publish(stale_plan).error == ERR_BUSY and not FileAccess.file_exists(stale_plan.definition_path), "A stale preview cannot replace a changed manifest")
	check(FileAccess.get_sha256(AUTHOR.MANIFEST) == hash_before and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == profile_before, "Authoring fixture never changes production definitions or profile")
	DirAccess.remove_absolute(plan.definition_path); DirAccess.remove_absolute(path)
	AudioDirector.shutdown_for_test()
	print("ITEM_AUTHORING_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
