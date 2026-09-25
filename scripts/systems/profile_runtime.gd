extends Node

var _profile: ProfileState


func _ready() -> void:
	if SaveService.save_exists():
		load_profile()
	else:
		new_profile()


func get_profile() -> ProfileState:
	return _profile


func new_profile() -> ProfileState:
	_profile = ProfileState.create_new()
	return _profile


func save_profile(path: String = SaveService.DEFAULT_SAVE_PATH) -> Error:
	return SaveService.save_profile(_profile, path)


func load_profile(path: String = SaveService.DEFAULT_SAVE_PATH) -> bool:
	var loaded_profile := SaveService.load_profile(path)
	if not loaded_profile:
		return false
	# Schema 1 stored carried capacity on the warehouse. Keep old saves valid while
	# restoring the now-explicit long-term warehouse capacity.
	loaded_profile.inventory.capacity = maxf(
		loaded_profile.inventory.capacity,
		ProfileState.DEFAULT_WAREHOUSE_CAPACITY
	)
	_profile = loaded_profile
	return true
