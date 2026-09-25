import bpy,pathlib,json,hashlib
D=pathlib.Path(__file__).resolve().parent; R=D.parent

def snapshot(path):
 bpy.ops.wm.open_mainfile(filepath=str(path));rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');rest={b.name:[list(v) for v in b.matrix_local] for b in rig.data.bones};meshes={}
 for o in bpy.context.scene.objects:
  if o.type!='MESH' or o.name.startswith('Reference_'):continue
  data={'vertices':[list(v.co) for v in o.data.vertices],'polygons':[list(p.vertices) for p in o.data.polygons],'weights': [[(o.vertex_groups[g.group].name,g.weight) for g in v.groups] for v in o.data.vertices]}
  meshes[o.name]=hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()
 weights={b.name:sum(1 for o in bpy.context.scene.objects if o.type=='MESH' for v in o.data.vertices for g in v.groups if o.vertex_groups[g.group].name==b.name and g.weight>0) for b in rig.data.bones if 'Hand' in b.name}
 return {'rest':rest,'meshes':meshes,'finger_weighted_vertices':weights,'actions':[a.name for a in bpy.data.actions]}
a=snapshot(D/'master_before.blend');b=snapshot(R/'battle_master.blend');out={'bone_count':len(b['rest']),'rest_unchanged':a['rest']==b['rest'],'skin_geometry_unchanged':a['meshes']==b['meshes'],'character_meshes':len(b['meshes']),'actions':b['actions'],'finger_weighted_vertices':b['finger_weighted_vertices']};(D/'integrity.json').write_text(json.dumps(out,indent=2));print(out)
assert out['rest_unchanged'] and out['skin_geometry_unchanged']
