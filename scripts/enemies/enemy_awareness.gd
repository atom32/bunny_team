class_name EnemyAwareness
extends RefCounted
## Knowledge, not a live player tracker. Only sight and localized sound may
## replace last_known; navigation and presentation consume this remembered point.
enum State { PATROL, INVESTIGATE, COMBAT, SEARCH, RETURN }
var initialized := false
var state: int = State.PATROL
var home := Vector3.ZERO
var home_forward := Vector3.FORWARD
var last_known := Vector3.ZERO
var suspicion := 0.0
var memory_remaining := 0.0
var search_elapsed := 0.0
var patrol_index := 0
var patrol_wait := 0.0
var target_visible := false

func initialize(position: Vector3, forward: Vector3) -> void:
	if initialized: return
	initialized = true
	home = position
	home_forward = Vector3(forward.x, 0, forward.z).normalized()
	last_known = home

func hear(position: Vector3, duration: float) -> void:
	# A visible confirmed contact is more reliable than another sound.
	if target_visible and state == State.COMBAT: return
	last_known = position
	memory_remaining = duration
	search_elapsed = 0.0
	state = State.INVESTIGATE

func update(seen: bool, observed: Vector3, position: Vector3, delta: float, acquisition: float, memory: float, patrol_radius: float) -> void:
	target_visible = seen
	if seen:
		last_known = observed
		memory_remaining = memory
		search_elapsed = 0.0
		suspicion = minf(1.0, suspicion + delta / acquisition)
		state = State.COMBAT if suspicion >= 1.0 else State.INVESTIGATE
		return
	suspicion = maxf(0.0, suspicion - delta * 0.5)
	if state == State.COMBAT: state = State.SEARCH
	if state in [State.INVESTIGATE, State.SEARCH]:
		memory_remaining = maxf(0.0, memory_remaining - delta)
		if memory_remaining <= 0.0:
			state = State.RETURN
		elif position.distance_to(last_known) < 1.5 or state == State.SEARCH:
			state = State.SEARCH
			search_elapsed += delta
	elif state == State.RETURN and position.distance_to(home) < 1.0:
		state = State.PATROL
		patrol_wait = 0.0
	elif state == State.PATROL:
		patrol_wait += delta
		# A local patrol point may be behind a closed door. Skip it rather than
		# walking into that obstacle forever; do not invent a path through it.
		if (patrol_wait >= 2.0 and position.distance_to(destination(patrol_radius)) < 0.8) or patrol_wait >= 8.0:
			patrol_index = (patrol_index + 1) % 4
			patrol_wait = 0.0

func destination(patrol_radius: float) -> Vector3:
	match state:
		State.COMBAT, State.INVESTIGATE: return last_known
		State.SEARCH:
			# First visit the contact position, then check its surroundings. This
			# contains no hidden target coordinates, even when the player moves.
			if search_elapsed < 3.0: return last_known
			return last_known + home_forward.rotated(Vector3.UP, floorf((search_elapsed - 3.0) / 3.0) * PI * 0.5) * 2.0
		State.RETURN: return home
	return home + home_forward.rotated(Vector3.UP, patrol_index * PI * 0.5) * patrol_radius

func aim_point(position: Vector3) -> Vector3:
	if state in [State.COMBAT, State.INVESTIGATE]: return last_known + Vector3.UP * 1.05
	if state == State.SEARCH:
		return position + home_forward.rotated(Vector3.UP, search_elapsed * 0.7) * 8.0 + Vector3.UP * 1.05
	return position + home_forward.rotated(Vector3.UP, patrol_index * PI * 0.5) * 8.0 + Vector3.UP * 1.05
