extends Node
## Hideout-only playback of the sourced Quaternius standing/seated clips. No gameplay owner/state.
const DATA := preload("res://assets/animations/quaternius_hideout/idle.json")
const TRANSITIONS := preload("res://assets/animations/quaternius_hideout/transitions.json")
const WALK_SPEED := 0.92
const STRIDE_SPEED := 0.94
const BLEND_TIME := 0.42
# Keep the sourced gait, with a shorter stride and relaxed shoulders/open idle hands.
const WALK_RELAX := {
	"hips": 0.18, "spine": 0.3, "chest": 0.4, "upperChest": 0.45,
	"neck": 0.45, "head": 0.5,
	"leftShoulder": 0.55, "rightShoulder": 0.55,
	"leftUpperArm": 0.45, "rightUpperArm": 0.45,
	"leftLowerArm": 0.5, "rightLowerArm": 0.5,
	"leftHand": 0.7, "rightHand": 0.7,
	"leftUpperLeg": 0.18, "rightUpperLeg": 0.18,
}
const AISLE_Z := 1.0
const DESTINATIONS := {
	"Overview": Vector3(-0.55,0,-0.1), "Hanger": Vector3(-0.55,0,-0.1),
	"Operations": Vector3(-1.05,0,-0.48), "Workshop": Vector3(-1.8,0,0.2),
	"Rest": Vector3(2.12,0.045,0.9),
}
const MAP := {
	"hips":"Hips", "spine":"Spine", "chest":"Spine1", "upperChest":"Spine2",
	"neck":"Neck", "head":"Head",
	"leftShoulder":"LeftShoulder", "leftUpperArm":"LeftArm", "leftLowerArm":"LeftForeArm", "leftHand":"LeftHand",
	"rightShoulder":"RightShoulder", "rightUpperArm":"RightArm", "rightLowerArm":"RightForeArm", "rightHand":"RightHand",
	"leftUpperLeg":"LeftUpLeg", "leftLowerLeg":"LeftLeg", "leftFoot":"LeftFoot", "leftToes":"LeftToeBase",
	"rightUpperLeg":"RightUpLeg", "rightLowerLeg":"RightLeg", "rightFoot":"RightFoot", "rightToes":"RightToeBase",
}
var actor: PlayerController
var enabled := false
var elapsed := 0.0
var idle_elapsed := 0.0
var modifiers := {}
var visibility := {}
var references: Array[Basis] = []
var semantics := {}
var original_rotation := 0.0
var original_tree_active := true
var original_position := Vector3.ZERO
var seated := false
var seat_anchor := Vector3.ZERO
var leg_height := 1.0
var destination_section := ""
var phase := "idle"
var clip_name := "Idle"
var route: Array[Vector3] = []
var blend_from: Array[Quaternion] = []
var blend_elapsed := BLEND_TIME
var target_yaw := PI - 0.25
var speed := 0.0
var equipment_blend := false
var equipment_start_yaw := 0.0
var height_offset := 0.0

func _clip() -> Dictionary:
	return DATA.data[clip_name] if DATA.data.has(clip_name) else TRANSITIONS.data[clip_name]

func _change_clip(value: String) -> void:
	blend_from.clear()
	for index in actor.character_skeleton.get_bone_count():
		blend_from.append(actor.character_skeleton.get_bone_pose_rotation(index))
	blend_elapsed = 0.0
	clip_name = value
	elapsed = 0.0

func transition_to(value: String, immediate := false) -> void:
	if destination_section == value: return
	destination_section = value
	equipment_blend = false
	set_relaxed(true)
	seat_anchor = DESTINATIONS["Rest"]
	if immediate:
		actor.position = DESTINATIONS[value]
		seated = value == "Rest"
		phase = "idle"
		clip_name = "Sitting_Idle" if seated else "Idle"
		target_yaw = PI if seated else PI - 0.25
		actor.body_visual.rotation.y = target_yaw
		_process(0.0)
		if value == "Hanger": set_relaxed(false)
		return
	# Interrupts keep the current world position and blend from the visible pose.
	route.clear()
	var destination: Vector3 = DESTINATIONS[value]
	var current := actor.position
	if Vector2(current.x, current.z).distance_to(Vector2(destination.x, destination.z)) > 0.08:
		if absf(current.x - destination.x) > 0.25:
			route.append(Vector3(current.x, 0, AISLE_Z))
			route.append(Vector3(destination.x, 0, AISLE_Z))
		route.append(Vector3(destination.x, 0, destination.z))
	if seated or phase == "sit" or phase == "rise":
		phase = "rise"
		seated = false
		_change_clip("Sitting_Exit")
	else:
		_begin_walk()

func _begin_walk() -> void:
	phase = "walk"
	speed = 0.0
	seated = false
	_change_clip("Walk_Loop" if not route.is_empty() else "Idle")

