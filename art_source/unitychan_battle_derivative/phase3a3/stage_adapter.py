import pathlib,json,shutil
D=pathlib.Path(__file__).resolve().parent;w=json.loads((D/'workspace.json').read_text());P=pathlib.Path(w['project']);S=P/'spike';S.mkdir(exist_ok=True)
for name in ['runtime_poses.json','presentation_adapter.gd','hand_modifier.gd']:shutil.copy2(D/name,S/name)
p=P/'scripts/player/player_controller.gd';s=p.read_text(encoding='utf-8');old='combat_rig = CharacterCombatRig.new()';new='combat_rig = preload("res://spike/presentation_adapter.gd").new()'
assert old in s or new in s
p.write_text(s.replace(old,new),encoding='utf-8')
(D/'isolated_changes.json').write_text(json.dumps({'project':str(P),'player_substitutions':['character asset preload only','presentation rig constructor only'],'production_edits':False},indent=2));print(P)
