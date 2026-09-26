from pathlib import Path
import os,json,subprocess
D=Path(__file__).resolve().parent;W=json.loads((D/'workspace.json').read_text());E=D/'fx';E.mkdir(exist_ok=True)
env=dict(os.environ,BUNNY_EVIDENCE=str(E),BUNNY_OLD_EFFECTS=str(D/'baseline_effects.gd'),APPDATA=str(Path(W['output'])/'fx'))
with (E/'run.log').open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',W['project'],'--rendering-method','gl_compatibility','--resolution','1280x720','--script',str(D/'fx_comparison.gd')],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=30)
print(r.returncode)
