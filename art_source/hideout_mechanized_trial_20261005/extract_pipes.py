import bpy,pathlib
from mathutils import Vector
base=pathlib.Path(__file__).parent
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(base/'project/polyhaven/modular_industrial_pipes_01/modular_industrial_pipes_01.gltf'))
out=base/'project'/'pipes';out.mkdir(exist_ok=True)
for o in list(bpy.data.objects):
 if o.type!='MESH':continue
 print('PIPE',o.name,list(o.dimensions),flush=True)
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.export_scene.gltf(filepath=str(out/(o.name+'.glb')),export_format='GLB',use_selection=True)
