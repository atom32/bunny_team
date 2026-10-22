"""Author the fixed Water Tower Street scene and original PA cue. No source art edits."""
from pathlib import Path
import json
import math
import struct
import wave

root = Path(__file__).resolve().parents[1]
q = lambda value: json.dumps(value, ensure_ascii=False)
v = lambda value: 'Vector3(' + ', '.join(str(n) for n in value) + ')'
resources, nodes, obstacles = [], [], []

def resource(kind, name, body):
    resources.append(f'[sub_resource type="{kind}" id="{name}"]\n{body}\n')
    return f'SubResource("{name}")'

def node(name, kind='Node3D', parent='.', body='', instance=None):
    props = f'type="{kind}"' if instance is None else f'instance=ExtResource("{instance}")'
    if kind == 'MeshInstance3D': props += ' groups=["camera_occluder"]'
    nodes.append(f'[node name="{name}" {props} parent="{parent}"]\n{body}\n')

def material(name, color, texture=None):
    body = f'albedo_color = Color({color})\nroughness = 0.85'
    if texture: body += f'\nalbedo_texture = ExtResource("{texture}")\nuv1_triplanar = true\nuv1_scale = Vector3(0.25,0.25,0.25)'
    return resource('StandardMaterial3D', name, body)

mats = {n: material(n,c,t) for n,c,t in [('road','0.5,0.5,0.5,1','asphalt'),('brick','0.8,0.77,0.68,1','brick'),('ground','0.34,0.39,0.33,1',None),('steel','0.25,0.34,0.35,1',None),('rust','0.57,0.32,0.21,1',None),('cream','0.83,0.79,0.63,1',None),('water','0.2,0.73,0.83,0.7',None)]}

def box(name, at, size, mat='steel', collide=False, parent='.'):
    mesh = resource('BoxMesh', name+'Mesh', 'size = '+v(size))
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')
    if collide:
        shape = resource('BoxShape3D',name+'Shape','size = '+v(size))
        node(name+'Body','StaticBody3D',parent,f'position = {v(at)}\ncollision_layer = 4\ncollision_mask = 0')
        node('CollisionShape3D','CollisionShape3D',name+'Body' if parent=='.' else parent+'/'+name+'Body',f'shape = {shape}')
        if at[1] - size[1]/2 < 2.0 and at[1]+size[1]/2 > .2:
            obstacles.append((at[0]-size[0]/2,at[2]-size[2]/2,size[0],size[2]))

def cylinder(name, at, radius, height, mat='steel', parent='.'):
    mesh = resource('CylinderMesh',name+'Mesh',f'top_radius = {radius}\nbottom_radius = {radius}\nheight = {height}')
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')

def label(name, at, text, parent='.', size=32):
    node(name,'Label3D',parent,f'position = {v(at)}\ntext = {q(text)}\nfont = ExtResource("font")\nfont_size = {size}\npixel_size = 0.008\nbillboard = 1\nno_depth_test = false\noutline_size = 3')

box('Ground',(0,-.25,0),(80,.5,68),'ground',True)
box('MainStreet',(0,.015,0),(13,.03,65),'road')
box('WestAlley',(-32,.02,0),(5,.03,58),'road')
box('NorthCrossing',(0,.02,-25),(73,.03,8),'road')
box('SouthCrossing',(0,.02,24),(73,.03,8),'road')
for z in range(-27,29,6): box('LaneMark'+str(z).replace('-','N'),(0,.045,z),(.18,.02,2.5),'cream')
for name,at,size in [('WestTenements',(-19,3.4,-2),(17,6.8,15)),('EastWarehouse',(25,3,9),(19,6,13)),('NorthHomes',(-23,3.1,-29),(23,6.2,8))]:
    box(name,at,size,'brick',True)
    for i in range(4): box(name+'Window'+str(i),(at[0]-size[0]/2+2.5+i*4,3.5,at[2]+size[2]/2+.02),(1.6,1.4,.04),'steel')
box('GarageBack',(-26,2,10),(17,4,.5),'brick',True)
box('GarageLeft',(-34,2,15),(.5,4,10),'brick',True)
box('GarageRight',(-18,2,15),(.5,4,10),'brick',True)
box('GarageFloor',(-26,.025,15),(16,.05,10),'cream')
label('GarageSign',(-26,4.4,10),'REPAIR / BATTERY')
for i,(x,z,sx,sz) in enumerate([(-5,15,3,1),(6,0,3,1),(12,-12,1,4),(-27,-12,3,1),(20,-22,3,1),(-10,27,4,1)]):
    box('Cover'+str(i),(x,.65,z),(sx,1.3,sz),'cream',True)
