"""Locally authored environment prop, NOT a character operation. Blender background."""
from pathlib import Path
import bpy, json, hashlib
from mathutils import Vector

D = Path(__file__).resolve().parent
R = D.parents[1]
OUT = R/'assets/environment/urban_defense'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
bpy.context.preferences.filepaths.save_version = 0

def mat(name, color, rough=.75, metal=.0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough
    p.inputs['Metallic'].default_value=metal
    m.diffuse_color=(*color,1)
    return m

armor=mat('Painted blue graphite',(.045,.075,.086))
panel=mat('Inset warm grey',(.12,.145,.14))
rubber=mat('Rubber bumper',(.028,.038,.041),.95)
warning=mat('Safety ochre',(.60,.38,.075))
ink=mat('Ivory stencil',(.66,.72,.68))

def box(name, size, pos, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(material)
    if bevel:
        m=o.modifiers.new('Manufactured edge','BEVEL');m.width=bevel;m.segments=1
        bpy.ops.object.modifier_apply(modifier=m.name)
    return o

box('Rubber base',(2.798,.578,.10),(0,0,.05),rubber,.022)
box('Armored body',(2.73,.51,.77),(0,0,.465),armor,.035)
box('Top rail',(2.76,.52,.05),(0,0,.872),panel,.018)
for x in [-1.19,1.19]:
    box('Corner guard',(.20,.556,.79),(x,0,.477),rubber,.016)
    box('Ochre top identification',(.14,.53,.02),(x,0,.887),warning,.005)
for side in [-1,1]:
    y=side*.261
    for x in [-.58,.58]:
        box('Recess panel',(.91,.020,.45),(x,y,.49),panel,.018)
        box('Panel lower seam',(.87,.021,.028),(x,y+side*.012,.28),rubber)
        for dx in [-.35,.35]:
            box('Fastener',(.036,.025,.036),(x+dx,y+side*.016,.64),ink,.008)
    box('Hazard insert',(.16,.026,.36),(0,y+side*.014,.49),warning,.01)
    for z in [.38,.47,.56]:
        o=box('Hazard diagonal',(.14,.001,.025),(0,y+side*.028,z),rubber)
        o.rotation_euler[1]=.45
    # Stencil is converted to geometry, not a runtime font/texture dependency.
    bpy.ops.object.text_add(location=(.38,y+side*.025,.40))
    t=bpy.context.object;t.name='SEC stencil';t.data.body='SEC';t.data.size=.155
    t.data.extrude=0;t.data.resolution_u=1
    t.rotation_euler=(1.57079632679 if side==-1 else -1.57079632679,0,0)
    if side==1:t.rotation_euler[2]=3.14159265359;t.location.x=.79
    t.data.materials.append(ink);bpy.ops.object.convert(target='MESH')

# Single mesh / five surfaces. No cameras, lights, collisions, rigs or animations.
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.ops.object.join()
o=bpy.context.object;o.name='SecurityBarrier'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.context.scene.cursor.location=(0,0,0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.ops.wm.save_as_mainfile(filepath=str(D/'security_barrier.blend'))
path=OUT/'security_barrier.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=False,export_cameras=False,export_lights=False,
    export_normals=True,export_tangents=False)
o.data.calc_loop_triangles()
points=[o.matrix_world@Vector(v) for v in o.bound_box]
report={'blender':bpy.app.version_string,'unit_scale':1,'export_yup':True,
    'triangles':len(o.data.loop_triangles),'material_count':len(set(o.data.materials)),
    'texture_count':0,'mesh_count':1,'collision':False,
    'blender_dimensions':list(o.dimensions),'root_identity':o.matrix_world==__import__('mathutils').Matrix.Identity(4),
    'runtime_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
    'master_sha256':hashlib.sha256((D/'security_barrier.blend').read_bytes()).hexdigest()}
(D/'barrier_export.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
