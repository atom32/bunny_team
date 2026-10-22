"""Author ONLY the new v2 approach and escape map; never execute the old generator."""
from pathlib import Path
import json
import math
import re

root = Path(__file__).resolve().parents[1]
q = lambda value: json.dumps(value, ensure_ascii=False)
v = lambda value: 'Vector3(' + ', '.join(str(n) for n in value) + ')'
resources, nodes, obstacles = [], [], []
resource_names = set()

def resource(kind, name, body):
    name = re.sub(r'[^A-Za-z0-9_]', '_', name)
    if name in resource_names: raise ValueError('Duplicate subresource: '+name)
    resource_names.add(name)
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

# Add original environment detailing without altering the established collision/nav layout.
for name, color, glow in [('paint','0.1,0.18,0.22,1',False),('rubber','0.035,0.045,0.05,1',False),('glass','0.07,0.2,0.25,1',False),('yellow','0.96,0.68,0.16,1',False),('white','0.9,0.93,0.86,1',False),('cyan','0.1,0.9,0.94,1',True),('red','1,0.19,0.05,1',True),('unlit','0.1,0.12,0.13,1',False)]:
    mats[name] = material(name,color)
    if glow: resources[-1] = resources[-1].replace('roughness = 0.85','roughness = 0.3\nshading_mode = 0')

def box(name, at, size, mat='steel', collide=False, parent='.'):

    mesh = resource('BoxMesh', parent+'_'+name+'Mesh', 'size = '+v(size))
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')
    if collide:
        shape = resource('BoxShape3D',parent+'_'+name+'Shape','size = '+v(size))
        node(name+'Body','StaticBody3D',parent,f'position = {v(at)}\ncollision_layer = 4\ncollision_mask = 0')
        node('CollisionShape3D','CollisionShape3D',name+'Body' if parent=='.' else parent+'/'+name+'Body',f'shape = {shape}')
        if at[1] - size[1]/2 < 2.0 and at[1]+size[1]/2 > .2:
            obstacles.append((at[0]-size[0]/2,at[2]-size[2]/2,size[0],size[2]))

def cylinder(name, at, radius, height, mat='steel', parent='.'):
    mesh = resource('CylinderMesh',parent+'_'+name+'Mesh',f'top_radius = {radius}\nbottom_radius = {radius}\nheight = {height}')
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')

def label(name, at, text, parent='.', size=32, pixel=.02):
    node(name,'Label3D',parent,f'position = {v(at)}\ntext = {q(text)}\nfont = ExtResource("font")\nfont_size = {size}\npixel_size = {pixel}\nbillboard = 1\nno_depth_test = false\noutline_size = 3')

box('Ground',(0,-.25,0),(44,.5,104),'ground',True)
box('Street',(0,.015,0),(16,.03,101),'road')
for z in range(-47,50,6): box('Lane'+str(z).replace('-','N'),(0,.04,z),(.2,.02,2.4),'cream')
for i,(at,size) in enumerate([((-22,2,0),(1,4,104)),((22,2,0),(1,4,104)),((0,2,-52),(44,4,1)),((0,2,52),(44,4,1)),((-16,3,11),(9,6,9)),((16,3,-3),(9,6,17))]):
    box('Buildings'+str(i),at,size,'brick',True)
for i,(x,z,sx,sz) in enumerate([(-4,14,3,1),(4,6,3,1),(-6,-1,2,5),(-12,-5,2,3),(5,-14,2,4),(0,-21,5,1)]):
    box('Concrete'+str(i),(x,.85,z),(sx,1.7,sz),'paint' if i==5 else 'cream',True)
label('AlleySign',(-16,3,-5),'SERVICE / PA',size=28)
label('GateSign',(0,3,-26),'CHECKPOINT / NORTH GATE',size=32)
label('TutorialSign',(0,2.5,19),'RED LINE: MOVE / BLUE VENTS: FIRE',size=24)

