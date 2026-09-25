class_name SaveService
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_SAVE_PATH := "user://profile.json"


static func save_profile(profile: ProfileState, path: String = DEFAULT_SAVE_PATH) -> Error:
	if not profile or not profile.validate():
		push_error("Cannot save an invalid profile")
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	var envelope := {
		"schema_version": SCHEMA_VERSION,
		"profile": profile.to_dict(),
	}
	file.store_string(JSON.stringify(envelope, "\t"))
	return OK


static func load_profile(path: String = DEFAULT_SAVE_PATH, report_errors := true) -> ProfileState:
	if not FileAccess.file_exists(path):
		return _load_failure("Profile save does not exist: %s" % path, report_errors)
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return _load_failure("Could not open profile save: %s" % path, report_errors)
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return _load_failure("Could not parse profile save: %s" % json.get_error_message(), report_errors)
	if typeof(json.data) != TYPE_DICTIONARY:
		return _load_failure("Profile save root must be a dictionary", report_errors)
	var envelope := json.data as Dictionary
	if int(envelope.get("schema_version", -1)) != SCHEMA_VERSION:
		return _load_failure("Unsupported profile schema version", report_errors)
	var profile_data: Variant = envelope.get("profile", null)
	if typeof(profile_data) != TYPE_DICTIONARY:
		return _load_failure("Profile save is missing profile data", report_errors)
	var profile := ProfileState.from_dict(profile_data)
	if not profile or not profile.validate():
		return _load_failure("Profile save failed validation", report_errors)
	return profile


static func save_exists(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func _load_failure(message: String, report_errors: bool) -> ProfileState:
	if report_errors:
		push_error(message)
	return null
