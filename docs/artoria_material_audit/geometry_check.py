import bpy,json,struct,numpy as np
from pathlib import Path
from mathutils import Vector,kdtree
root=Path('/Users/xudawei/bunny_team');out=Path('/tmp/bunny-face-audit')
exec(compile((root/'art_source/artoria_bunny/configure.py').read_text(),str(root/'art_source/artoria_bunny/configure.py'),'exec'))
body=bpy.data.objects['ArtoriaLancer_Body']
for m in body.modifiers:m.show_viewport=False
bpy.context.view_layer.update();ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
mi=next(i for i,s in enumerate(body.material_slots) if s.material.name=='ArtoriaLancer_Head')
ids={v for p in mesh.polygons if p.material_index==mi for v in p.vertices}
tree=kdtree.KDTree(len(ids))
for i,idx in enumerate(ids):
 v=body.matrix_world@mesh.vertices[idx].co;tree.insert(Vector((-v.x,v.z,v.y)),i)
tree.balance()
f=open(root/'assets/characters/artoria_bunny/bunny_player.glb','rb');f.read(12);n,t=struct.unpack('<II',f.read(8));d=json.loads(f.read(n));n,t=struct.unpack('<II',f.read(8));buf=f.read(n)
for m in d['meshes']:
 for p in m['primitives']:
  if d['materials'][p['material']]['name']=='ArtoriaLancer_Head_Game':
   a=d['accessors'][p['attributes']['POSITION']];v=d['bufferViews'][a['bufferView']];offset=v.get('byteOffset',0)+a.get('byteOffset',0);verts=np.ndarray((a['count'],3),dtype='<f4',buffer=buf,offset=offset,strides=(v.get('byteStride',12),4))
   errors=[tree.find(Vector(tuple(x)))[2] for x in verts]
   result={'source_head_vertices':len(ids),'exported_head_vertices_including_uv_splits':len(verts),'max_bind_position_error_m':max(errors),'mean_bind_position_error_m':float(np.mean(errors)),'scope':'Bind-space positions, matched by nearest source head vertex after coordinate conversion; not animation deformation validation.'}
mat=bpy.data.materials['ArtoriaLancer_Head'];node=mat.node_tree.nodes['Value']
result['source_blush_value']=node.outputs[0].default_value
result['source_blush_connections']=[{'node':l.to_node.name,'input':l.to_socket.identifier,'other_images':[l2.from_node.image.name for s in l.to_node.inputs for l2 in s.links if l2.from_node.type=='TEX_IMAGE']} for l in node.outputs[0].links]
(out/'geometry_check.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
