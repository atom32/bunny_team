"""Offline Blender hand pose authoring. No gameplay code or source package writes."""
import bpy,json,math,pathlib,hashlib
from mathutils import Vector,Matrix,Quaternion
D=pathlib.Path(__file__).resolve().parent; ROOT=D.parent; REPO=ROOT.parent.parent
bpy.ops.wm.open_mainfile(filepath=str(D/'master_before.blend' if (D/'master_before.blend').exists() else ROOT/'battle_master.blend'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE'); meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
if not (D/'master_before.blend').exists():
 import shutil;shutil.copy2(ROOT/'battle_master.blend',D/'master_before.blend')
# Backup retains paths relative to the authoritative master directory, not backup directory.
active_images={n.image for o in meshes for mat in o.data.materials if mat and mat.use_nodes for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image}
for image in active_images:
 if image.source=='FILE' and image.filepath.startswith('//'):
  image.filepath=str((ROOT/image.filepath[2:]).resolve());assert pathlib.Path(image.filepath).exists(),image.filepath;image.reload()
# Godot design space -> Blender, preserving metres and forward.
def B(v):return Vector((v[0],-v[2],v[1]))
def G(v):return [v.x,v.z,-v.y]
def pb(side,n):return rig.pose.bones['Character1_'+side+n]
def update():bpy.context.view_layer.update()
def point(side,n):return pb(side,n).head.copy()
def frame(long,across):
 l=long.normalized();a=(across-l*across.dot(l)).normalized();return Matrix((l,a,l.cross(a))).transposed()
def align_segment(b,child,target):
 update();m=b.matrix.copy();rot=(child.head-b.head).normalized().rotation_difference((target-b.head).normalized());m=rot.to_matrix().to_4x4()@m;m.translation=b.head;b.matrix=m;update()
def arm(side,target):
 s=point(side,'Arm');e=point(side,'ForeArm');w=point(side,'Hand');a=(e-s).length;b=(w-e).length;delta=target-s;d=delta.length;axis=delta.normalized()
 if d>a+b:raise RuntimeError(f'{side} unreachable {d} > {a+b}')
 pole=B((0.28 if side=='Right' else -0.28,-0.28,0.04));normal=(pole-axis*pole.dot(axis)).normalized();along=(a*a-b*b+d*d)/(2*d);elbow=s+axis*along+normal*math.sqrt(max(0,a*a-along*along))
 align_segment(pb(side,'Arm'),pb(side,'ForeArm'),elbow);align_segment(pb(side,'ForeArm'),pb(side,'Hand'),target)
 return dict(shoulder=G(s),elbow=G(point(side,'ForeArm')),wrist=G(point(side,'Hand')))
def hand(side,data):
 h=pb(side,'Hand');long=point(side,'HandMiddle1')-h.head;across=point(side,'HandIndex1')-point(side,'HandPinky1');source=frame(long,across)
 direction=B(data['palm_long']).normalized();normal=B(data['palm_normal']).normalized();sign=1 if side=='Right' else -1
 destination=frame(direction,sign*direction.cross(normal));rot=destination@source.transposed();m=h.matrix.copy();position=h.head.copy();m=rot.to_4x4()@m;m.translation=position;h.matrix=m;update()
 if data.get('index_splay_deg'):
  b=pb(side,'HandIndex1');m=b.matrix.copy();pos=b.head.copy();m=Quaternion(normal,math.radians(data['index_splay_deg'])).to_matrix().to_4x4()@m;m.translation=pos;b.matrix=m;update()
 # Curl axes derived from actual phalanx head-to-child directions, not FBX bone tails.
 for finger,angles in data['curl_deg'].items():
  for j,angle in enumerate(angles,1):
   b=pb(side,'Hand'+finger+str(j));child=pb(side,'Hand'+finger+str(j+1));v=(child.head-b.head).normalized();axis=v.cross(normal).normalized();m=b.matrix.copy();pos=b.head.copy();m=Quaternion(axis,math.radians(angle)).to_matrix().to_4x4()@m;m.translation=pos;b.matrix=m;update()
 return dict(palm_long=G(direction),palm_normal=G(normal),wrist_quaternion=list(h.matrix.to_quaternion()),curl_deg=data['curl_deg'],index_splay_deg=data.get('index_splay_deg',0))
configs=json.loads((D/'hand_poses.json').read_text(encoding='utf-8')); reports={}
# Import references with existing wrapper transforms, not modified weapon definitions.
weapons={}
for label,asset,loc,scale in [('Rifle','e',(.053,.03,-1.48),1.18),('SMG','g',(0,0,-.46),1.5),('Rocket','o',(0,0,-.866),3.15)]:
 before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(REPO/f'assets/weapons/kenney_blaster_kit/blaster-{asset}.glb'))
 objs=[o for o in set(bpy.data.objects)-before if o.type=='MESH'];weapons[label]=objs
 for o in objs:
  world=o.matrix_world.copy();o.parent=None;o.matrix_world=Matrix.Identity(4)
  for v in o.data.vertices:v.co=(world@v.co*scale+B(loc))*.44
  o.name='Reference_'+label+'_'+o.name;o.hide_render=True;o.hide_set(True)
for label,c in configs.items():
 rig.animation_data_clear()
 for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
 update();report={};origin=B(c['weapon_origin'])
 for side in ['Right','Left']:
  data=c[side];target=origin+B(data['wrist_from_weapon']);report[side]=arm(side,target);report[side].update(hand(side,data))
  report[side]['authored_bone_matrices']={b.name:[list(v) for v in b.matrix] for b in rig.pose.bones if b.name.startswith('Character1_'+side+'Hand')}
 action=bpy.data.actions.new('Pose_'+label);action.use_fake_user=True;rig.animation_data_create();rig.animation_data.action=action
 for b in rig.pose.bones:
  b.rotation_mode='QUATERNION';b.keyframe_insert(data_path='rotation_quaternion',frame=1,group=b.name);b.keyframe_insert(data_path='location',frame=1,group=b.name);b.keyframe_insert(data_path='scale',frame=1,group=b.name)
 report['action']=action.name;report['status']='CANDIDATE_REQUIRES_VISUAL_ACCEPTANCE';reports[label]=report
 # Evaluated static meshes are evidence exports only; skeleton/rest/skin remain in master.
 export=[];deps=bpy.context.evaluated_depsgraph_get()
 for obj in meshes:
  ev=obj.evaluated_get(deps);mesh=bpy.data.meshes.new_from_object(ev,depsgraph=deps);o=bpy.data.objects.new('Static_'+obj.name,mesh);bpy.context.collection.objects.link(o);o.matrix_world=obj.matrix_world.copy();export.append(o)
 for obj in weapons[label]:
  obj.hide_set(False);obj.hide_render=False;obj.location=origin;export.append(obj)
 bpy.ops.object.select_all(action='DESELECT')
 for o in export:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(D/('Pose_'+label+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
 for obj in export:
  if obj not in weapons[label]:bpy.data.objects.remove(obj,do_unlink=True)
 for obj in weapons[label]:obj.hide_set(True);obj.hide_render=True
# Leave neutral source visible; pose actions intentionally separate from gameplay clips.
rig.animation_data_clear()
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
update();rig['hand_pose_status']='Phase3A2 candidates; no Gate A acceptance'
for label in configs:rig['Pose_'+label]=json.dumps(configs[label])
bpy.context.preferences.filepaths.save_version=0
for image in bpy.data.images:
 if image.source=='FILE' and image.filepath:image.filepath=bpy.path.relpath(image.filepath,start=str(ROOT))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'battle_master.blend'))
(D/'authored_measurements.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('STATIC_HAND_AUTHORING_COMPLETE - NOT VISUAL ACCEPTANCE')
