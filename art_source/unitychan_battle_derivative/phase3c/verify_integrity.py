from pathlib import Path
import json,hashlib,subprocess
D=Path(__file__).resolve().parent;R=D.parents[2];B=json.loads((D/'baseline.json').read_text());W=json.loads((D/'workspace.json').read_text());P=Path(W['project'])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assets={k:sha(R/v['path'])==v['sha256'] for k,v in B['assets'].items()}
manifest=json.loads((D/'source_manifest.json').read_text());source_drift=[n for n,h in manifest.items() if not (R/n).exists() or sha(R/n)!=h]
isolated_drift=[n for n,h in manifest.items() if not (P/n).exists() or sha(P/n)!=h]
source=(R/'scripts/player/player_controller.gd').read_text(encoding='utf-8-sig')
for old,new in json.loads((D/'isolated_changes.json').read_text())['substitutions'].items():source=source.replace(old,new)
exact=(P/'scripts/player/player_controller.gd').read_text()==source
M=json.loads((R/'art_source/unitychan_battle_legacy/recovery_manifest.json').read_text());official=[]
for row in M['files']:
 for suffix,key in [('', 'sha256'),('.meta','meta_sha256')]:official.append(sha(R/'art_source/unitychan_battle_legacy/official_1_1'/(row['path']+suffix))==row[key])
protected=subprocess.check_output(['git','diff','--name-only','--','scripts','scenes','tests','resources'],cwd=R,text=True).splitlines()
report={'assets_unchanged':assets,'source_snapshot_drift':source_drift,'isolated_snapshot_drift':isolated_drift,'isolated_player_exact_two_substitutions':exact,'official_hashes_checked':len(official),'official_all_match':all(official),'protected_diff':protected,'HEAD':subprocess.check_output(['git','rev-parse','HEAD'],cwd=R,text=True).strip()}
report['pass']=all(assets.values()) and not source_drift and isolated_drift==['scripts/player/player_controller.gd'] and exact and all(official) and not protected
(D/'final_integrity.json').write_text(json.dumps(report,indent=2));(D/'git_status_final.txt').write_text(subprocess.check_output(['git','status','--short'],cwd=R,text=True));print(json.dumps(report,indent=2));assert report['pass']
