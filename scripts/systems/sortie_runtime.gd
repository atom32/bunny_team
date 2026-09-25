extends Node

var _current_session: SortieSession


func start_sortie(request: SortieRequest, profile: ProfileState) -> SortieSession:
	var session := SortieSession.create_from_profile(request, profile)
	if not session or not session.activate():
		return null
	_current_session = session
	return session


func get_current_session() -> SortieSession:
	return _current_session


func clear_session() -> void:
	_current_session = null
