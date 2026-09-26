extends SkeletonModifier3D
## Applies Blender-authored hand frames AFTER existing retarget and arm IK.
## No fingers are solved procedurally at runtime; this consumes baked master poses.
var pose: Dictionary = {}
var weapon: Node3D

func _process_modification_with_delta(_delta: float) -> void:
 var sk := get_skeleton()
 if pose.is_empty() or not is_instance_valid(weapon):
  return
 for side in ["Right", "Left"]:
  var hand_name: String = "Character1_" + side + "Hand"
  var index := sk.find_bone(hand_name)
  var authored := transform_from_rows(pose.hands[side].world_hand)
  var hand := sk.get_bone_global_pose(index)
  hand.basis = sk.global_basis.inverse() * weapon.global_basis.orthonormalized() * authored.basis
  sk.set_bone_global_pose(index, hand)
  var fingers: Dictionary = pose.hands[side].relative_fingers
  for name in fingers:
   sk.set_bone_global_pose(sk.find_bone(name), hand * transform_from_rows(fingers[name]))

static func transform_from_rows(rows: Array) -> Transform3D:
 return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])),Vector3(rows[0][3],rows[1][3],rows[2][3]))
