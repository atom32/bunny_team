"""Snapshot current Git-visible WIP, cold import, regress and optionally render route.

No dependencies beyond Python stdlib and Godot. Never changes the source checkout.
Output must be a NEW directory outside the repository. Godot profiles are isolated.
Example: python tools/verify_migration.py --godot <console.exe> --output <new-dir> --route
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--import-only", action="store_true")
    parser.add_argument("--route", action="store_true")
    args = parser.parse_args()
    if args.route and args.import_only:
        parser.error("--route and --import-only are mutually exclusive")
    root = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    if out.exists() or out.is_relative_to(root):
        parser.error("Output must be a NEW directory outside the repository")
    out.mkdir(parents=True)
    project = out / "project"
    names = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root
    ).decode().split("\0")
    manifest = {}
    for name in sorted(set(names)):
        src = root / name
        if not name or not src.is_file():
            continue  # A moved/deleted old tracked path is not in the working snapshot.
        if not src.resolve().is_relative_to(root):
            raise ValueError(f"Source escapes checkout: {name}")
        dest = project / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        manifest[name] = hashlib.sha256(src.read_bytes()).hexdigest()
    (out / "source_manifest.json").write_text(json.dumps(manifest, indent=2))
    env = dict(os.environ, APPDATA=str(out / "userdata"), LOCALAPPDATA=str(out / "localdata"))
    results = []

    def run(name, extra, route=False):
        log = out / (name + ".log")
        command = [str(args.godot.resolve()), "--path", str(project)] + extra
        child_env = dict(env)
        if route:
            capture = out / "captures"
            capture.mkdir()
            child_env.update(BUNNY_EVIDENCE=str(capture), APPDATA=str(out / "route_userdata"),
                             LOCALAPPDATA=str(out / "route_localdata"))
        with log.open("wb") as f:
            result = subprocess.run(command, env=child_env, stdout=f, stderr=subprocess.STDOUT,
                                    timeout=180, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        data = log.read_bytes()
        text = data.decode("utf-8", errors="replace")
        errors = re.findall(r"^(?:SCRIPT )?ERROR:.*$", text, re.M)
        warnings = re.findall(r"^WARNING:.*$", text, re.M)
        passed = result.returncode == 0 and not errors and not re.search(r"(?:ROUTE_FAIL|: FAIL)", text)
        if name not in {"cold_import", "main", "route"}:
            passed = passed and "PASS" in text
        if name == "cold_import":
            passed = passed and not warnings  # This checkpoint expects 0/0, not ignored warnings.
        row = {"name": name, "command": command, "exit": result.returncode, "pass": bool(passed),
               "errors": errors, "warnings": warnings, "sha256": hashlib.sha256(data).hexdigest()}
        results.append(row)
        (out / "results.json").write_text(json.dumps(results, indent=2))
        print(name, "PASS" if passed else "FAIL", "exit", result.returncode,
              "ERROR", len(errors), "WARNING", len(warnings), flush=True)
        return passed

    if not run("cold_import", ["--headless", "--editor", "--import"]):
        raise SystemExit(1)
    if args.import_only:
        return
    scenes = sorted((project / "tests").glob("*.tscn"))
    if len(scenes) != 33:
        raise RuntimeError(f"Expected checkpoint's 33 tests, got {len(scenes)}; review the test inventory")
    for scene in scenes:
        if not run(scene.stem, ["--headless", "res://tests/" + scene.name, "--quit-after", "1200"]):
            raise SystemExit(1)
    if not run("main", ["--headless", "--quit-after", "180"]):
        raise SystemExit(1)
    if args.route and not run("route", ["--rendering-method", "gl_compatibility", "--resolution", "1280x720",
                                        "--script", "res://tools/phase2b_route_probe.gd"], route=True):
        raise SystemExit(1)
    print("ALL TESTS 33/33 PASS; manual input NOT claimed; release permission NOT implied")


if __name__ == "__main__":
    main()
