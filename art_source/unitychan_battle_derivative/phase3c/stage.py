"""Fresh isolated validation snapshot; never modifies production files."""
import pathlib,subprocess,hashlib,json,shutil,os,datetime
D=pathlib.Path(__file__).resolve().parent; R=D.parent; REPO=R.parents[1]
OUT=pathlib.Path(os.environ['TEMP'])/('bunny_phase3c_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'));P=OUT/'project';P.mkdir(parents=True)
files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=REPO).decode().split('\0'); hashes={}
for name in sorted(set(files)):
 source=REPO/name
 if not name or name.startswith(('art_source/','docs/','tools/__pycache__/')) or not source.is_file():continue
 dest=P/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest);hashes[name]=hashlib.sha256(source.read_bytes()).hexdigest()
for name in ['battle_presentation.glb','battle_presentation.glb.import']:shutil.copy2(R/name,P/'assets/characters/unitychan_battle'/name)
S=P/'spike';S.mkdir(exist_ok=True)
for name in ['runtime_poses.json','hand_modifier.gd']:shutil.copy2(R/'phase3a3'/name,S/name)
shutil.copy2(R/'phase3a3/presentation_adapter.gd',S/'phase3a3_adapter.gd')
for name in ['presentation_adapter.gd','anime_surface.gdshader','material_profile.json','mount_profile.json']:shutil.copy2(R/'phase3b'/name,S/name)
shutil.copy2(D/'presentation_switch.gd',S/'presentation_switch.gd')
player=P/'scripts/player/player_controller.gd';s=player.read_text(encoding='utf-8-sig')
substitutions={
 'character_model = CHARACTER_SCENE.instantiate()':'character_model = preload("res://spike/presentation_switch.gd").character_scene(CHARACTER_SCENE).instantiate()',
 'combat_rig = CharacterCombatRig.new()':'combat_rig = preload("res://spike/presentation_switch.gd").create_rig()'
}
for old,new in substitutions.items():
 assert s.count(old)==1,old
 s=s.replace(old,new)
player.write_text(s,encoding='utf-8')
(D/'isolated_changes.json').write_text(json.dumps({'substitutions':substitutions,'default':'legacy','selector':'BUNNY_PRESENTATION=unitychan','production_edits':False},indent=2))
manifest=json.loads((R.parent/'unitychan_battle_legacy/recovery_manifest.json').read_text(encoding='utf-8'));official=[]
for row in manifest['files']:
 for suffix,key in [('', 'sha256'),('.meta','meta_sha256')]:official.append(hashlib.sha256((R.parent/'unitychan_battle_legacy/official_1_1'/(row['path']+suffix)).read_bytes()).hexdigest()==row[key])
assert all(official)
state={'project':str(P),'output':str(OUT),'master_exists':(R/'battle_master.blend').is_file(),'official_hashes_match':sum(official),'production_player_sha256':hashes['scripts/player/player_controller.gd'],'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()}
(D/'workspace.json').write_text(json.dumps(state,indent=2));(D/'source_manifest.json').write_text(json.dumps(hashes,indent=2));(D/'git_status_before.txt').write_text(subprocess.check_output(['git','status','--short'],cwd=REPO,text=True),encoding='utf-8');(D/'import_config.diff').write_text(subprocess.check_output(['git','diff','--','*.import','project.godot'],cwd=REPO,text=True),encoding='utf-8')
print(json.dumps(state),flush=True)
env=dict(os.environ,APPDATA=str(OUT/'userdata'),LOCALAPPDATA=str(OUT/'localdata'))
with (D/'cold_import.log').open('wb') as f:r=subprocess.run(['E:/Godot/Godot_v4.7.2-stable_win64_console.exe','--path',str(P),'--headless','--editor','--import'],stdout=f,stderr=subprocess.STDOUT,env=env,timeout=240)
log=(D/'cold_import.log').read_text(encoding='utf-8',errors='replace');state.update(cold_import_exit=r.returncode,errors=sum(l.startswith(('ERROR:','SCRIPT ERROR:')) for l in log.splitlines()),warnings=sum(l.startswith('WARNING:') for l in log.splitlines()));(D/'workspace.json').write_text(json.dumps(state,indent=2));print(state,flush=True)
