"""Read-only content audit in a Git-visible snapshot with isolated Godot profiles.

python tools/audit_content.py --godot <console.exe> --output <NEW outside directory>
The report lists validation errors, warnings, references and acquisition channels.
Neither imports nor project autoloads access the normal checkout/user directory.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    if out.exists() or out.is_relative_to(root):
        parser.error("Output must be a NEW directory outside the repository")
    out.mkdir(parents=True)
    project = out / "project"
    names = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root).decode().split("\0")
    manifest = {}
    for name in sorted(set(names)):
        src = root / name
        if not name or not src.is_file():
            continue
        if not src.resolve().is_relative_to(root):
            raise ValueError(f"Source escapes checkout: {name}")
        dst = project / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        manifest[name] = hashlib.sha256(src.read_bytes()).hexdigest()
    (out / "source_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    env = dict(os.environ, APPDATA=str(out / "userdata"), LOCALAPPDATA=str(out / "localdata"),
               XDG_DATA_HOME=str(out / "userdata"), HOME=str(out / "home"),
               NEON_CONTENT_AUDIT_REPORT=str(out / "content_audit.json"))
    settings = project / "project.godot"
    settings.write_text(re.sub(r'^config/name=.*$', 'config/name="Neon Content Audit ' + out.name + '"',
                              settings.read_text(encoding="utf-8"), flags=re.M), encoding="utf-8")
    commands = [("cold_import", ["--headless", "--editor", "--import"]),
                ("content_audit", ["--headless", "res://tools/content_audit.tscn", "--quit-after", "1200"])]
    results = []
    for name, extra in commands:
        log = out / (name + ".log")
        with log.open("wb") as stream:
            result = subprocess.run([str(args.godot.resolve()), "--path", str(project)] + extra,
                                    env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=180,
                                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        text = log.read_text(encoding="utf-8", errors="replace")
        errors = re.findall(r"^(?:SCRIPT )?ERROR:.*$", text, re.M)
        warnings = re.findall(r"^WARNING:.*$", text, re.M)
        passed = result.returncode == 0 and not errors and (name == "cold_import" or "CONTENT_AUDIT: PASS" in text)
        if name == "cold_import":
            passed = passed and all(re.fullmatch(r"WARNING: FBX: ufbx warning: Bad UTF-8 string \(x\d+\)", warning) for warning in warnings)
        results.append({"name": name, "exit": result.returncode, "pass": passed, "errors": errors, "warnings": warnings,
                        "sha256": hashlib.sha256(log.read_bytes()).hexdigest()})
        (out / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(name, "PASS" if passed else "FAIL", flush=True)
        if not passed:
            raise SystemExit(1)
    report = json.loads((out / "content_audit.json").read_text(encoding="utf-8"))
    print("Items:", report["counts"]["items"], "Warnings:", len(report["warnings"]), "Report:", out / "content_audit.json")


if __name__ == "__main__":
    main()
