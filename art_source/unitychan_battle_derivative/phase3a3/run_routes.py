from pathlib import Path
import json,shutil,subprocess,os
D=Path(__file__).resolve().parent;w=json.loads((D/'workspace.json').read_text());P=Path(w['project']);shutil.copy2(D/'route_probe.gd',P/'spike/route_probe.gd');results=[]
for primary in ['Rifle','SMG']:
 folder=D/('route_'+primary);folder.mkdir(exist_ok=True);env=dict(os.environ,BUNNY_PRIMARY=primary,BUNNY_EVIDENCE=str(folder),APPDATA=str(Path(w['output'])/('route_'+primary+'_userdata')),LOCALAPPDATA=str(Path(w['output'])/('route_'+primary+'_localdata')))
 with (folder/'route.log').open('wb') as f:
  try:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://spike/route_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=150);code=r.returncode
  except subprocess.TimeoutExpired:code=-999
 results.append({'primary':primary,'exit':code});(D/'route_runs.json').write_text(json.dumps(results,indent=2));print(primary,code,flush=True)
