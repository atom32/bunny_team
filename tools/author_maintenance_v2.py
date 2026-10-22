"""Author the steam rescue v2 only; never rewrite the legacy scene or registry."""
from pathlib import Path
import json,re,math
root=Path(__file__).resolve().parents[1];q=lambda s:json.dumps(s,ensure_ascii=False);v=lambda a:'Vector3('+','.join(map(str,a))+')'
resources=[];nodes=[];obstacles=[];resource_ids=set()
def res(kind,name,body):
 assert name not in resource_ids,name;resource_ids.add(name)
 resources.append(f'[sub_resource type="{kind}" id="{name}"]\n{body}\n');return f'SubResource("{name}")'
def node(name,kind='Node3D',parent='.',body=''):
 group=' groups=["camera_occluder"]' if kind=='MeshInstance3D' else (' groups=["player_spawn_point"]' if name=='PlayerSpawn' else '')
 nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"{group}]\n{body}\n')
mats={}
for n,c in [('floor','0.24,0.29,0.29,1'),('wall','0.49,0.57,0.55,1'),('door','0.27,0.36,0.36,1'),('orange','0.91,0.57,0.18,1'),('pipe','0.31,0.4,0.43,1'),('bed','0.68,0.77,0.73,1'),('paint','0.8,0.8,0.66,1'),('green','0.2,0.9,0.57,1'),('steam','0.78,0.87,0.89,1'),('red','0.9,0.28,0.16,1')]:
 mats[n]=res('StandardMaterial3D','mat_'+n,f'albedo_color = Color({c})\nroughness = 0.85')
def box(name,at,size,mat='wall',collide=False,parent='.',nav=True):
 key=(parent+'/'+name).replace('/','_').replace('.','Root')
 mesh=res('BoxMesh',key+'Mesh','size = '+v(size));node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')
 if collide:
  shape=res('BoxShape3D',key+'Shape','size = '+v(size));node(name+'Body','StaticBody3D',parent,f'position = {v(at)}\ncollision_layer = 4\ncollision_mask = 0');node('CollisionShape3D','CollisionShape3D',name+'Body' if parent=='.' else parent+'/'+name+'Body',f'shape = {shape}')
  if nav:obstacles.append((at[0]-size[0]/2,at[2]-size[2]/2,size[0],size[2]))
def label(name,at,text,parent='.',size=26):node(name,'Label3D',parent,f'position = {v(at)}\ntext = {q(text)}\nfont = ExtResource("font")\nfont_size = {size}\npixel_size = 0.007\nbillboard = 1\noutline_size = 3')
box('Ground',(0,-.25,-7),(52,.5,70),'floor',True,nav=False)
for i,(at,size) in enumerate([((-26,1.8,-7),(1,3.6,70)),((26,1.8,-7),(1,3.6,70)),((0,1.8,28),(52,3.6,1)),((0,1.8,-42),(52,3.6,1)),((-14.5,1.8,0),(23,3.6,.7)),((14.5,1.8,0),(23,3.6,.7)),((-14.5,1.8,-28),(23,3.6,.7)),((14.5,1.8,-28),(23,3.6,.7)),((6,1.7,-11),(.7,3.4,14)),((21,1.7,-11),(.7,3.4,14)),((13.5,1.7,-18),(15,3.4,.7)),((9.5,1.7,-4),(7,3.4,.7)),((19,1.7,-4),(4,3.4,.7))]):box('Wall'+str(i),at,size,collide=True)
for i,(x,z,sx,sz) in enumerate([(-6,18,3,1),(-14,9,2,5),(5,9,2,3),(-8,-8,3,1),(-7,-17,2,4),(-16,-23,3,1),(15,-25,2,4),(-5,-24,2,3)]):box('Cover'+str(i),(x,.7,z),(sx,1.4,sz),'door',True)
for i,x in enumerate([10,18]):
 box('Bed'+str(i),(x,.45,-13),(1.8,.9,3.5),'bed',True)
 box('Pillow'+str(i),(x,.95,-14),(1.3,.2,.6),'paint')
# Pipes/paint identify the two wings without adding authoring-only assets.
for i,x in enumerate([-23,-21.5]):
 mesh=res('CylinderMesh','PipeMesh'+str(i),'top_radius = 0.25\nbottom_radius = 0.25\nheight = 30');node('Pipe'+str(i),'MeshInstance3D',body=f'position = Vector3({x},1.5,11)\nrotation_degrees = Vector3(90,0,0)\nmesh = {mesh}\nmaterial_override = {mats["pipe"]}')
