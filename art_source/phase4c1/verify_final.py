"""Fail-closed audit of the visible-only enemy replacement and preserved WIP."""
from pathlib import Path
import hashlib, json, struct

D=Path(__file__).resolve().parent; R=D.parents[1]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
base=read(D/'baseline.json')
changed=[p for p,h in base['hashes'].items() if sha(R/p)!=h]
checks={'only_existing_enemy_scene_changed':changed==['scenes/enemies/enemy.tscn'],
        'baseline_e915d21':base['head'].startswith('e915d21'),
        'controller_rig_player_arena_tests_unchanged':not any(p!='scenes/enemies/enemy.tscn' for p in changed)}
source=R/'art_source/unitychan_battle_legacy/official_1_1'
manifest=read(R/'art_source/unitychan_battle_legacy/recovery_manifest.json'); hashes=[]
for row in manifest['files']:
    hashes.append(sha(source/row['path'])==row['sha256'])
    if row.get('meta_sha256'):hashes.append(sha(source/(row['path']+'.meta'))==row['meta_sha256'])
checks['official_68_hashes_identical']=len(hashes)==68 and all(hashes)
contract=read(D/'contract.json');checks['all_comparative_contract_checks']=all(contract['checks'].values())
export=read(D/'export.json')
checks['master_hash_correct']=sha(D/'enemy_master.blend')==export['master_sha256']
checks['runtime_hash_correct']=sha(R/'assets/enemies/kite_security/enemy_visual.glb')==export['runtime_sha256']
cold=read(D/'cold_import.json')
checks['fresh_isolated_import_zero_errors_warnings']=len(cold)==1 and cold[0]['pass'] and not cold[0]['errors'] and not cold[0]['warnings']
checks['cold_import_used_current_runtime_files']=all(sha(R/p)==h for p,h in read(D/'cold_import_sources.json').items())
tests=read(D/'regression/results.json');checks['33_tests_main_pass']=len(tests)==34 and all(t['pass'] for t in tests)
save=read(D/'save_source.json');checks['actual_user_save_unchanged']=sha(Path(save['path']))==save['sha256']
routes={}
runs=read(D/'route_runs.json')
checks['two_current_route_processes_clean']=len(runs)==2 and all(row['pass'] for row in runs)
for primary in ['Rifle','SMG']:
    route=read(D/f'route_{primary}/route_result.json');restart=read(D/f'persistence_{primary}/reload.json')
    checks[primary+'_complete_route']=not route['failure'] and all(route['checks'].values())
    checks[primary+'_normal_enemy_death_before_extraction']=route['combat']['enemies_defeated']>0 and route['combat_events'].get('EnemyDied',0)>0
    checks[primary+'_cross_process_save_load']=all(restart['checks'].values())
    flow=read(D/f'route_{primary}/identity_flow.json')
    before,after,outcome=flow['pre_sortie_profile'],flow['post_result_profile'],flow['outcome']
    expected={item['instance_id']:item for item in before['inventory']['items']}
    for ident in outcome['initial_carried_instance_ids']:expected.pop(ident,None)
    for item in outcome['inventory']['items']:expected[item['instance_id']]=item
    checks[primary+'_warehouse_commit_equivalent']=expected=={item['instance_id']:item for item in after['inventory']['items']} and after['loadout']==outcome['loadout']
    routes[primary]={'checks':len(route['checks']),'combat':route['combat'],'effects':route['combat_events'],'restart_checks':len(restart['checks'])}
logs={}
for p in list(D.glob('*.log'))+list(D.glob('route_*/*.log'))+list(D.glob('persistence_*/*.log')):
    lines=p.read_text(encoding='utf-8',errors='replace').splitlines()
    logs[str(p.relative_to(D))]={'errors':[l for l in lines if l.startswith(('ERROR:','SCRIPT ERROR:'))],
                               'warnings':[l for l in lines if l.startswith('WARNING:')]}
checks['final_logs_no_errors']=not any(v['errors'] for v in logs.values())
captures=list(D.glob('route_*/*.png'))
checks['production_captures_1280x720']=bool(captures) and all(struct.unpack('>II',p.read_bytes()[16:24])==(1280,720) for p in captures)
result={'status':'PASS' if all(checks.values()) else 'BLOCKED','checks':checks,'changed_existing_files':changed,
        'tests':f"{sum(t['pass'] for t in tests if t['name']!='main')}/33",'main_exit':tests[-1]['exit'],
        'test_warnings':{t['name']:t['warnings'] for t in tests if t['warnings']},'logs':logs,'contract':contract,
        'asset':export,'routes':routes,'license':'Hidden AvatarSample_A driver retained; public-release blocker NOT resolved.',
        'acceptance_method':'Real OpenGL scripted/input/API production routes; controlled supplementary views. Not manual keyboard/mouse.'}
(D/'final_validation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(checks,indent=2))
raise SystemExit(0 if all(checks.values()) else 1)
