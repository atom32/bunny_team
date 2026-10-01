import bpy,json,sys
from pathlib import Path
from mathutils import Vector
root=Path('/Users/xudawei/bunny_team')
exec(compile((root/'art_source/artoria_bunny/configure.py').read_text(),str(root/'art_source/artoria_bunny/configure.py'),'exec'))
out=Path('/tmp/bunny-face-audit')
rig=bpy.data.objects['ArtoriaLancer_rig']; body=bpy.data.objects['ArtoriaLancer_Body']
info={'shape_keys':{k.name:k.value for k in body.data.shape_keys.key_blocks if k.value},'modifiers':[{'name':m.name,'type':m.type,'viewport':m.show_viewport,'render':m.show_render} for m in body.modifiers],'pose_bones':{},'materials':{},'head_bounds':{}}
for n in ['head.x','head_ref.x','jawbone.x','neck.x']:
 b=rig.pose.bones[n]
 info['pose_bones'][n]={'basis':[list(r) for r in b.matrix_basis],'matrix':[list(r) for r in b.matrix],'rest':[list(r) for r in b.bone.matrix_local]}
for name in ['ArtoriaLancer_Head','ArtoriaLancer_Body','ArtoriaLancer_Hair']:
 mat=bpy.data.materials[name]; info['materials'][name]={'drivers':[(d.data_path,d.driver.expression) for d in mat.node_tree.animation_data.drivers] if mat.node_tree.animation_data else []}
 for n in mat.node_tree.nodes:
  if n.type=='GROUP':info['materials'][name][n.name]={'group':n.node_tree.name,'inputs':{s.name:list(s.default_value) if hasattr(s.default_value,'__len__') and not isinstance(s.default_value,str) else s.default_value for s in n.inputs if hasattr(s,'default_value') and not s.is_linked}}
scene=bpy.context.scene
for name in ['source','export_bind']:
 if name=='export_bind':
  for m in body.modifiers:m.show_viewport=False
 bpy.context.view_layer.update(); ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get()); mesh=ev.to_mesh()
 verts=[body.matrix_world@v.co for v in mesh.vertices if (body.matrix_world@v.co).z>1.45]
 info['head_bounds'][name]={'count':len(verts),'min':[min(v[i] for v in verts) for i in range(3)],'max':[max(v[i] for v in verts) for i in range(3)]}
 ev.to_mesh_clear()
(out/'source_audit.json').write_text(json.dumps(info,indent=2))
# Use the source's render modifiers/materials, clothed and neutral.
for o in list(scene.objects):
 if o.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(o,do_unlink=True)
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('AuditWorld');scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.12,.15,.19,1);scene.world.node_tree.nodes.get('Background').inputs[1].default_value=.5
cam_data=bpy.data.cameras.new('AuditCamera');cam=bpy.data.objects.new('AuditCamera',cam_data);scene.collection.objects.link(cam);cam.location=(0,-4,1.63);cam.rotation_euler=(Vector((0,0,1.63))-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=.68;scene.camera=cam
for name,pos,energy,size in [('Key',(-2,-3,4),180,3),('Fill',(2,-2,2),90,3)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
scene.view_settings.view_transform='AgX';scene.render.filepath=str(out/'blender_source_face.png');bpy.ops.render.render(write_still=True)
print('FACE_AUDIT_DONE',flush=True)
