import pathlib,re,math,json
base=pathlib.Path(__file__).parent; project=base/'project'
bounds={}
for line in (base/'bounds.log').read_text().splitlines():
 m=re.match(r'(\S+) BOUNDS \[P: \(([^)]+)\), S: \(([^)]+)\)\]',line)
 if m:bounds[m[1]]=([float(v) for v in m[2].split(',')],[float(v) for v in m[3].split(',')])
assets={name:'concrete/'+name+'.glb' for name in ['Floor','Ceiling','Wall','WallDoorway','Pillar','DoorwayConnector','Stairs']}
assets.update({p.stem:'furniture/'+p.name for p in (project/'furniture').glob('*.glb')})
assets.update({id:'polyhaven/'+id+'/'+id+'.gltf' for id in ['steel_frame_shelves_01','metal_tool_chest']})
ids={name:str(i+1) for i,name in enumerate(assets)}
lines=['[gd_scene load_steps=%d format=3]'%(len(assets)+3)]
for name,path in assets.items():lines.append('[ext_resource type="PackedScene" path="res://%s" id="%s"]'%(path,ids[name]))
lines += ['[ext_resource type="Script" path="res://capture.gd" id="capture"]','[sub_resource type="Environment" id="environment"]','background_mode = 1','background_color = Color(0.018,0.025,0.03,1)','ambient_light_source = 3','ambient_light_color = Color(0.58,0.64,0.68,1)','ambient_light_energy = 0.16','ssao_enabled = true','tonemap_mode = 2','[node name="HideoutKitbashTrial" type="Node3D"]','script = ExtResource("capture")','[node name="Environment" type="WorldEnvironment" parent="."]','environment = SubResource("environment")']
placements=[]
def place(name,label,pos,scale=1,yaw=0,center=True):
 raw=pos[:]
 if center:
  file=pathlib.Path(assets[name]).name;lo,size=bounds[file]
  cx=(lo[0]+size[0]/2)*scale;cz=(lo[2]+size[2]/2)*scale
  raw=[pos[0]-(cx*math.cos(yaw)+cz*math.sin(yaw)),pos[1]-lo[1]*scale,pos[2]-(-cx*math.sin(yaw)+cz*math.cos(yaw))]
 lines.extend(['[node name="%s" parent="." instance=ExtResource("%s")]'%(label,ids[name]),'position = Vector3(%s)'%','.join(map(str,raw)),'rotation = Vector3(0,%s,0)'%yaw,'scale = Vector3(%s,%s,%s)'%(scale,scale,scale)])
 placements.append({'asset':assets[name],'name':label,'floor_center':pos,'scale':scale,'yaw':yaw})
# Fixed authored layout: 8m x 6m, 3m ceiling. These are imported modules, not generated meshes.
for x in [-3,-1,1,3]:
 for z in [-2,0,2]:
  place('Floor',f'Floor_{x+3}_{z+2}',[x,0,z],center=False)
  place('Ceiling',f'Ceiling_{x+3}_{z+2}',[x,3,z],center=False)
for z in [-2,0,2]:
 place('Wall',f'West_{z+2}',[-3.2,0,z],center=False)
 place('Wall',f'East_{z+2}',[4.8,0,z],center=False)
for x in [-3,-1,1,3]:
 place('Wall',f'North_{x+3}',[x,0,-3.8],yaw=math.pi/2,center=False)
 place('WallDoorway' if x==-1 else 'Wall',f'Front_{x+3}',[x,0,3.8],yaw=-math.pi/2,center=False)
# Partial separation hides the bed from the entrance; middle doorway stays open.
for z in [-2,0]:place('WallDoorway' if z==0 else 'Wall',f'Partition_{z+2}',[1.8,0,z],center=False)
place('Pillar','OldColumn',[-.7,0,-.9],center=False)
place('steel_frame_shelves_01','StockShelves',[-3.15,0,-2.55],.1)
place('metal_tool_chest','ToolChest',[-1.8,0,-2.48],1.6)
place('desk','RepairBench',[-3.0,0,-.45],2,math.pi/2)
place('chair','BenchChair',[-2.0,0,-.4],2,-math.pi/2)
place('computerScreen','BenchMonitor',[-3.25,.77,-.75],1.4,math.pi/2)
place('computerKeyboard','Keyboard',[-2.95,.77,-.65],1.1,math.pi/2)
place('radio','Radio',[-3.0,.77,.05],1)
place('lampRoundTable','BenchLamp',[-3.24,.77,.11],1.2)
place('bedSingle','RestBed',[2.8,0,-1.7],2)
place('sideTable','BedsideTable',[1.75,0,-2.1],1.7)
place('lampRoundTable','BedsideLamp',[1.75,.654,-2.1],1.1)
place('books','ReadingBooks',[1.75,.654,-1.94],1)
place('rugRectangle','RestRug',[2.5,.006,.0],1)
place('bookcaseOpen','LivingShelf',[3.6,0,1.5],2,math.pi/2)
place('kitchenFridgeSmall','SmallFridge',[2.25,0,2.25],1.5)
place('coatRackStanding','CoatRack',[3.4,0,2.35],2)
place('trashcan','Bin',[-3.55,0,.65],1.4)
for i,(x,z,s) in enumerate([(-2.85,-2.5,1.6),(-3.45,-2.5,1.8),(-2.6,1.8,2),(-2.05,1.75,1.8),(-2.6,1.8,1.5)]):
 place('cardboardBoxClosed',f'SupplyBox{i}',[x,.56 if i==4 else 0,z],s, .12*i)
place('cardboardBoxOpen','OpenBox',[-1.7,0,2.15],2)
for i,(x,y,z,s) in enumerate([(-3.4,.48,-2.55,1.4),(-2.95,.48,-2.55,1.6),(-3.4,.99,-2.55,1.5),(-2.95,1.5,-2.55,1.6)]):place('cardboardBoxClosed',f'ShelfBox{i}',[x,y,z],s)
# Model fixtures plus warm local pools; no showroom strip lighting.
for name,pos,col,energy,rng in [('WorkshopLight',[-2.3,2.45,-.7],(.68,.82,1),0.8,5),('RestLight',[2,1.7,-1.5],(1,.67,.35),0.55,4),('EntranceLight',[-.9,2.2,2.0],(.8,.68,.48),.25,3)]:
 lines += ['[node name="%s" type="OmniLight3D" parent="."]'%name,'position = Vector3(%s)'%','.join(map(str,pos)),'light_color = Color(%s,1)'%','.join(map(str,col)),'light_energy = '+str(energy),'omni_range = '+str(rng),'shadow_enabled = true']
lines += ['[node name="Camera" type="Camera3D" parent="."]','position = Vector3(-0.8,1.7,2.55)','current = true','fov = 75.0']
(project/'trial.tscn').write_text('\n\n'.join(lines)+'\n');(base/'placements.json').write_text(json.dumps(placements,indent=2))

