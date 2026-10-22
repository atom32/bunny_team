"""Author the maintenance chapter's second room, not a new campaign region.

Only new core resources are generated. All previous areas remain byte-identical.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
q = lambda s: json.dumps(s, ensure_ascii=False)
v = lambda p: 'Vector3(' + ','.join(map(str, p)) + ')'
resources, nodes, obstacles = [], [], []

def res(kind, name, body):
    resources.append(f'[sub_resource type="{kind}" id="{name}"]\n{body}\n')
    return f'SubResource("{name}")'

def node(name, kind='Node3D', parent='.', body=''):
    group = ' groups=["camera_occluder"]' if kind == 'MeshInstance3D' else ''
    if name == 'PlayerSpawn': group = ' groups=["player_spawn_point"]'
    nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"{group}]\n{body}\n')

materials = {}
for name, color in [('floor', '.3,.32,.31,1'), ('wall', '.68,.68,.6,1'),
                    ('steel', '.25,.3,.31,1'), ('paint', '.94,.72,.3,1'),
                    ('green', '.2,.95,.57,1'), ('amber', '1,.55,.06,1'),
                    ('blue', '.25,.7,1,1'), ('arc', '1,.92,.75,1')]:
    extra = '\nshading_mode = 0' if name in ('green', 'amber', 'blue', 'arc') else ''
    materials[name] = res('StandardMaterial3D', 'mat_' + name,
                          'albedo_color = Color(' + color + ')\nroughness = 0.8' + extra)

def box(name, at, size, mat='steel', collide=False, parent='.', nav=True):
    mesh = res('BoxMesh', name + 'Mesh', 'size = ' + v(size))
    node(name, 'MeshInstance3D', parent, f'position = {v(at)}\nmesh = {mesh}\nmaterial_override = {materials[mat]}')
    if collide:
        shape = res('BoxShape3D', name + 'Shape', 'size = ' + v(size))
        node(name + 'Body', 'StaticBody3D', parent, f'position = {v(at)}\ncollision_layer = 4\ncollision_mask = 0')
        node('CollisionShape3D', 'CollisionShape3D', name + 'Body', 'shape = ' + shape)
        if nav: obstacles.append((at[0]-size[0]/2, at[2]-size[2]/2, size[0], size[2]))

def label(name, at, text, parent='.', size=26):
    node(name, 'Label3D', parent, f'position = {v(at)}\ntext = {q(text)}\nfont = ExtResource("font")\nfont_size = {size}\npixel_size = 0.007\nbillboard = 1\noutline_size = 3')

box('Ground', (0,-.25,-4), (42,.5,62), 'floor', True, nav=False)
for i, (at, size) in enumerate([((-21,1.8,-4),(.8,3.6,62)), ((21,1.8,-4),(.8,3.6,62)),
                              ((0,1.8,27),(42,3.6,.8)), ((0,1.8,-35),(42,3.6,.8)),
                              ((-12,1.8,-28),(18,3.6,.6)), ((12,1.8,-28),(18,3.6,.6))]):
    box('Wall'+str(i), at, size, 'wall', True)
# Covers sit BETWEEN the marked arc lanes, leaving both outer aisles passable.
for i, (x,z) in enumerate([(-4,0),(4,-6),(-4,-12),(4,-20),(-15,18),(15,12)]):
    box('Cover'+str(i), (x,.65,z), (1.5,1.3,3), 'steel', True)
for lane, x in enumerate([-8,0,8]):
    for z in range(-23,7,4):
        box('Lane'+str(lane)+'Mark'+str(z).replace('-','N'),(x,.012,z),(4.8,.024,.16),'paint')
    label('LaneSign'+str(lane),(x,2.3,7),['LEFT','MIDDLE','RIGHT'][lane],size=24)
for name, at, oid, prompt in [
    ('Radio',(3,0,22),'core_radio','LISTEN / THE LAST CLICK'),
    ('Bridge',(0,0,12),'core_shelter_bridge','KEEP L-02A / CONNECT SHELTER BRIDGE'),
    ('LeftFeed',(-14,0,-9),'core_left_feed','ISOLATE LEFT BATTERY FEED'),
    ('RightFeed',(14,0,-19),'core_right_feed','ISOLATE RIGHT BATTERY FEED'),
    ('MasterStop',(0,0,-25),'core_shutdown','MASTER STOP / NO RESTART')]:
    node(name, body=f'position = {v(at)}\nscript = ExtResource("control")\nobjective_id = &{q(oid)}\ninteraction_prompt = {q(prompt)}')
    box('TerminalPedestal',(0,.55,0),(.8,1.1,.5),parent=name)
    box('Handle',(0,1.15,0),(.8,.14,.14),'paint',parent=name)
    label('WorldLabel',(0,1.9,0),prompt,name,size=21)
node('ShelterBridge',body='position = Vector3(0,0,15)')
box('BridgeArm',(0,.8,0),(.35,.3,6),'green',parent='ShelterBridge')
box('ShelterLamp',(-15,1.9,12),(1,.6,.4),'green')
label('ShelterSign',(-15,2.8,12),'L-02A / SHELTER / KEEP ON',size=24)
box('BackupLamp',(0,3,-29),(2,.5,.4),'amber')
label('CoreSign',(0,3.8,-29),'BACKUP CORE / TEST EQUIPMENT',size=24)
node('Sweep',body='script = ExtResource("sweep")')
box('WarningLane',(0,.035,-9),(5,.025,30),'amber',parent='Sweep')
box('LiveBar',(0,.16,6),(5,.2,.3),'arc',parent='Sweep')
box('CoolingLamp',(0,3.4,-26),(1,.3,.3),'blue',parent='Sweep')
box('Rotor',(0,1.6,-30),(5,.25,1),'steel',parent='Sweep')
label('WorldLabel',(0,4.3,-24),'CORE STARTING','Sweep',size=30)
shape = res('BoxShape3D','NorthGateShape','size = Vector3(6,3.6,.6)')
node('NorthGate','StaticBody3D',body='position = Vector3(0,0,-28)\ncollision_layer = 4\ncollision_mask = 0')
node('CollisionShape3D','CollisionShape3D','NorthGate','position = Vector3(0,1.8,0)\nshape = '+shape)
box('NorthPanel',(0,1.8,0),(6,3.6,.6),'steel',parent='NorthGate')
obstacles.append((-3,-29,6,2))
node('NorthLink','NavigationLink3D',body='enabled = false\nstart_position = Vector3(0,0,-25)\nend_position = Vector3(0,0,-31)')
node('PlayerSpawn','Marker3D',body='position = Vector3(0,0,24)')
for name, at, required in [('Retreat',(0,0,24),''),('NorthExit',(0,0,-32),'core_shutdown')]:
    node(name,body=f'position = {v(at)}\nscript = ExtResource("exit")\nextraction_id = &{q("core_"+name)}\nrequired_objective_id = &{q(required)}')
for i,(at,kind,group) in enumerate([
    ((-13,0,17),'prototype_basic_enemy',''), ((12,0,5),'campus_infected',''),
    ((-15,0,-14),'campus_infected',''), ((14,0,-24),'prototype_basic_enemy',''),
    ((-16,0,-19),'campus_infected','core_response'), ((16,0,-8),'campus_infected','core_response'),
    ((-6,0,-32),'prototype_heavy_enemy','core_final'), ((6,0,-31),'prototype_basic_enemy','core_final')]):
    node('Enemy'+str(i),'Marker3D',body=f'position = {v(at)}\nscript = ExtResource("enemy")\nenemy_definition_id = &{q(kind)}\ninitial_spawn = {str(not group).lower()}\nactivation_group_id = &{q(group)}')
node('Supplies',body='position = Vector3(-17,0,22)\nscript = ExtResource("loot")\nloot_table_id = &"street_pharmacy_loot"\nroll_count = 2')
vertices,polygons,lookup=[],[],{}
def vertex(x,z):
    key=(x,z)
    if key not in lookup:lookup[key]=len(vertices);vertices.append((x,0,z))
    return lookup[key]
for x in range(-20,20):
    for z in range(-34,26):
        if any(x+1>ox-.4 and x<ox+sx+.4 and z+1>oz-.4 and z<oz+sz+.4 for ox,oz,sx,sz in obstacles):continue
        polygons.append([vertex(x,z),vertex(x,z+1),vertex(x+1,z+1),vertex(x+1,z)])
nav=res('NavigationMesh','CoreNav','vertices = PackedVector3Array('+','.join(','.join(map(str,p)) for p in vertices)+')\npolygons = Array[PackedInt32Array](['+','.join('PackedInt32Array('+','.join(map(str,p))+')' for p in polygons)+'])\nagent_radius = 0.4')
node('Navigation','NavigationRegion3D',body='navigation_mesh = '+nav)
env=res('Environment','Interior','background_mode = 1\nbackground_color = Color(.12,.14,.15,1)\nambient_light_source = 2\nambient_light_color = Color(.8,.83,.8,1)\nambient_light_energy = .8\ntonemap_mode = 4')
node('Environment','WorldEnvironment',body='environment = '+env)
node('Light','DirectionalLight3D',body='rotation_degrees = Vector3(-70,-20,0)\nlight_energy = 0.85\nshadow_enabled = true')
ext=[('Script','area','scripts/world/finale/core_area.gd'),('Script','control','scripts/world/finale/core_control.gd'),
     ('Script','sweep','scripts/world/finale/arc_sweep.gd'),('Script','exit','scripts/world/finale/core_exit.gd'),
     ('Script','enemy','scripts/world/enemy_spawn_point.gd'),('Script','loot','scripts/world/loot_spawn_point.gd'),
     ('FontFile','font','assets/fonts/noto_sans_sc/NotoSansSC.ttf')]
scene='[gd_scene format=3]\n'+''.join(f'[ext_resource type="{t}" path="res://{p}" id="{n}"]\n' for t,n,p in ext)+'\n'+'\n'.join(resources)+'\n[node name="MaintenanceCore" type="Node3D"]\nscript = ExtResource("area")\nmetadata/map_revision = 1\n\n'+'\n'.join(nodes)
scene=re.sub(r'(?<![\w\d])\.(\d)',r'0.\1',scene)
(ROOT/'scenes/areas/maintenance_core.tscn').write_text(scene,encoding='utf-8')
mission='[gd_resource type="Resource" script_class="MissionDefinition" format=3]\n[ext_resource type="Script" path="res://scripts/data/mission_definition.gd" id="1"]\n[ext_resource type="Script" path="res://scripts/data/objective_definition.gd" id="2"]\n'
for i,(oid,title) in enumerate([('core_shelter_bridge','Keep L-02A shelter power'),('core_left_feed','Isolate left battery feed'),('core_right_feed','Isolate right battery feed'),('core_shutdown','Stop the backup core')]):
    mission+=f'[sub_resource type="Resource" id="O{i}"]\nscript = ExtResource("2")\nobjective_id = &{q(oid)}\ndisplay_name = {q(title)}\nobjective_type = 1\ntarget_id = &{q(oid)}\nrequired = {str(i==3).lower()}\n'
mission+='[resource]\nscript = ExtResource("1")\nmission_id = &"maintenance_shutdown"\ndisplay_name = "Backup Power / The Last Click"\ndescription = "Keep the shelter bridge on. Move out of amber lanes; the white bar is a live discharge. Use blue cooling windows to isolate both side feeds, then the north master stop. South retreat stays open."\nobjective_definitions = Array[ExtResource("2")](['+','.join(f'SubResource("O{i}")' for i in range(4))+'])\n'
(ROOT/'resources/missions/maintenance_shutdown.tres').write_text(mission,encoding='utf-8')
(ROOT/'resources/areas/maintenance_core.tres').write_text('[gd_resource type="Resource" script_class="AreaDefinition" format=3]\n[ext_resource type="Script" path="res://scripts/data/area_definition.gd" id="1"]\n[ext_resource type="PackedScene" path="res://scenes/areas/maintenance_core.tscn" id="2"]\n[resource]\nscript = ExtResource("1")\nid = &"maintenance_core"\ndisplay_name = "Sealed Maintenance / Backup Power Room"\nscene = ExtResource("2")\n',encoding='utf-8')
p=ROOT/'resources/content/content_manifest.tres';s=p.read_text(encoding='utf-8')
if 'id="core_area"' not in s:
    i=s.index('[resource]');s=s[:i]+'[ext_resource type="Resource" path="res://resources/areas/maintenance_core.tres" id="core_area"]\n[ext_resource type="Resource" path="res://resources/missions/maintenance_shutdown.tres" id="core_mission"]\n\n'+s[i:]
    for field,key in [('areas','core_area'),('missions','core_mission')]:
        s=re.sub(r'^('+field+r' = .*?)(\]\))$',lambda m:m[1]+', ExtResource("'+key+'")'+m[2],s,flags=re.M)
    p.write_text(s,encoding='utf-8')
print('Authored backup-core finale:',len(nodes),'nodes,',len(polygons),'navigation polygons')