func _arrive() -> void:
	phase = "turn"
	speed = 0.0
	target_yaw = PI if destination_section == "Rest" else (0.0 if destination_section in ["Operations", "Workshop"] else PI - 0.25)
	_change_clip("Idle")

func _finish_equipment() -> void:
	phase = "idle"
	_change_clip("Idle")
	equipment_start_yaw = actor.body_visual.rotation.y
	set_relaxed(false)
	actor.body_visual.rotation.y = equipment_start_yaw
	for index in blend_from.size(): actor.character_skeleton.set_bone_pose_rotation(index, blend_from[index])
	equipment_blend = true


func bind(value: PlayerController) -> void:
	if actor == value: return
	if is_instance_valid(actor) and actor.is_inside_tree(): set_relaxed(false)
	else:
		enabled = false
		modifiers.clear()
		visibility.clear()
	actor = value
	destination_section = ""
	phase = "idle"
	seated = false
	height_offset = 0.0
	equipment_blend = false
	blend_from.clear()
	references.clear()
	semantics.clear()
	if not is_instance_valid(actor): return
	var sk := actor.character_skeleton
	for side in ["left", "right"]:
		for finger in ["Index", "Middle", "Pinky", "Ring", "Thumb"]:
			for segment in range(1,4):
				var bone_name: String = side.capitalize()+"Hand"+finger+str(segment)
				semantics[sk.find_bone("Character1_"+bone_name)] = side+finger+str(segment)
	leg_height = sk.get_bone_global_rest(sk.find_bone("Character1_Hips")).origin.y - sk.get_bone_global_rest(sk.find_bone("Character1_LeftFoot")).origin.y
	for key in MAP:
		semantics[sk.find_bone("Character1_" + MAP[key])] = key
	for index in sk.get_bone_count():
		var reference := sk.get_bone_global_rest(index).basis.orthonormalized()
		# Rest-space retarget only: source uses normalized T-pose, target is A-pose.
		for side in ["Left", "Right"]:
			var upper := sk.find_bone("Character1_"+side+"Arm")
			var ancestor := index
			while ancestor >= 0 and ancestor != upper: ancestor = sk.get_bone_parent(ancestor)
			if ancestor == upper:
				var elbow := sk.find_bone("Character1_"+side+"ForeArm")
				var axis := sk.get_bone_global_rest(upper).origin.direction_to(sk.get_bone_global_rest(elbow).origin)
				reference = Basis(Quaternion(axis, Vector3.LEFT if side == "Left" else Vector3.RIGHT)) * reference
		references.append(reference)

