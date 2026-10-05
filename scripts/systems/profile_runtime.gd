extends Node

var _profile: ProfileState
var recovery_required := false
var recovery_path := SaveService.DEFAULT_SAVE_PATH


func _ready() -> void:
	initialize()


func initialize(path: String = SaveService.DEFAULT_SAVE_PATH) -> void:
	new_profile()
	recovery_path = path
	if SaveService.save_exists(path):
		recovery_required = not load_profile(path)


func get_profile() -> ProfileState:
	return _profile


func new_profile() -> ProfileState:
	_profile = ProfileState.create_new()
	recovery_required = false
	return _profile


func save_profile(path: String = SaveService.DEFAULT_SAVE_PATH) -> Error:
	if recovery_required:
		return ERR_FILE_CORRUPT
	return SaveService.save_profile(_profile, path)


func load_profile(path: String = SaveService.DEFAULT_SAVE_PATH) -> bool:
	var loaded_profile := SaveService.load_profile(path, false)
	if not loaded_profile:
		return false
	_upgrade(loaded_profile)
	_profile = loaded_profile
	recovery_required = false
	return true


func recover_profile(use_backup: bool) -> Error:
	var candidate := SaveService.load_profile(recovery_path + ".bak", false) if use_backup else ProfileState.create_new()
	if not candidate:
		return ERR_FILE_CORRUPT
	_upgrade(candidate)
	var error := SaveService.archive_save(recovery_path)
	if error == OK:
		error = SaveService.save_profile(candidate, recovery_path)
	if error == OK:
		_profile = candidate
		recovery_required = false
	return error


func _upgrade(profile: ProfileState) -> void:
	profile.inventory.capacity = maxf(profile.inventory.capacity, ProfileState.DEFAULT_WAREHOUSE_CAPACITY)
	# Alpha ownership is persistent. Never regrant sold/lost guns on load.