for i,(x,z) in enumerate([(22,-7),(32,-7),(22,-17),(32,-17)]): box('TowerLeg'+str(i),(x,3.6,z),(.6,7.2,.6),'steel',True)
cylinder('WaterTank',(27,8,-12),5,4,'rust')
cylinder('TowerRim',(27,10.1,-12),5.2,.2,'steel')
cylinder('TowerPipe',(20,2,-12),.18,4,'steel')
label('TowerSign',(27,11.2,-12),'WATER / 07',size=48)
node('WaterFlow')
cylinder('RunningWater',(20,.8,-12),.12,1.5,'water','WaterFlow')
box('PumpMotor',(24,.65,-13),(1.4,1.3,1.5),'rust',True)
cylinder('PumpHousing',(24,1.4,-13),.55,.6,'steel')
node('PublicWater')
cylinder('TapStream',(-20,.8,-18),.09,1.4,'water','PublicWater')
node('TankerWater')
cylinder('LoadingStream',(35,2,-24),.12,1.2,'water','TankerWater')
for i in range(5):
    cylinder('Bucket'+str(i),(-24+i*1.1,.25,-18.5),.32,.5,'cream')
    cylinder('BucketRim'+str(i),(-24+i*1.1,.52,-18.5),.36,.05,'steel')
box('TruckChassis',(34,1,-25),(3.1,.65,7),'steel',True)
box('TruckCab',(34,2,-28),(3,2.3,2),'rust',True)
box('TruckWindscreen',(34,2.5,-29.05),(2.3,.8,.08),'steel')
cylinder('TruckTank',(34,2.7,-24),1.35,4,'cream')
nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(90,0,0)\nmesh =')
for i,(x,z) in enumerate([(32.4,-27),(35.6,-27),(32.4,-22),(35.6,-22)]):
    cylinder('TruckWheel'+str(i),(x,.65,z),.65,.45,'steel')
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(0,0,90)\nmesh =')
for i,(x,z) in enumerate([(-38,0),(38,0),(0,-33),(0,33)]):
    box('Boundary'+str(i),(x,2,z),(1 if x else 80,4,68 if x else 1),'brick',True)
node('Loudspeaker',body='position = Vector3(-3,0,-7)')
box('SpeakerPole',(-3,2.2,-7),(.16,4.4,.16),'steel',True)
box('SpeakerBox',(-3,4.5,-7),(1.2,.7,.7),'cream')
label('RadioSign',(-3,5.4,-7),'PLEASE WAIT PATIENTLY',size=22)
node('PlayerSpawn','Marker3D',body='position = Vector3(0,0.1,29)\ngroups = ["player_spawn_point"]')
# Groups are node metadata in the section header, not a serialized property.
nodes[-1] = nodes[-1].replace('parent="."]','parent="." groups=["player_spawn_point"]]').replace('\ngroups = ["player_spawn_point"]','')
actions = [('Radio','radio',(0,0,24),'water_briefing','RADIO / TANG KUI'),('Battery','battery',(-26,0,15),'water_battery','TAKE PUMP BATTERY / 8kg'),('Pump','pump',(25,0,-13),'water_pump','INSTALL PUMP BATTERY / 8s'),('Decoy','decoy',(-28,0,3),'water_decoy','SOUND THE SQUARE LOUDSPEAKER / ONCE'),('PublicValve','public',(-20,0,-17),'water_public','INSPECT COURTYARD DELIVERY'),('TankerValve','tanker',(26,0,-26),'water_tanker','INSPECT TANKER DELIVERY')]
for name,kind,at,oid,prompt in actions:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("action")\nkind = {q(kind)}\nobjective_id = &{q(oid)}\ninteraction_prompt = {q(prompt)}')
    box('TerminalPedestal',(0,.45,0),(.8,.9,.6),'steel',parent=name)
    label('WorldLabel',(0,1.8,0),prompt,name,size=25)
    if kind=='battery':
        node('Cargo',parent=name)
        box('BatteryCase',(0,.85,0),(.7,.55,.45),'rust',parent=name+'/Cargo')
        for i,x in enumerate([-.2,.2]): box('Terminal'+str(i),(x,1.15,0),(.1,.1,.15),'cream',parent=name+'/Cargo')
for name,at,oid in [('Retreat',(0,0,30),''),('PublicExit',(-32,0,-21),'water_public'),('TankerExit',(31,0,-28),'water_tanker')]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("exit")\nextraction_id = &{q("water_"+name)}\nrequired_objective_id = &{q(oid)}')
for name,at,table,enabled,rolls in [('PublicReward',(-21,0,-18),'water_public_reward',False,2),('TankerReward',(28,0,-26),'water_tanker_reward',False,1),('GarageLoot',(-29,0,13),'street_repair_loot',True,2),('AlleyMedicine',(-34,0,-14),'street_pharmacy_loot',True,2),('StreetSalvage',(9,0,6),'street_supply_loot',True,2)]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("loot")\nloot_table_id = &{q(table)}\nenabled = {str(enabled).lower()}\nroll_count = {rolls}\nmetadata/campus_storage = 1')
    node('Art',parent=name,body='scale = Vector3(0.7,0.7,0.7)',instance='supply')
