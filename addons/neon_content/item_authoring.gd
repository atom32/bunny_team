@tool
extends RefCounted
## Two-phase creation: review a plan, then explicitly publish. Never edits the template.
const AUDIT := preload("res://addons/neon_content/content_audit.gd")
const MANIFEST := "res://resources/content/content_manifest.tres"
const TEMPLATES := {
	"Material": "res://resources/items/fabric.tres",
	"Medical": "res://resources/items/field_dressing.tres",
	"Ammo": "res://resources/ammo/556_standard.tres",
	"Equipment": "res://resources/equipment/light_armor.tres",
	"Weapon": "res://resources/weapons/assault_rifle.tres",
}

static func plan(manifest: ContentManifest, options: Dictionary, manifest_path := MANIFEST) -> Dictionary:
	var result := {"pass": false, "errors": [], "manifest_path": manifest_path, "manifest_sha256": FileAccess.get_sha256(manifest_path)}
	var id := String(options.get("id", ""))
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)+$")
	if not pattern.search(id): result.errors.append("Use a namespaced lowercase ID, e.g. material.insulated_wire")
	var kind := String(options.get("template", ""))
	if not TEMPLATES.has(kind): result.errors.append("Select an existing template")
	if not manifest or not FileAccess.file_exists(manifest_path): result.errors.append("Manifest file is missing")
	if not result.errors.is_empty(): return result
	var template: ItemDefinition = load(TEMPLATES[kind])
	var definition := template.duplicate() as ItemDefinition
	definition.id = StringName(id)
	definition.display_name = String(options.get("name", "")).strip_edges()
	definition.description = String(options.get("description", template.description))
	if definition.description.strip_edges().is_empty(): result.errors.append("Describe this item's actual use before creating it")
	definition.weight = float(options.get("weight", template.weight))
	definition.base_value = int(options.get("value", template.base_value))
	definition.stash_size = options.get("stash_size", template.stash_size)
	definition.stackable = bool(options.get("stackable", template.stackable))
	definition.max_stack = int(options.get("max_stack", template.max_stack))
	definition.set_meta("authoring_source", String(options.get("source", TEMPLATES[kind])))
	definition.set_meta("license_ref", String(options.get("license_ref", "res://THIRD_PARTY_ASSETS.md")))
	var candidate := manifest.duplicate() as ContentManifest
	candidate.definitions = manifest.definitions.duplicate()
	candidate.definitions.append(definition)
	result.errors.append_array(AUDIT.item_errors(definition))
	if String(definition.get_meta("authoring_source")).is_empty() or String(definition.get_meta("license_ref")).is_empty(): result.errors.append("Source and license reference are required")
	for field in ["authoring_source", "license_ref"]:
		var reference := String(definition.get_meta(field))
		if reference.begins_with("res://") and not FileAccess.file_exists(reference): result.errors.append("Missing source/license reference: " + reference)
	var validation: Dictionary = AUDIT.audit(candidate, false)
	for error in validation.errors: result.errors.append(error.message)
	var folder := String(TEMPLATES[kind]).get_base_dir()
	if manifest_path.begins_with("user://"): folder = manifest_path.get_base_dir() # Disposable test fixtures only.
	var path := folder + "/" + id.replace(".", "_") + ".tres"
	if FileAccess.file_exists(path): result.errors.append("Refusing to overwrite existing resource: " + path)
	result.merge({"definition": definition, "candidate": candidate, "definition_path": path, "template_path": TEMPLATES[kind], "template_sha256": FileAccess.get_sha256(TEMPLATES[kind])})
	result.pass = result.errors.is_empty()
	return result

static func publish(plan_data: Dictionary) -> Dictionary:
	if not plan_data.get("pass", false): return {"error": ERR_INVALID_DATA, "message": "Review a valid plan first"}
	var path: String = plan_data.definition_path
	var manifest_path: String = plan_data.manifest_path
	if FileAccess.file_exists(path): return {"error": ERR_ALREADY_EXISTS, "message": "Destination already exists; nothing overwritten"}
	if FileAccess.get_sha256(manifest_path) != plan_data.manifest_sha256 or FileAccess.get_sha256(plan_data.template_path) != plan_data.template_sha256:
		return {"error": ERR_BUSY, "message": "Manifest or template changed since preview; review a new plan"}
	var definition: ItemDefinition = plan_data.definition
	var candidate: ContentManifest = plan_data.candidate
	if not AUDIT.audit(candidate, false).pass: return {"error": ERR_INVALID_DATA, "message": "Candidate no longer validates"}
	var stage := path.trim_suffix(".tres") + ".pending.tres"
	var manifest_stage := manifest_path.trim_suffix(".tres") + ".pending.tres"
	if FileAccess.file_exists(stage) or FileAccess.file_exists(manifest_stage): return {"error": ERR_ALREADY_EXISTS, "message": "Previous pending file exists; inspect it before retry"}
	var error := ResourceSaver.save(definition, stage)
	if error != OK: return {"error": error, "message": "Could not stage definition"}
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(stage), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(stage)
		return {"error": error, "message": "Could not publish definition; manifest unchanged"}
	definition.take_over_path(path)
	_bind_uid(path)
	error = ResourceSaver.save(candidate, manifest_stage)
	if error == OK:
		var reloaded := ResourceLoader.load(manifest_stage, "", ResourceLoader.CACHE_MODE_IGNORE) as ContentManifest
		if not reloaded or not AUDIT.audit(reloaded, false).pass: error = ERR_FILE_CORRUPT
	if error == OK and FileAccess.get_sha256(manifest_path) != plan_data.manifest_sha256: error = ERR_BUSY
	if error == OK: error = DirAccess.rename_absolute(ProjectSettings.globalize_path(manifest_stage), ProjectSettings.globalize_path(manifest_path))
	if error != OK:
		DirAccess.remove_absolute(manifest_stage)
		DirAccess.remove_absolute(path)
		return {"error": error, "message": "Manifest commit failed; new definition rolled back"}
	_bind_uid(manifest_path)
	return {"error": OK, "message": "Created and registered " + String(definition.id), "path": path}

static func _bind_uid(path: String) -> void:
	# Editor ResourceSaver associates a new UID with the staging filename.
	# Move that association too, before verifying references through the manifest.
	var uid := ResourceLoader.get_resource_uid(path)
	if uid == ResourceUID.INVALID_ID: return
	if ResourceUID.has_id(uid): ResourceUID.set_id(uid, path)
	else: ResourceUID.add_id(uid, path)