for z in range(-36,25,5):box('FloorMark'+str(z).replace('-','N'),(0,.02,z),(.22,.04,1.6),'paint')
for name,x,z,width in [('ServiceGate',0,0,6),('WardGate',15,-4,4),('NorthGate',0,-28,6)]:
 shape=res('BoxShape3D',name+'Shape','size = '+v((width,3.6,.7)));node(name,'StaticBody3D',body=f'position = Vector3({x},0,{z})\ncollision_layer = 4\ncollision_mask = 0');node('CollisionShape3D','CollisionShape3D',name,f'position = Vector3(0,1.8,0)\nshape = {shape}');box(name+'Panel',(0,1.8,0),(width,3.6,.7),'door',parent=name)
 node(name+'Link','NavigationLink3D',body=f'enabled = false\nstart_position = {v((x,0,z+3))}\nend_position = {v((x,0,z-3))}')
 obstacles.append((x-width/2,z-1,width,2))
for name,at,oid,prompt,duration in [('Radio',(3,0,23),'maintenance_radio','LISTEN / THE WOMAN INSIDE',0),('Bypass',(-10,0,12),'maintenance_bypass','UNLATCH SERVICE BULKHEAD',6),('WardControl',(10,0,-2),'maintenance_release','OPEN THE WARD DOOR',4),('NorthControl',(0,0,-24),'maintenance_gate','OPEN NORTH SHUTTER / ISOLATE STEAM FIRST',8)]:
 node(name,body=f'position = {v(at)}\nscript = ExtResource("action")\nobjective_id = &{q(oid)}\ninteraction_prompt = {q(prompt)}\nduration = {duration}')
 box('TerminalPedestal',(0,.55,0),(.8,1.1,.5),'door',parent=name)
 box('Handle',(0,1.18,0),(.8,.1,.12),'orange',parent=name)
 label('WorldLabel',(0,1.8,0),prompt,name,22)
node('PlayerSpawn','Marker3D',body='position = Vector3(0,0,25)')
for name,at,oid in [('Retreat',(0,0,25),''),('NorthExit',(0,0,-37),'maintenance_rescue')]:node(name,body=f'position = {v(at)}\nscript = ExtResource("exit")\nextraction_id = &{q("maintenance_"+name)}\nrequired_objective_id = &{q(oid)}')
node('Survivor','CharacterBody3D',body='position = Vector3(15,0,-11)\nscript = ExtResource("survivor")')
shape=res('CapsuleShape3D','SurvivorShape','radius = 0.28\nheight = 1.7');node('CollisionShape3D','CollisionShape3D','Survivor',f'position = Vector3(0,0.85,0)\nshape = {shape}')
label('WorldLabel',(0,2.0,0),'XU TANG / SURVIVOR','Survivor',24)
for i,(at,kind,initial,group) in enumerate([((-10,0,18),'prototype_basic_enemy',True,''),((7,0,11),'campus_infected',True,''),((0,0,-18),'prototype_basic_enemy',True,''),((15,0,-14),'campus_infected',True,''),((15,0,-2),'campus_infected',False,'ward_release'),((-2,0,-23),'campus_infected',False,'ward_release'),((-12,0,-23),'campus_infected',False,'north_shutter'),((12,0,-24),'prototype_basic_enemy',False,'north_shutter')]):
 node('Enemy'+str(i),'Marker3D',body=f'position = {v(at)}\nscript = ExtResource("enemy")\nenemy_definition_id = &{q(kind)}\ninitial_spawn = {str(initial).lower()}\nactivation_group_id = &{q(group)}')
for name,at in [('Supplies',(-18,0,17)),('WardSupplies',(19,0,-7))]:node(name,body=f'position = {v(at)}\nscript = ExtResource("loot")\nloot_table_id = &"street_pharmacy_loot"\nroll_count = 2')
label('ServiceSign',(-12,2.6,4),'MAINTENANCE / PRESSURE BYPASS')
label('WardSign',(14,2.6,-3),'L-02 / WARD')
label('ExitSign',(0,2.6,-32),'NORTH / WAY OUT')
# Chamber walls use the existing ward wall on the east: do not split the ward.
for i,(at,size) in enumerate([((-4,1.8,-13.5),(.7,3.6,13)),((4,1.8,-13.5),(.7,3.6,13)),((-15,1.8,-7),(22,3.6,.7)),((5,1.8,-7),(2,3.6,.7)),((23.5,1.8,-7),(5,3.6,.7)),((-15,1.8,-20),(22,3.6,.7)),((15,1.8,-20),(22,3.6,.7))]):box('ChamberWall'+str(i),at,size,collide=True)
node('Steam',body='script = ExtResource("steam")')
for name in ['Jets','Warning','Safe']:node(name,parent='Steam')
for i,x in enumerate([-2.9,-1.45,0,1.45,2.9]):
 for j,z in enumerate([-15,-13,-11]):
  # Narrow vertical columns leave the character silhouette readable.
  mesh=res('CylinderMesh',f'JetMesh{i}_{j}','top_radius = 0.14\nbottom_radius = 0.24\nheight = 1.9')
  node(f'Jet{i}_{j}','MeshInstance3D','Steam/Jets',f'position = Vector3({x},0.95,{z})\nmesh = {mesh}\nmaterial_override = {mats["steam"]}')
