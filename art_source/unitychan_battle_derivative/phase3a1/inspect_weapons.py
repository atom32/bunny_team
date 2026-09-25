import bpy,json,re,pathlib,math
from mathutils import Vector
from mathutils.geometry import closest_point_on_tri
root=pathlib.Path('D:/bunny_team');out=root/'art_source/unitychan_battle_derivative/phase3a1';rows=[]
for name,file,loc,scale in [('Rifle','blaster-e.glb',(0.053,0.03,-1.48),1.18),('SMG','blaster-g.glb',(0,0,-0.46),1.5),('Rocket','blaster-o.glb',(0,0,-0.866),3.15)]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/'assets/weapons/kenney_blaster_kit'/file))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];triangles=[]
 # Blender -> Godot coordinates, then existing wrapper model transform and .44 mount scale.
 for o in meshes:
  o.data.calc_loop_triangles()
  def transform(v):
   p=o.matrix_world@v;return (Vector((p.x,p.z,-p.y))*scale+Vector(loc))*.44
  verts=[transform(v.co) for v in o.data.vertices]
  triangles += [tuple(verts[i] for i in t.vertices) for t in o.data.loop_triangles]
 tscn=root/'scenes/weapons'/({'Rifle':'assault_rifle','SMG':'smg','Rocket':'rocket_launcher'}[name]+'.tscn')
 s=tscn.read_text();markers={}
 for marker in ['PrimaryGrip','SupportGrip','ReloadGrip','Muzzle']:
  raw=re.search(r'\[node name="'+marker+r'"[^\]]*\]\s*position = Vector3\(([^)]+)',s)[1]
  p=Vector(tuple(float(v) for v in raw.split(',')))*.44
  closest=min((closest_point_on_tri(p,*t) for t in triangles),key=lambda c:(p-c).length)
  markers[marker]={'point_m':list(p),'nearest_surface_m':list(closest),'surface_distance_m':(p-closest).length}
 points=[v for t in triangles for v in t]
 rows.append({'weapon':name,'source':file,'unchanged_mount_scale':.44,'markers':markers,'bounds_min':[min(p[i] for p in points) for i in range(3)],'bounds_max':[max(p[i] for p in points) for i in range(3)]})
(out/'weapon_geometry.json').write_text(json.dumps(rows,indent=2),encoding='utf8');print(json.dumps(rows))
