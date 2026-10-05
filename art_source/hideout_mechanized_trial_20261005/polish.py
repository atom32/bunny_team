import pathlib
b=pathlib.Path(__file__).parent
f=b/'project/character_preview.gd';f.write_text(f.read_text().replace('model.rotation.y=PI-.25','model.rotation.y=PI*1.5-.25'))
f=b/'author_scene.py';s=f.read_text().replace("place('wall-detail','ServicePanel',[-.15,1.17,-1.91],1)","place('wall-detail','ServicePanel',[-2.91,1.45,.1],1,math.pi/2)").replace("('CharacterFill',[.1,2.4,1.0]","('CharacterFill',[.1,2.25,1.61]")
insert='''# Fixed overhead placement of original straight modules.
for i,x in enumerate([-1.843,.111]):
 name='modular_industrial_pipes_01_pipe02';lo,size=bounds[name+'.glb'];mid=[lo[j]+size[j]/2 for j in range(3)]
 lines += [f'[node name="OverheadRun{i}" type="Node3D" parent="."]',f'position = Vector3({x},2.78,-1.76)','rotation = Vector3(0,0,1.57079632679)',f'[node name="Pipe" parent="OverheadRun{i}" instance=ExtResource("{ids[name]}")]',f'position = Vector3({-mid[0]},{-mid[1]},{-mid[2]})']
'''
s=s.replace("lines += ['[node name=\"Character\"",insert+"lines += ['[node name=\"Character\"");f.write_text(s)
f=b/'project/capture.gd';s=f.read_text();s=s.replace(' $Camera.look_at(Vector3(-.85,1.0,-.45))',''' $Camera.look_at(Vector3(-.85,1.0,-.45))
 for label in ["EntranceDoor","ServicePanel"]:
  for mesh in get_node(label).find_children("*","MeshInstance3D",true,false):
   for i in mesh.mesh.get_surface_count():
    var original=mesh.get_active_material(i)
    if original is StandardMaterial3D:
     var mat=original.duplicate()
     mat.albedo_color=Color(.25,.30,.28,1)
     mat.roughness=.82
     mesh.set_surface_override_material(i,mat)
''');f.write_text(s)