for z in [-9.6,-16.4]:box('YellowLine'+str(z).replace('-','N'),(0,.04,z),(7,.06,.12),'orange')
for z in [-9.2,-16.8]:
 for state,mat in [('Warning','orange'),('Safe','green')]:box('Border'+str(z).replace('-','N'),(0,.04,z),(7,.06,.16),mat,parent='Steam/'+state)
node('Lamp','OmniLight3D','Steam','position = Vector3(0,2,-13)\nlight_energy = 0.8\nomni_range = 9')
label('WorldLabel',(0,2.2,-9),'CLEAR WINDOW / CROSS NOW','Steam',24)
node('SteamValve',body='position = Vector3(2,0,-23)\nscript = ExtResource("valve")')
box('Pedestal',(0,.65,0),(.7,1.3,.6),'pipe',parent='SteamValve')
box('Handle',(0,1.4,0),(1,.12,.16),'orange',parent='SteamValve')
label('WorldLabel',(0,2,0),'CLOSE STEAM VALVE / FAR SIDE','SteamValve',22)

vertices=[];polys=[];lookup={}
def vertex(x,z):
 key=(x,z)
 if key not in lookup:lookup[key]=len(vertices);vertices.append((x,0,z))
 return lookup[key]
for ix in range(-50,50):
 for iz in range(-82,54):
  x,z=ix/2,iz/2
  if any(x+.5>ox-.75 and x<ox+sx+.75 and z+.5>oz-.75 and z<oz+sz+.75 for ox,oz,sx,sz in obstacles):continue
  polys.append([vertex(x,z),vertex(x,z+.5),vertex(x+.5,z+.5),vertex(x+.5,z)])
nav=res('NavigationMesh','MaintenanceNav','vertices = PackedVector3Array('+','.join(','.join(map(str,p)) for p in vertices)+')\npolygons = Array[PackedInt32Array](['+','.join('PackedInt32Array('+','.join(map(str,p))+')' for p in polys)+'])\nagent_radius = 0.75')
node('Navigation','NavigationRegion3D',body='navigation_mesh = '+nav)
env=res('Environment','Interior','background_mode = 1\nbackground_color = Color(0.12,0.17,0.18,1)\nambient_light_source = 2\nambient_light_color = Color(0.7,0.79,0.8,1)\nambient_light_energy = 0.85\ntonemap_mode = 4');node('Environment','WorldEnvironment',body='environment = '+env)
node('Light','DirectionalLight3D',body='rotation_degrees = Vector3(-70,-20,0)\nlight_energy = 0.9\nshadow_enabled = true')
ext=[('Script','steam','scripts/world/maintenance/steam.gd'),('Script','valve','scripts/world/maintenance/steam_valve.gd'),('Script','area','scripts/world/maintenance/steam_zone.gd'),('Script','action','scripts/world/maintenance/maintenance_action.gd'),('Script','survivor','scripts/world/maintenance/survivor.gd'),('Script','exit','scripts/world/maintenance/maintenance_exit.gd'),('Script','enemy','scripts/world/enemy_spawn_point.gd'),('Script','loot','scripts/world/loot_spawn_point.gd'),('FontFile','font','assets/fonts/noto_sans_sc/NotoSansSC.ttf')]
text='[gd_scene format=3]\n'+''.join(f'[ext_resource type="{t}" path="res://{p}" id="{n}"]\n' for t,n,p in ext)+'\n'+'\n'.join(resources)+'\n[node name="MaintenanceZone" type="Node3D"]\nscript = ExtResource("area")\nmetadata/map_revision = 2\n\n'+'\n'.join(nodes)
(root/'scenes/areas/maintenance_zone_v2.tscn').write_text(text,encoding='utf-8')
print('Authored maintenance steam v2:',len(nodes),'nodes,',len(polys),'nav polygons, unique subresources:',len(resource_ids))
