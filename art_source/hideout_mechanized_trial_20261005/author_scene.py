import pathlib,re,math,json
base=pathlib.Path(__file__).parent; project=base/'project'
bounds={}
for line in (base/'bounds.log').read_text().splitlines():
 m=re.match(r'(\S+) BOUNDS \[P: \(([^)]+)\), S: \(([^)]+)\)\]',line)
 if m:bounds[m[1]]=([float(v) for v in m[2].split(',')],[float(v) for v in m[3].split(',')])
assets={name:'concrete/'+name+'.glb' for name in ['Floor','Ceiling','Wall','WallDoorway','Pillar','DoorwayConnector','Stairs']}
assets.update({p.stem:'furniture/'+p.name for p in (project/'furniture').glob('*.glb')})
assets.update({d.name:'polyhaven/'+d.name+'/'+d.name+'.gltf' for d in (project/'polyhaven').iterdir() if d.is_dir()})
assets.update({p.stem:'kit/'+p.name for p in (project/'kit').glob('*.glb')})
assets.update({p.stem:'pipes/'+p.name for p in (project/'pipes').glob('*.glb')})
assets['assault_rifle']='weapons/assault_rifle.glb'
ids={name:str(i+1) for i,name in enumerate(assets)}
lines=['[gd_scene load_steps=%d format=3]'%(len(assets)+4)]
for name,path in assets.items():lines.append('[ext_resource type="PackedScene" path="res://%s" id="%s"]'%(path,ids[name]))
lines += ['[ext_resource type="Script" path="res://capture.gd" id="capture"]','[ext_resource type="Script" path="res://character_preview.gd" id="actor"]','[sub_resource type="Environment" id="environment"]','background_mode = 1','background_color = Color(0.018,0.025,0.03,1)','ambient_light_source = 3','ambient_light_color = Color(0.58,0.64,0.68,1)','ambient_light_energy = 0.28','ssao_enabled = true','tonemap_mode = 2','[node name="HideoutKitbashTrial" type="Node3D"]','script = ExtResource("capture")','[node name="Environment" type="WorldEnvironment" parent="."]','environment = SubResource("environment")']
placements=[]
def place(name,label,pos,scale=1,yaw=0,center=True):
 raw=pos[:]
 if center:
  file=pathlib.Path(assets[name]).name;lo,size=bounds[file]
  cx=(lo[0]+size[0]/2)*scale;cz=(lo[2]+size[2]/2)*scale
  raw=[pos[0]-(cx*math.cos(yaw)+cz*math.sin(yaw)),pos[1]-lo[1]*scale,pos[2]-(-cx*math.sin(yaw)+cz*math.cos(yaw))]
 lines.extend(['[node name="%s" parent="." instance=ExtResource("%s")]'%(label,ids[name]),'position = Vector3(%s)'%','.join(map(str,raw)),'rotation = Vector3(0,%s,0)'%yaw,'scale = Vector3(%s,%s,%s)'%(scale,scale,scale)])
 placements.append({'asset':assets[name],'name':label,'floor_center':pos,'scale':scale,'yaw':yaw})
# Compact authored layout: 6m x 4m. Imported modular meshes only.
for x in [-2,0,2]:
 for z in [-1,1]:
  place('Floor',f'Floor_{x+2}_{z+1}',[x,0,z],center=False)
  place('Ceiling',f'Ceiling_{x+2}_{z+1}',[x,3,z],center=False)
for z in [-1,1]:
 place('Wall',f'West_{z+1}',[-2.2,0,z],center=False)
 place('Wall',f'East_{z+1}',[3.8,0,z],center=False)
for x in [-2,0,2]:
 place('Wall',f'Rear_{x+2}',[x,0,-2.8],yaw=math.pi/2,center=False)
 place('WallDoorway' if x==0 else 'Wall',f'Front_{x+2}',[x,0,2.8],yaw=-math.pi/2,center=False)
