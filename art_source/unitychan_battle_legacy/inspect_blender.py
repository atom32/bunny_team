import bpy,json,pathlib
root=pathlib.Path(__file__).resolve().parent
source=root/'official_1_1/Assets/UnityChanTPK/Models/01_kohaku_A'
report={'blender':bpy.app.version_string,'textures':[],'scope':'Read-only texture decoding and source FBX inspection, NOT visual or animation acceptance'}
for p in sorted((source/'Textures').glob('*.png')):
 im=bpy.data.images.load(str(p),check_existing=False)
 report['textures'].append({'name':p.name,'width':im.size[0],'height':im.size[1],'channels':im.channels})
 assert im.size[0]>0 and im.size[1]>0
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(source/'01_kohaku_A.fbx'),use_image_search=False)
report['armatures']=[{'name':o.name,'bones':len(o.data.bones)} for o in bpy.context.scene.objects if o.type=='ARMATURE']
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:o.data.calc_loop_triangles()
report['mesh_count']=len(meshes);report['triangles']=sum(len(o.data.loop_triangles) for o in meshes)
report['material_count']=len({m.name for o in meshes for m in o.data.materials if m})
report['action_count']=len(bpy.data.actions)
report['original_files_not_saved_or_modified']=True
print('BATTLE_SOURCE_PROBE '+json.dumps(report))
(root/'blender_source_probe.json').write_text(json.dumps(report,indent=2),encoding='utf8')
