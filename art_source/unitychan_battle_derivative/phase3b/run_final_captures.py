from pathlib import Path
import json,shutil,subprocess,os
D=Path(__file__).resolve().parent;w=json.loads((D/'workspace.json').read_text());P=Path(w['project']);O=Path(w['output'])
for name in ['paired_capture','final_hanger_probe','final_office_probe']:shutil.copy2(D/(name+'.gd'),P/'spike'/(name+'.gd'))
folder=D/'final_comparison';folder.mkdir(exist_ok=True)
results=[]
for scene in ['hanger','office']:
 env=dict(os.environ,BUNNY_EVIDENCE=str(folder),APPDATA=str(O/('final_'+scene+'_userdata')),LOCALAPPDATA=str(O/('final_'+scene+'_localdata')),BUNNY_PRIMARY='Rifle')
 with (folder/(scene+'.log')).open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://spike/final_'+scene+'_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=150)
 results.append({'scene':scene,'exit':r.returncode});print(scene,r.returncode,flush=True);(folder/'runs.json').write_text(json.dumps(results,indent=2))
