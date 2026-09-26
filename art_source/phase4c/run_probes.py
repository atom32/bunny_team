from pathlib import Path
import subprocess, os, json
D=Path(__file__).resolve().parent
W=json.loads((D/'workspace.json').read_text()); P=Path(W['project']); O=Path(W['output'])
G='E:/Godot/Godot_v4.7.2-stable_win64_console.exe'
env=dict(os.environ,BUNNY_EVIDENCE=str(D),APPDATA=str(O/'probes'),LOCALAPPDATA=str(O/'probes_local'))
for name,flags in [('arena_probe',['--headless']),('visual_probe',['--rendering-method','gl_compatibility','--resolution','1280x720']),('performance_probe',['--rendering-method','gl_compatibility','--resolution','1280x720'])]:
    with (D/(name+'.log')).open('wb') as f:
        result=subprocess.run([G,'--path',str(P),*flags,'--script',str(D/(name+'.gd'))],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=60)
    print(name,result.returncode,flush=True)
    text=(D/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    if result.returncode or 'ERROR:' in text: raise SystemExit(text)
