from pathlib import Path
import json,subprocess,os,shutil
D=Path(__file__).resolve().parent;W=json.loads((D/'workspace.json').read_text());P=Path(W['project']);O=Path(W['output']);G='E:/Godot/Godot_v4.7.2-stable_win64_console.exe';results=[]
for primary in ['Rifle','SMG']:
 E=D/('route_'+primary);E.mkdir(exist_ok=True);Q=D/('persistence_'+primary);Q.mkdir(exist_ok=True);shutil.copy2(D/'persistence/original_profile.json',Q/'profile.json')
 env=dict(os.environ,BUNNY_PRIMARY=primary,BUNNY_PRESENTATION='unitychan',BUNNY_PERSISTENCE=str(Q),BUNNY_EVIDENCE=str(E),APPDATA=str(O/('route_'+primary)),LOCALAPPDATA=str(O/('route_local_'+primary)))
 with (E/'route.log').open('wb') as f:r=subprocess.run([G,'--path',str(P),'--rendering-method','gl_compatibility','--resolution','1280x720','--script',str(D/'route_probe.gd')],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=150)
 print(primary,r.returncode,flush=True);results.append({'primary':primary,'exit':r.returncode});(D/'route_runs.json').write_text(json.dumps(results,indent=2))
 if r.returncode:raise SystemExit(r.returncode)
 env.update(BUNNY_EVIDENCE=str(Q),BUNNY_SAVE_STAGE='reload',APPDATA=str(O/('restart_'+primary)))
 with (Q/'reload.log').open('wb') as f:r=subprocess.run([G,'--path',str(P),'--headless','--script',str(D/'persistence_probe.gd')],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=30)
 print('reload',primary,r.returncode,flush=True)
 if r.returncode:raise SystemExit(r.returncode)
