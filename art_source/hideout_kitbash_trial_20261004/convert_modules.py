import bpy,pathlib,json,shutil
base=pathlib.Path(__file__).parent
src=base/'source'/'Modular Concrete Interior'
out=base/'project'/'concrete';out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src/'Modular Concrete Interior.blend'))
# Repair the author's stale absolute texture links. Geometry and UVs are untouched.
for m in bpy.data.materials:
 if m.name not in ['Wall','Floor','Metal']:continue
 for n in m.node_tree.nodes:
  if n.type!='TEX_IMAGE':continue
  old=n.image.filepath.lower()
  kind='Normal' if ('nor' in old) else 'Roughness' if 'rough' in old else 'Metallic' if 'metalness' in old else 'Color'
  stem={'Wall':'ConcreteWall','Floor':'ConcreteFloor','Metal':'RustyMetal'}[m.name]
  file=next(src.glob('Assets/Textures/**/'+stem+'_'+kind+'_2k.*'))
  n.image.filepath=str(file);n.image.reload()
  if kind!='Color': n.image.colorspace_settings.name='Non-Color'
 m.use_backface_culling=False
scene=bpy.data.scenes.new('ExportOnly');bpy.context.window.scene=scene
for obj in list(bpy.data.objects):
 if obj.type=='MESH':scene.collection.objects.link(obj);obj.hide_set(False);obj.hide_viewport=False
selected=['Floor','Ceiling','Wall','WallDoorway','Pillar','DoorwayConnector','Stairs']
for name in selected:
 bpy.ops.object.select_all(action='DESELECT')
 obj=bpy.data.objects[name];obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
shutil.copy2(src/'readme.txt',out/'LICENSE.txt')
furniture=base/'furniture_source'
fout=base/'project'/'furniture';fout.mkdir(exist_ok=True)
for name in ['bedSingle','desk','chair','bookcaseOpen','cardboardBoxClosed','cardboardBoxOpen','radio','lampRoundTable','computerScreen','computerKeyboard','kitchenFridgeSmall','rugRectangle','coatRackStanding','trashcan','books','sideTable']:
 shutil.copy2(furniture/'Models'/'GLTF format'/(name+'.glb'),fout/(name+'.glb'))
shutil.copy2(furniture/'License.txt',fout/'LICENSE.txt')
print('EXPORT_COMPLETE',flush=True)