# Fixed, editable armored PA vehicle. No human meshes are generated.
node('Van','StaticBody3D',body='position = Vector3(0,0,-10)\nscript = ExtResource("van")\nmax_structure_health = 360.0')
shape=resource('BoxShape3D','VanShape','size = Vector3(3.8,3.1,7)')
node('CollisionShape3D','CollisionShape3D','Van',f'position = Vector3(0,1.55,0)\nshape = {shape}')
box('BarrierMesh',(0,1.4,0),(3.5,1.9,6.5),'paint',parent='Van')
box('Cab',(0,2.15,2.1),(3.4,1.4,2),'paint',parent='Van')
box('Windscreen',(0,2.35,3.12),(2.7,.65,.05),'glass',parent='Van')
box('Bumper',(0,.7,3.5),(3.9,.3,.4),'rust',parent='Van')
box('Grille',(0,1.25,3.3),(2.5,.55,.1),'rust',parent='Van')
for i,x in enumerate([-1.2,1.2]): box('Headlight'+str(i),(x,1.8,3.15),(.4,.25,.1),'white',parent='Van')
for i,(x,z) in enumerate([(-1.9,-2),(1.9,-2),(-1.9,2),(1.9,2)]):
    cylinder('Wheel'+str(i),(x,.6,z),.65,.4,'rubber','Van')
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(0,0,90)\nmesh =')
box('Roof',(0,2.7,-1),(3.5,.3,4),'paint',parent='Van')
cylinder('GunMount',(0,2.95,1.3),.5,.5,'rust','Van')
box('GunBarrel',(0,2.6,2),( .18,.18,2),'steel',parent='Van')
for i,x in enumerate([-1,1]):
    box('Speaker'+str(i),(x,3.25,-1),(1.0,.75,.8),'rust',parent='Van')
    box('SpeakerMouth'+str(i),(x,3.25,-.58),(.8,.55,.05),'steel',parent='Van')
box('ShutterLeft',(-1.83,1.8,-1),(.1,.8,2.4),'rust',parent='Van')
box('ShutterRight',(1.83,1.8,-1),(.1,.8,2.4),'rust',parent='Van')
box('SpeakerLight',(0,3.5,-1),(.45,.16,.45),'rust',parent='Van')
box('VentLight',(0,2.9,-1),(2.7,.15,2.4),'cyan',parent='Van')
box('WreckSmoke',(0,3,-1),(.7,1.4,.7),'steel',parent='Van')
# Flat alpha-free ribbon shows a frozen trajectory, not a tracking laser.
warn=material('warning','1.0,0.13,0.05,1')
mats['warning']=warn
box('WarningLine',(0,.08,0),(.18,.025,1),'warning',parent='Van')
# Fixed warning impact ring, exactly at the saved aim point. Rendering never changes damage.
ring=resource('TorusMesh','WarningRing','inner_radius = 0.62\nouter_radius = 0.75\nrings = 24\nring_segments = 6')
node('WarningTarget','MeshInstance3D','Van',f'mesh = {ring}\nmaterial_override = {mats["red"]}\ncast_shadow = 0')
# Cab and side armor details remain authored meshes, not runtime props or human geometry.
for i, x in enumerate([-1.15,1.15]):
    box('WindowFrame'+str(i),(x,2.35,3.18),(.055,.72,.08),'steel',parent='Van')
    box('MirrorArm'+str(i),(x*1.6,2.25,2.2),(.42,.055,.1),'steel',parent='Van')
    box('Mirror'+str(i),(x*1.75,2.25,2.2),(.14,.4,.22),'rubber',parent='Van')
for i, (x,z) in enumerate([(-1.76,-2.2),(1.76,-2.2),(-1.76,0),(1.76,0)]):
    box('ArmorPlate'+str(i),(x,1.9,z),(.12,1.3,1.9),'steel',parent='Van')
    for k in range(3):box('PlateBolt'+str(i)+'_'+str(k),(x*1.04,2.35,z-.6+k*.6),(.07,.07,.07),'yellow',parent='Van')
for i in range(7):
    box('GrilleSlat'+str(i),(-1.05+i*.35,1.25,3.38),(.08,.5,.035),'rubber',parent='Van')
    for side in [-1,1]:box('CoolingSlot'+str(i)+'_'+str(side),(side*1.85,2,-2.0+i*.3),(.04,.48,.07),'rubber',parent='Van')
