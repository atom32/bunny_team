from pathlib import Path
import json,os,shutil,subprocess
D=Path(__file__).resolve().parent
w=json.loads((D/'workspace.json').read_text());P=Path(w['project'])
shutil.copy2(D/'office_material_probe.gd',P/'spike/office_material_probe.gd')
out=D/'office_material_trials';out.mkdir(exist_ok=True)
env=dict(os.environ,BUNNY_EVIDENCE=str(out),APPDATA=str(Path(w['output'])/'office_material_userdata4'),LOCALAPPDATA=str(Path(w['output'])/'office_material_localdata4'))
with (D/'office_material_probe.log').open('wb') as f:
 r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://spike/office_material_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=150)
print('exit',r.returncode)
