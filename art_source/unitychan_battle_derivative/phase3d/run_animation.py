from pathlib import Path
import os,subprocess,json
D=Path(__file__).resolve().parent;W=json.loads((D/'workspace.json').read_text());E=D/'animation';E.mkdir(exist_ok=True)
env=dict(os.environ,BUNNY_EVIDENCE=str(E),APPDATA=str(Path(W['output'])/'animation'))
with (E/'run.log').open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',W['project'],'--rendering-method','gl_compatibility','--resolution','1280x720','--script',str(D/'animation_contract.gd')],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=80)
print(r.returncode)
