from pathlib import Path
import json
D=Path(__file__).resolve().parent
flow=json.loads((D/'route_Rifle/identity_flow.json').read_text())
pre=flow['pre_sortie_profile'];out=flow['outcome'];post=flow['post_result_profile']
def items(profile):return {i['instance_id']:i for i in profile['inventory']['items']}
expected=items(pre)
for id in out['initial_carried_instance_ids']:expected.pop(id,None)
for item in out['inventory']['items']:expected[item['instance_id']]=item
saved=json.loads((D/'persistence/profile.json').read_text())
reload=json.loads((D/'persistence/reload.json').read_text())
checks={
 'outcome_session_matches':out['session_id']==flow['session_id'],
 'completed_result':out['result_type']==0,
 'warehouse_equals_uncarried_plus_recovered':items(post)==expected,
 'warehouse_capacity_preserved':post['inventory']['capacity']==pre['inventory']['capacity'],
 'loadout_matches_outcome':post['loadout']==out['loadout'],
 'equipped_instance_ids_preserved':pre['loadout']==post['loadout'],
 'schema_unchanged':saved['schema_version']==1,
 'save_matches_committed_profile':saved['profile']==post,
 'separate_process_reload_matches':reload['profile']==post,
 'no_avatar_identity_serialized':set(post)=={'inventory','loadout'},
}
report={'checks':checks,'pass':all(checks.values()),'note':'Independently reconstructs warehouse merge from pre-sortie + recovered outcome. Ammo consumption is expected, not equal-to-before. No Person/progression/economy fields exist in current schema.'}
(D/'identity_verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2));assert report['pass']
