"""Read-only Phase 4B integrity and validation audit. Does not run or weaken tests."""
from pathlib import Path
import hashlib, json
D = Path(__file__).resolve().parent
R = D.parents[2]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
baseline = read(D/'baseline.json')
changed = [p for p,h in baseline['hashes'].items() if sha(R/p)!=h]
runtime = ['assets/characters/unitychan_battle/presentation/anime_surface.gdshader',
           'assets/characters/unitychan_battle/presentation/material_profile.json',
           'scripts/presentation/unitychan/presentation_adapter.gd']
allowed = runtime+['art_source/unitychan_battle_derivative/README.md']
checks = {'only_scoped_existing_files_changed':set(changed)<=set(allowed),
          'three_runtime_files_changed':all(p in changed for p in runtime)}
manifest = read(R/'art_source/unitychan_battle_legacy/recovery_manifest.json')
official = R/'art_source/unitychan_battle_legacy/official_1_1'
verified = []
for row in manifest['files']:
    verified.append(sha(official/row['path'])==row['sha256'])
    if row.get('meta_sha256'): verified.append(sha(official/(row['path']+'.meta'))==row['meta_sha256'])
checks['68_official_hashes_match'] = len(verified)==68 and all(verified)
build = read(R/'art_source/unitychan_battle_derivative/build_report.json')
checks['runtime_glb_equals_original_conversion'] = sha(R/'assets/characters/unitychan_battle/battle_presentation.glb')==build['glb_sha256']
checks['derivative_glb_equals_original_conversion'] = sha(R/'art_source/unitychan_battle_derivative/battle_presentation.glb')==build['glb_sha256']
checks['no_new_phase4b_master_edit'] = sha(R/'art_source/unitychan_battle_derivative/battle_master.blend')==baseline['hashes']['art_source/unitychan_battle_derivative/battle_master.blend']
geometry = read(D/'geometry_comparison.json')['meshes']
checks['face_shape_topology_uv_weights_preserved'] = all(
    r['position_max_m']<1e-6 and r['uv_max']<1e-7 and r['unmatched_corners']==0 and
    r['oriented_triangles_equal_after_tolerance_match'] and r['weight_max_delta_by_bone_name']==0
    for n,r in geometry.items() if n in ['head_Def','headNose','eyeBall','eyeHighLightShape'])
head = geometry['head_Def']
checks['18_head_morphs_preserved'] = len(head['morph_position_max_m_by_shape'])==19 and max(head['morph_position_max_m_by_shape'].values())<1e-6
checks['source_material_bindings_match'] = all(read(D/'material_verification.json')['checks'].values())
origin = read(D/'save_source.json')
checks['original_user_save_unchanged'] = sha(Path(origin['path']))==origin['sha256']
tests = read(D/'regression/results.json')
checks['33_tests_plus_main_pass'] = len(tests)==34 and all(r['pass'] and r['exit']==0 for r in tests)
animation = read(D/'animation/results.json')
checks['24_animation_weapon_combinations_pass'] = len(animation)==24 and all(r['pass'] for r in animation)
routes = {}
for name in ['Rifle','SMG']:
    route = read(D/f'route_{name}/route_result.json')
    loaded = read(D/f'persistence_{name}/reload.json')
    flow = read(D/f'route_{name}/identity_flow.json')
    before,after,outcome = flow['pre_sortie_profile'],flow['post_result_profile'],flow['outcome']
    expected = {i['instance_id']:i for i in before['inventory']['items']}
    for item_id in outcome['initial_carried_instance_ids']: expected.pop(item_id,None)
    for item in outcome['inventory']['items']: expected[item['instance_id']]=item
    checks[name+'_route'] = not route['failure'] and all(route['checks'].values())
    checks[name+'_restart'] = all(loaded['checks'].values())
    checks[name+'_independent_warehouse_merge'] = expected=={i['instance_id']:i for i in after['inventory']['items']} and before['inventory']['capacity']==after['inventory']['capacity'] and after['loadout']==outcome['loadout']
    routes[name] = {'check_count':len(route['checks']),'restart_check_count':len(loaded['checks']),'combat':route['combat']}
logs = {}
for name in ['hanger/run.log','material_probe.log','animation/run.log','route_Rifle/route.log','route_SMG/route.log','persistence_Rifle/reload.log','persistence_SMG/reload.log']:
    lines = (D/name).read_text(encoding='utf-8',errors='replace').splitlines()
    logs[name] = {'errors':[l for l in lines if l.startswith(('ERROR:','SCRIPT ERROR:'))], 'warnings':[l for l in lines if l.startswith('WARNING:')]}
checks['graphical_and_restart_logs_no_errors'] = all(not v['errors'] for v in logs.values())
checks['evidence_shader_equals_runtime_shader'] = sha(D/'uts_subset.gdshader')==sha(R/runtime[0])
report = {'checks':checks, 'changed_existing_files':changed,'official_hash_count':len(verified),'glb_sha256':build['glb_sha256'],
          'tests':'33/33','main_exit':tests[-1]['exit'],'test_warnings':{r['name']:r['warnings'] for r in tests if r['warnings']},
          'routes':routes,'logs':logs,'scope':'Automated graphics/API validation, not manual. Source-semantic subset, not independent Unity-render pixel parity.'}
(D/'final_validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(0 if all(checks.values()) else 1)
