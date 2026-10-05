from pathlib import Path
import json,os,shutil,subprocess,math
D=Path(__file__).resolve().parent;w=json.loads((D/'workspace.json').read_text());P=Path(w['project']);O=Path(w['output']);L=D/'contract';L.mkdir(exist_ok=True)
shutil.copy2(D/'contract_probe.gd',P/'spike/contract_probe.gd')
for mode in ['legacy','unitychan']:
 env=dict(os.environ,BUNNY_PRESENTATION=mode,BUNNY_CONTRACT_OUTPUT=str(L/(mode+'.json')),APPDATA=str(O/('contract_'+mode)),LOCALAPPDATA=str(O/('contract_local_'+mode)))
 with (L/(mode+'.log')).open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--headless','--path',str(P),'--script','res://spike/contract_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=25)
 assert r.returncode==0
 assert 'ERROR:' not in (L/(mode+'.log')).read_text()
a=json.loads((L/'legacy.json').read_text());b=json.loads((L/'unitychan.json').read_text());assert len(a)==len(b)==270
error=max(math.dist(x['origin'],y['origin']) for x,y in zip(a,b));direction=max(math.dist(x['direction'],y['direction']) for x,y in zip(a,b));exact=all(all(x[k]==y[k] for k in ['weapon','frame','has_weapon','reloading','state']) for x,y in zip(a,b))
r={'samples':len(a),'origin_max_delta_m':error,'direction_max_delta':direction,'state_flags_exact':exact,'pass':error<1e-6 and direction<1e-6 and exact,'scope':'same actor transform/aim, 90 deterministic rig steps per weapon: idle, recoil, reload, Dodge weight; gameplay routines unchanged'}
(L/'comparison.json').write_text(json.dumps(r,indent=2));print(r);assert r['pass']
