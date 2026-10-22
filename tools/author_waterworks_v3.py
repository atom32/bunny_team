"""Author the south market and optional repair depot; retain v1/v2 geometry unchanged."""
from pathlib import Path
import json
import math
import re
import struct
import wave

root = Path(__file__).resolve().parents[1]
q = lambda value: json.dumps(value, ensure_ascii=False)
v = lambda value: 'Vector3(' + ', '.join(str(n) for n in value) + ')'
resources, nodes, obstacles = [], [], []
resource_ids = set()

def resource(kind, name, body):
    assert name not in resource_ids, name
    resource_ids.add(name)
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

mats = {n: material(n,c,t) for n,c,t in [('road','0.5,0.5,0.5,1','asphalt'),('brick','0.8,0.77,0.68,1','brick'),('ground','0.34,0.39,0.33,1',None),('steel','0.25,0.34,0.35,1',None),('rust','0.57,0.32,0.21,1',None),('cream','0.83,0.79,0.63,1',None),('water','0.2,0.73,0.83,0.45',None)]}

resources[-1] += 'transparency = 1\n'

def box(name, at, size, mat='steel', collide=False, parent='.'):
    key = (parent+'_'+name).replace('/', '_').replace('.', 'Root').replace('-', 'N')
    mesh = resource('BoxMesh', key+'Mesh', 'size = '+v(size))
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')
    if collide:
        shape = resource('BoxShape3D',key+'Shape','size = '+v(size))
        node(name+'Body','StaticBody3D',parent,f'position = {v(at)}\ncollision_layer = 4\ncollision_mask = 0')
        node('CollisionShape3D','CollisionShape3D',name+'Body' if parent=='.' else parent+'/'+name+'Body',f'shape = {shape}')
        if at[1] - size[1]/2 < 2.0 and at[1]+size[1]/2 > .2:
            obstacles.append((at[0]-size[0]/2,at[2]-size[2]/2,size[0],size[2]))

