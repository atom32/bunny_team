import pathlib,shutil,re
r=pathlib.Path(r'D:/bunny_team');b=pathlib.Path(__file__).parent;a=r/'assets/environment/compact_hideout'
shutil.copy2(r/'assets/environment/kenney_space_station_kit/container-tall.glb',a/'kit/container-tall.glb')
shutil.copy2(b/'project/pipes/modular_industrial_pipes_01_pipe04.glb',a/'pipes/modular_industrial_pipes_01_pipe04.glb')
p=r/'scenes/presentation/compact_hideout/environment.tscn';s=p.read_text()
s=s.replace('[sub_resource type="Environment"','[ext_resource type="PackedScene" path="res://assets/environment/compact_hideout/kit/container-tall.glb" id="locker"]\n\n[ext_resource type="PackedScene" path="res://assets/environment/compact_hideout/pipes/modular_industrial_pipes_01_pipe04.glb" id="bend"]\n\n[sub_resource type="Environment"',1)
s=s.replace('load_steps=25','load_steps=27')
start=s.index('[node name="EquipmentLocker"');end=s.index('[node ',start+1)
s=s[:start]+'''[node name="EquipmentLocker" parent="." instance=ExtResource("locker")]
position = Vector3(-2.5,0,1.5)
scale = Vector3(1.5,1.5,1.5)

'''+s[end:]
# Imported 90-degree elbow: authored top-riser corner, rough alignment first.
s+='\n[node name="RiserBend" parent="." instance=ExtResource("bend")]\nposition = Vector3(-2.56,2.245,-1.735)\n'
p.write_text(s)
p=r/'scenes/presentation/compact_hideout/appearance.gd';s=p.read_text().replace('["EntranceDoor","ServicePanel"]','["EntranceDoor","ServicePanel","EquipmentLocker"]');p.write_text(s)
print('FIELD_LOCKER_AND_SOURCED_BEND_ADDED')
