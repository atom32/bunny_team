from pathlib import Path
import json,os,shutil,subprocess
D=Path(__file__).resolve().parent
w=json.loads((D/'workspace.json').read_text());P=Path(w['project'])
shutil.copy2(D/'material_probe.gd',P/'spike/material_probe.gd')
shutil.copy2(D/'soft_diffuse_trial.gdshader',P/'spike/soft_diffuse_trial.gdshader')
shutil.copy2(D/'zero_light_diagnostic.gdshader',P/'spike/zero_light_diagnostic.gdshader')
for name in ['soft_no_ambient_diagnostic','ambient_only_diagnostic']:shutil.copy2(D/(name+'.gdshader'),P/'spike'/(name+'.gdshader'))
out=D/'material_trials';out.mkdir(exist_ok=True)
env=dict(os.environ,BUNNY_EVIDENCE=str(out),APPDATA=str(Path(w['output'])/'material_userdata'),LOCALAPPDATA=str(Path(w['output'])/'material_localdata'))
with (D/'material_probe.log').open('wb') as f:
 r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--rendering-method','gl_compatibility','--resolution','1280x720','--script','res://spike/material_probe.gd'],env=env,stdout=f,stderr=subprocess.STDOUT,timeout=60)
print('exit',r.returncode)
