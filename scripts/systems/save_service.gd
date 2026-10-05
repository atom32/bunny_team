class_name SaveService
extends RefCounted

const SCHEMA_VERSION := 4
const DEFAULT_SAVE_PATH := "user://profile.json"
const MAX_SAVE_BYTES := 8 * 1024 * 1024


static func is_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func save_profile(profile: ProfileState, path: String = DEFAULT_SAVE_PATH) -> Error:
	if not profile or not profile.validate():
		return ERR_INVALID_DATA
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema_version": SCHEMA_VERSION, "profile": profile.to_dict()}, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	if not load_profile(temporary, false):
		return ERR_FILE_CORRUPT
	# Only rotate a verified primary. A corrupt primary must never destroy a good backup.
	if load_profile(path, false):
		var backup_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak.tmp"))
		if backup_error != OK:
			return backup_error
		backup_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".bak.tmp"), ProjectSettings.globalize_path(path + ".bak"))
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))


static func load_profile(path: String = DEFAULT_SAVE_PATH, report_errors := true) -> ProfileState:
	if not FileAccess.file_exists(path):
		return _load_failure("Profile save does not exist: %s" % path, report_errors)
	var file := FileAccess.open(path, FileAccess.READ)
	if not file or file.get_length() > MAX_SAVE_BYTES:
		return _load_failure("Profile save is unreadable or too large", report_errors)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _load_failure("Profile save is not valid JSON data", report_errors)
	var envelope := json.data as Dictionary
	var version: Variant = envelope.get("schema_version")
	if not is_number(version) or float(version) not in [1.0, 2.0, 3.0, 4.0]:
		return _load_failure("Unsupported profile schema version", report_errors)
	var profile_data: Variant = envelope.get("profile")
	if typeof(profile_data) != TYPE_DICTIONARY:
		return _load_failure("Profile save is missing profile data", report_errors)
	if float(version) >= 2.0:
		for key in ["credits", "successful_sorties", "failed_sorties", "relief_claimed_after", "settled_outcomes"]:
			if not profile_data.has(key): return _load_failure("Profile save is missing economy data", report_errors)
	if float(version) >= 3.0 and not profile_data.has("sortie_checkpoint"):
		return _load_failure("Profile save is missing sortie checkpoint data", report_errors)
	if float(version) >= 4.0 and not profile_data.has("campaign"):
		return _load_failure("Profile save is missing campaign data", report_errors)
	var profile := ProfileState.from_dict(profile_data)
	if not profile or not profile.validate():
		return _load_failure("Profile save failed validation", report_errors)
	return profile


static func save_exists(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func archive_save(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	var archive := "%s.recovery-%s-%s" % [path, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(archive))


static func _load_failure(message: String, report_errors: bool) -> ProfileState:
	if report_errors:
		push_warning(message)
	return null
