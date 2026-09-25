extends CharacterCombatRig
## Isolated subclass. Base gameplay-facing has_weapon/reload/recoil behavior unchanged.
const HAND_MODIFIER = preload("res://spike/hand_modifier.gd")
var poses: Dictionary = {}
var selected_pose := ""
var hand_modifier: SkeletonModifier3D
var _raw_pose := Transform3D.IDENTITY
var _has_raw_pose := false

func setup(driver: Skeleton3D, target: Skeleton3D, retarget: RetargetModifier3D) -> void:
 super.setup(driver, target, retarget)
 poses = JSON.parse_string(FileAccess.get_file_as_string("res://spike/runtime_poses.json"))
 hand_modifier = HAND_MODIFIER.new()
 hand_modifier.name = "UnityChanAuthoredHands"
 display_skeleton.add_child(hand_modifier)

func clear_weapon() -> void:
 super.clear_weapon()
 selected_pose = ""
 _has_raw_pose = false
 if hand_modifier:
  hand_modifier.pose = {}
  hand_modifier.weapon = null

func update_pose(point: Vector3, direction: Vector3, dodge: float, delta: float, preview: bool) -> void:
 # Parent-local cache retains inherited host motion (including socket recoil).
 if _has_raw_pose and _pose_initialized:
  weapon_pose_root.transform = _raw_pose
 super.update_pose(point,direction,dodge,delta,preview)
 var weapon: Node3D = equipped_weapon if is_instance_valid(equipped_weapon) else _socket_visual
 if not is_instance_valid(weapon):
  return
 _raw_pose = weapon_pose_root.transform
 _has_raw_pose = true
 selected_pose = {"assault_rifle":"Rifle","smg":"SMG","rocket_launcher":"Rocket"}.get(weapon.scene_file_path.get_file().get_basename(), "")
 if selected_pose.is_empty():
  push_error("UnityChan adapter cannot resolve weapon presentation: " + weapon.scene_file_path)
  return
 var data: Dictionary = poses[selected_pose]
 var offset := vector(data.weapon_origin) - Vector3(0,1.13,-0.06)
 weapon_pose_root.global_position += weapon_pose_root.global_basis.orthonormalized() * offset
 if is_instance_valid(_socket_visual):
  _socket_visual.global_transform = weapon_pose_root.global_transform * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.44),Vector3.ZERO)
 var basis := weapon.global_basis.orthonormalized()
 right_hand_target.global_position = weapon.global_position + basis * vector(data.Right.wrist_from_weapon)
 var support := weapon.global_position + basis * vector(data.Left.wrist_from_weapon)
 # Preserve existing reload trajectory delta; don't reinterpret its gameplay duration/state.
 support += (reload_grip.global_position-support_grip.global_position) * _reload_hand_weight()
 left_hand_target.global_position = support
 hand_modifier.pose = data
 hand_modifier.weapon = weapon
 _sync_modifier_targets()

static func vector(a: Array) -> Vector3:
 return Vector3(a[0],a[1],a[2])
