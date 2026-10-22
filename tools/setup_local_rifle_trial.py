"""Install the optional local animation trial into an isolated source snapshot.

Legacy installer for snapshots without motion integration. Current checkout already
includes the authorized 16-clip library in local_motion/; it needs no installation.
For legacy snapshots, supply the library produced by bake_rifle_trial.gd. Refuses the repository, Git checkouts, non-isolated names,
changed base files, and existing outputs. Never modifies the source checkout.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    project = args.project.resolve(strict=True)
    library = args.library.resolve(strict=True)
    if project == root or project.is_relative_to(root) or any((p / ".git").exists() for p in [project, *project.parents]):
        parser.error("Use a NEW isolated snapshot outside every Git checkout")
    settings = (project / "project.godot").read_text(encoding="utf-8")
    if 'config/name="Bunny Verification ' not in settings:
        parser.error("Snapshot must retain its separate Bunny Verification app name")
    if library.suffix != ".tres":
        parser.error("Expected a locally baked .tres AnimationLibrary")
    local = project / "local_motion"
    templates = {
        "local_rifle_trial_player.gd": "player.gd",
        "local_rifle_trial_rig.gd": "rig.gd",
        "local_rifle_trial_hands.gd": "hands.gd",
        "local_rifle_trial_axis.gd": "axis.gd",
        "local_rifle_trial_gaze.gd": "gaze.gd",
        "local_rifle_trial_relax.gd": "relax.gd",
    }
    targets = [local / name for name in [*templates.values(), "library.tres", "installation.json"]]
    if any(p.exists() for p in targets):
        parser.error("Local trial already exists; never overwrite an earlier candidate")
    patches = [
        ("scenes/player/player.tscn", "res://scripts/player/player_controller.gd", "res://local_motion/player.gd"),
        ("scripts/player/player_controller.gd", "res://scripts/presentation/artoria_bunny/pose_adapter.gd", "res://local_motion/rig.gd"),
    ]
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    prepared = []
    for name, old, new in patches:
        path = project / name
        text = path.read_text(encoding="utf-8")
        if path.read_bytes() != (root / name).read_bytes() or text.count(old) != 1:
            parser.error(f"Base source differs or was already patched: {name}")
        prepared.append((path, text.replace(old, new), {"path": name, "before": sha(path), "replacement": [old, new]}))
    local.mkdir(exist_ok=True)
    for source, dest in templates.items():
        shutil.copy2(root / "tools" / source, local / dest)
    shutil.copy2(library, local / "library.tres")
    rows = []
    for path, text, row in prepared:
        path.write_text(text, encoding="utf-8")
        row["after"] = sha(path)
        rows.append(row)
    report = {
        "scope": "LOCAL ONLY, no model substitution or public distribution approval",
        "library_input": str(library), "library_sha256": sha(library),
        "patched_base_files": rows,
        "generated_files": {p.name: sha(p) for p in targets[:-1]},
    }
    (local / "installation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("LOCAL RIFLE TRIAL INSTALLED", project, "original model and gameplay rules preserved")


if __name__ == "__main__":
    main()
