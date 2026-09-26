"""Author an original unmanned hard-surface platform. Never opens character assets."""
from pathlib import Path
import bpy, json, hashlib, math
from mathutils import Vector

D = Path(__file__).resolve().parent
R = D.parents[1]
OUT = R / 'assets/enemies/kite_security'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1
bpy.context.preferences.filepaths.save_version = 0
parts = {}

def point(p):  # author in Godot coordinates; Blender Z-up, +Y is forward
    return (p[0], -p[2], p[1])

def material(name, color, rough=.72, metal=.12, emission=0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metal
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*color, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    m.diffuse_color = (*color, 1)
    return m

armor = material('Oxide ceramic armor', (.25, .074, .078))
edge = material('Warm titanium panels', (.40, .32, .25), .66, .24)
dark = material('Carbon mechanisms', (.024, .033, .040), .85, .12)
steel = material('Brushed mechanical steel', (.11, .15, .17), .59, .38)
ink = material('Ivory unit markings', (.79, .74, .61), .8, 0)
signal = material('Hostile optics', (.90, .09, .036), .5, 0, .65)

def finish(o, group, mat, bevel=0):
    o.data.materials.append(mat)
    bpy.context.view_layer.objects.active = o
    if bevel:
        modifier = o.modifiers.new('Small manufactured edge', 'BEVEL')
        modifier.width = bevel; modifier.segments = 2
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    parts.setdefault(group, []).append(o)
    return o

def box(group, label, size, pos, mat, bevel=.009):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(pos))
    o=bpy.context.object; o.name=label
    o.dimensions=(size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o,group,mat,bevel)

def hull(group,label,sections,mat,bevel=.012):
    # Each section is (z, y-low, y-high, width); tapered, chamfered octagonal hull.
    verts=[]
    for z,low,high,width in sections:
        w=width*.5; c=min(.07,width*.15,(high-low)*.28)
        for x,y in [(-w+c,low),(w-c,low),(w,low+c),(w,high-c),(w-c,high),(-w+c,high),(-w,high-c),(-w,low+c)]:
            verts.append(point((x,y,z)))
    faces=[tuple(range(7,-1,-1)),tuple(range((len(sections)-1)*8,len(sections)*8))]
    for s in range(len(sections)-1):
        for i in range(8): faces.append((s*8+i,s*8+(i+1)%8,(s+1)*8+(i+1)%8,(s+1)*8+i))
    mesh=bpy.data.meshes.new(label);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(label,mesh);bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    return finish(o,group,mat,bevel)

def cylinder(group,label,radius,depth,pos,mat,axis=(0,1,0),vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=point(pos))
    o=bpy.context.object;o.name=label
    o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector(point(axis)).to_track_quat('Z','Y')
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,group,mat,.005)

# A narrow suspended keel, swept shoulders and twin shrouded lift pods: not a humanoid.
hull('Chassis','Swept ceramic shell',[(-.42,.91,1.04,.34),(-.10,.68,1.13,.65),(.32,.74,1.04,.55)],armor)
hull('Chassis','Lower carbon keel',[(-.33,.76,.93,.28),(0,.58,.90,.47),(.28,.64,.87,.35)],dark)
hull('Chassis','Dorsal titanium spine',[(-.29,1.04,1.11,.17),(.1,1.07,1.20,.26),(.29,1.03,1.14,.20)],edge,.006)
for side in [-1,1]:
    box('Chassis','Shoulder recess',(.035,.13,.34),(side*.31,.90,.01),dark,.006)
    for z in [-.09,-.02,.05,.12]:
        box('Chassis','Recess rib',(.038,.018,.024),(side*.325,.91,z),steel,.002)
    cylinder('Chassis','Pod axle',.065,.18,(side*.32,.77,.04),steel,(1,0,0),12)

for side,group in [(-1,'PortPod'),(1,'StarboardPod')]:
    # Build centred parts then offset as a group, keeping the flight silhouette symmetric.
    before=set(bpy.context.scene.objects)
    hull(group,'Split shroud',[(-.43,.53,.69,.13),(-.24,.43,.79,.22),(.30,.45,.77,.21),(.39,.54,.70,.12)],armor,.01)
    box(group,'Inlet spine',(.16,.03,.53),(0,.786,-.01),dark,.009)
    for z in [-.23,-.13,-.03,.07,.17,.27]:
        box(group,'Inlet louver',(.147,.016,.023),(0,.806,z),steel,.002)
    box(group,'Outer recognition band',(.025,.12,.23),(side*.104,.64,-.13),ink,.004)
    for z in [-.20,.23]:
        cylinder(group,'Shrouded lift rotor',.081,.035,(0,.43,z),dark,(0,1,0),20)
        cylinder(group,'Lift hub',.034,.042,(0,.426,z),steel,(0,1,0),12)
    box(group,'Rear caution lamp',(.06,.043,.012),(0,.61,.396),signal,.002)
    for o in set(bpy.context.scene.objects)-before: o.location.x += side*.349

