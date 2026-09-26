"""Read-only Phase 4A scope, budget, regression and persistence evidence audit."""
from pathlib import Path
import hashlib, json, struct, subprocess

D = Path(__file__).resolve().parent
R = D.parents[1]
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
baseline = read(D / 'protected_baseline.json')
changed = [p for p,h in baseline['hashes'].items() if not (R/p).exists() or sha(R/p) != h]
allowed = ['scenes/areas/prototype_field_office.tscn', 'scenes/hanger/hanger.tscn', 'scripts/combat/combat_effects.gd']
checks = {'only_three_existing_runtime_files_changed': sorted(changed) == sorted(allowed)}
sources = read(D / 'existing_prop_metrics.json')
checks['six_Kenney_source_meshes_unchanged'] = all(sha(R/'assets/environment/kenney_space_station_kit'/f'{k}.glb') == v['sha256'] for k,v in sources.items())
manifest = read(R/'art_source/unitychan_battle_legacy/recovery_manifest.json')
official = R/'art_source/unitychan_battle_legacy/official_1_1'
official_checks = []
for row in manifest['files']:
    official_checks.append(sha(official/row['path']) == row['sha256'])
    if row.get('meta_sha256'):
        official_checks.append(sha(official/(row['path']+'.meta')) == row['meta_sha256'])
checks['official_source_unchanged'] = all(official_checks)
for category,path in [('player','assets/characters/unitychan_battle/battle_presentation.glb'),('enemy','assets/characters/vrm_avatar')]:
    names = subprocess.check_output(['git','ls-files',path],cwd=R,text=True).splitlines()
    def baseline_equal(n):
        data = (R/n).read_bytes()
        if Path(n).suffix == '.md': data = data.replace(b'\r\n', b'\n')
        return data == subprocess.check_output(['git','show',f"{baseline['head']}:{n}"],cwd=R)
    checks[category+'_source_unchanged'] = bool(names) and all(baseline_equal(n) for n in names if not n.endswith('.import'))
origin = read(D/'save_source.json')
checks['original_production_save_unchanged'] = sha(Path(origin['path'])) == origin['sha256']
tests = read(D/'regression/results.json')
checks['33_tests_and_main_exit_zero'] = len(tests) == 34 and all(r['pass'] for r in tests)
routes = {}
for name in ['Rifle','SMG']:
    route = read(D/f'route_{name}/route_result.json')
    reloaded = read(D/f'persistence_{name}/reload.json')
    flow = read(D/f'route_{name}/identity_flow.json')
    before, after, outcome = flow['pre_sortie_profile'], flow['post_result_profile'], flow['outcome']
    expected_items = {i['instance_id']:i for i in before['inventory']['items']}
    for item_id in outcome['initial_carried_instance_ids']: expected_items.pop(item_id, None)
    for item in outcome['inventory']['items']: expected_items[item['instance_id']] = item
    actual_items = {i['instance_id']:i for i in after['inventory']['items']}
    checks[name+'_route'] = not route['failure'] and all(route['checks'].values())
    checks[name+'_restart'] = all(reloaded['checks'].values())
    checks[name+'_independent_warehouse_merge'] = (actual_items == expected_items and before['inventory']['capacity'] == after['inventory']['capacity'] and after['loadout'] == outcome['loadout'])
    routes[name] = {'checks':len(route['checks']), 'combat':route['combat'], 'reload_checks':len(reloaded['checks']), 'warehouse_merge':checks[name+'_independent_warehouse_merge']}
checks['smoke_cleanup'] = all(read(D/'fx/fx_result.json').values())
checks['runtime_prop_contract'] = all(read(D/'prop_contract.json')['checks'].values())
budget = []
for row in read(D/'prop_exports.json')['assets']:
    path = R/'assets/environment/service_props'/f"{row['asset']}.glb"
    data = path.read_bytes(); length = struct.unpack_from('<I',data,12)[0]
    gltf = json.loads(data[20:20+length]); blob = data[28+length:]
    images = []
    for image in gltf.get('images',[]):
        view = gltf['bufferViews'][image['bufferView']]; offset = view.get('byteOffset',0)
        png = blob[offset:offset+view['byteLength']]
        assert png[:8] == b'\x89PNG\r\n\x1a\n'
        images.append({'width':struct.unpack_from('>I',png,16)[0], 'height':struct.unpack_from('>I',png,20)[0], 'bytes':len(png)})
    checks[row['asset']+'_export_hash'] = sha(path) == row['runtime_sha256']
    checks[row['asset']+'_static_only'] = not gltf.get('skins') and not gltf.get('animations') and not gltf.get('cameras')
    budget.append({'asset':row['asset'], 'triangles':row['triangles'], 'materials':len(gltf['materials']), 'surfaces':sum(len(m['primitives']) for m in gltf['meshes']), 'images':images,'glb_bytes':len(data),'instances':2})
log_issues = {}
for path in [D/'fx/run.log'] + [D/f'{folder}/{log}' for folder,log in [('route_Rifle','route.log'),('route_SMG','route.log'),('persistence_Rifle','reload.log'),('persistence_SMG','reload.log')]]:
    lines = path.read_text(encoding='utf-8',errors='replace').splitlines()
    errors = [l for l in lines if l.startswith(('ERROR:', 'SCRIPT ERROR:'))]
    warnings = [l for l in lines if l.startswith('WARNING:')]
    log_issues[str(path.relative_to(D))] = {'errors':errors,'warnings':warnings}
checks['final_route_and_fx_no_errors'] = all(not v['errors'] for v in log_issues.values())
report = {'checks':checks, 'changed_runtime_files':changed, 'official_file_hashes_checked':len(official_checks), 'tests':'33/33', 'main_exit':tests[-1]['exit'], 'routes':routes, 'budgets':budget, 'test_warnings':{r['name']:r['warnings'] for r in tests if r['warnings']}, 'route_fx_logs':log_issues, 'limitation':'One concurrent graphical route exit timeout retained in diagnostic_route_failure; not reproduced in the final sequential run. Cause not established. No gameplay workaround.'}
(D/'final_validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(0 if all(checks.values()) else 1)
