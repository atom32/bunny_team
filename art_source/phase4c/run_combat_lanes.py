from pathlib import Path
import json,subprocess,os,shutil
D=Path(__file__).resolve().parent;W=json.loads((D/'workspace.json').read_text());O=Path(W['output'])
for name in ['Rifle','SMG']:
    E=D/('combat_'+name);E.mkdir(exist_ok=True)
    Q=D/'local'/('combat_'+name);Q.mkdir(exist_ok=True)
    shutil.copy2(D/'local/original_profile.json',Q/'profile.json')
    env=dict(os.environ,BUNNY_PRIMARY=name,BUNNY_EVIDENCE=str(E),BUNNY_PERSISTENCE=str(Q),APPDATA=str(O/('combat_'+name)),LOCALAPPDATA=str(O/('combat_local_'+name)))
    with (E/'run.log').open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',W['project'],'--rendering-method','gl_compatibility','--resolution','1280x720','--script',str(D/'combat_lane_probe.gd')],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=75)
    print(name,r.returncode,flush=True)
    text=(E/'run.log').read_text(encoding='utf-8',errors='replace')
    if r.returncode or any(line.startswith(('ERROR:','SCRIPT ERROR:')) for line in text.splitlines()):raise SystemExit(r.returncode or 1)
