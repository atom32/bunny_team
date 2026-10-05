"""Launch an imported build with an isolated, persistent human playtest profile.
Never deletes saves, imports assets, changes repository files, or starts a test driver.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import subprocess


def launch_spec(project, godot, root, profile):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,39}", profile):
        raise ValueError("Profile must be 1-40 letters, digits, underscores or hyphens.")
    project, godot, root = Path(project).resolve(), Path(godot).resolve(), Path(root).resolve()
    if not (project / "project.godot").is_file() or not (project / ".godot/imported").is_dir():
        raise ValueError("Choose an already imported, verified build. This launcher will not import or modify it.")
    if not godot.is_file():
        raise ValueError("Godot executable does not exist.")
    if root == project or project in root.parents:
        raise ValueError("Playtest data must be outside the project.")
    data = root / profile
    env = dict(os.environ, APPDATA=str(data / "userdata"), LOCALAPPDATA=str(data / "localdata"))
    # Never inherit verification capture paths into a real human session.
    env.pop("BUNNY_EVIDENCE", None)
    return [str(godot), "--path", str(project)], env, data


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", required=True, help="Imported verified project; no test-scene override")
    p.add_argument("--godot", default="E:/Godot/Godot_v4.7.2-stable_win64_console.exe")
    p.add_argument("--profile", default="alpha01-human")
    p.add_argument("--data-root", default=str(Path(os.environ["LOCALAPPDATA"]) / "BunnyAlphaPlaytests"))
    p.add_argument("--dry-run", action="store_true", help="Print launch details; do not create files or start game")
    args = p.parse_args()
    command, env, data = launch_spec(args.project, args.godot, args.data_root, args.profile)
    print("Build:", args.project, "\nIsolated persistent profile:", data)
    print("Normal BOOT; no tutorial skip, fixture grants, fixed-fps or autoplay.")
    if args.dry_run:
        print(json.dumps({"command": command, "APPDATA": env["APPDATA"], "LOCALAPPDATA": env["LOCALAPPDATA"]}, indent=2))
        return
    for key in ("APPDATA", "LOCALAPPDATA"):
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    log = data / (stamp + ".log")
    print("Log:", log, "\nClose the game normally to finish this session.")
    # The requested game window is visible; this is not a background helper.
    with log.open("wb") as output:
        result = subprocess.run(command, env=env, stdout=output, stderr=subprocess.STDOUT)
    (data / (stamp + ".json")).write_text(json.dumps({"build": str(Path(args.project).resolve()), "profile": args.profile, "exit": result.returncode, "log": str(log)}, indent=2), encoding="utf-8")
    raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
