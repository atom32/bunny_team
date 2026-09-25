from pathlib import Path
import json,subprocess,os,re
D=Path(__file__).resolve().parent;W=json.loads((D/'workspace.json').read_text());P=Path(W['project']);O=Path(W['output']);L=D/'regression';L.mkdir(exist_ok=True)
env=dict(os.environ,APPDATA=str(O/'regression_userdata'),LOCALAPPDATA=str(O/'regression_localdata'));rows=[]
jobs=[(p.stem,['res://tests/'+p.name]) for p in sorted((P/'tests').glob('*.tscn'))]+[('main',['--quit-after','180'])]
for name,args in jobs:
 command=['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--headless']+args
 with (L/(name+'.log')).open('wb') as f:
  try:code=subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,env=env,timeout=180).returncode
  except subprocess.TimeoutExpired:code=-999
 text=(L/(name+'.log')).read_text(encoding='utf-8',errors='replace');errs=[s for s in text.splitlines() if s.startswith(('ERROR:','SCRIPT ERROR:'))];warnings=[s for s in text.splitlines() if s.startswith('WARNING:')]
 row={'name':name,'exit':code,'errors':errs,'warnings':warnings,'pass':code==0 and not errs and ': FAIL' not in text,'command':command};rows.append(row);(L/'results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8');print(name,row['pass'],code,flush=True)
