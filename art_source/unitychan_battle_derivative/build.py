"""Blender 5.2.2: isolated, reproducible Battle Costume presentation derivative.
Run blender --background --factory-startup --python <this file>.
Does not change official files or install the output as the live player.
"""
import bpy
import hashlib
import json
import math
from pathlib import Path
import re
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'unitychan_battle_legacy'
PACK = SOURCE / 'official_1_1'
MODEL = PACK / 'Assets/UnityChanTPK/Models/01_kohaku_A'
manifest = json.loads((SOURCE / 'recovery_manifest.json').read_text())
for row in manifest['files']:
    assert hashlib.sha256((PACK / row['path']).read_bytes()).hexdigest() == row['sha256']
    assert hashlib.sha256((PACK / (row['path'] + '.meta')).read_bytes()).hexdigest() == row['meta_sha256']

chunks = re.split(r'--- !u!(\d+) &(\d+)\n', (MODEL / 'Prefabs/01_kohaku_A.prefab').read_text())
objects = {chunks[i+1]: (chunks[i], chunks[i+2]) for i in range(1, len(chunks), 3)}
def ref(text, key):
    return re.search(key + r': \{fileID: (\d+)', text)[1]
def object_name(go):
    return re.search(r'm_Name: (.*)', objects[go][1])[1]
def components(text, key):
    return {k:float(v) for k,v in re.findall(r'(\w): ([\d.e+\-]+)', re.search(key+r': \{([^}]+)',text)[1])}
transforms = {ref(text,'m_GameObject'): id for id,(kind,text) in objects.items() if kind == '4'}
def unity_world(id):
    if id == '0': return Matrix.Identity(4)
    text = objects[id][1]
    p,q,s = [components(text,k) for k in ['m_LocalPosition','m_LocalRotation','m_LocalScale']]
    local = Matrix.LocRotScale(Vector(tuple(p[k] for k in 'xyz')), Quaternion(tuple(q[k] for k in 'wxyz')), Vector(tuple(s[k] for k in 'xyz')))
    return unity_world(ref(text,'m_Father')) @ local

guid_paths = {}
mesh_names = {}
for p in MODEL.rglob('*.meta'):
    text=p.read_text(); guid=re.search(r'^guid: (\w+)',text,re.M)[1]
    guid_paths[guid] = p.with_suffix('').relative_to(PACK).as_posix()
    if p.name.endswith('.fbx.meta'):
        mesh_names[guid] = dict(re.findall(r'^    (43\d+): (.*)$',text,re.M))
mapping=[]
for id,(kind,text) in objects.items():
    if kind not in ['137','23']: continue
    go=ref(text,'m_GameObject')
    mesh_text=text
    if kind=='23':
        mesh_text=next(t for k,t in objects.values() if k=='33' and ref(t,'m_GameObject')==go)
    mesh = re.search(r'm_Mesh: \{fileID: (\d+), guid: (\w+)',mesh_text)
    mats=re.findall(r'guid: (\w+)',text.split('m_Materials:')[1].split('  m_',1)[0])
    mapping.append({'object':object_name(go),'mesh':mesh_names[mesh[2]][mesh[1]],
                    'fbx':guid_paths[mesh[2]],'materials':[guid_paths[g] for g in mats],
                    'transform_id':transforms[go],'enabled':bool(re.search(r'm_Enabled: 1',text))})

bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene.unit_settings.scale_length=1.0
bpy.ops.import_scene.fbx(filepath=str(MODEL/'01_kohaku_A.fbx'),use_image_search=False)
rig=bpy.data.objects['Character1_Reference']
bpy.ops.import_scene.fbx(filepath=str(MODEL/'01_kohaku_A_head.fbx'),use_image_search=False)
materials={}
material_report=[]
for item in manifest['materials']:
    name=Path(item['path']).stem
    text=(PACK/item['path']).read_text()
    color=components(text,'_BaseColor')
    mat=bpy.data.materials.new('Battle_'+name);mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    # UTS colors are authored in sRGB; Principled's color socket stores linear.
    def linear(v): return v/12.92 if v<=0.04045 else ((v+0.055)/1.055)**2.4
    bsdf.inputs['Base Color'].default_value=tuple(linear(color[k]) for k in 'rgb')+(color['a'],)
    bsdf.inputs['Roughness'].default_value=0.8
    bsdf.inputs['Metallic'].default_value=0.0
    base=next((s['path'] for s in item['textures'] if s['slot']=='_BaseMap'),None)
    if base:
        image=bpy.data.images.load(str(PACK/base),check_existing=True)
        image.colorspace_settings.name='sRGB'
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
        mat.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color'])
    materials[item['path']]=mat
    material_report.append({'material':name,'base_texture':base,'base_color_srgb':color,
        'roughness':0.8,'metallic':0,'emission':'none (no active emission source)',
        'shade_grade_specular':'preserved as source evidence, not mapped to PBR channels'})