box('GunActive',(0,3.23,1.3),(.2,.12,.2),'red',parent='Van')
box('DisabledMark',(0,3.32,1.3),(.65,.1,.65),'unlit',parent='Van')
for i,x in enumerate([-1.1,1.1]):box('RoofHazard'+str(i),(x,2.88,-1),(.16,.03,3.7),'yellow',parent='Van')
for i,x in enumerate([-.75,.75]):
    box('HoodStripe'+str(i),(x,2.87,2.15),(.15,.03,1.6),'white',parent='Van')
# The existing fifth concrete collider becomes the lifting traffic blast shield.
# Its CLOSED collider and navigation footprint are byte-equivalent to the prior build.
for i in range(9):
    box('GateStripe'+str(i),(-2.1+i*.52,0,.52),(.16,1.58,.025),'yellow',parent='Concrete5')
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(0,0,-20)\nmesh =')
for i,x in enumerate([-3.2,3.2]):box('GateTrack'+str(i),(x,2.9,-21),(.35,5.8,.8),'steel')
box('GateGantry',(0,5.6,-21),(7,.4,.9),'steel')

obstacles.append((-2.5,-14,5,8))

node('PlayerSpawn','Marker3D',body='position = Vector3(0,0.1,48)')
nodes[-1]=nodes[-1].replace('parent="."]','parent="." groups=["player_spawn_point"]]')
for name,at,oid,prompt in [('Radio',(0,0,46),'blockade_brief','RADIO / TANG KUI'),('PASwitch',(-15,0,-7),'blockade_speaker','CUT PA SUPPLY / WEST ALLEY')]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("switch")\nobjective_id = &{q(oid)}\ninteraction_prompt = {q(prompt)}')
    box('TerminalPedestal',(0,.5,0),(.7,1,.4),'steel',parent=name)
    label('WorldLabel',(0,1.8,0),prompt,parent=name,size=22)
    if name=='PASwitch':
        box('SwitchCase',(0,.9,0),(.9,.8,.5),'paint',parent=name)
        node('Lever',parent=name,body='position = Vector3(0,.9,.32)')
        box('Handle',(0,.26,0),(.12,.55,.12),'yellow',parent=name+'/Lever')
        box('PowerOn',(.28,1.17,.29),(.13,.13,.06),'red',parent=name)
        box('PowerOff',(.28,1.17,.3),(.13,.13,.06),'unlit',parent=name)

for name,at,oid in [('Retreat',(0,0,50),''),('NorthExit',(0,0,-48),'blockade_van')]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("exit")\nextraction_id = &{q("blockade_"+name)}\nrequired_objective_id = &{q(oid)}')
for i,(at,yaw) in enumerate([((-15,0,-17),0),((12,0,-20),0),((10,0,9),math.pi)]):
    node('Infected'+str(i),'Marker3D',body=f'position = {v(at)}\nrotation = Vector3(0,{yaw},0)\nscript = ExtResource("enemy")\nenemy_definition_id = &"campus_infected"')
node('Medicine',body='position = Vector3(-17,0,-1)\nscript = ExtResource("loot")\nloot_table_id = &"street_pharmacy_loot"\nroll_count = 2\nmetadata/campus_storage = 1')
node('Art',parent='Medicine',body='scale = Vector3(.7,.7,.7)',instance='supply')
# Ground cable and energized indicator segments make the independent PA circuit visible.
box('CableFromSwitch',(-9,.06,-7),(12,.08,.08),'rubber')
box('CableToVan',(-3,.06,-8.5),(.08,.08,3),'rubber')
node('PowerIndicators')
for i in range(6):box('Current'+str(i),(-14+i*2,.11,-7),(.28,.05,.13),'red',parent='PowerIndicators')

