"""Read-only verification of phase scope, frozen oracle and unchanged test inventory."""
from pathlib import Path
import hashlib, json, re, subprocess
D = Path(__file__).resolve().parent
P = D.parents[1]
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
baseline = json.loads((D / "baseline.json").read_text(encoding="utf-8"))
allowed = {
    "scripts/enemies/enemy_controller.gd", "scripts/presentation/enemy_drone_presentation.gd",
    "scenes/enemies/enemy.tscn", "tests/acceptance_smoke.gd", "tests/visual_enemy_acceptance.gd",
}
changed = [p for p, h in baseline["files"].items() if (sha(P / p) if (P / p).is_file() else None) != h]
current = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=P).decode().split("\0")
added = [p for p in current if p and (P / p).is_file() and p not in baseline["files"] and not p.startswith("art_source/phase4e/")]
old = (D / "oracle/enemy_controller.gd.txt").read_text(encoding="utf-8")
new = (P / "scripts/enemies/enemy_controller.gd").read_text(encoding="utf-8")
normalized = new.replace("_update_presentation", "_update_humanoid_visual").replace("KiteEnemyPresentation", "HumanoidRetargetVisual").replace('"EnemyPresentation"', '"EnemyCharacterVisual"')
normalized = re.sub(r"\bpresentation\b", "humanoid_visual", normalized)
manifest = json.loads((D / "oracle_manifest.json").read_text(encoding="utf-8"))
oracle = {}
for path in ["scripts/characters/humanoid_retarget_visual.gd", "scripts/player/character_combat_rig.gd", "scenes/weapons/assault_rifle.tscn"]:
    frozen = D / manifest["files"][path]["stored"]
    oracle[path] = {"frozen_hash_valid": sha(frozen) == manifest["files"][path]["baseline_sha256"], "lf_normalized_text_identical": frozen.read_text(encoding="utf-8") == (P/path).read_text(encoding="utf-8")}
old_tests = sorted(p for p in baseline["files"] if p.startswith("tests/") and p.endswith(".tscn"))
new_tests = sorted(p.relative_to(P).as_posix() for p in (P/"tests").glob("*.tscn"))
profile = Path.home()/"AppData/Roaming/Godot/app_userdata/Neon Bastion/profile.json"
checks = {
    "only_authorized_existing_files_changed": set(changed) == allowed,
    "no_unrelated_new_files": not added,
    "enemy_controller_only_presentation_identifier_type_constructor_changes": normalized == old,
    "frozen_oracle_dependencies_unchanged": all(all(v.values()) for v in oracle.values()),
    "same_33_test_scenes": old_tests == new_tests and len(new_tests) == 33,
    "test_runner_unchanged": (D/"run_regression.py").read_bytes() == (P/"art_source/phase4c1/run_regression.py").read_bytes(),
    "real_user_save_unchanged": sha(profile) == sha(D/"local/original_profile.json"),
}
report = {"checks":checks, "changed_existing_files":changed, "unexpected_added_files":added, "oracle_dependencies":oracle, "test_scenes":new_tests,
          "protected_files_compared":len(baseline["files"])-len(allowed), "real_user_save_sha256":sha(profile),
          "line_endings": "Git blobs LF vs Windows checkout CRLF; raw hashes retained, content equality normalized only for frozen text dependencies",
          "result": "PASS" if all(checks.values()) else "FAIL"}
(D/"scope_final.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(json.dumps({k:v for k,v in report.items() if k not in ["test_scenes","oracle_dependencies"]},indent=2))
raise SystemExit(0 if all(checks.values()) else 1)
