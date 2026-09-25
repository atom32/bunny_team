"""Validate a Battle Costume-only asset selection in a fresh external WIP copy.
No gameplay changes: exactly one preload path is substituted in the COPY only.
python validate.py --output <NEW outside directory> [--route]
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
GODOT=Path('E:/Godot/Godot_v4.7.2-stable_win64_console.exe')
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--route',action='store_true')
args=parser.parse_args()
out=args.output.resolve()
if out.exists() or out.is_relative_to(REPO): parser.error('Output must be NEW and outside repository')
out.mkdir(parents=True)
project=out/'project'
names=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=REPO).decode().split('\0')
hashes={}
for name in sorted(set(names)):
    p=REPO/name
    if not name or not p.is_file():continue
    target=project/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
    hashes[name]=hashlib.sha256(p.read_bytes()).hexdigest()
src=project/'scripts/player/player_controller.gd'
original=src.read_text(encoding='utf-8-sig')
old='res://assets/characters/vrm_avatar/avatar_sample_a.glb'
new='res://assets/characters/unitychan_battle/battle_presentation.glb'
assert original.count(old)==1
src.write_text(original.replace(old,new),encoding='utf8')
shutil.copy2(HERE/'battle_presentation.glb',project/'assets/characters/unitychan_battle/battle_presentation.glb')
shutil.copy2(HERE/'battle_presentation.glb.import',project/'assets/characters/unitychan_battle/battle_presentation.glb.import')
shutil.copy2(HERE/'presentation_probe.gd',project/'tools/phase3a_presentation_probe.gd')
# The old probe aims at the door HINGE x=-17.1, outside the capsule-safe opening.
# FieldOffice center x=-16, wall opening +/-1.2, capsule radius .36: use center.
# Only test input waypoints change. No map/collision/route gameplay changes.
route=(project/'tools/phase2b_route_probe.gd').read_text(encoding='utf-8-sig').replace('-17.1','-16.0')
(project/'tools/phase3a_route_probe.gd').write_text(route,encoding='utf8')
(out/'source_manifest.json').write_text(json.dumps(hashes,indent=2))
(out/'presentation_override.json').write_text(json.dumps({'file':'scripts/player/player_controller.gd','old':old,'new':new,'scope':'ISOLATED SPIKE ONLY; default player/enemy unchanged'},indent=2))
env=dict(os.environ,APPDATA=str(out/'userdata'),LOCALAPPDATA=str(out/'localdata'))
results=[]
def run(name,params,child_env=env):
    log=out/(name+'.log');command=[str(GODOT),'--path',str(project)]+params
    try:
        with log.open('wb') as f:r=subprocess.run(command,env=child_env,stdout=f,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
        code=r.returncode
    except subprocess.TimeoutExpired:code=-999
    text=log.read_text(encoding='utf8',errors='replace')
    errors=re.findall(r'^(?:SCRIPT )?ERROR:.*$',text,re.M);warnings=re.findall(r'^WARNING:.*$',text,re.M)
    passed=code==0 and not errors and not re.search(r'(?:ROUTE_FAIL|: FAIL)',text)
    if name not in ['cold_import','main','route']:passed=passed and 'PASS' in text
    if name=='cold_import':passed=passed and not warnings
    results.append({'name':name,'exit':code,'pass':bool(passed),'errors':errors,'warnings':warnings,'command':command})
    (out/'results.json').write_text(json.dumps(results,indent=2))
    print(name,'PASS' if passed else 'FAIL',code,'errors',len(errors),'warnings',len(warnings),flush=True)
    return passed
if not run('cold_import',['--headless','--editor','--import']):raise SystemExit(1)
for scene in sorted((project/'tests').glob('*.tscn')):
    run(scene.stem,['--headless','res://tests/'+scene.name])
run('main',['--headless','--quit-after','180'])
if args.route:
    captures=out/'captures';captures.mkdir()
    route_env=dict(env,BUNNY_EVIDENCE=str(captures),APPDATA=str(out/'route_userdata'),LOCALAPPDATA=str(out/'route_localdata'))
    run('presentation_probe',['--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://tools/phase3a_presentation_probe.gd'],route_env)
    run('route',['--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://tools/phase3a_route_probe.gd'],route_env)
print('Validation evidence:',out)
sys.exit(0 if all(row['pass'] for row in results) else 1)
