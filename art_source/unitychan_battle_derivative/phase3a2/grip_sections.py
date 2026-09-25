import bpy,pathlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
p=pathlib.Path('D:/bunny_team/art_source/unitychan_battle_derivative');bpy.ops.wm.open_mainfile(filepath=str(p/'battle_master.blend'))
objs=[o for o in bpy.data.objects if o.name.startswith('Reference_Rocket') and o.type=='MESH'];verts=[];faces=[]
for o in objs:
 o.data.calc_loop_triangles();offset=len(verts);verts += [v.co.copy() for v in o.data.vertices];faces += [tuple(offset+i for i in t.vertices) for t in o.data.loop_triangles]
b=BVHTree.FromPolygons(verts,faces,all_triangles=True)
for y in [-.08,-.10,-.12,-.15]:
 for z in [-.10,-.15,-.25,-.30,-.35]:
  hit=b.ray_cast(Vector((1,-z,y)),Vector((-1,0,0)))
  if hit[0]:print(y,z,round(hit[0].x,4))
