"""One-off authoring of three fixed assemblies. No runtime asset generation."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
D=Path(__file__).resolve().parent;R=D.parents[1];OUT=R/'assets/environment/service_props';OUT.mkdir(parents=True,exist_ok=True)
rows=[]
def mat(name,c,metal=0.0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.8;p.inputs['Metallic'].default_value=metal;p.inputs['Specular IOR Level'].default_value=.2
 return m
def box(name,size,xyz,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);return o
def source(name,xyz,scale=1,rz=0):
 before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=str(R/'assets/environment/kenney_space_station_kit'/(name+'.glb')))
 objects=[o for o in bpy.context.scene.objects if o not in before];meshes=[o for o in objects if o.type=='MESH']
 for o in meshes:
  world=o.matrix_world.copy();o.parent=None;o.matrix_world=world
  o.matrix_world=Matrix.Translation(Vector(xyz))@Matrix.Rotation(rz,4,'Z')@Matrix.Scale(scale,4)@o.matrix_world
  o.name=name.replace('-','_')+'_'+str(len(bpy.context.scene.objects))
  for m in o.data.materials:
   if m.use_nodes:
    p=m.node_tree.nodes.get('Principled BSDF')
    if p:
     m['GodotBaseColorFactor']=[.26,.30,.32,1]
     p.inputs['Roughness'].default_value=.82;p.inputs['Metallic'].default_value=.05;p.inputs['Specular IOR Level'].default_value=.15
     base=p.inputs['Base Color']
     if base.is_linked:
      socket=base.links[0].from_socket
      mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.26,.30,.32,1)
      m.node_tree.links.new(socket,mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],base)
 for o in objects:
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
for asset in ['supply_stack','service_cabinet','pipe_rack']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
 frame=mat('PaintedGraphite',(.11,.17,.18),.15);accent=mat('SafetyOchre',(.47,.30,.12));panel=mat('MutedTeal',(.18,.31,.32),.05)
 if asset=='supply_stack':
  box('SkidBase',(1.6,1.35,.1),(0,0,.05),frame)
  source('container-flat',(-.4,0,.10));source('container-flat',(-.4,0,.70));source('container-tall',(.37,0,.10))
  box('LoadID',(0.32,.035,.13),(.42,-.315,.7),accent)
 elif asset=='service_cabinet':
  box('Plinth',(1.05,.8,.12),(0,0,.06),frame)
  box('CabinetLower',(.94,.72,.76),(0,0,.50),panel)
  source('computer-system',(0,0,.90),1.08)
  box('AccessPanel',(.66,.018,.50),(0,-.37,.48),frame)
  for x in [-.24,-.08,.08,.24]:box('Louvre',(.06,.025,.33),(x,-.39,.49),panel)
  box('IdentificationBand',(.73,.025,.065),(0,-.393,.82),accent)
  source('wall-switch',(.32,-.407,.42))
 else:
  box('Footplate',(1.6,.72,.1),(0,0,.05),frame)
  for x in [-.69,.69]:box('Upright',(.075,.075,1.75),(x,.23,.925),frame)
  for z in [.28,1.12,1.76]:box('Crossmember',(1.44,.075,.075),(0,.23,z),panel)
  for x in [-.44,0,.44]:
   for z in [.1,.6,1.1]:source('pipe',(x,0,z))
   source('pipe-bend',(x,0,1.60),1,math.pi/2)
  box('ServiceID',(.42,.05,.16),(0,-.19,.48),accent)
 # Bake transforms into static geometry; all exported object roots identity.
 meshes=[o for o in scene.objects if o.type=='MESH']
 bpy.context.view_layer.update()
 for o in meshes:
  o.data.transform(o.matrix_world);o.matrix_world=Matrix.Identity(4);o.data.update()
  o.data.calc_loop_triangles()
 bpy.context.view_layer.update()
 points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
 lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
 # Shared palette material references across imported copies.
 canonical={}
 for o in meshes:
  for i,m in enumerate(o.data.materials):
   key=m.name.split('.')[0]
   if key in canonical:o.data.materials[i]=canonical[key]
   else:canonical[key]=m
 for o in scene.objects:o.select_set(o.type=='MESH')
 scene['Source']='Existing Kenney Space Station Kit subset; source files immutable'
 scene['AssetId']=asset;scene['Forward']='Front Blender -Y maps to glTF +Z; upright Z maps to Y';scene['NoCollision']=True
 bpy.ops.wm.save_as_mainfile(filepath=str(D/(asset+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(asset+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_tangents=True)
 rows.append({'asset':asset,'triangles':sum(len(o.data.loop_triangles) for o in meshes),'materials':len({m for o in meshes for m in o.data.materials}),'mesh_objects':len(meshes),'blender_bounds_min':lo,'max':hi,'blender_dimensions':[hi[i]-lo[i] for i in range(3)],'identity_transforms':all(o.matrix_world==Matrix.Identity(4) for o in meshes),'collision':False,'runtime_sha256':hashlib.sha256((OUT/(asset+'.glb')).read_bytes()).hexdigest()})
(D/'prop_exports.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'meters','export_yup':True,'assets':rows},indent=2))
print(json.dumps(rows))
