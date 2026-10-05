import pathlib,json,hashlib
r=pathlib.Path(r'D:/bunny_team');v=pathlib.Path(r'C:/Users/admin/AppData/Local/Temp/bunny_compact_releasecheck_20261005')
results=json.loads((v/'results.json').read_text());assert len(results)==79 and all(x['pass'] for x in results)
manifest=json.loads((v/'source_manifest.json').read_text());runtime=['scripts/presentation/slice/hideout.gd','tests/hideout_idle_test.gd','scenes/presentation/compact_hideout/environment.tscn','scenes/presentation/compact_hideout/appearance.gd']
assets=[k for k in manifest if k.startswith('assets/environment/compact_hideout/') and pathlib.Path(k).suffix in ['.glb','.gltf','.bin','.jpg','.png']]
for k in runtime+assets:assert hashlib.sha256((r/k).read_bytes()).hexdigest()==manifest[k],k
b=r/'art_source/hideout_mechanized_trial_20261005';before=json.loads((b/'character_before.json').read_text())
assert all(hashlib.sha256((r/k).read_bytes()).hexdigest()==h for k,h in before.items())
cap=b/'integration_evidence/detail_capture_final.log';t=cap.read_text();assert 'COMPACT_PRODUCTION_CAPTURE: PASS' in t and 'ERROR:' not in t
row={'checks':len(results),'scene_tests':59,'all_pass':True,'runtime_and_asset_manifest_match':len(runtime+assets),'current_character_files_unchanged':len(before),'final_verification':str(v),'actual_capture_log':str(cap),'remaining_required_work':[],'optional_polish':['ambient fan/radio sound','lower hardware performance profiling','seat transition blending']}
(b/'COMPLETION_AUDIT.json').write_text(json.dumps(row,indent=2));print(json.dumps(row))
p=r/'scenes/presentation/compact_hideout/INTEGRATION.md';s=p.read_text().replace('Final exact-state full gate running:','Final exact-state full gate PASS (79/79 checks, 59 scene tests; current runtime/source asset hashes match its manifest):').replace('Inspect results.json before claiming completion.','Completion audit retained in art_source/hideout_mechanized_trial_20261005/COMPLETION_AUDIT.json.');p.write_text(s)
p=r/'Handoff.md';s=p.read_text();prefix='''## Latest working tree — Compact mechanized Hideout integrated (2026-10-05)

- Approved 6x4m imported environment now replaces the exhibition shell in Hideout/menu. Hanger retains inventory/loadout/save ownership; camera-only hub, not a new walkable level.
- Floor-level character anchor; equipment preview restoration/rebuild preserved. Rest uses original Quaternius seated clip at a separate imported metal stool. Character GLB/materials/geometry unchanged (27 current Artoria source files SHA256 match).
- Free CC0 concrete/Poly Haven/Kenney resources, field locker, pipe bend and authored electrical cable dressing; local cold/warm lights. No purchase, procedural environment modeling, unrelated WIP reset, commit or push.
- Exact-state 79/79 checks (59 scene tests) PASS; cold0errors/2knownFBX warnings, cross-process/quit probes PASS. C:/Users/admin/AppData/Local/Temp/bunny_compact_releasecheck_20261005. Final runtime/import asset hashes match snapshot. No renderer errors in actual Forward+ captures.
- Docs: scenes/presentation/compact_hideout/INTEGRATION.md. Durable actual menu/equipment/Operations/Workshop/Rest captures, scoped backups/diff and audit: art_source/hideout_mechanized_trial_20261005/.
- Optional next polish: ambient fan/radio audio, seated transition blend, lower-hardware profiling. Do not confuse this presentation integration with complete Alpha human endurance acceptance.

'''
s=s.replace('# Bunny Team — Current Project Handoff\n','# Bunny Team — Current Project Handoff\n\n'+prefix,1);p.write_text(s)
