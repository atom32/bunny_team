"""Author a fixed, editable off-duty gym scene. Only environment geometry is generated."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
resources = []
nodes = ['[node name="TrainingEnvironment" type="Node3D"]']


def resource(kind, **values):
    key = str(len(resources) + 1)
    resources.append(f'[sub_resource type="{kind}" id="{key}"]\n' + '\n'.join(f'{k} = {v}' for k, v in values.items()))
    return f'SubResource("{key}")'


def vec(values):
    return 'Vector3(' + ', '.join(str(v) for v in values) + ')'


def node(name, kind, parent='.', **values):
    name = name.replace('.', 'p')
    nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n' + '\n'.join(f'{k} = {v}' for k, v in values.items()))


materials = {name: resource('StandardMaterial3D', albedo_color=f'Color({rgb}, 1)', roughness='0.78') for name, rgb in {
    'floor': '.17,.21,.22', 'wall': '.66,.69,.63', 'teal': '.18,.37,.36', 'mat': '.55,.25,.18',
    'rubber': '.045,.061,.065', 'metal': '.25,.31,.32', 'edge': '.63,.69,.68', 'wood': '.44,.28,.16',
    'accent': '.84,.65,.30', 'white': '.83,.85,.77', 'screen': '.08,.22,.21',
}.items()}


def box(name, size, position, material, parent='.'):
    mesh = resource('BoxMesh', size=vec(size), material=materials[material])
    node(name, 'MeshInstance3D', parent, position=vec(position), mesh=mesh)


def rod(name, radius, height, position, material, rotation=None, parent='.'):
    mesh = resource('CylinderMesh', top_radius=str(radius), bottom_radius=str(radius), height=str(height), radial_segments='20', material=materials[material])
    props = dict(position=vec(position), mesh=mesh)
    if rotation: props['rotation'] = vec(rotation)
    node(name, 'MeshInstance3D', parent, **props)


box('Floor', (17, .16, 17), (0, -.08, 0), 'floor')
box('BackWall', (17, 3.6, .18), (0, 1.8, -7), 'wall')
box('WallStripe', (17, .65, .04), (0, .5, -6.89), 'teal')
for x in [-8.4, 8.4]:
    box('SideWall' + str(x), (.16, 3.6, 16), (x, 1.8, 0), 'wall')
for x in [-4.5, -1.5, 1.5, 4.5]:
    box('WindowFrame' + str(x), (2.4, 1.55, .08), (x, 2.35, -6.85), 'metal')
    box('Window' + str(x), (2.22, 1.37, .09), (x, 2.35, -6.79), 'teal')
    box('WindowBar' + str(x), (.045, 1.4, .03), (x, 2.35, -6.72), 'edge')
for x in [-4.5, 0, 4.5]:
    box('CeilingBeam' + str(x), (.14, .14, 10), (x, 3.55, 0), 'metal')
    box('LightHousing' + str(x), (1.8, .12, .38), (x, 3.38, -.2), 'edge')
    box('LightPanel' + str(x), (1.65, .02, .28), (x, 3.3, -.2), 'white')
box('Mat', (1.8, .04, 2.6), (-2.5, .0, 0), 'mat')
for x in [-3.25, -1.75]: box('MatEdge' + str(x), (.025, .003, 2.4), (x, .021, 0), 'accent')
node('Equipment', 'Node3D')
node('Treadmill', 'Node3D', 'Equipment')
treadmill = 'Equipment/Treadmill'
box('Deck', (1.16, .16, 2.3), (0, .08, 0), 'metal', treadmill)
box('Belt', (.85, .02, 1.9), (0, .151, -.02), 'rubber', treadmill)
for x in [-.54, .54]:
    box('SideFootrest' + str(x), (.16, .03, 2.12), (x, .17, 0), 'edge', treadmill)
    rod('Upright' + str(x), .045, 1.02, (x, .67, .85), 'metal', parent=treadmill)
    rod('Rail' + str(x), .035, 1.3, (x, .93, .23), 'edge', (1.5707963, 0, 0), treadmill)
box('Console', (1.08, .18, .3), (0, 1.22, .85), 'metal', treadmill)
box('ConsoleScreen', (.37, .10, .015), (0, 1.245, .69), 'screen', treadmill)
for x in [-.36, .35]: box('ConsoleButton' + str(x), (.09, .06, .02), (x, 1.23, .69), 'accent', treadmill)
# A broad shallow rear ramp aligns the imported walking clip with the elevated belt.
ramp = resource('BoxMesh', size='Vector3(1.15, 0.035, 0.65)', material=materials['metal'])
node('RearRamp', 'MeshInstance3D', treadmill, position='Vector3(0, 0.068, -1.43)', rotation='Vector3(-0.245, 0, 0)', mesh=ramp)
node('BeltMarks', 'Node3D', treadmill)
for i in range(6): box('Stripe' + str(i), (.75, .002, .025), (0, .163, -.9 + i * .3), 'metal', treadmill + '/BeltMarks')
box('BenchSeat', (1.25, .12, .65), (2.5, .42, -.24), 'rubber')
box('BenchTrim', (1.28, .035, .68), (2.5, .35, -.24), 'accent')
for x in [2.05, 2.95]:
    box('BenchLeg' + str(x), (.09, .34, .45), (x, .17, -.24), 'metal')
    box('BenchFoot' + str(x), (.25, .04, .65), (x, .02, -.24), 'edge')
box('Locker', (1.4, 1.9, .55), (4.6, .95, -3.5), 'teal')
for x in [4.25, 4.95]:
    box('LockerDoor' + str(x), (.65, 1.82, .035), (x, .97, -3.2), 'metal')
    box('LockerHandle' + str(x), (.035, .18, .035), (x + .2, 1.05, -3.16), 'accent')
    for y in [1.65, 1.7, 1.75]: box('Vent' + str(x) + str(y), (.38, .014, .02), (x, y, -3.17), 'rubber')
box('Shelf', (2.1, .08, .6), (-4.3, .8, -3.6), 'wood')
for x in [-5.1, -3.5]: box('ShelfLeg' + str(x), (.08, .8, .5), (x, .4, -3.6), 'metal')
for x in [-4.9, -4.3, -3.7]:
    rod('DumbbellGrip' + str(x), .035, .46, (x, .96, -3.55), 'edge', (0, 0, 1.5707963))
    for side in [-1, 1]: rod('DumbbellEnd' + str(x) + str(side), .13, .1, (x + side * .21, .96, -3.55), 'rubber', (0, 0, 1.5707963))
env = resource('Environment', background_mode='1', background_color='Color(.14,.18,.2,1)', ambient_light_source='2', ambient_light_color='Color(.79,.86,.92,1)', ambient_light_energy='.65', tonemap_mode='2', reflected_light_source='2')
node('WorldEnvironment', 'WorldEnvironment', environment=env)
node('KeyLight', 'DirectionalLight3D', rotation='Vector3(-.9,-.4,0)', light_color='Color(1,.91,.78,1)', light_energy='1.15', shadow_enabled='true', directional_shadow_max_distance='24.0')
for x in [-3, 2.5]:
    node('Fill' + str(x), 'OmniLight3D', position=vec((x, 2.7, 1.0)), light_color='Color(.76,.87,1,1)', light_energy='1.8', omni_range='6.0')

target = ROOT / 'scenes/presentation/training/environment.tscn'
target.parent.mkdir(parents=True, exist_ok=True)
text = f'[gd_scene load_steps={len(resources)+1} format=3]\n\n' + '\n\n'.join(resources + nodes) + '\n'
text = re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text)
target.write_text(text, encoding='utf-8')
print(f'Authored {len(nodes)} fixed environment nodes: {target}')
