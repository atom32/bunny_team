"""Derive a self-contained game asset from the user's authored Bunny Suit model.

Run with Blender --background --factory-startup --disable-autoexec SOURCE --python FILE.
Only the selected clothed outfit is exported. No source .blend is written.
"""
import bpy, json, re, math
from pathlib import Path
from mathutils import Matrix, Vector

here = Path(__file__).resolve().parent
exec((here / 'configure.py').read_text())
dest = here.parents[1] / 'assets/characters/artoria_bunny'
dest.mkdir(parents=True,exist_ok=True)
texture_dir = here / 'textures'
materials = json.loads((here/'materials.json').read_text())
source_rig = bpy.data.objects['ArtoriaLancer_rig']
active = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.visible_get() and not o.hide_render]
# The clean game skeleton follows the source's reference joints. Its deformation
# weights are merged from the source's twist/control groups, never regenerated.
definitions = [
    ('Hips','root_ref.x',None), ('Spine','spine_01_ref.x','Hips'),
    ('Spine1','spine_02_ref.x','Spine'), ('Spine2','spine_03_ref.x','Spine1'),
    ('Neck','neck_ref.x','Spine2'), ('Head','head_ref.x','Neck'),
]
for side, suffix in [('Left','l'),('Right','r')]:
    for target, source, parent in [
        ('Shoulder','shoulder','Spine2'), ('Arm','arm',side+'Shoulder'),
        ('ForeArm','forearm',side+'Arm'), ('Hand','hand',side+'ForeArm'),
        ('UpLeg','thigh','Hips'), ('Leg','leg',side+'UpLeg'),
        ('Foot','foot',side+'Leg'), ('ToeBase','toes',side+'Foot'),
    ]:
        definitions.append((side+target,source+'_ref.'+suffix,parent))
    for finger in ['Thumb','Index','Middle','Ring','Pinky']:
        for joint in range(1,4):
            parent = side+'Hand' if joint == 1 else side+'Hand'+finger+str(joint-1)
            definitions.append((side+'Hand'+finger+str(joint),finger.lower()+str(joint)+'_ref.'+suffix,parent))
rest = {}
forward_correction = Matrix.Rotation(math.pi,4,'Z')
for target, source, parent in definitions:
    bone = source_rig.data.bones[source]
    rest[target] = (forward_correction @ source_rig.matrix_world @ bone.matrix_local,bone.length,parent)

def map_weight(name):
    n = name.lower()
    side = 'Left' if n.endswith('.l') else 'Right'
    if 'toes' in n: return side+'ToeBase'
    if 'foot' in n: return side+'Foot'
    if 'thigh' in n: return side+'UpLeg'
    if 'leg_' in n or n.startswith('leg.'): return side+'Leg'
    if 'forearm' in n: return side+'ForeArm'
    if 'shoulder' in n: return side+'Shoulder'
    if 'arm_' in n or n.startswith('arm.'): return side+'Arm'
    for finger in ['thumb','index','middle','ring','pinky']:
        match = re.search(finger+r'([123])',n)
        if match:
            return side+'Hand' if '_base' in n else side+'Hand'+finger.title()+match[1]
    if 'hand' in n: return side+'Hand'
    if 'neck' in n: return 'Neck'
    if 'spine_01' in n: return 'Spine'
    if 'spine_02' in n: return 'Spine1'
    if 'spine_03' in n or 'breast' in n: return 'Spine2'
    if any(word in n for word in ['root','butt','genital','vagina','anus','skirt','belly','pelvis']): return 'Hips'
    return 'Head'  # Remaining authored groups are face, ears and hair.

converted = []
weight_map = {}
for obj in active:
    # Bake the chosen fit shape keys in bind space; omit animation-time solvers.
    for modifier in obj.modifiers:
        modifier.show_viewport = False
    bpy.context.view_layer.update()
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=bpy.context.evaluated_depsgraph_get())
    copy = obj.copy()
    copy.data = mesh
    copy.name = obj.name.replace('ArtoriaLancer Bunny Suit - ','Bunny_').replace(' ','_')+'_Runtime'
    copy.animation_data_clear()
    copy.modifiers.clear()
    copy.parent = None
    bpy.context.scene.collection.objects.link(copy)
    copy.matrix_world = obj.matrix_world.copy()
    old_groups = {group.index:group.name for group in obj.vertex_groups}
    vertex_weights = []
    for v in mesh.vertices:
        summed = {}
        for entry in v.groups:
            old_name = old_groups[entry.group]
            # Fit-mask vertex groups do not contribute to deformation.
            if old_name not in source_rig.data.bones:
                continue
            target = map_weight(old_name)
            weight_map[old_name] = target
            summed[target] = summed.get(target,0) + entry.weight
        strongest = sorted(summed.items(),key=lambda item:item[1],reverse=True)[:4]
        total = sum(value for _,value in strongest)
        if total <= 0:
            raise ValueError('Unweighted authored vertex: '+obj.name+' '+str(v.index))
        vertex_weights.append([(name,value/total) for name,value in strongest])
    copy.vertex_groups.clear()
    groups = {name:copy.vertex_groups.new(name='Character1_'+name) for name,_,_ in definitions}
    for v,strongest in zip(mesh.vertices,vertex_weights):
        for name,value in strongest:
            groups[name].add([v.index],value,'REPLACE')
    mesh.transform(forward_correction @ copy.matrix_world)
    copy.matrix_world = Matrix.Identity(4)
    converted.append(copy)