place('Wall','RestPartition',[1.8,0,-1],center=False)
place('WallDoorway','RestDoorway',[1.8,0,1],center=False)
place('metal_office_desk','MaintenanceBench',[-1.8,0,-1.37],1)
place('metal_stool_01','BenchStool',[-1.9,0,-.35],.62)
place('desk_lamp_arm_01','TaskLamp',[-2.55,.79,-1.5],.65)
place('metal_toolbox','OpenToolbox',[-2.08,.79,-1.4],.7)
place('computerScreen','MissionMonitor',[-1.11,.79,-1.59],1.05)
place('computerKeyboard','Keyboard',[-1.1,.79,-1.29],1)
place('radio','Radio',[-.97,.79,-1.72],.7)
place('assault_rifle','BenchRifle',[-1.45,.81,-1.02],.65,math.pi/2)
place('metal_tool_chest','ToolChest',[-2.53,0,.55],1.5,math.pi/2)
place('steel_frame_shelves_01','StockShelves',[.25,0,-1.69],.09)
for i,(x,y,z) in enumerate([(.25,.05,-1.65),(.25,.55,-1.65),(.25,1.0,-1.65)]):
 place('old_military_crate',f'MilitaryCrate{i}',[x,y,z],.42)
place('old_military_crate','EquipmentLocker',[-2.37,0,1.3],.65)
place('old_military_crate','SealedSupply',[-1.53,0,1.64],.55)
place('old_military_crate','SupplyOnTop',[-1.53,.17,1.64],.5)
place('vintage_day_bed','RestCot',[2.11,0,-.67],1,math.pi/2)
place('old_military_crate','PersonalTrunk',[2.05,0,1.05],.65)
place('industrial_wall_lamp','RestFixture',[2.16,1.85,-1.86],1)
place('industrial_wall_lamp','WorkshopFixture',[-1.5,2.32,-1.87],1)
place('wall-detail','ServicePanel',[-2.91,1.45,.1],1,math.pi/2)
place('wall-switch','DoorControl',[.79,1.25,1.88],1.5,math.pi)
place('door-double-closed','EntranceDoor',[0,0,1.97],2.75)
place('modular_industrial_pipes_01_pipe02','FeedRiser',[-2.82,.08,-.8],1)
place('modular_industrial_pipes_01_pipe01','FeedExtension',[-2.82,2.034,-.8],1)
place('industrial_wall_lamp','FrontFixture',[.1,2.1,1.86],1,math.pi)
for name,pos,col,energy,rng in [
 ('BenchLight',[-1.5,2.34,-1.57],(.83,.9,1),1.2,4),
 ('TaskLight',[-2.47,1.3,-1.23],(1,.88,.69),.4,1.5),
 ('RestLight',[2.16,2.04,-1.64],(1,.72,.43),.8,2.8),
 ('CharacterFill',[.1,2.25,1.61],(.8,.86,1),.95,3.5),
 ('EntryLight',[0,2.0,1.7],(.53,.67,.6),.2,1.5)]:
 lines += ['[node name="%s" type="OmniLight3D" parent="."]'%name,'position = Vector3(%s)'%','.join(map(str,pos)),'light_color = Color(%s,1)'%','.join(map(str,col)),'light_energy = '+str(energy),'omni_range = '+str(rng),'shadow_enabled = true','omni_shadow_mode = 1']
# Fixed overhead placement of original straight modules.
for i,x in enumerate([-1.843,.111]):
 name='modular_industrial_pipes_01_pipe02';lo,size=bounds[name+'.glb'];mid=[lo[j]+size[j]/2 for j in range(3)]
 lines += [f'[node name="OverheadRun{i}" type="Node3D" parent="."]',f'position = Vector3({x},2.78,-1.76)','rotation = Vector3(0,0,1.57079632679)',f'[node name="Pipe" parent="OverheadRun{i}" instance=ExtResource("{ids[name]}")]',f'position = Vector3({-mid[0]},{-mid[1]},{-mid[2]})']
lines += ['[node name="Character" type="Node3D" parent="."]','position = Vector3(-0.55,0,-0.1)','script = ExtResource("actor")','[node name="Camera" type="Camera3D" parent="."]','position = Vector3(0.35,1.6,1.82)','current = true','fov = 67.0']
(project/'trial.tscn').write_text('\n\n'.join(lines)+'\n');(base/'placements.json').write_text(json.dumps(placements,indent=2))

