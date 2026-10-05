import bpy,pathlib
from mathutils import Vector
b=pathlib.Path(__file__).parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(b/'project/polyhaven/modular_electric_cables/modular_electric_cables.gltf'))
out=pathlib.Path(r'D:/bunny_team/assets/environment/compact_hideout/cables');out.mkdir(exist_ok=True)
for name in ['cable_straight_medium','cable_turn_short','cable_box_turn','cable_plug_covered','cable_lightswitch']:
 o=bpy.data.objects[name]
 print('CABLE',name,list(o.dimensions),flush=True)
 pts=[o.matrix_world@Vector(v) for v in o.bound_box]
 center=Vector(((min(p.x for p in pts)+max(p.x for p in pts))/2,(min(p.y for p in pts)+max(p.y for p in pts))/2,(min(p.z for p in pts)+max(p.z for p in pts))/2))
 o.location-=center
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',use_selection=True)