def cylinder(name, at, radius, height, mat='steel', parent='.'):
    key = (parent+'_'+name).replace('/', '_').replace('.', 'Root').replace('-', 'N')
    mesh = resource('CylinderMesh',key+'Mesh',f'top_radius = {radius}\nbottom_radius = {radius}\nheight = {height}')
    node(name,'MeshInstance3D',parent,f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {mats[mat]}')

def label(name, at, text, parent='.', size=32):
    node(name,'Label3D',parent,f'position = {v(at)}\ntext = {q(text)}\nfont = ExtResource("font")\nfont_size = {size}\npixel_size = 0.008\nbillboard = 1\nno_depth_test = false\noutline_size = 3')

box('Ground',(0,-.25,-6),(96,.5,80),'ground',True)
box('MainStreet',(0,.015,0),(13,.03,65),'road')
box('WestAlley',(-32,.02,-3),(5,.03,70),'road')
box('NorthCrossing',(0,.02,-25),(73,.03,8),'road')
box('LoadingRoad',(34,.02,-34),(8,.03,22),'road')
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
cylinder('TapStream',(-39,.8,-16),.09,1.4,'water','PublicWater')
node('TankerWater')
cylinder('LoadingStream',(35,2,-24),.12,1.2,'water','TankerWater')
cylinder('CourtyardTapStand',(-39,.7,-15.7),.08,1.4,'steel')
box('CourtyardTapNeck',(-39,1.35,-15.85),(.16,.16,.5),'rust')
for i in range(5):cylinder('FilledBucket'+str(i),(-42+i*1.1,.53,-16.5),.27,.015,'water','PublicWater')
for i in range(5):
    cylinder('Bucket'+str(i),(-42+i*1.1,.25,-16.5),.32,.5,'cream')
    cylinder('BucketRim'+str(i),(-42+i*1.1,.52,-16.5),.36,.05,'steel')
# Dynamic truck collider moves with its body; it is not baked into navigation.
node('Tanker','AnimatableBody3D',body='position = Vector3(34,0,-25)\ncollision_layer = 4\ncollision_mask = 0\nsync_to_physics = false\nscript = ExtResource("truck")')
shape=resource('BoxShape3D','TruckCollision','size = Vector3(3.5,4.2,8)')
node('CollisionShape3D','CollisionShape3D','Tanker','position = Vector3(0,2.1,-0.4)\nshape = '+shape)
box('TruckChassis',(0,1,0),(3.1,.65,7),'steel',parent='Tanker')
box('TruckCab',(0,2,-3),(3,2.3,2),'rust',parent='Tanker')
box('TruckWindscreen',(0,2.5,-4.05),(2.3,.8,.08),'steel',parent='Tanker')
cylinder('TruckTank',(0,2.7,1),1.35,4,'cream',parent='Tanker')
nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(90,0,0)\nmesh =')
node('Wheels',parent='Tanker')
for i,(x,z) in enumerate([(-1.6,-2),(1.6,-2),(-1.6,3),(1.6,3)]):
    cylinder('Wheel'+str(i),(x,.65,z),.65,.45,'steel',parent='Tanker/Wheels')
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(0,0,90)\nmesh =')
label('WorldLabel',(0,4.5,0),'WATER TRUCK / HANDBRAKE','Tanker',size=25)
node('Handbrake',parent='Tanker',body='position = Vector3(-1.8,0,0)\nscript = ExtResource("control")\nkind = "handbrake"')
label('WorldLabel',(0,1.5,0),'WATER TRUCK / HANDBRAKE','Tanker/Handbrake',size=18)
for i,(x,z) in enumerate([(-47,-6),(47,-6),(0,-45)]):
    box('Boundary'+str(i),(x,2,z),(1 if x else 96,4,80 if x else 1),'brick',True)
# Courtyard gate and loading gate have explicit links across their baked gaps.
for name,at,size in [('PublicGate',(0,0,0),(.6,2.8,6)),('LoadingGate',(0,0,0),(6,3.4,.6))]:
    node(name)
    loc=(-31,1.4,-18) if name=='PublicGate' else (34,1.7,-34)
    box('Door',loc,size,'rust',True,parent=name)
for name,x,z,sx,sz in [('CourtNorth',-39,-27,16,.6),('CourtSouth',-39,-10,16,.6),('CourtEastN',-31,-24,.6,6),('CourtEastS',-31,-12,.6,6),('LoadingWest',27.5,-34,7,.6),('LoadingEast',42,-34,10,.6)]:
    box(name,(x,1.4,z),(sx,2.8,sz),'brick',True)
for name,start,end in [('PublicLink',(-28,0,-18),(-34,0,-18)),('LoadingLink',(34,0,-31),(34,0,-37))]:
    node(name,'NavigationLink3D',body='enabled = false\nstart_position = '+v(start)+'\nend_position = '+v(end))
for name,at,kind in [('Bypass',(-30,0,-8),'bypass'),('LoadingLever',(28,0,-32),'loading_gate')]:
    node(name,body='position = '+v(at)+'\nscript = ExtResource("control")\nkind = '+q(kind))
    cylinder('Wheel',(0,1,0),.5,.15,'rust',parent=name)
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(90,0,0)\nmesh =')
    label('WorldLabel',(0,2,0),'WEST BYPASS / RELIEVE PRESSURE' if kind=='bypass' else 'RAISE LOADING GATE',name,size=23)
red=material('LatchRed','0.9,0.12,0.08,1')
node('Latch','StaticBody3D',body='position = Vector3(-27,0,-18)\nscript = ExtResource("latch")\nmax_structure_health = 16.0')
shape=resource('BoxShape3D','LatchShape','size = Vector3(0.7,1.3,0.7)')
mesh=resource('BoxMesh','LatchMesh','size = Vector3(0.7,1.3,0.7)')
node('CollisionShape3D','CollisionShape3D','Latch','position = Vector3(0,1.2,0)\nshape = '+shape)
node('BarrierMesh','MeshInstance3D','Latch','position = Vector3(0,1.2,0)\nmesh = '+mesh+'\nmaterial_override = '+red)
label('LatchSign',(-27,2.3,-18),'RED RELIEF LATCH / SHOOT TO RELEASE',size=22)
node('PressureJet',body='visible = false')
box('WetDangerZone',(-25.5,.05,-18),(7,.04,2),'water',parent='PressureJet')
for i in range(5):
    cylinder('Jet'+str(i),(-25.5,.45+i*.12,-18.32+i*.16),.045,6.7,'water',parent='PressureJet')
    nodes[-1]=nodes[-1].replace('mesh =','rotation_degrees = Vector3(0,0,90)\nmesh =')
for i in range(7):box('WarningStripe'+str(i),(-28.5+i,.03,-16.85),(.45,.03,.16),'rust')
label('JetWarning',(-25.5,2.8,-18),'PRESSURE JET / KEEP CLEAR','PressureJet',size=25)
for i,(at,target) in enumerate([((-39,0,-22),(-39,0,-16)),((-42,0,-22),(-40.5,0,-17.5))]):
    node('Resident'+str(i),'CharacterBody3D',body='position = '+v(at)+'\nscript = ExtResource("resident")\ndestination = '+v(target)+'\nmale = '+str(i==1).lower())
    shape=resource('CapsuleShape3D','ResidentShape'+str(i),'radius = 0.28\nheight = 1.7')
    node('CollisionShape3D','CollisionShape3D','Resident'+str(i),'position = Vector3(0,0.85,0)\nshape = '+shape)
    label('WorldLabel',(0,1.95,0),'COURTYARD RESIDENT / ART PLACEHOLDER','Resident'+str(i),size=18)
node('Loudspeaker',body='position = Vector3(-3,0,-7)')
box('SpeakerPole',(-3,2.2,-7),(.16,4.4,.16),'steel',True)
box('SpeakerBox',(-3,4.5,-7),(1.2,.7,.7),'cream')
label('RadioSign',(-3,5.4,-7),'PLEASE WAIT PATIENTLY',size=22)
node('PlayerSpawn','Marker3D',body='position = Vector3(0,0.1,86)\ngroups = ["player_spawn_point"]')
# Groups are node metadata in the section header, not a serialized property.
nodes[-1] = nodes[-1].replace('parent="."]','parent="." groups=["player_spawn_point"]]').replace('\ngroups = ["player_spawn_point"]','')
actions = [('Radio','radio',(0,0,82),'water_briefing','RADIO / TANG KUI'),('Battery','battery',(-26,0,15),'water_battery','TAKE PUMP BATTERY / 8kg'),('Pump','pump',(25,0,-13),'water_pump','INSTALL PUMP BATTERY / 8s'),('Decoy','decoy',(-28,0,3),'water_decoy','SOUND THE SQUARE LOUDSPEAKER / ONCE'),('PublicValve','public',(-20,0,-17),'water_public','INSPECT COURTYARD DELIVERY'),('TankerValve','tanker',(26,0,-26),'water_tanker','INSPECT TANKER DELIVERY')]
for name,kind,at,oid,prompt in actions:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("action")\nkind = {q(kind)}\nobjective_id = &{q(oid)}\ninteraction_prompt = {q(prompt)}')
    box('TerminalPedestal',(0,.45,0),(.8,.9,.6),'steel',parent=name)
    label('WorldLabel',(0,1.8,0),prompt,name,size=25)
    if kind=='battery':
        node('Cargo',parent=name)
        box('BatteryCase',(0,.85,0),(.7,.55,.45),'rust',parent=name+'/Cargo')
        for i,x in enumerate([-.2,.2]): box('Terminal'+str(i),(x,1.15,0),(.1,.1,.15),'cream',parent=name+'/Cargo')
for name,at,oid in [('Retreat',(0,0,92),''),('PublicExit',(-42,0,-24),'water_public'),('TankerExit',(29,0,-40),'water_tanker')]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("exit")\nextraction_id = &{q("water_"+name)}\nrequired_objective_id = &{q(oid)}')
for name,at,table,enabled,rolls in [('PublicReward',(-37,0,-20),'water_public_reward',False,2),('TankerReward',(28,0,-26),'water_tanker_reward',False,1),('GarageLoot',(-29,0,13),'street_repair_loot',True,2),('AlleyMedicine',(-34,0,-14),'street_pharmacy_loot',True,2),('StreetSalvage',(9,0,6),'street_supply_loot',True,2)]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("loot")\nloot_table_id = &{q(table)}\nenabled = {str(enabled).lower()}\nroll_count = {rolls}\nmetadata/campus_storage = 1')
    node('Art',parent=name,body='scale = Vector3(0.7,0.7,0.7)',instance='supply')
for i,(at,enemy,role,yaw) in enumerate([((2,0,9),'prototype_basic_enemy',0,0),((5,0,-10),'prototype_basic_enemy',1,math.pi),((-24,0,-18),'prototype_basic_enemy',1,0),((18,0,-24),'prototype_basic_enemy',2,math.pi),((28,0,-16),'prototype_heavy_enemy',3,math.pi),((-8,0,-18),'campus_infected',3,0),((-33,0,-3),'campus_infected',3,math.pi),((10,0,18),'campus_infected',3,0)]):
    node('Enemy'+str(i),'Marker3D',body=f'position = {v(at)}\nrotation = Vector3(0,{yaw},0)\nscript = ExtResource("enemy")\nenemy_definition_id = &{q(enemy)}\ntactical_role = {role}')
for i,at in enumerate([(7,0,-26),(-9,0,-21)]):
    node('Response'+str(i),'Marker3D',body='position = '+v(at)+'\nscript = ExtResource("enemy")\nenemy_definition_id = &"prototype_basic_enemy"\ninitial_spawn = false\nactivation_group_id = &"water_choice"')
# South market: two readable lanes, different sight lines, optional noisy depot.
box('MarketGround',(0,-.25,65),(96,.5,62),'ground',True)
box('MarketEastRoad',(17,.02,63),(9,.04,60),'road')
box('MarketWestRoad',(-27,.02,63),(9,.04,60),'road')
box('MarketSouthCross',(0,.025,84),(86,.05,9),'road')
box('MarketNorthCross',(0,.025,39),(86,.05,10),'road')
box('MarketSouthBoundary',(0,2,96),(96,4,1),'brick',True)
for x in [-47,47]:box('MarketSideBoundary'+str(x).replace('-','N'),(x,2,65),(1,4,62),'brick',True)
box('ClosedMarketShops',(-3,2.5,61),(27,5,30),'brick',True)
box('MarketShopRoof',(-3,5.08,61),(29,.15,32),'rust')
label('MarketSign',(-3,5.5,78),'SOUTH MARKET / WATER TOWER NORTH',size=38)
for i in range(6):
    box('ShopShutter'+str(i),(-14+i*4.4,1.6,76.1),(3.2,3.1,.09),'steel')
    box('ShopLintel'+str(i),(-14+i*4.4,3.6,76.3),(3.9,.3,.6),'cream')
for i,z in enumerate([76,63,48]):
    box('WestStall'+str(i),(-37,1,z),(6,2,6),'rust',True)
    box('StallAwning'+str(i),(-33.7,2.5,z),(9,.12,6.5),'cream')
    cylinder('StallPost'+str(i),(-29.3,1.2,z+2.8),.08,2.4,'steel')
for i,(x,z,sx,sz) in enumerate([(16,72,3,1),(17,54,3,1),(-24,73,1,4),(-24,53,1,4),(7,84,3,1),(29,42,3,1)]):
    box('MarketCover'+str(i),(x,.65,z),(sx,1.3,sz),'cream',True)
# Depot west entrance and north exit are gaps crossed only by explicit nav links.
for name,at,size in [('DepotSouth',(33,1.8,79),(22,3.6,.5)),('DepotEast',(44,1.8,65),(.5,3.6,28)),('DepotNorthL',(25,1.8,51),(6,3.6,.5)),('DepotNorthR',(40,1.8,51),(8,3.6,.5)),('DepotWestS',(22,1.8,74),(.5,3.6,10)),('DepotWestN',(22,1.8,57),(.5,3.6,12))]:
    box(name,at,size,'brick',True)
box('DepotFloor',(33,.03,65),(22,.06,28),'cream')
node('Market',body='script = ExtResource("market")')
node('FrontGate',parent='Market')
box('Door',(22,1.5,66),(.5,3,6),'steel',True,parent='Market/FrontGate')
node('NorthGate',parent='Market')
box('Door',(32,1.5,51),(8,3,.5),'rust',True,parent='Market/NorthGate')
for name,start,end in [('FrontLink',(19,0,66),(25,0,66)),('NorthLink',(32,0,54),(32,0,48))]:
    node(name,'NavigationLink3D','Market',body='enabled = false\nstart_position = '+v(start)+'\nend_position = '+v(end))
node('BellLight',parent='Market',body='visible = false')
box('AlarmLamp',(22,3.7,66),(.45,.4,.6),'rust',parent='Market/BellLight')
node('BreakerHandle',parent='Market',body='position = Vector3(-31,1.25,57)')
box('Handle',(0,0,0),(.15,.55,.15),'rust',parent='Market/BreakerHandle')
# Visible cable route makes the quiet option discoverable before committing.
box('BellCableWest',(-31,.08,48),(.09,.08,18),'rust')
box('BellCableAcross',(-5.5,.08,39),(51,.08,.09),'rust')
box('BellCableEast',(20,.08,52.5),(.09,.08,27),'rust')
box('BellCableDoor',(21,.08,66),(2,.08,.09),'rust')
for name,at,kind,prompt in [('MarketNotice',(0,0,78),'notice','MARKET ROUTES / OPTIONAL DEPOT'),('MarketBreaker',(-31,0,57),'breaker','WEST STALLS / DEPOT BELL WIRE'),('MarketShutter',(19.5,0,69),'shutter','OPTIONAL DEPOT / 6kg SALVAGE'),('MarketBackBar',(32,0,54),'back_bar','NORTH BAR / OPEN FROM INSIDE')]:
    node(name,body='position = '+v(at)+'\nscript = ExtResource("market_control")\nkind = '+q(kind))
    box('ControlBox',(0,.6,0),(.65,1.2,.5),'steel',parent=name)
    label('WorldLabel',(0,2.2,0),prompt,name,size=21)
label('WestLaneSign',(-27,3.2,81),'WEST / STALL COVER / BELL WIRE',size=25)
label('EastLaneSign',(17,3.2,81),'EAST / OPEN ROAD / REPAIR DEPOT',size=25)
for name,at,table,enabled,rolls in [('MarketMedicine',(-35,0,46),'street_pharmacy_loot',True,2),('MarketStreetLoot',(17,0,43),'street_supply_loot',True,2),('DepotCore',(39,0,71),'prototype_high_value_loot',False,1),('DepotParts',(38,0,58),'street_repair_loot',False,2)]:
    node(name,body='position = '+v(at)+'\nscript = ExtResource("loot")\nloot_table_id = &'+q(table)+'\nenabled = '+str(enabled).lower()+'\nroll_count = '+str(rolls)+'\nmetadata/campus_storage = 1')
    node('Art',parent=name,body='scale = Vector3(0.7,0.7,0.7)',instance='supply')
label('DepotCoreSign',(39,2,71),'SALVAGE CORE / 6kg / OPTIONAL',size=22)
# Real workbench cover splits the depot's sight lines; shelf/rivet details do not
# alter navigation. It is still one optional room, not a new quest or a loot roll.
for name,at,size in [('DepotWorkbench',(31,0.65,65),(4,1.3,1.4)),('DepotToolRack',(28,1.1,76),(8,2.2,.8)),('DepotPartsBench',(39,.65,61),(6,1.3,1.2))]:
    box(name,at,size,'steel',True)
    box(name+'Top',(at[0],at[1]+size[1]/2+.03,at[2]),(size[0]+.12,.06,size[2]+.12),'rust')
for i in range(5):
    box('DepotLockerLine'+str(i),(25+i*1.5,1.2,75.55),(.04,1.8,.03),'cream')
    box('DepotLockerHandle'+str(i),(25.5+i*1.5,1.4,75.5),(.07,.35,.04),'rust')
for i,z in enumerate(range(54,79,3)):box('DepotFloorSeam'+str(i),(33,.065,z),(21,.008,.035),'steel')
for i,x in enumerate(range(24,44,3)):box('DepotFloorJoin'+str(i),(x,.065,65),(.035,.008,27),'steel')
# New decision signs must be readable in the ordinary combat camera.
for i,chunk in enumerate(nodes):
    if 'type="Label3D"' in chunk and any('name="'+name+'"' in chunk or 'parent="'+name+'"' in chunk for name in ['MarketNotice','MarketBreaker','MarketShutter','MarketBackBar','MarketSign','WestLaneSign','EastLaneSign','DepotCoreSign']):
        nodes[i]=re.sub(r'font_size = \d+', 'font_size = 30', chunk).replace('pixel_size = 0.008','pixel_size = 0.016')

for i,(at,enemy,role) in enumerate([((17,0,78),'prototype_basic_enemy',1),((17,0,48),'prototype_basic_enemy',2),((-27,0,70),'campus_infected',3),((-29,0,46),'campus_infected',3),((3,0,39),'prototype_basic_enemy',0)]):
    node('MarketEnemy'+str(i),'Marker3D',body='position = '+v(at)+'\nscript = ExtResource("enemy")\nenemy_definition_id = &'+q(enemy)+'\ntactical_role = '+str(role))
for i,at in enumerate([(29,0,37),(38,0,42)]):
    node('MarketResponse'+str(i),'Marker3D',body='position = '+v(at)+'\nscript = ExtResource("enemy")\nenemy_definition_id = &"prototype_basic_enemy"\ninitial_spawn = false\nactivation_group_id = &"water_market_alarm"')
# Fixed native nav grid, omitting collision footprints with capsule clearance.
vertices=[]; polygons=[]; lookup={}
def vertex(x,z):
    key=(x,z)
    if key not in lookup: lookup[key]=len(vertices); vertices.append((x,0,z))
    return lookup[key]
for x in range(-46,46):
    for z in range(-44,95):
        if any(ox-.95 <= x+.5 <= ox+sx+.95 and oz-.95 <= z+.5 <= oz+sz+.95 for ox,oz,sx,sz in obstacles): continue
        polygons.append([vertex(x,z),vertex(x,z+1),vertex(x+1,z+1),vertex(x+1,z)])
nav=resource('NavigationMesh','Navigation', 'vertices = PackedVector3Array('+','.join(','.join(map(str,p)) for p in vertices)+')\npolygons = Array[PackedInt32Array](['+','.join('PackedInt32Array('+','.join(map(str,p))+')' for p in polygons)+'])\nagent_radius = 0.6')
node('StreetNavigation','NavigationRegion3D',body='navigation_mesh = '+nav)
environment=resource('Environment','Dawn','background_mode = 1\nbackground_color = Color(0.31,0.41,0.44,1)\nambient_light_source = 2\nambient_light_color = Color(0.77,0.83,0.87,1)\nambient_light_energy = 0.7\ntonemap_mode = 4')
node('Environment','WorldEnvironment',body='environment = '+environment)
node('Sun','DirectionalLight3D',body='rotation_degrees = Vector3(-58,-25,0)\nlight_color = Color(1,0.85,0.67,1)\nlight_energy = 1.2\nshadow_enabled = true')
ext=[('Script','truck','scripts/world/waterworks/tanker.gd'),('Script','control','scripts/world/waterworks/delivery_control.gd'),('Script','latch','scripts/world/waterworks/public_latch.gd'),('Script','resident','scripts/world/waterworks/resident.gd'),('Script','district','scripts/world/waterworks/market_district.gd'),('Script','market','scripts/world/waterworks/market.gd'),('Script','market_control','scripts/world/waterworks/market_control.gd'),('Script','action','scripts/world/waterworks/waterworks_action.gd'),('Script','exit','scripts/world/waterworks/waterworks_exit.gd'),('Script','enemy','scripts/world/enemy_spawn_point.gd'),('Script','loot','scripts/world/loot_spawn_point.gd'),('FontFile','font','assets/fonts/NotoSansSC-Regular.ttf'),('Texture2D','asphalt','assets/environment/polyhaven_streets/asphalt_02_diff_1k.jpg'),('Texture2D','brick','assets/environment/polyhaven_streets/wall_bricks_plaster_diff_1k.jpg'),('PackedScene','supply','assets/environment/service_props/supply_stack.glb')]
# Match the existing project's actual font, without creating a second font asset.
font_files=list((root/'assets').rglob('*.ttf'))+list((root/'assets').rglob('*.otf'))
assert font_files
ext=[(t,n,font_files[0].relative_to(root).as_posix() if n=='font' else p) for t,n,p in ext]
dest=root/'scenes/areas/waterworks_district_v3.tscn'; dest.parent.mkdir(parents=True,exist_ok=True)
dest.write_text('[gd_scene format=3]\n'+''.join(f'[ext_resource type="{t}" path="res://{p}" id="{n}"]\n' for t,n,p in ext)+'\n'+'\n'.join(resources)+'\n[node name="WaterworksDistrict" type="Node3D"]\nscript = ExtResource("district")\nmetadata/map_revision = 3\n\n'+'\n'.join(nodes),encoding='utf-8')
print('Authored',dest,'nav polygons',len(polygons))

