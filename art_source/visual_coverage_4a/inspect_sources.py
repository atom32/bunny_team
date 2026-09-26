import bpy,json
from pathlib import Path
D=Path(__file__).resolve().parent;R=D.parents[1];rows=[]
for name in ['container-flat','container-tall','computer-system','wall-switch','pipe','pipe-bend']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(R/'assets/environment/kenney_space_station_kit'/(name+'.glb')))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 from mathutils import Vector
 points=[o.matrix_world@Vector(corner) for o in meshes for corner in o.bound_box]
 low=[min(v[i] for v in points) for i in range(3)];high=[max(v[i] for v in points) for i in range(3)]
 rows.append({'asset':name,'blender_z_up_bounds_min':low,'max':high,'dimensions':[high[i]-low[i] for i in range(3)],'mesh_objects':len(meshes),'polygons':sum(len(o.data.polygons) for o in meshes),'normals_finite':all(all(__import__('math').isfinite(a) for a in p.normal) for o in meshes for p in o.data.polygons),'uv_layers':[len(o.data.uv_layers) for o in meshes],'unwanted_objects':[o.name for o in bpy.context.scene.objects if o.type not in ['MESH','EMPTY']],'material_slots':[m.name for o in meshes for m in o.data.materials],'textures':[{'name':i.name,'size':list(i.size),'packed':i.packed_file is not None} for i in bpy.data.images if i.size[0]>0]})
(D/'blender_source_inspection.json').write_text(json.dumps({'blender':bpy.app.version_string,'convention':'glTF Y-up imported normally to Blender Z-up; no -90 rotation','rows':rows},indent=2))
print(json.dumps(rows))
