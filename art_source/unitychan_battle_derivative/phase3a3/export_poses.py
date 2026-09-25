import bpy,pathlib,json,hashlib
from mathutils import Matrix
D=pathlib.Path(__file__).resolve().parent;R=D.parent
bpy.ops.wm.open_mainfile(filepath=str(R/'battle_master.blend'));rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)));out={}
for label in ['Rifle','SMG','Rocket']:
 action=bpy.data.actions.get('Pose_'+label);assert action is not None
 rig.animation_data_create();rig.animation_data.action=action;bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
 config=json.loads(rig['Pose_'+label]);config['hands']={}
 for side in ['Right','Left']:
  name='Character1_'+side+'Hand';hand=C@rig.pose.bones[name].matrix@C.inverted();rel={}
  for b in rig.pose.bones:
   if b.name.startswith(name) and b.name!=name:rel[b.name]=[list(row) for row in hand.inverted()@C@b.matrix@C.inverted()]
  config['hands'][side]={'world_hand':[list(row) for row in hand],'relative_fingers':rel}
 out[label]=config
(D/'runtime_poses.json').write_text(json.dumps(out,indent=2),encoding='utf-8');(D/'master_export.json').write_text(json.dumps({'master_sha256':hashlib.sha256((R/'battle_master.blend').read_bytes()).hexdigest(),'actions':list(out),'bones':len(rig.data.bones),'blender':bpy.app.version_string},indent=2));print('MASTER_POSES_EXPORTED',list(out))