for i,(at,enemy,role,yaw) in enumerate([((2,0,9),'prototype_basic_enemy',0,0),((5,0,-10),'prototype_basic_enemy',1,math.pi),((-24,0,-18),'prototype_basic_enemy',1,0),((18,0,-24),'prototype_basic_enemy',2,math.pi),((28,0,-16),'prototype_heavy_enemy',3,math.pi),((-8,0,-18),'campus_infected',3,0),((-33,0,-3),'campus_infected',3,math.pi),((10,0,18),'campus_infected',3,0)]):
    node('Enemy'+str(i),'Marker3D',body=f'position = {v(at)}\nrotation = Vector3(0,{yaw},0)\nscript = ExtResource("enemy")\nenemy_definition_id = &{q(enemy)}\ntactical_role = {role}')
# Fixed native nav grid, omitting collision footprints with capsule clearance.
vertices=[]; polygons=[]; lookup={}
def vertex(x,z):
    key=(x,z)
    if key not in lookup: lookup[key]=len(vertices); vertices.append((x,0,z))
    return lookup[key]
for x in range(-37,37,2):
    for z in range(-31,31,2):
        if any(ox-1 < x+1 < ox+sx+1 and oz-1 < z+1 < oz+sz+1 for ox,oz,sx,sz in obstacles): continue
        polygons.append([vertex(x,z),vertex(x,z+2),vertex(x+2,z+2),vertex(x+2,z)])
nav=resource('NavigationMesh','Navigation', 'vertices = PackedVector3Array('+','.join(','.join(map(str,p)) for p in vertices)+')\npolygons = Array[PackedInt32Array](['+','.join('PackedInt32Array('+','.join(map(str,p))+')' for p in polygons)+'])\nagent_radius = 0.6')
node('StreetNavigation','NavigationRegion3D',body='navigation_mesh = '+nav)
environment=resource('Environment','Dawn','background_mode = 1\nbackground_color = Color(0.31,0.41,0.44,1)\nambient_light_source = 2\nambient_light_color = Color(0.77,0.83,0.87,1)\nambient_light_energy = 0.7\ntonemap_mode = 4')
node('Environment','WorldEnvironment',body='environment = '+environment)
node('Sun','DirectionalLight3D',body='rotation_degrees = Vector3(-58,-25,0)\nlight_color = Color(1,0.85,0.67,1)\nlight_energy = 1.2\nshadow_enabled = true')
ext=[('Script','district','scripts/world/waterworks/waterworks_district.gd'),('Script','action','scripts/world/waterworks/waterworks_action.gd'),('Script','exit','scripts/world/waterworks/waterworks_exit.gd'),('Script','enemy','scripts/world/enemy_spawn_point.gd'),('Script','loot','scripts/world/loot_spawn_point.gd'),('FontFile','font','assets/fonts/NotoSansSC-Regular.ttf'),('Texture2D','asphalt','assets/environment/polyhaven_streets/asphalt_02_diff_1k.jpg'),('Texture2D','brick','assets/environment/polyhaven_streets/wall_bricks_plaster_diff_1k.jpg'),('PackedScene','supply','assets/environment/service_props/supply_stack.glb')]
# Match the existing project's actual font, without creating a second font asset.
font_files=list((root/'assets').rglob('*.ttf'))+list((root/'assets').rglob('*.otf'))
assert font_files
ext=[(t,n,font_files[0].relative_to(root).as_posix() if n=='font' else p) for t,n,p in ext]
dest=root/'scenes/areas/waterworks_district.tscn'; dest.parent.mkdir(parents=True,exist_ok=True)
dest.write_text('[gd_scene format=3]\n'+''.join(f'[ext_resource type="{t}" path="res://{p}" id="{n}"]\n' for t,n,p in ext)+'\n'+'\n'.join(resources)+'\n[node name="WaterworksDistrict" type="Node3D"]\nscript = ExtResource("district")\nmetadata/map_revision = 1\n\n'+'\n'.join(nodes),encoding='utf-8')
audio=root/'assets/audio/water_horn.wav'
with wave.open(str(audio),'wb') as f:
    f.setparams((1,2,22050,0,'NONE','not compressed'))
    for i in range(44100):
        t=i/22050; pulse=t%0.7
        env=min(1,pulse/.04)*max(0,min(1,(.52-pulse)/.07))
        sample=.18*env*(math.sin(2*math.pi*370*t)+.4*math.sin(2*math.pi*480*t))
        f.writeframesraw(struct.pack('<h',int(32767*sample)))
print('Authored',dest,'nav polygons',len(polygons),'and original PA horn')
