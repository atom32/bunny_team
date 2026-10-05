import pathlib,re,json,struct
base=pathlib.Path(__file__).parent
src=pathlib.Path(r'D:/bunny_team/scripts/presentation/slice/hideout_idle.gd').read_text()
mp=re.search(r'const MAP := (\{.*?\n\})',src,re.S).group(1)
renames=dict(re.findall(r'&"([^"]+)": &"([^"]+)"',pathlib.Path(r'D:/bunny_team/scripts/player/player_controller.gd').read_text()))
inv={v.replace('Character1_',''):k for k,v in renames.items()}
for side in ['left','right']:
 for finger in ['Index','Middle','Pinky','Ring','Thumb']:
  for seg in range(1,4):inv[side.capitalize()+'Hand'+finger+str(seg)]='J_Bip_'+side[0].upper()+'_'+('Little' if finger=='Pinky' else finger)+str(seg)
code='''extends Node3D
const DATA = preload("res://character/idle.json")
const MAP = '''+mp+'''
const ORIGINAL = '''+json.dumps(inv)+'''
var sk:Skeleton3D
var refs:Array[Basis]=[]
var semantics={}
var elapsed=0.0
func _ready():
 var model=load("res://character/bunny_player.glb").instantiate()
 add_child(model)
 model.rotation.y=PI-.25
 var weapon=model.find_child("Wep",true,false)
 if weapon:weapon.hide()
 sk=model.find_child("Skeleton3D",true,false)
 for key in MAP:
  var index=sk.find_bone(ORIGINAL[MAP[key]])
  assert(index>=0,"Missing body mapping: "+key)
  semantics[index]=key
 for side in ["left","right"]:
  for finger in ["Index","Middle","Pinky","Ring","Thumb"]:
   for segment in range(1,4):
    var name=side.capitalize()+"Hand"+finger+str(segment)
    var index=sk.find_bone(ORIGINAL[name])
    if index>=0:semantics[index]=side+finger+str(segment)
 for index in sk.get_bone_count():
  var reference=sk.get_bone_global_rest(index).basis.orthonormalized()
  for side in ["Left","Right"]:
   var upper=sk.find_bone(ORIGINAL[side+"Arm"])
   var ancestor=index
   while ancestor>=0 and ancestor!=upper:ancestor=sk.get_bone_parent(ancestor)
   if ancestor==upper:
    var elbow=sk.find_bone(ORIGINAL[side+"ForeArm"])
    var axis=sk.get_bone_global_rest(upper).origin.direction_to(sk.get_bone_global_rest(elbow).origin)
    reference=Basis(Quaternion(axis,Vector3.LEFT if side=="Left" else Vector3.RIGHT))*reference
  refs.append(reference)
 print("TRIAL_CHARACTER_MAPPING ",semantics.size()," scale=1")
func _process(delta):
 if not sk:return
 var clip:Dictionary=DATA.data["Idle"]
 elapsed=fmod(elapsed+delta,float(clip.duration))
 var frames:Array=clip.frames
 var sample=elapsed*float(clip.fps)
 var first=mini(int(sample),frames.size()-1)
 var second=mini(first+1,frames.size()-1)
 var globals:Array[Basis]=[]
 var forward=Basis(Vector3.UP,PI)
 for index in sk.get_bone_count():
  var parent=sk.get_bone_parent(index)
  var desired=refs[index]
  if semantics.has(index):
   var a:Array=frames[first][semantics[index]]
   var b:Array=frames[second][semantics[index]]
   var q=Quaternion(a[0],a[1],a[2],a[3]).slerp(Quaternion(b[0],b[1],b[2],b[3]),sample-first)
   desired=forward*Basis(q)*forward.inverse()*refs[index]
  elif parent>=0:desired=globals[parent]*refs[parent].inverse()*refs[index]
  globals.append(desired)
  var local:Basis=desired if parent<0 else globals[parent].inverse()*desired
  sk.set_bone_pose_rotation(index,local.get_rotation_quaternion())
'''
(base/'project'/'character_preview.gd').write_text(code)
# Inspect all imported assets, not only the first two props.
p=base/'project'/'inspect.gd'
s=p.read_text();s=s.replace('for folder in ["concrete","furniture","polyhaven/steel_frame_shelves_01","polyhaven/metal_tool_chest"]:', 'var folders=["concrete","furniture","kit","weapons"]\n for d in DirAccess.get_directories_at("res://polyhaven"):folders.append("polyhaven/"+d)\n for folder in folders:')
p.write_text(s)