# The game scene contains only the selected imported meshes and clean skeleton.
for obj in list(bpy.data.objects):
    if obj not in converted:
        bpy.data.objects.remove(obj,do_unlink=True)
armature = bpy.data.armatures.new('BunnyGameRig')
rig = bpy.data.objects.new('BunnyGameRig',armature)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,source,parent in definitions:
    matrix,length,_ = rest[name]
    bone = armature.edit_bones.new('Character1_'+name)
    bone.matrix = matrix
    bone.length = max(length,.015)
    if parent:
        bone.parent = armature.edit_bones['Character1_'+parent]
bpy.ops.object.mode_set(mode='OBJECT')

def image_node(tree, filename, color):
    node = tree.nodes.new('ShaderNodeTexImage')
    node.image = bpy.data.images.load(str(texture_dir/filename),check_existing=True)
    node.image.colorspace_settings.name = color
    return node

runtime_materials = {}
for name,info in materials.items():
    mat = bpy.data.materials.new(name+'_Game')
    mat.use_nodes = True
    tree = mat.node_tree
    bsdf = tree.nodes.get('Principled BSDF')
    if info.get('cornea'):
        bsdf.inputs['Base Color'].default_value = (.98,.99,1,1)
        bsdf.inputs['Alpha'].default_value = .08
        bsdf.inputs['Roughness'].default_value = .08
        mat.surface_render_method = 'BLENDED'
    else:
        maps, values = info['maps'], info['values']
        base = image_node(tree,maps['base'],'sRGB')
        tree.links.new(base.outputs['Color'],bsdf.inputs['Base Color'])
        for key,socket in [('roughness','Roughness'),('metallic','Metallic')]:
            if key in maps:
                node=image_node(tree,maps[key],'Non-Color')
                tree.links.new(node.outputs['Color'],bsdf.inputs[socket])
            else:
                bsdf.inputs[socket].default_value=values.get(key,0.5 if key=='roughness' else 0)
        if 'alpha' in maps:
            tree.links.new(base.outputs['Alpha'],bsdf.inputs['Alpha'])
            mat.surface_render_method = 'BLENDED' if name in ['Eyeshadow','ArtoriaBunny_Stockings'] else 'DITHERED'
        if 'normal' in maps:
            node=image_node(tree,maps['normal'],'Non-Color')
            normal=tree.nodes.new('ShaderNodeNormalMap')
            tree.links.new(node.outputs['Color'],normal.inputs['Color'])
            tree.links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
    runtime_materials[name]=mat

counts={}
for obj in converted:
    for slot in obj.material_slots:
        slot.material=runtime_materials[slot.material.name]
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    if obj.name.startswith('ArtoriaLancer_Hair'):
        decimate=obj.modifiers.new('RuntimeHairReduction','DECIMATE')
        decimate.ratio=.4
        decimate.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=decimate.name)
    obj.parent=rig
    modifier=obj.modifiers.new('GameSkin','ARMATURE')
    modifier.object=rig
    counts[obj.name]=sum(len(poly.vertices)-2 for poly in obj.data.polygons)
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(dest/'bunny_player.glb'),export_format='GLB',use_selection=True,
    export_animations=False,export_morph=False,export_skins=True,export_def_bones=True,
    export_yup=True,export_apply=False,export_texcoords=True,export_normals=True,export_tangents=True)
(here/'export_report.json').write_text(json.dumps({'meshes':counts,'triangles':sum(counts.values()),
    'bone_count':len(definitions),'weight_map':weight_map,'source_geometry':'authored meshes; fitted shape keys baked; hair decimated to 40%',
    'materials':'baked source node graphs, transparent cornea approximation'},indent=2))
print('BUNNY_EXPORT_COMPLETE',sum(counts.values()),len(definitions),flush=True)