# Front yard: parked deliveries provide real sight/shot cover. Two physical entries.
for name,at,size in [('EntryFenceWest',(-19.5,1.2,21),(5,2.4,.35)),('EntryFenceMiddle',(-8,1.2,21),(10,2.4,.35)),('EntryFenceEast',(12.5,1.2,21),(19,2.4,.35)),('DeliveryWest',(-7,1.3,36),(7,2.6,3)),('DeliveryEast',(8,1.3,31),(7,2.6,3)),('AlarmCoverWest',(-6,1.4,19),(4,2.8,1)),('AlarmCoverEast',(9,1.4,19),(6,2.8,1))]:
    box(name,at,size,'steel',True)
for name,x,z,width in [('ServiceGate',-15,21,4),('StreetGate',0,21,6),('EscapeGate',0,-40,4)]:
    node(name)
    box('Panel',(x,1.2,z),(width,2.4,.3),'paint',True,parent=name)
    for i in range(int(width*2)):
        box('Stripe'+str(i),(x-width*.5+.2+i*.5,1.2,z+.17),(.12,2,.03),'yellow',parent=name)
for name,x,z0,z1 in [('ServiceLink',-15,25,17),('StreetLink',0,25,17),('EscapeLink',0,-36,-44)]:
    node(name,'NavigationLink3D',body=f'enabled = false\nstart_position = Vector3({x},0,{z0})\nend_position = Vector3({x},0,{z1})')
node('Passage',body='script = ExtResource("passage")')
for name,x,z,is_escape in [('ServiceLever',-15,24,False),('EscapeLever',14,-29,True)]:
    node(name,body=f'position = Vector3({x},0,{z})\nscript = ExtResource("lever")\nescape = {str(is_escape).lower()}')
    box('Case',(0,.8,0),(.8,1.6,.5),'steel',parent=name)
    node('Lever',parent=name,body='position = Vector3(0,1.15,.35)')
    box('Handle',(0,.25,0),(.14,.5,.12),'yellow',parent=name+'/Lever')
    label('WorldLabel',(0,2.1,0),'RELEASE COUNTERWEIGHT / NORTH GATE' if is_escape else 'OPEN SERVICE SHUTTER / QUIET ENTRY',parent=name,size=30,pixel=.024)
node('StreetChain','StaticBody3D',body='position = Vector3(0,1.25,21.35)\nscript = ExtResource("chain")\nmax_structure_health = 24.0')
chain_shape=resource('BoxShape3D','ChainShape','size = Vector3(1,.8,.18)')
node('CollisionShape3D','CollisionShape3D','StreetChain',f'shape = {chain_shape}')
box('BarrierMesh',(0,0,0),(1,.8,.18),'red',parent='StreetChain')
label('WorldLabel',(0,1.7,0),'SHOOT RED CHAIN / LOUD ENTRY',parent='StreetChain',size=30,pixel=.024)
# A second yard behind the original lifting traffic shield: no instant victory.
for name,x,z,width in [('NorthWallWest',-12.25,-21,19.5),('NorthWallEast',12.25,-21,19.5),('EscapeWallWest',-12,-40,20),('EscapeWallEast',12,-40,20)]:
    box(name,(x,1.5,z),(width,3,.5),'brick',True)
box('EastBooth',(17,1.6,-26),(7,3.2,3),'brick',True)
box('NorthCover',(-3,1,-31),(4,2,1),'cream',True)
label('ExitYardSign',(0,3,-39),'NORTH SHUTTER / EAST BOOTH',size=30,pixel=.024)
for name,at,definition,group in [('Alarm0',(-6,0,16.5),'campus_infected','blockade_alarm'),('Alarm1',(9,0,16.5),'campus_infected','blockade_alarm'),('EscapeRam',(-9,0,-34),'campus_rammer','blockade_escape'),('EscapeFollower',(12,0,-34),'campus_infected','blockade_escape')]:
    node(name,'Marker3D',body=f'position = {v(at)}\nrotation = Vector3(0,3.14159265,0)\nscript = ExtResource("enemy")\nenemy_definition_id = &{q(definition)}\ninitial_spawn = false\nactivation_group_id = &{q(group)}')
