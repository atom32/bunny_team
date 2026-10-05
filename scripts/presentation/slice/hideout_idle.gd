extends Node
## Hideout-only playback of the sourced Quaternius standing/seated clips. No gameplay owner/state.
const DATA := preload("res://assets/animations/quaternius_hideout/idle.json")
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

func bind(value: PlayerController) -> void:
	if actor == value: return
	if is_instance_valid(actor) and actor.is_inside_tree(): set_relaxed(false)
	else:
		enabled = false
		modifiers.clear()
		visibility.clear()
	actor = value
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
		actor.character_skeleton.reset_bone_poses()
		actor.body_visual.rotation.y = PI - 0.25
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

func set_seated(value: bool, anchor: Vector3) -> void:
	seat_anchor = anchor
	if seated == value: return
	seated = value
	elapsed = 0.0
	if enabled: _process(0.0)

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(actor): return
	var clip: Dictionary = DATA.data["Sitting_Idle" if seated else "Idle"]
	elapsed = fmod(elapsed + delta, float(clip.duration))
	var frames: Array = clip.frames
	var sample := elapsed * float(clip.fps)
	var first := mini(int(sample), frames.size()-1)
	var second := mini(first+1, frames.size()-1)
	actor.position = seat_anchor if seated else original_position
	if seated:
		actor.position.y += lerpf(float(clip.height[first]),float(clip.height[second]),sample-first)*leg_height
	actor.body_visual.rotation.y = PI if seated else PI - 0.25
	var sk := actor.character_skeleton
	var globals: Array[Basis] = []
	var forward := Basis(Vector3.UP, PI)
	for index in sk.get_bone_count():
		var parent := sk.get_bone_parent(index)
		var desired := references[index]
		if semantics.has(index):
			var a: Array = frames[first][semantics[index]]
			var b: Array = frames[second][semantics[index]]
			var q := Quaternion(a[0],a[1],a[2],a[3]).slerp(Quaternion(b[0],b[1],b[2],b[3]),sample-first)
			desired = forward * Basis(q) * forward.inverse() * references[index]
		elif parent >= 0:
			# Unanimated fingers/accessories retain their authored local rest relationship.
			desired = globals[parent] * references[parent].inverse() * references[index]
		globals.append(desired)
		var local: Basis = desired if parent < 0 else globals[parent].inverse() * desired
		sk.set_bone_pose_rotation(index, local.get_rotation_quaternion())

