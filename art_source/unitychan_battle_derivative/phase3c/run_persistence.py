from pathlib import Path
import json,os,subprocess,shutil,sys
D=Path(__file__).resolve().parent;w=json.loads((D/'workspace.json').read_text());P=Path(w['project']);O=Path(w['output']);folder=D/'persistence';folder.mkdir(exist_ok=True)
shutil.copy2(D/'persistence_probe.gd',P/'spike/persistence_probe.gd')
jobs=[('seed','legacy'),('verify_before','unitychan')] if len(sys.argv)==1 else [('reload','unitychan')]
for stage,mode in jobs:
 env=dict(os.environ,BUNNY_PRESENTATION=mode,BUNNY_SAVE_STAGE=stage,BUNNY_EVIDENCE=str(folder),APPDATA=str(O/('save_'+stage+'_userdata')),LOCALAPPDATA=str(O/('save_'+stage+'_localdata')))
 with (folder/(stage+'.log')).open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--headless','--script','res://spike/persistence_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=30)
 print(stage,r.returncode,flush=True)
 if r.returncode:raise SystemExit(r.returncode)
