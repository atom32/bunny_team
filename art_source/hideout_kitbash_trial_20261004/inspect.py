import bpy,json
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=r'D:\bunny_team\art_source\hideout_kitbash_trial_20261004\source\Modular Concrete Interior\Modular Concrete Interior.blend')
data=[]
for o in bpy.data.objects:
 if o.type=='MESH':
  pts=[o.matrix_world@Vector(v) for v in o.bound_box]
  data.append({'name':o.name,'loc':list(o.location),'dims':list(o.dimensions),'min':[min(p[i] for p in pts) for i in range(3)],'max':[max(p[i] for p in pts) for i in range(3)],'materials':[m.name for m in o.data.materials]})
print(json.dumps(data))
print('MATERIALS',[(m.name,[(n.type,getattr(n.image,'filepath','')) for n in m.node_tree.nodes if n.type=='TEX_IMAGE']) for m in bpy.data.materials if m.use_nodes])
