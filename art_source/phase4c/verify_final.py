"""Read-only, fail-closed Phase 4C evidence audit. Never edits tests or user saves."""
from pathlib import Path
import json, hashlib
D=Path(__file__).resolve().parent; R=D.parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
b=read(D/'baseline.json')
changed=[p for p,h in b['hashes'].items() if sha(R/p)!=h]
allowed={'scripts/combat/combat_effects.gd','scenes/battle/urban_arena.tscn','scripts/enemies/enemy_controller.gd','scripts/systems/audio_director.gd'}
checks={'only_two_presentation_files_plus_two_authorized_cleanup_fixes_changed':set(changed)==allowed,
        'baseline_is_cc81d303':b['head']=='cc81d3034d364d51f213cb9b5d1128d1564222a6'}
manifest=read(R/'art_source/unitychan_battle_legacy/recovery_manifest.json')
official=R/'art_source/unitychan_battle_legacy/official_1_1'
verified=[]
for row in manifest['files']:
    verified.append(sha(official/row['path'])==row['sha256'])
    if row.get('meta_sha256'):verified.append(sha(official/(row['path']+'.meta'))==row['meta_sha256'])
checks['68_official_hashes_identical']=len(verified)==68 and all(verified)
build=read(R/'art_source/unitychan_battle_derivative/build_report.json')
checks['character_glb_unchanged']=sha(R/'assets/characters/unitychan_battle/battle_presentation.glb')==build['glb_sha256']
checks['character_files_materials_adapters_unchanged']=not any('unitychan' in p or p.startswith('assets/characters/') for p in changed)
checks['all_existing_tests_unchanged']=not any(p.startswith('tests/') for p in changed)
checks['authorized_lifecycle_probe']=all(read(D/'lifecycle_probe.json')['checks'].values())
# Prove the only controller difference is the explicitly authorized scene guard.
import subprocess
enemy=(R/'scripts/enemies/enemy_controller.gd').read_text()
original=subprocess.check_output(['git','show',b['head']+':scripts/enemies/enemy_controller.gd'],cwd=R).decode().replace('\r\n','\n')
expected=original.replace('if is_dead or not is_instance_valid(target) or target.is_dead:',
    'if not is_inside_tree() or is_dead or not is_instance_valid(target) or not target.is_inside_tree() or target.is_dead:')
checks['enemy_change_exactly_authorized_guard']=enemy==expected
audio=(R/'scripts/systems/audio_director.gd').read_text()
original_audio=subprocess.check_output(['git','show',b['head']+':scripts/systems/audio_director.gd'],cwd=R).decode().replace('\r\n','\n')
def without_shutdown(text):
    before,tail=text.split('func shutdown_for_test() -> void:',1)
    return before+tail.split('\n\n\nfunc _exit_tree()',1)[1]
checks['audio_change_only_test_shutdown']=without_shutdown(audio)==without_shutdown(original_audio)
audio_runs=read(D/'audio_shutdown/results.json')
checks['audio_shutdown_fixed_count_25_runs']=len(audio_runs)==25 and all(row['pass'] for row in audio_runs)
source=read(D/'save_source.json')
checks['real_user_save_unchanged']=sha(Path(source['path']))==source['sha256']
arena=read(D/'arena_contract.json')
checks['arena_geometry_navigation_contract']=all(arena['checks'].values())
fx=read(D/'visual_probe.json')
checks['fx_rng_and_cleanup']=all(v for k,v in fx.items() if k.endswith(('_cleanup','_unchanged')))
old=(D/'before/combat_effects.gd').read_text();new=(R/'scripts/combat/combat_effects.gd').read_text()
def function(t,n):return t.split('static func '+n+'(',1)[1].split('\n\n\nstatic func',1)[0].strip()
checks['tracer_telegraph_rocket_explosion_unchanged']=all(function(old,n)==function(new,n) for n in ['tracer','telegraph','rocket_trail','explosion'])
tests=read(D/'regression/results.json')
checks['33_tests_and_main_pass']=len(tests)==34 and all(row['pass'] for row in tests)
routes={};events={}
for primary in ['Rifle','SMG']:
    route=read(D/f'route_{primary}/route_result.json')
    reload=read(D/f'persistence_{primary}/reload.json')
    flow=read(D/f'route_{primary}/identity_flow.json')
    checks[primary+'_production_route']=not route['failure'] and all(route['checks'].values())
    checks[primary+'_cross_process_reload']=all(reload['checks'].values())
    before,after,outcome=flow['pre_sortie_profile'],flow['post_result_profile'],flow['outcome']
    expected={i['instance_id']:i for i in before['inventory']['items']}
    for item in outcome['initial_carried_instance_ids']:expected.pop(item,None)
    for item in outcome['inventory']['items']:expected[item['instance_id']]=item
    checks[primary+'_independent_inventory_commit']=expected=={i['instance_id']:i for i in after['inventory']['items']} and after['loadout']==outcome['loadout'] and before['inventory']['capacity']==after['inventory']['capacity']
    routes[primary]={'checks':len(route['checks']),'restart_checks':len(reload['checks']),'combat':route['combat'],'effects':route['combat_events']}
    for name,count in route['combat_events'].items():events[name]=events.get(name,0)+count
combat_lanes={}
for primary in ['Rifle','SMG']:
    lane=read(D/f'combat_{primary}/combat_lane.json')
    checks[primary+'_normal_AI_combat_lane']=all(lane['checks'].values())
    combat_lanes[primary]={'checks':lane['checks'],'shots':lane['shots'],'effects':lane['effects']}
    for name,count in lane['effects'].items():events[name]=events.get(name,0)+count
checks['production_combat_effects_observed']=all(events.get(n,0)>0 for n in ['MuzzleFlash','HitEffect','ImpactSmoke','RocketTrail','Explosion','DodgeStreak','EnemyDied'])
logs={}
for p in list(D.glob('*.log'))+list(D.glob('route_*/*.log'))+list(D.glob('persistence_*/*.log'))+list(D.glob('combat_*/*.log'))+list(D.glob('audio_shutdown/*.log')):
    lines=p.read_text(encoding='utf-8',errors='replace').splitlines()
    logs[str(p.relative_to(D))]={'errors':[l for l in lines if l.startswith(('ERROR:','SCRIPT ERROR:'))],'warnings':[l for l in lines if l.startswith('WARNING:')]}
checks['validation_logs_no_errors']=not any(v['errors'] for v in logs.values())
report={'status':'PASS' if all(checks.values()) else 'BLOCKED','checks':checks,'changed_existing_files':changed,'official_hashes':len(verified),'tests':f"{sum(t['pass'] for t in tests if t['name']!='main')}/33",'main_exit':tests[-1]['exit'],
        'routes':routes,'combat_lanes':combat_lanes,'logs':logs,'test_warnings':{t['name']:t['warnings'] for t in tests if t['warnings']},'asset':read(D/'barrier_export.json'),
        'performance':read(D/'performance.json'),'scope':'Bounded C+D subphase only; A enemy and B weapon replacements deferred. Automated graphical/API evidence, not manual acceptance.'}
(D/'final_validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(checks,indent=2))
raise SystemExit(0 if all(checks.values()) else 1)