# Sweeping light is a bounded perception test, not a hit/damage zone or new stealth stat.
node('Searchlight',body='position = Vector3(-4,4.2,19)\nscript = ExtResource("light")')
box('Pole',(0,-2.1,0),(.2,4.2,.2),'steel',parent='Searchlight')
node('Head',parent='Searchlight',body='rotation = Vector3(-.35,3.14159265,0)')
box('Lamp',(0,0,0),(.7,.35,.45),'yellow',parent='Searchlight/Head')
node('Beam','SpotLight3D','Searchlight/Head','light_color = Color(1,.86,.42,1)\nlight_energy = 4.0\nspot_range = 26.0\nspot_angle = 20.0\nshadow_enabled = true')

vertices=[]; polygons=[]; lookup={}
def vertex(x,z):
    key=(x,z)
    if key not in lookup: lookup[key]=len(vertices);vertices.append((x,0,z))
    return lookup[key]
for x in range(-21,21):
    for z in range(-51,51):
        if any(ox-.95 < x+1 and x < ox+sx+.95 and oz-.95 < z+1 and z < oz+sz+.95 for ox,oz,sx,sz in obstacles): continue
        polygons.append([vertex(x,z),vertex(x,z+1),vertex(x+1,z+1),vertex(x+1,z)])
nav=resource('NavigationMesh','Navigation','vertices = PackedVector3Array('+','.join(','.join(map(str,p)) for p in vertices)+')\npolygons = Array[PackedInt32Array](['+','.join('PackedInt32Array('+','.join(map(str,p))+')' for p in polygons)+'])\nagent_radius = 0.6')
node('StreetNavigation','NavigationRegion3D',body='navigation_mesh = '+nav)
node('NorthGateLink','NavigationLink3D',body='enabled = false\nstart_position = Vector3(0,0,-18)\nend_position = Vector3(0,0,-24)')
env=resource('Environment','Dawn','background_mode = 1\nbackground_color = Color(.31,.41,.44,1)\nambient_light_source = 2\nambient_light_color = Color(.77,.83,.87,1)\nambient_light_energy = .7\ntonemap_mode = 4')
node('Environment','WorldEnvironment',body='environment = '+env)
node('Sun','DirectionalLight3D',body='rotation_degrees = Vector3(-58,-25,0)\nlight_color = Color(1,.85,.67,1)\nlight_energy = 1.2\nshadow_enabled = true')
ext=[('Script','district','scripts/world/blockade/journey_district.gd'),('Script','van','scripts/world/blockade/blockade_van.gd'),('Script','switch','scripts/world/blockade/blockade_switch.gd'),('Script','exit','scripts/world/blockade/blockade_exit.gd'),('Script','enemy','scripts/world/enemy_spawn_point.gd'),('Script','loot','scripts/world/loot_spawn_point.gd'),('FontFile','font','assets/fonts/noto_sans_sc/NotoSansSC.ttf'),('Texture2D','asphalt','assets/environment/polyhaven_streets/asphalt_02_diff_1k.jpg'),('Texture2D','brick','assets/environment/polyhaven_streets/wall_bricks_plaster_diff_1k.jpg'),('PackedScene','supply','assets/environment/service_props/supply_stack.glb'),('Script','passage','scripts/world/blockade/passage.gd'),('Script','lever','scripts/world/blockade/journey_lever.gd'),('Script','chain','scripts/world/blockade/street_chain.gd'),('Script','light','scripts/world/blockade/searchlight.gd')]
text='[gd_scene format=3]\n'+''.join(f'[ext_resource type="{t}" path="res://{p}" id="{n}"]\n' for t,n,p in ext)+'\n'+ '\n'.join(resources)+'\n[node name="BlockadeCheckpoint" type="Node3D"]\nscript = ExtResource("district")\nmetadata/map_revision = 2\n\n'+'\n'.join(nodes)
text = re.sub(r'(?<![\w\d])\.(\d)', r'0.\1', text)
(root/'scenes/areas/blockade_checkpoint_v2.tscn').write_text(text,encoding='utf-8')
print('Authored NEW blockade v2:',len(nodes),'nodes,',len(polygons),'navigation polygons')

