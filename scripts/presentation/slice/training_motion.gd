extends "res://scripts/presentation/slice/hideout_idle.gd"
## Off-duty preview only. Reuses the existing 52-bone adapter and sourced gait/seat clips.
const STATIONS := {
	"idle": Vector3(-2.5, 0, 0), "stretch": Vector3(-2.5, 0, 0),
	"treadmill": Vector3(0, 0, 0), "bench": Vector3(2.5, 0, 0), "rest": Vector3(2.5, 0, 0),
}
var station := "idle"
var pending_station := ""
var exercise_elapsed := 0.0
var hold_elapsed := 0.0
var repetitions := 0
var playback_paused := false
var playback_speed := 1.0

func initialize(value: PlayerController) -> void:
	bind(value)
	actor.position = STATIONS.idle
	set_relaxed(true)
	phase = "exercise"
	target_yaw = PI
	actor.body_visual.rotation.y = PI
	_process(0.0)

func select_station(value: String) -> void:
	if not STATIONS.has(value) or value == pending_station or (value == station and pending_station.is_empty()): return
	pending_station = value
	station = ""
	playback_paused = false
	route.clear()
	var destination: Vector3 = STATIONS[value]
	var current := actor.position
	if Vector2(current.x, current.z).distance_to(Vector2(destination.x, destination.z)) > 0.05:
		# The bench sits behind the actor. Rise toward its front, then go around the end.
		# Also handle a new selection while the previous approach is still in flight.
		if current.x > 1.55 and current.x < 3.5 and current.z > -0.8 and current.z < 1.4:
			route.append(Vector3(current.x, 0, 1.25))
			route.append(Vector3(3.7, 0, 1.25))
			route.append(Vector3(3.7, 0, -1.9))
		else:
			route.append(Vector3(current.x, 0, -1.9))
		if value in ["bench", "rest"]:
			route.append(Vector3(3.7, 0, -1.9))
			route.append(Vector3(3.7, 0, 1.25))
			route.append(Vector3(2.5, 0, 1.25))
		else:
			route.append(Vector3(destination.x, 0, -1.9))
		route.append(destination)
	if seated or phase in ["sit", "rise"]:
		phase = "rise"
		seated = false
		_change_clip("Sitting_Exit")
	else:
		_begin_walk()

func _arrive() -> void:
	phase = "turn"
	speed = 0.0
	target_yaw = PI
	_change_clip("Idle")

func _begin_walk() -> void:
	if station == "bench" and pending_station.is_empty():
		phase = "exercise"
		seated = false
		hold_elapsed = 0.0
		repetitions += 1
		_change_clip("Idle")
	else:
		super._begin_walk()

func _start_station() -> void:
	station = pending_station
	pending_station = ""
	exercise_elapsed = 0.0
	hold_elapsed = 0.0
	repetitions = 0
	phase = "exercise"
	seat_anchor = Vector3(2.5, 0.045, 0)
	if station == "treadmill":
		_change_clip("Walk_Loop")
	elif station in ["rest", "bench"]:
		phase = "sit"
		_change_clip("Sitting_Enter")
	else:
		_change_clip("Idle")

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or playback_paused: return
	delta *= playback_speed
	super._process(delta)
	if not pending_station.is_empty() and phase == "idle": _start_station()
	if not station.is_empty(): exercise_elapsed += delta
	if station == "bench":
		if (seated and phase == "idle") or phase == "exercise":
			hold_elapsed += delta
			if hold_elapsed >= 2.0:
				hold_elapsed = 0.0
				phase = "rise" if seated else "sit"
				seated = false
				_change_clip("Sitting_Exit" if phase == "rise" else "Sitting_Enter")
	elif station == "stretch":
		repetitions = int(exercise_elapsed / 16.0)
		_apply_stretch()
	elif station == "treadmill":
		repetitions = int(exercise_elapsed / float(TRANSITIONS.data.Walk_Loop.duration))
		var clip: Dictionary = TRANSITIONS.data.Walk_Loop
		var sample := elapsed * float(clip.fps)
		var a := mini(int(sample), clip.height.size() - 1)
		var b := mini(a + 1, clip.height.size() - 1)
		actor.position.y += lerpf(float(clip.height[a]), float(clip.height[b]), sample - a) * leg_height * 0.75
	# The treadmill has a shallow rear approach ramp; the route never crosses its rails.
	if absf(actor.position.x) < 0.45:
		actor.position.y += 0.16 * smoothstep(-1.65, -1.05, actor.position.z)
	elif actor.position.x < -2.0:
		actor.position.y += 0.02

func _apply_stretch() -> void:
	# Original, gentle overhead side-bend keys. Feet, translations, scales and model stay intact.
	var t := fmod(exercise_elapsed, 16.0)
	var raised := smoothstep(0.0, 2.0, t) * (1.0 - smoothstep(13.0, 15.5, t))
	var bend := deg_to_rad(12.0) * (smoothstep(2.5, 4.5, t) - smoothstep(5.0, 7.0, t) - smoothstep(7.5, 9.5, t) + smoothstep(10.0, 12.0, t))
	var sk := actor.character_skeleton
	var baseline: Array[Basis] = []
	for index in sk.get_bone_count(): baseline.append(sk.get_bone_global_pose(index).basis.orthonormalized())
	var globals: Array[Basis] = []
	for index in sk.get_bone_count():
		var parent := sk.get_bone_parent(index)
		var desired := baseline[index] if parent < 0 else globals[parent] * baseline[parent].inverse() * baseline[index]
		var key: String = semantics.get(index, "")
		var tilt: float = {"spine": 0.33, "chest": 0.66, "upperChest": 1.0, "neck": 0.85, "head": 0.7}.get(key, -1.0)
		if tilt >= 0.0: desired = Basis(Vector3.BACK, bend * tilt) * baseline[index]
		var arm_angles := {"leftUpperArm": -75.0, "leftLowerArm": -105.0, "leftHand": -105.0, "rightUpperArm": 75.0, "rightLowerArm": 105.0, "rightHand": 105.0}
		if arm_angles.has(key):
			var overhead := Basis(Vector3.BACK, bend + deg_to_rad(arm_angles[key])) * references[index]
			desired = Basis(desired.get_rotation_quaternion().slerp(overhead.get_rotation_quaternion(), raised))
		globals.append(desired)
		var local: Basis = desired if parent < 0 else globals[parent].inverse() * desired
		sk.set_bone_pose_rotation(index, local.get_rotation_quaternion())
