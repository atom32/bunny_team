"""Read-only import/compare. Never saves a Blend, FBX, GLB or texture."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector, kdtree
from collections import Counter, defaultdict
D=Path(__file__).resolve().parent;R=D.parents[2]
M=R/'art_source/unitychan_battle_legacy/official_1_1/Assets/UnityChanTPK/Models/01_kohaku_A'
names=['head_Def','headNose','eyeBall','eyeHighLightShape','hairFront','hairSide','hairBack','hairUnder']
def capture(o,conversion):
 m=o.data;m.calc_loop_triangles();w=conversion@o.matrix_world;n=w.to_3x3().inverted().transposed()
 points=[w@v.co for v in m.vertices]
 uv=m.uv_layers.active
 loops=[{'p':points[l.vertex_index],'n':(n@m.corner_normals[l.index].vector).normalized(),'uv':Vector(uv.data[l.index].uv) if uv else Vector((0,0)),'v':l.vertex_index} for l in m.loops]
 weights=[{o.vertex_groups[g.group].name:g.weight for g in v.groups if g.weight>1e-7} for v in m.vertices]
 tangents=False
 if uv:
  try:m.calc_tangents();tangents=True
  except Exception:pass
 return {'points':points,'loops':loops,'weights':weights,'triangles':[tuple(t.loops) for t in m.loop_triangles],
  'tangents':[(n@l.tangent).normalized() for l in m.loops] if tangents else [],
  'bits':[l.bitangent_sign for l in m.loops] if tangents else [],'matrix':[list(v) for v in w],
  'groups':[g.name for g in o.vertex_groups], 'shape_keys':list(m.shape_keys.key_blocks.keys()) if m.shape_keys else [],
  'morph_points':{k.name:[w@v.co for v in k.data] for k in m.shape_keys.key_blocks} if m.shape_keys else {}}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(M/'01_kohaku_A.fbx'),use_image_search=False)
bpy.ops.import_scene.fbx(filepath=str(M/'01_kohaku_A_head.fbx'),use_image_search=False)
bpy.context.view_layer.update()
# Documented derivative heading normalization only; Blender imports both formats into Z-up.
source={name:capture(bpy.data.objects[name],Matrix.Rotation(math.pi,4,'Z')) for name in names}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(R/'assets/characters/unitychan_battle/battle_presentation.glb'))
bpy.context.view_layer.update()
target={name:capture(bpy.data.objects[name],Matrix.Identity(4)) for name in names}
def key(loop):return tuple(round(x,5) for x in loop['p'])+tuple(round(x,5) for x in loop['uv'])
def tri_keys(data):
 out=[]
 for indices in data['triangles']:
  t=tuple(key(data['loops'][i]) for i in indices)
  out.append(min(t,t[1:]+t[:1],t[2:]+t[:2]))
 return Counter(out)
rows={}
for name in names:
 a,b=source[name],target[name];tree=kdtree.KDTree(len(a['points']))
 for i,p in enumerate(a['points']):tree.insert(p,i)
 tree.balance()
 distances=[tree.find(p)[2] for p in b['points']]
 groups=defaultdict(list)
 for i,l in enumerate(a['loops']):groups[key(l)].append(i)
 normal_errors=[];tangent_errors=[];uv_errors=[];weight_errors=[];missing=0;sign_errors=0;matched=[];morph_errors=defaultdict(float)
 for j,l in enumerate(b['loops']):
  candidates=groups.get(key(l),[])
  if not candidates:
   # Round-boundary differences are diagnosed via physical position + UV tolerance.
   candidates=[i for i,x in enumerate(a['loops']) if (x['p']-l['p']).length<2e-6 and (x['uv']-l['uv']).length<2e-6]
  if not candidates:missing+=1;matched.append(None);continue
  i=min(candidates,key=lambda i:(a['loops'][i]['n']-l['n']).length)
  matched.append(key(a['loops'][i]))
  for shape in set(a['morph_points']) & set(b['morph_points']):
   morph_errors[shape]=max(morph_errors[shape],(a['morph_points'][shape][a['loops'][i]['v']]-b['morph_points'][shape][l['v']]).length)
  if a['tangents'] and b['tangents']:
   tangent_errors.append(math.degrees(a['tangents'][i].angle(b['tangents'][j],0)))
   sign_errors+=a['bits'][i]!=b['bits'][j]
  normal_errors.append(math.degrees(a['loops'][i]['n'].angle(l['n'],0)))
  uv_errors.append((a['loops'][i]['uv']-l['uv']).length)
  wa=a['weights'][a['loops'][i]['v']];wb=b['weights'][l['v']]
  # Official head/nose are rigid prefab attachments; derivative encodes the equivalent single-head-bone weight.
  if name in ['head_Def','headNose'] and not wa:wa={'Character1_Head':1.0}
  weight_errors.append(max([abs(wa.get(k,0)-wb.get(k,0)) for k in set(wa)|set(wb)] or [0]))
 # Index numbers themselves may change with UV/normal vertex splits; compare oriented position+UV triangles.
 mapped_triangles=[]
 for indices in b['triangles']:
  t=tuple(matched[i] for i in indices)
  if None not in t:mapped_triangles.append(min(t,t[1:]+t[:1],t[2:]+t[:2]))
 rows[name]={'source_vertices':len(a['points']),'glb_vertices':len(b['points']),'source_indices':len(a['triangles'])*3,'glb_indices':len(b['triangles'])*3,
  'position_max_m':max(distances),'uv_max':max(uv_errors,default=None),'normal_max_degrees':max(normal_errors,default=None),
  'weight_max_delta_by_bone_name':max(weight_errors,default=None),'unmatched_corners':missing,'oriented_triangle_multiset_equal_rounded_1e5':tri_keys(a)==tri_keys(b),
  'oriented_triangles_equal_after_tolerance_match':tri_keys(a)==Counter(mapped_triangles),'derived_tangent_max_degrees':max(tangent_errors,default=None),'derived_bitangent_sign_differences':sign_errors,
  'source_bone_groups':a['groups'],'glb_bone_groups':b['groups'],'source_matrix':a['matrix'],'glb_matrix':b['matrix'],
  'source_shape_keys':a['shape_keys'],'glb_shape_keys':b['shape_keys'],
  'morph_position_max_m_by_shape':dict(morph_errors),
  'source_active_bones':sorted({n for weights in a['weights'] for n in weights}),
  'glb_active_bones':sorted({n for weights in b['weights'] for n in weights}),
  'tangent_note':'Production GLB accessor availability checked separately. Blender can derive Mikk tangents from unchanged normals/UVs; no normal maps enabled in official materials.'}
(D/'geometry_comparison.json').write_text(json.dumps({'method':'Blender5.2.2 read-only FBX/GLB import; documented 180 degree heading; position/UV triangle-corner comparison; bone-name rather than numerical palette index comparison','meshes':rows},indent=2),encoding='utf-8')
print(json.dumps({k:{a:b for a,b in v.items() if not a.endswith(('groups','matrix','keys','note'))} for k,v in rows.items()},indent=2))
