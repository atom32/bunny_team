import bpy,json,pathlib
p=pathlib.Path('D:/bunny_team/art_source/unitychan_battle_derivative');bpy.ops.wm.open_mainfile(filepath=str(p/'battle_master.blend'))
r=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE'); rows=[]
for b in r.data.bones:
 if any(x in b.name for x in ['Hand','Finger','Thumb','Index','Middle','Ring','Pinky']):
  rows.append(dict(name=b.name,parent=b.parent.name if b.parent else None,head=list(b.head_local),tail=list(b.tail_local),matrix=[list(x) for x in b.matrix_local]))
(p/'phase3a2/hand_hierarchy.json').write_text(json.dumps(rows,indent=2));print(r.name);print('\n'.join(str((v['name'],v['parent'],v['head'],v['tail'])) for v in rows))
