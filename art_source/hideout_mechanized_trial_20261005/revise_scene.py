import pathlib
base=pathlib.Path(__file__).parent
p=base/'author_scene.py';s=p.read_text();start=s.index('ids={')
s=s[:start]+s[start:]
s=s.replace("assets.update({id:'polyhaven/'+id+'/'+id+'.gltf' for id in ['steel_frame_shelves_01','metal_tool_chest']})", "assets.update({d.name:'polyhaven/'+d.name+'/'+d.name+'.gltf' for d in (project/'polyhaven').iterdir() if d.is_dir()})\nassets.update({p.stem:'kit/'+p.name for p in (project/'kit').glob('*.glb')})\nassets['assault_rifle']='weapons/assault_rifle.glb'")
s=s.replace("len(assets)+3", "len(assets)+4")
s=s.replace("'[ext_resource type=\"Script\" path=\"res://capture.gd\" id=\"capture\"]'", "'[ext_resource type=\"Script\" path=\"res://capture.gd\" id=\"capture\"]','[ext_resource type=\"Script\" path=\"res://character_preview.gd\" id=\"actor\"]'")
s=s.replace("'ambient_light_energy = 0.16'", "'ambient_light_energy = 0.28'")
s=s[:s.index('# Fixed authored layout:')]+'''# Compact authored layout: 6m x 4m. Imported modular meshes only.
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
place('container-tall','EquipmentLocker',[-2.61,0,1.3],1.2)
place('container-flat','SealedSupply',[-1.53,0,1.64],.8,math.pi/2)
place('container-flat','SupplyOnTop',[-1.53,.48,1.64],.65,math.pi/2)
place('vintage_day_bed','RestCot',[2.11,0,-.67],1,math.pi/2)
place('old_military_crate','PersonalTrunk',[2.05,0,1.05],.65)
place('industrial_wall_lamp','RestFixture',[2.16,1.85,-1.86],1)
place('industrial_wall_lamp','WorkshopFixture',[-1.5,2.32,-1.87],1)
place('wall-detail','ServicePanel',[-.15,1.17,-1.91],1)
place('wall-switch','DoorControl',[.79,1.25,1.88],1.5,math.pi)
place('door-double-closed','EntranceDoor',[0,0,1.97],2.75)
place('modular_industrial_pipes_01','RearPipeAssembly',[-1.7,1.05,-1.93],1)
place('modular_industrial_pipes_01','RestPipeAssembly',[2.13,1.55,-1.95],.62)
for name,pos,col,energy,rng in [
 ('BenchLight',[-1.5,2.34,-1.57],(.83,.9,1),1.2,4),
 ('TaskLight',[-2.47,1.3,-1.23],(1,.88,.69),.4,1.5),
 ('RestLight',[2.16,2.04,-1.64],(1,.72,.43),.8,2.8),
 ('CharacterFill',[.1,2.4,1.0],(.8,.86,1),.45,3.5),
 ('EntryLight',[0,2.0,1.7],(.53,.67,.6),.2,1.5)]:
 lines += ['[node name="%s" type="OmniLight3D" parent="."]'%name,'position = Vector3(%s)'%','.join(map(str,pos)),'light_color = Color(%s,1)'%','.join(map(str,col)),'light_energy = '+str(energy),'omni_range = '+str(rng),'shadow_enabled = true','omni_shadow_mode = 1']
lines += ['[node name="Character" type="Node3D" parent="."]','position = Vector3(-0.55,0,-0.1)','script = ExtResource("actor")','[node name="Camera" type="Camera3D" parent="."]','position = Vector3(0.35,1.6,1.82)','current = true','fov = 67.0']
(project/'trial.tscn').write_text('\\n\\n'.join(lines)+'\\n');(base/'placements.json').write_text(json.dumps(placements,indent=2))
'''
p.write_text(s)
