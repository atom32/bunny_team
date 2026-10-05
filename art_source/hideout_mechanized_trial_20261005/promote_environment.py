import pathlib,re,shutil,json,hashlib
root=pathlib.Path(r'D:/bunny_team');base=pathlib.Path(__file__).parent
out=root/'scenes/presentation/compact_hideout';assets=root/'assets/environment/compact_hideout'
assert not out.exists() and not assets.exists(),'Refuse to overwrite existing WIP'
out.mkdir(parents=True);assets.mkdir(parents=True)
s=(base/'project/trial.tscn').read_text()
# Environment-only reusable scene: no duplicate actor, camera, capture script or save owner.
s=re.sub(r'\[node name="Character".*?(?=\[node name="Camera")','',s,flags=re.S)
s=re.sub(r'\[node name="Camera".*','',s,flags=re.S)
s=s.replace('script = ExtResource("capture")','script = ExtResource("appearance")')
s=re.sub(r'\[ext_resource type="Script"[^\n]+\]\s*','',s)
used=set(re.findall(r'instance=ExtResource\("([^"]+)"\)',s))
records=[]
def resource(m):
 path,id=m.group(1),m.group(2)
 if id not in used:return ''
 rel=path.removeprefix('res://');src=base/'project'/rel;dest=assets/rel
 dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
 if src.suffix=='.gltf':
  data=json.loads(src.read_text())
  for dep in data.get('buffers',[])+data.get('images',[]):
   if 'uri' in dep and not dep['uri'].startswith('data:'):
    f=src.parent/dep['uri'];d=dest.parent/dep['uri'];d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d)
 records.append({'source':str(src),'destination':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
 return f'[ext_resource type="PackedScene" path="res://assets/environment/compact_hideout/{rel}" id="{id}"]'
s=re.sub(r'\[ext_resource type="PackedScene" path="([^"]+)" id="([^"]+)"\]',resource,s)
s=s.replace('[sub_resource type="Environment"', '[ext_resource type="Script" path="res://scenes/presentation/compact_hideout/appearance.gd" id="appearance"]\n\n[sub_resource type="Environment"',1)
s=s.replace('name="HideoutKitbashTrial"','name="CompactHideoutEnvironment"')
s=re.sub(r'load_steps=\d+','load_steps='+str(len(used)+3),s,count=1)
(out/'environment.tscn').write_text(s)
code=(base/'project/capture.gd').read_text();appearance='extends Node3D\n## Instance-local tint for existing imported equipment panels. No model/character edits.\nfunc _ready():\n'+code.split(' for label in [')[1].split('func set_view')[0]
appearance=appearance.replace('extends Node3D\n## Instance-local tint for existing imported equipment panels. No model/character edits.\nfunc _ready():\n','extends Node3D\n## Instance-local tint for existing imported equipment panels. No model/character edits.\nfunc _ready():\n for label in [',1)
(out/'appearance.gd').write_text(appearance)
for folder in ['concrete','furniture','kit','weapons']:
 for notice in (base/'project'/folder).glob('*'):
  if notice.name in ['LICENSE.txt','License.txt','SOURCE.md']:
   d=assets/folder/notice.name;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(notice,d)
(assets/'SOURCE.json').write_text(json.dumps({'date':'2026-10-05','scope':'Static environment only; not yet connected to Hideout','selected_instances':records,'polyhaven_license':'CC0 https://polyhaven.com/license','trial_provenance':'art_source/hideout_mechanized_trial_20261005/README.md'},indent=2))
shutil.copy2(base/'polyhaven_sources.json',assets/'polyhaven_downloads.json');shutil.copy2(base/'inherited_polyhaven_sources.json',assets/'inherited_polyhaven_downloads.json')
print('PROMOTED',len(records),'selected imported assets; original trial untouched')
