extends SkeletonModifier3D
## R_PutGun returns to a transition/bind pose after its socket event. Recover
## into the project's existing Quaternius idle, not a permanent T-pose.
const IDLE=preload("res://scripts/presentation/slice/hideout_idle.gd")
var rig: Node3D
var elapsed:=0.0
var references: Array[Basis]=[]
var semantics:={}
func _process_modification_with_delta(delta: float) -> void:
 if not is_instance_valid(rig):return
 elapsed=fmod(elapsed+delta,2.5)
 var weight:=0.0
 if rig.motion_mode=="Holstered":weight=1.0
 elif rig.motion_mode=="PutGun":weight=smoothstep(.49282077,.80,rig.motion_time)
 elif rig.motion_mode=="TakeGun":weight=1.0-smoothstep(0,.2,rig.motion_time)
 if weight<=0:return
 var sk:=get_skeleton()
 if references.is_empty():
  for i in sk.get_bone_count():
   var ref:=sk.get_bone_global_rest(i).basis.orthonormalized()
   var name:=String(sk.get_bone_name(i))
   for side in ["Left","Right"]:
    var upper:=sk.find_bone("Character1_"+side+"Arm");var ancestor:=i
    while ancestor>=0 and ancestor!=upper:ancestor=sk.get_bone_parent(ancestor)
    if ancestor==upper:
     var axis:=sk.get_bone_global_rest(upper).origin.direction_to(sk.get_bone_global_rest(sk.find_bone("Character1_"+side+"ForeArm")).origin)
     ref=Basis(Quaternion(axis,Vector3.LEFT if side=="Left" else Vector3.RIGHT))*ref
    for finger in ["Index","Middle","Pinky","Ring","Thumb"]:
     for joint in range(1,4):
      if name=="Character1_"+side+"Hand"+finger+str(joint):semantics[i]=side.to_lower()+finger+str(joint)
   references.append(ref)
  for key in IDLE.MAP:semantics[sk.find_bone("Character1_"+IDLE.MAP[key])]=key
 var clip: Dictionary=IDLE.DATA.data.Idle
 var at:=elapsed*float(clip.fps);var lo:=mini(int(at),clip.frames.size()-1);var hi:=mini(lo+1,clip.frames.size()-1)
 var globals: Array[Basis]=[]
 var forward:=Basis(Vector3.UP,PI)
 for i in sk.get_bone_count():
  var parent:=sk.get_bone_parent(i);var desired:=references[i]
  if semantics.has(i):
   var a: Array=clip.frames[lo][semantics[i]];var b: Array=clip.frames[hi][semantics[i]]
   desired=forward*Basis(Quaternion(a[0],a[1],a[2],a[3]).slerp(Quaternion(b[0],b[1],b[2],b[3]),at-lo))*forward.inverse()*references[i]
  elif parent>=0:desired=globals[parent]*references[parent].inverse()*references[i]
  globals.append(desired)
  var name:=String(sk.get_bone_name(i))
  if "Shoulder" not in name and "Arm" not in name and "Hand" not in name:continue
  # Use the live torso's global pose, but preserve the idle arm-chain offsets.

  var local: Basis=desired if parent<0 else globals[parent].inverse()*desired
  sk.set_bone_pose_rotation(i,sk.get_bone_pose_rotation(i).slerp(local.get_rotation_quaternion(),weight))
