import pathlib,re,shutil
r=pathlib.Path(r'D:/bunny_team');b=pathlib.Path(__file__).parent
p=r/'scenes/presentation/compact_hideout/environment.tscn';s=p.read_text()
for name in ['cable_straight_medium','cable_box_turn','cable_plug_covered','cable_lightswitch']:
 s=s.replace('[sub_resource type="Environment"',f'[ext_resource type="PackedScene" path="res://assets/environment/compact_hideout/cables/{name}.glb" id="{name}"]\n\n[sub_resource type="Environment"',1)
s=s.replace('load_steps=27','load_steps=31')
def update(name,props):
 global s
 start=s.index('[node name="'+name+'"');end=s.find('[node ',start+1)
 if end<0:end=len(s)
 block=s[start:end]
 for key,val in props.items():
  line=key+' = '+val
  if re.search(r'^'+key+' = ',block,re.M):block=re.sub(r'^'+key+r' = .*$',line,block,flags=re.M)
  else:block+=line+'\n'
 s=s[:start]+block+s[end:]
update('FeedRiser',{'position':'Vector3(-2.22,1.08232,-1.735)'})
update('FeedExtension',{'position':'Vector3(-3.008,2.4832696,-1.74825)','scale':'Vector3(0.47,0.47,0.47)'})
update('RiserBend',{'position':'Vector3(-2.895,1.95341,-1.735)','scale':'Vector3(-1,1,1)'})
update('OverheadRun0',{'position':'Vector3(-1.522,2.78,-1.76)'})
update('OverheadRun1',{'position':'Vector3(0.432,2.78,-1.76)'})
for prefix,x,bottom,count in [('Workshop',-1.5,.8825,7),('Rest',2.16,.14,8)]:
 for i in range(count):
  y=bottom+(i+.5)*.207252
  s+=f'\n[node name="{prefix}Cable{i}" parent="." instance=ExtResource("cable_straight_medium")]\nposition = Vector3({x},{y},-1.9802)\n'
 s+=f'\n[node name="{prefix}Outlet" parent="." instance=ExtResource("cable_plug_covered")]\nposition = Vector3({x},{bottom-.05},-1.9725)\n'
s+='\n[node name="BenchJunction" parent="." instance=ExtResource("cable_box_turn")]\nposition = Vector3(-1.5,.83,-1.9815)\n'
s+='\n[node name="RestSwitch" parent="." instance=ExtResource("cable_lightswitch")]\nposition = Vector3(2.16,1.86,-1.973)\n'
p.write_text(s)
shutil.copy2(b/'cable_sources.json',r/'assets/environment/compact_hideout/cable_sources.json')
print('AUTHORED_CABLE_ROUTING_AND_PIPE_CORNER_UPDATED')