# Optical mast: asymmetric slit + independent small ranging aperture, not a human face.
cylinder('Sensor','Gimbal neck',.083,.14,(0,1.21,.14),steel)
hull('Sensor','Sensor hood',[(-.02,1.25,1.39,.28),(.16,1.22,1.42,.30),(.28,1.26,1.37,.20)],armor,.009)
box('Sensor','Dark optic recess',(.24,.065,.026),(0,1.30,-.027),dark,.008)
box('Sensor','Hostile optic slit',(.165,.027,.028),(-.025,1.31,-.044),signal,.004)
cylinder('Sensor','Rangefinder',.022,.029,(.10,1.31,-.044),ink,(0,0,1),12)
box('Sensor','Sensor upper armor',(.21,.026,.15),(0,1.41,.13),edge,.008)

# Rear service pack is a readable mechanical counterweight with one short antenna.
hull('RearPack','Power cassette',[(.24,.83,1.06,.37),(.43,.79,1.01,.39),(.47,.83,.96,.28)],dark,.009)
for x in [-.12,-.06,0,.06,.12]: box('RearPack','Radiator fin',(.025,.14,.11),(x,.95,.43),steel,.003)
box('RearPack','Pack armor cap',(.37,.026,.15),(0,1.073,.36),edge,.008)
cylinder('RearPack','Antenna base',.027,.07,(-.14,1.13,.34),dark)
cylinder('RearPack','Short command antenna',.009,.27,(-.14,1.29,.34),steel,vertices=8)

# Gun is authored around its real bore opening at local origin (-Z forward).
# The runtime object reads the old gameplay muzzle transform, never supplies one.
gun_pivot=(0,1.15,-.711)
def gp(x,y,z):return (x,y+gun_pivot[1],z+gun_pivot[2])
cylinder('Gun','Bore shadow',.046,.003,gp(0,0,.001),dark,(0,0,1),20)
for side in [-1,1]:
    box('Gun','Split muzzle brake',(.041,.13,.17),gp(side*.063,0,.082),steel,.006)
    box('Gun','Muzzle brake dorsal',(.094,.024,.15),gp(0,side*.056,.085),edge,.004)
cylinder('Gun','Recoil barrel',.046,.26,gp(0,0,.278),steel,(0,0,1),16)
cylinder('Gun','Mantlet collar',.078,.11,gp(0,0,.44),dark,(0,0,1),16)
box('Gun','Receiver',(.24,.20,.24),gp(0,0,.595),armor,.028)
box('Gun','Receiver rail',(.12,.028,.25),gp(0,.112,.565),edge,.007)
for z in [.49,.545,.60,.655]:box('Gun','Receiver vent',(.247,.018,.025),gp(0,.026,z),dark,.002)
cylinder('Gun','Yaw bearing',.135,.09,gp(0,-.137,.61),steel,(0,1,0),20)

# Unit ID, geometry from Blender's built-in font; no downloaded text/texture input.
bpy.ops.object.text_add(location=point((-.093,1.155,.13)))
t=bpy.context.object;t.name='KITE 07 identification';t.data.body='07';t.data.size=.13;t.data.resolution_u=2
t.data.materials.append(ink);bpy.ops.object.convert(target='MESH');parts['Chassis'].append(bpy.context.object)

objects=[]
for group,group_objects in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in group_objects:o.select_set(True)
    bpy.context.view_layer.objects.active=group_objects[0];bpy.ops.object.join()
    o=bpy.context.object;o.name=group
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.context.scene.cursor.location=point(gun_pivot) if group=='Gun' else (0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    objects.append(o)

collection=bpy.data.collections.new('APPROVED_KITE_07');bpy.context.scene.collection.children.link(collection)
for o in objects:
    for c in list(o.users_collection):c.objects.unlink(o)
    collection.objects.link(o)
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.wm.save_as_mainfile(filepath=str(D/'enemy_master.blend'))
runtime=OUT/'enemy_visual.glb'
bpy.ops.export_scene.gltf(filepath=str(runtime),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
triangles=0
for o in objects:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
report={'blender':bpy.app.version_string,'units':'meters','export_yup':True,'parts':[o.name for o in objects],
        'triangles':triangles,'materials':6,'textures':0,'bones':0,'animation_clips':0,'collisions':0,
        'gun_pivot_godot':gun_pivot,'runtime_sha256':hashlib.sha256(runtime.read_bytes()).hexdigest(),
        'master_sha256':hashlib.sha256((D/'enemy_master.blend').read_bytes()).hexdigest()}
(D/'export.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