kept=[]
for row in mapping:
    obj=bpy.data.objects[row['mesh']]
    if row['mesh']=='kwep_exebreaker':
        row['derivative']='excluded bundled melee weapon; use existing game weapon contract'
        continue
    row['derivative']='included'
    obj.data.materials.clear()
    for m in row['materials']: obj.data.materials.append(materials[m])
    for poly in obj.data.polygons: poly.material_index=0
    if row['mesh'] in ['head_Def','headNose']:
        # Official head is a rigid mesh parented beneath Character1_Head, not a
        # separately skinned rig. Preserve its prefab rest transform, encode the
        # same rigid relationship as one-bone weights for a portable single skin.
        # Unity left-handed Y-up -> Blender right-handed Z-up (no extra -90 hack).
        C=Matrix(((-1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
        prefab_world=C @ unity_world(row['transform_id']) @ C.inverted()
        obj.matrix_world=prefab_world @ obj.matrix_world
        matrix=obj.matrix_world.copy();obj.parent=rig;obj.parent_type='OBJECT'
        obj.parent_bone='';obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_world=matrix
        vg=obj.vertex_groups.new(name='Character1_Head');vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        modifier=obj.modifiers.new('OfficialRigidHead','ARMATURE');modifier.object=rig
        row['head_prefab_world_blender']=[list(v) for v in prefab_world]
    kept.append(obj)

for obj in list(bpy.data.objects):
    if obj not in kept and obj != rig: bpy.data.objects.remove(obj,do_unlink=True)
# Do not reset bones, rebind existing skin or import animations into this asset.
bpy.ops.object.select_all(action='DESELECT')
for obj in kept+[rig]: obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.context.view_layer.update()
# Observed in the production-camera spike: the official character faces +Z in
# glTF/Godot, while the existing presentation contract is -Z. Normalize heading
# on the derivative root before baking, not on gameplay or animation tracks.
rig.matrix_world=Matrix.Rotation(math.pi,4,'Z')@rig.matrix_world
bpy.context.view_layer.update()
before_bones={b.name:rig.matrix_world@b.matrix_local for b in rig.data.bones}
before_vertices={o.name:[o.matrix_world@v.co for v in o.data.vertices] for o in kept}
# FBX's object-level centimeter conversion must not be lost when Godot reparents
# Skeleton3D into CharacterRetarget. Bake object rotation/scale, not a rest reset.
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
bpy.context.view_layer.update()
bone_error=max(((rig.matrix_world@b.matrix_local).translation-before_bones[b.name].translation).length for b in rig.data.bones)
bone_rotation_error=max((rig.matrix_world@b.matrix_local).to_quaternion().rotation_difference(before_bones[b.name].to_quaternion()).angle for b in rig.data.bones)
vertex_error=max(((o.matrix_world@v.co)-before_vertices[o.name][i]).length for o in kept for i,v in enumerate(o.data.vertices))
assert bone_error<0.0001 and vertex_error<0.0001,(bone_error,vertex_error)
for obj in kept: obj.data.calc_loop_triangles()
points=[obj.matrix_world@Vector(v) for obj in kept for v in obj.bound_box]
report={'blender':bpy.app.version_string,'mapping':mapping,'materials':material_report,
        'normalization_world_bone_position_max_error_m':bone_error,
        'normalization_world_bone_rotation_max_error_rad':bone_rotation_error,
        'normalization_world_vertex_max_error_m':vertex_error,
        'triangles':sum(len(o.data.loop_triangles) for o in kept),'meshes':len(kept),
        'bones':len(rig.data.bones),'animations':len(bpy.data.actions),
        'bounds_min':[min(v[i] for v in points) for i in range(3)],
        'bounds_max':[max(v[i] for v in points) for i in range(3)],
        'export':{'format':'GLB','yup':True,'selected':True,'animations':False},
        'heading_normalization_degrees':180,
        'limitations':['Principled approximation, not UTS parity','deformation acceptance pending']}
bpy.context.preferences.filepaths.save_version=0
for image in bpy.data.images:
    if image.source=='FILE' and image.filepath:
        image.filepath=bpy.path.relpath(bpy.path.abspath(image.filepath),start=str(ROOT))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'battle_master.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'battle_presentation.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
report['glb_sha256']=hashlib.sha256((ROOT/'battle_presentation.glb').read_bytes()).hexdigest()
(ROOT/'build_report.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('BATTLE_BUILD',report['triangles'],report['meshes'],report['bones'],report['bounds_min'],report['bounds_max'])