func set_relaxed(value: bool) -> void:
	if enabled == value: return
	enabled = value
	if not is_instance_valid(actor): return
	if enabled:
		height_offset = actor.position.y
		original_position = actor.position
		original_rotation = actor.body_visual.rotation.y
		original_tree_active = actor.animation_tree.active
		actor.set_process(false)
		actor.animation_tree.active = false
		for modifier in actor.body_visual.find_children("*", "SkeletonModifier3D", true, false):
			modifiers[modifier] = modifier.active
			modifier.active = false
		for node in [actor.combat_rig, actor._find_socket(&"Chest"), actor._find_socket(&"Backpack"), actor._find_socket(&"HandL"), actor._find_socket(&"HandR"), actor._find_socket(&"ShoulderR")]:
			if is_instance_valid(node):
				visibility[node] = node.visible
				node.hide()

	else:
		for modifier in modifiers:
			if is_instance_valid(modifier): modifier.active = modifiers[modifier]
		for node in visibility:
			if is_instance_valid(node): node.visible = visibility[node]
		modifiers.clear()
		visibility.clear()
		actor.position = original_position
		actor.character_skeleton.reset_bone_poses()
		actor.animation_tree.active = original_tree_active
		actor.body_visual.rotation.y = original_rotation
		actor.set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	if equipment_blend:
		blend_elapsed = minf(blend_elapsed + delta, BLEND_TIME)
		var weight := smoothstep(0.0, BLEND_TIME, blend_elapsed)
		actor.body_visual.rotation.y = lerp_angle(equipment_start_yaw, original_rotation, weight)
		for index in actor.character_skeleton.get_bone_count():
			var current := actor.character_skeleton.get_bone_pose_rotation(index)
			actor.character_skeleton.set_bone_pose_rotation(index, blend_from[index].slerp(current, weight))
		if blend_elapsed >= BLEND_TIME: equipment_blend = false
		return
	if not enabled: return
	idle_elapsed = fmod(idle_elapsed + delta, float(DATA.data["Idle"].duration))
	var clip := _clip()
	var one_shot := phase in ["rise", "sit"]
	var playback_delta := delta * speed / STRIDE_SPEED if phase == "walk" else (delta * 0.78 if one_shot else delta)
	elapsed = minf(elapsed + playback_delta, float(clip.duration)) if one_shot else fmod(elapsed + playback_delta, float(clip.duration))
	if phase == "walk":
		while not route.is_empty() and Vector2(actor.position.x, actor.position.z).distance_to(Vector2(route[0].x, route[0].z)) < 0.025:
			actor.position.x = route[0].x
			actor.position.z = route[0].z
			route.pop_front()
		if route.is_empty():
			_arrive()
		else:
			var offset := route[0] - Vector3(actor.position.x, 0, actor.position.z)
			target_yaw = atan2(-offset.x, -offset.z)
			var alignment := maxf(0.0, cos(wrapf(target_yaw - actor.body_visual.rotation.y, -PI, PI)))
			var desired_speed := WALK_SPEED * alignment * minf(1.0, offset.length() / 0.35)
			speed = move_toward(speed, desired_speed, delta * 1.9)
			var step := offset.normalized() * minf(speed * delta, offset.length())
			actor.position += step
	elif phase == "turn" and absf(wrapf(target_yaw - actor.body_visual.rotation.y, -PI, PI)) < 0.035 and blend_elapsed >= BLEND_TIME:
		if destination_section == "Rest":
			phase = "sit"
			_change_clip("Sitting_Enter")
		elif destination_section == "Hanger":
			_finish_equipment()
			return
		else:
			phase = "idle"
			height_offset = 0.0
	elif one_shot and elapsed >= float(clip.duration):
		if phase == "rise":
			_begin_walk()
		else:
			phase = "idle"
			seated = true
			_change_clip("Sitting_Idle")
	clip = _clip()
	actor.body_visual.rotation.y = lerp_angle(actor.body_visual.rotation.y, target_yaw, 1.0 - exp(-delta * 5.0))
	var frames: Array = clip.frames
	var sample := elapsed * float(clip.fps)
	var first := mini(int(sample), frames.size()-1)
	var second := mini(first+1, frames.size()-1)
	var seat_motion := seated or phase in ["rise", "sit"]
	var desired_height := lerpf(float(clip.height[first]),float(clip.height[second]),sample-first)*leg_height if seat_motion or phase == "walk" else 0.0
	if phase == "walk": desired_height *= 0.75
	if seat_motion: desired_height += seat_anchor.y
	height_offset = lerpf(height_offset, desired_height, 1.0 - exp(-delta * 18.0)) if delta > 0.0 else desired_height
	actor.position.y = height_offset
	blend_elapsed = minf(blend_elapsed + delta, BLEND_TIME)
	var weight := smoothstep(0.0, BLEND_TIME, blend_elapsed)
	var sk := actor.character_skeleton
	var globals: Array[Basis] = []
	var forward := Basis(Vector3.UP, PI)
	var idle: Dictionary = DATA.data["Idle"]
	var idle_sample := idle_elapsed * float(idle.fps)
	var idle_first := mini(int(idle_sample), idle.frames.size()-1)
	var idle_second := mini(idle_first+1, idle.frames.size()-1)
	for index in sk.get_bone_count():
		var parent := sk.get_bone_parent(index)
		var desired := references[index]
		if semantics.has(index):
			var a: Array = frames[first][semantics[index]]
			var b: Array = frames[second][semantics[index]]
			var q := Quaternion(a[0],a[1],a[2],a[3]).slerp(Quaternion(b[0],b[1],b[2],b[3]),sample-first)
			if phase == "walk":
				var semantic: String = semantics[index]
				var relaxed_weight: float = WALK_RELAX.get(semantic, 0.0)
				if "Index" in semantic or "Middle" in semantic or "Pinky" in semantic or "Ring" in semantic or "Thumb" in semantic: relaxed_weight = 0.9
				var idle_a: Array = idle.frames[idle_first][semantic]
				var idle_b: Array = idle.frames[idle_second][semantic]
				var idle_q := Quaternion(idle_a[0],idle_a[1],idle_a[2],idle_a[3]).slerp(Quaternion(idle_b[0],idle_b[1],idle_b[2],idle_b[3]),idle_sample-idle_first)
				q = q.slerp(idle_q, relaxed_weight)
			desired = forward * Basis(q) * forward.inverse() * references[index]
		elif parent >= 0:
			desired = globals[parent] * references[parent].inverse() * references[index]
		globals.append(desired)
		var local: Basis = desired if parent < 0 else globals[parent].inverse() * desired
		var rotation := local.get_rotation_quaternion()
		if blend_from.size() == sk.get_bone_count(): rotation = blend_from[index].slerp(rotation, weight)
		sk.set_bone_pose_rotation(index, rotation)
