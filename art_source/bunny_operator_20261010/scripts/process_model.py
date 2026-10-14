"""Blender batch inspection/normalization for this one character.
--background --factory-startup --disable-autoexec --python FILE --
--input RAW.glb --output OUT.glb --height 2.05 --yaw-degrees VISUALLY_VERIFIED
Preserves mesh/material/UV/rig/animation structure. Never alters the input.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh
from mathutils import Vector

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--input',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--height',type=float,default=2.05)
parser.add_argument('--yaw-degrees',type=float,required=True)
parser.add_argument('--inspect-only',action='store_true')
parser.add_argument('--exclude-mesh',action='append',default=[],help='Explicitly reviewed auxiliary mesh only; default excludes nothing')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
source=args.input.resolve();output=args.output.resolve()
if source==output: raise RuntimeError('Input/output must differ.')
if not source.is_file(): raise RuntimeError('A real generated input is required.')
if not .5<=args.height<=3: raise RuntimeError('Unexpected character height.')
source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
previous_report=output.with_suffix('.inspection.json')
if output.exists():
    if not previous_report.exists() or json.loads(previous_report.read_text()).get('input_sha256')!=source_hash:
        raise RuntimeError('Refusing to overwrite an unrelated preserved output. Choose a new version path.')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
excluded=[]
for name in args.exclude_mesh:
    obj=bpy.data.objects.get(name)
    if not obj or obj.type!='MESH': raise RuntimeError('Explicit exclusion did not match a mesh: '+name)
    excluded.append({'name':obj.name,'vertices':len(obj.data.vertices),'polygons':len(obj.data.polygons)})
    bpy.data.objects.remove(obj,do_unlink=True)
objects=list(bpy.context.scene.objects)
meshes=[o for o in objects if o.type=='MESH']
rigs=[o for o in objects if o.type=='ARMATURE']
if not meshes: raise RuntimeError('No mesh in input.')
report={'input':str(source),'input_sha256':source_hash,'blender_version':bpy.app.version_string,
        'yaw_degrees':args.yaw_degrees,'height_target_m':args.height,'objects':[],
        'materials':[],'rigs':[],'explicitly_excluded':excluded,'warnings':[],'fatal_errors':[],'semantic_review_required':
        ['face/fingers','ears and ponytail separation','ruffles/holster/belt','joint deformation'],
        'operations':['root transform only; no decimation, mesh joining, welding or UV rewriting']}
for obj in meshes:
    mesh=obj.data
    mesh.calc_loop_triangles()
    bm=bmesh.new();bm.from_mesh(mesh)
    isolated=sum(not v.link_edges for v in bm.verts)
    boundary=sum(e.is_boundary for e in bm.edges)
    nonmanifold=sum(not e.is_manifold and not e.is_boundary for e in bm.edges)
    degenerate=sum(face.calc_area()<1e-12 for face in bm.faces)
    visited=set();components=[]
    for v in bm.verts:
        if v in visited:continue
        stack=[v];visited.add(v);count=0
        while stack:
            current=stack.pop();count+=1
            for edge in current.link_edges:
                other=edge.other_vert(current)
                if other not in visited:visited.add(other);stack.append(other)
        components.append(count)
    bm.free()
    invalid=sum(not all(math.isfinite(c) for c in v.co) for v in mesh.vertices)
    missing_slots=not obj.material_slots or any(s.material is None for s in obj.material_slots)
    weighted=sum(any(group.weight>1e-6 for group in vertex.groups) for vertex in mesh.vertices)
    item={'name':obj.name,'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),
          'uv_layers':len(mesh.uv_layers),'material_slots':len(obj.material_slots),
          'isolated_vertices':isolated,'boundary_edges':boundary,'nonmanifold_interior_edges':nonmanifold,
          'degenerate_faces':degenerate,'invalid_vertices':invalid,'connected_components':len(components),
          'largest_components':sorted(components,reverse=True)[:12],
          'weighted_vertices':weighted,'armature_modifiers':sum(m.type=='ARMATURE' for m in obj.modifiers)}
    report['objects'].append(item)
    if invalid or missing_slots or not mesh.vertices or not mesh.polygons:
        report['fatal_errors'].append('Incomplete/invalid mesh or material: '+obj.name)
    if not mesh.uv_layers:report['warnings'].append('No UV layer: '+obj.name)
    if boundary or nonmanifold or degenerate:
        report['warnings'].append('Topology requires visual review: '+obj.name)
    if rigs and item['armature_modifiers'] and weighted<len(mesh.vertices):
        report['warnings'].append('Unweighted skinned vertices: '+obj.name)
for mat in set(s.material for o in meshes for s in o.material_slots if s.material):
    images=[]
    if mat.use_nodes:
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':
                image=node.image
                ok=bool(image and image.size[0]>0 and image.size[1]>0)
                images.append({'name':image.name if image else None,'size':list(image.size) if image else [],'valid':ok})
                if not ok:report['fatal_errors'].append('Missing texture in '+mat.name)
                elif not args.inspect_only:image.pack()
    report['materials'].append({'name':mat.name,'images':images})
for rig in rigs:
    report['rigs'].append({'name':rig.name,'bones':[b.name for b in rig.data.bones],
                           'animation_data':bool(rig.animation_data)})
world_corners=[obj.matrix_world@Vector(corner) for obj in meshes for corner in obj.bound_box]
minimum=Vector([min(p[i] for p in world_corners) for i in range(3)])
maximum=Vector([max(p[i] for p in world_corners) for i in range(3)])
report['input_bounds_blender']={'min':list(minimum),'max':list(maximum)}
report['animation_actions']=[a.name for a in bpy.data.actions]
if maximum.z-minimum.z<=1e-5: report['fatal_errors'].append('Input has no vertical extent.')
output.parent.mkdir(parents=True,exist_ok=True)
if not args.inspect_only and not report['fatal_errors']:
    # One shared parent transforms meshes, rigs, bind poses and animations together.
    # Keep all imported local transforms intact, including authored skin matrices.
    roots=[obj for obj in objects if obj.parent is None]
    correction=bpy.data.objects.new('Normalization',None)
    bpy.context.scene.collection.objects.link(correction)
    for obj in roots:obj.parent=correction
    correction.rotation_euler.z=math.radians(args.yaw_degrees)
    bpy.context.view_layer.update()
    corners=[obj.matrix_world@Vector(corner) for obj in meshes for corner in obj.bound_box]
    low=Vector([min(p[i] for p in corners) for i in range(3)])
    high=Vector([max(p[i] for p in corners) for i in range(3)])
    scale=args.height/(high.z-low.z)
    correction.scale=Vector((scale,scale,scale))
    correction.location=Vector((-(low.x+high.x)*.5*scale,-(low.y+high.y)*.5*scale,-low.z*scale))
    root=bpy.data.objects.new('BunnyOperator',None)
    bpy.context.scene.collection.objects.link(root);correction.parent=root
    bpy.context.view_layer.update()
    final_corners=[obj.matrix_world@Vector(corner) for obj in meshes for corner in obj.bound_box]
    report['output_bounds_blender']={'min':[min(p[i] for p in final_corners) for i in range(3)],
                                      'max':[max(p[i] for p in final_corners) for i in range(3)]}
    report['root_scale']=scale
    blend_path=output.with_suffix('.blend')
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene.unit_settings.scale_length=1
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',export_yup=True,
                             export_animations=True,export_skins=True,export_extras=True)
    report['output_sha256']=hashlib.sha256(output.read_bytes()).hexdigest()
    report['output']=str(output);report['blend_source']=str(blend_path)
    report['output_bytes']=output.stat().st_size
if hashlib.sha256(source.read_bytes()).hexdigest()!=source_hash:
    report['fatal_errors'].append('Source changed unexpectedly.')
report['engineering_export_pass']=not report['fatal_errors']
report['visual_approved']=False  # A geometry export is never the visual acceptance.
report['production_replacement_allowed']=False
output.with_suffix('.inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print('BUNNY_MODEL_INSPECTION',json.dumps({'meshes':len(meshes),'rigs':len(rigs),'fatal_errors':report['fatal_errors'],'warnings':len(report['warnings']),'exported':output.exists() and not args.inspect_only}))
if report['fatal_errors']:raise RuntimeError('Model failed inspection; no accepted export.')
