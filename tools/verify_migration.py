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
import sys
import time


def q02_extra_returns(profile, evidence):
    """Account for actual 1..3 Q02 loot trips, never fabricate or reroll progress."""
    before, after, outings = evidence["profile_before"], evidence["profile_after"], evidence["outings"]
    assert before["successful_sorties"] == 2 and before["narrative_slice"]["settled"]["Q01"] and not before["narrative_slice"]["settled"]["Q02"]
    assert 1 <= len(outings) <= 3 and all(row["number"] == i+1 for i, row in enumerate(outings))
    assert profile["successful_sorties"] == after["successful_sorties"] == 2+len(outings)
    assert profile["narrative_slice"]["settled"]["Q02"] and after["narrative_slice"]["settled"]["Q02"] and not profile["sortie_checkpoint"]
    return len(outings)-1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--import-only", action="store_true")
    parser.add_argument("--route", action="store_true")
    parser.add_argument("--renderer", choices=["forward_plus", "gl_compatibility"], default="forward_plus")
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
    # APPDATA is Windows-only; a unique Godot name also isolates user:// on macOS/Linux.
    settings = project / "project.godot"
    settings.write_text(re.sub(r'^config/name=.*$', 'config/name="Bunny Verification ' + out.name + '"',
                              settings.read_text(), flags=re.M))
    env = dict(os.environ, APPDATA=str(out / "userdata"), LOCALAPPDATA=str(out / "localdata"))
    results = []
    campaign_extra_returns = 0

    def run(name, extra, route=False):
        if campaign_extra_returns and not name.startswith("medical_intercept_"):
            extra = list(extra)
            if "--" not in extra: extra.append("--")
            extra.append(f"--campaign-extra-returns={campaign_extra_returns}")
        log = out / (name + ".log")
        command = [str(args.godot.resolve()), "--path", str(project)] + extra
        if name == "campaign_return_offsets_unit":
            command = [sys.executable, "-X", "utf8", "-B", str(project / "tests/test_campaign_return_offsets.py"), "-v"]
        if name == "localization_build":
            command = [sys.executable, "-X", "utf8", "-B", str(project / "tests/test_localization_build.py"), "-v"]
        child_env = dict(env)
        if name.startswith("normal_start") and not route:
            fixture = "normal_start_test" if name == "normal_start_read" else name
            child_env.update(APPDATA=str(out / (fixture + "_userdata")), LOCALAPPDATA=str(out / (fixture + "_localdata")))
        if name.startswith("first_sortie") and not route:
            fixture = {"first_sortie_read":"first_sortie_run", "first_sortie_salvage_read":"first_sortie_salvage"}.get(name,name)
            child_env.update(APPDATA=str(out / (fixture + "_userdata")), LOCALAPPDATA=str(out / (fixture + "_localdata")))
        if name.startswith("campus_entry_") and not route:
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"first_sortie_run_userdata"),LOCALAPPDATA=str(out/"first_sortie_run_localdata"),BUNNY_EVIDENCE=str(capture))
        if name.startswith("campus_gate_earned_"):
            capture=out/(name+"_captures");capture.mkdir()
            group="campus_gate_earned_loud" if "_loud" in name else "campus_gate_earned_quiet"
            data=out/(group+"_userdata")
            if not name.endswith("_read"):
                source=out/"first_sortie_run_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                profile=json.loads(source.read_text())["profile"]
                assert profile["successful_sorties"]==1 and profile["ar_damage_upgraded"] and not profile["narrative_slice"]["settled"]["Q01"] and not profile["sortie_checkpoint"]
                target=data/"Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                target.parent.mkdir(parents=True);shutil.copy2(source,target)
                (capture/"input_provenance.json").write_text(json.dumps({"path":str(source),"sha256":hashlib.sha256(source.read_bytes()).hexdigest()}))
            child_env.update(APPDATA=str(data),LOCALAPPDATA=str(out/(group+"_localdata")),BUNNY_EVIDENCE=str(capture))
        if name.startswith("medical_intercept_"):
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"medical_intercept_userdata"),LOCALAPPDATA=str(out/"medical_intercept_localdata"),BUNNY_EVIDENCE=str(capture))
        if name.startswith("relay_diversion_"):
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"relay_diversion_userdata"),LOCALAPPDATA=str(out/"relay_diversion_localdata"),BUNNY_EVIDENCE=str(capture))
        if name.startswith("shared_earned_"):
            capture=out/(name+"_captures");capture.mkdir()
            group="shared_earned_en" if name.startswith("shared_earned_en") else "shared_earned_zh"
            child_env.update(APPDATA=str(out/(group+"_userdata")),LOCALAPPDATA=str(out/(group+"_localdata")),BUNNY_EVIDENCE=str(capture))
        if name in ["rescue_earned","rescue_earned_read"]:
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"rescue_earned_userdata"),LOCALAPPDATA=str(out/"rescue_earned_localdata"),BUNNY_EVIDENCE=str(capture))
        if name in ["story_rescue_first","story_rescue_first_read"]:
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"rescue_first_userdata"),LOCALAPPDATA=str(out/"rescue_first_localdata"),BUNNY_EVIDENCE=str(capture))
        if name in ["story_maintenance", "story_finish", "story_finish_read"]:
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/"first_sortie_run_userdata"),LOCALAPPDATA=str(out/"first_sortie_run_localdata"),BUNNY_EVIDENCE=str(capture))
        if name in ["blockade_earned", "blockade_earned_read"]:
            capture=out/(name+"_captures");capture.mkdir()
            group=out/"blockade_earned_userdata"
            if name=="blockade_earned":
                source=out/"bucket_earned_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                assert json.loads(source.read_text())["profile"]["successful_sorties"]==8+campaign_extra_returns
                dest=group/"Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                dest.parent.mkdir(parents=True);shutil.copy2(source,dest)
                (capture/"input.json").write_text(json.dumps({"path":str(source),"sha256":hashlib.sha256(source.read_bytes()).hexdigest()}))
            child_env.update(APPDATA=str(group),LOCALAPPDATA=str(out/"blockade_earned_localdata"),BUNNY_EVIDENCE=str(capture))
        if name in ["bucket_earned", "bucket_earned_read"]:
            capture=out/(name+"_captures");capture.mkdir()
            group=out/"bucket_earned_userdata"
            if name=="bucket_earned":
                source=out/"first_sortie_run_userdata"/"Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                assert json.loads(source.read_text())["profile"]["successful_sorties"]==7+campaign_extra_returns
                dest=group/"Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                dest.parent.mkdir(parents=True);shutil.copy2(source,dest)
                (capture/"input.json").write_text(json.dumps({"path":str(source),"sha256":hashlib.sha256(source.read_bytes()).hexdigest()}))
            child_env.update(APPDATA=str(group),LOCALAPPDATA=str(out/"bucket_earned_localdata"),BUNNY_EVIDENCE=str(capture))
        if name.startswith("market_earned_"):
            group=name.removesuffix("_read")
            folder=out/(group+"_userdata/Godot/app_userdata")/("Bunny Verification "+out.name)
            if not name.endswith("_read"):
                source=out/"first_sortie_run_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
                assert json.loads(source.read_text())["profile"]["successful_sorties"]==7+campaign_extra_returns
                folder.mkdir(parents=True);shutil.copy2(source,folder/"profile.json")
            capture=out/(name+"_captures");capture.mkdir()
            child_env.update(APPDATA=str(out/(group+"_userdata")),LOCALAPPDATA=str(out/(group+"_localdata")),BUNNY_EVIDENCE=str(capture))
        if route:
            capture = out / ("captures" if name == "route" else name + "_captures")
            capture.mkdir()
            child_env.update(BUNNY_EVIDENCE=str(capture), APPDATA=str(out / (name + "_userdata")),
                             LOCALAPPDATA=str(out / (name + "_localdata")))
        with log.open("wb") as f:
            result = subprocess.run(command, env=child_env, stdout=f, stderr=subprocess.STDOUT,
                                    timeout=30 if name.startswith("quit_") else 180, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        data = log.read_bytes()
        text = data.decode("utf-8", errors="replace").replace("\r\n", "\n")
        errors = re.findall(r"^(?:SCRIPT )?ERROR:.*$", text, re.M)
        warnings = re.findall(r"^WARNING:.*$", text, re.M)
        passed = result.returncode == 0 and not errors and not re.search(r"(?:ROUTE_FAIL|: FAIL)", text)
        if name in {"localization_build", "campaign_return_offsets_unit"}:
            passed = passed and "\nOK\n" in text
        elif name not in {"cold_import", "main", "route"}:
            passed = passed and "PASS" in text
        # The newly reviewed tests print intermediate PASS checks too. Require
        # their final marker so a frame-budget exit cannot masquerade as completion.
        completion_markers = {
            **{name:"CAMPUS_EXIT_GATE_TEST: PASS" for name in ["campus_exit_gate_test","campus_exit_gate_read","campus_exit_gate_loud","campus_exit_gate_loud_read"]},
            **{name:"CAMPUS_ENTRY_RUN: PASS" for name in ["campus_gate_earned_quiet","campus_gate_earned_quiet_read","campus_gate_earned_loud","campus_gate_earned_loud_read"]},
            **{name:"MAINTENANCE_SHARED_TEST: PASS" for name in ["maintenance_shared_test","maintenance_shared_read","maintenance_shared_pending_read"]},
            **{name:"MAINTENANCE_RUN: PASS" for name in ["shared_earned_zh","shared_earned_zh_read","shared_earned_en","shared_earned_en_read"]},
            "campus_packing_test":"CAMPUS_PACKING_TEST: PASS",
            "debrief_guidance_test":"DEBRIEF_GUIDANCE_TEST: PASS",
            **{name:"RECOVERED_CARRIER_TEST: PASS" for name in ["recovered_carrier_test","recovered_carrier_read","recovered_carrier_world_write","recovered_carrier_world_read"]},
            **{name:"RECOVERED_ARMS_TEST: PASS" for name in ["recovered_arms_test","recovered_arms_read"]},
            "normal_start_wait_test":"NORMAL_START_WAIT_TEST: PASS",
            **{name:"CAMPUS_RELAY_DIVERSION_TEST: PASS" for name in ["campus_relay_diversion_test","relay_pa_write","relay_pa_read"]},
            **{name:"CAMPUS_ENTRY_RUN: PASS" for name in ["relay_diversion_earned","relay_diversion_read"]},
            **{name:"MEDICAL_RUNNERS_TEST: PASS" for name in ["medical_runners_test","medical_runners_write","medical_runners_read","medical_runners_route-write","medical_runners_route-read","medical_runners_escape"]},
            **{name:"CAMPUS_ENTRY_RUN: PASS" for name in ["medical_intercept_earned","medical_intercept_read"]},
            "water_market_test":"WATER_MARKET_TEST: PASS", "market_write":"WATER_MARKET_TEST: PASS", "market_read":"WATER_MARKET_TEST: PASS",
            **{name:"WATER_MARKET_RUN: PASS" for name in ["market_earned_quiet","market_earned_quiet_read","market_earned_loud","market_earned_loud_read","market_earned_skip","market_earned_skip_read"]},
            "rescue_return_test":"RESCUE_RETURN_TEST: PASS", "rescue_result_test":"RESCUE_RESULT_TEST: PASS",
            "rescue_earned":"RESCUE_RETURN_RUN: PASS", "rescue_earned_read":"RESCUE_RETURN_RUN: PASS",
            "maintenance_art_test":"MAINTENANCE_ART_TEST: PASS",
            **{name:"MAINTENANCE_JOURNEY_TEST: PASS" for name in ["maintenance_journey_test","maintenance_steam_write","maintenance_steam_read"]},
            **{name:"MAINTENANCE_RUN: PASS" for name in ["story_rescue_first","story_rescue_first_read"]},
            "blockade_journey_test":"BLOCKADE_JOURNEY_TEST: PASS",
            **{name:"BLOCKADE_JOURNEY_TEST: PASS" for name in ["blockade_chain_write","blockade_chain_read","blockade_sweep_write","blockade_sweep_read","blockade_gate_write","blockade_gate_read"]},
            "blockade_street":"BLOCKADE_RUN: PASS", "blockade_earned":"BLOCKADE_EARNED_RUN: PASS", "blockade_earned_read":"BLOCKADE_EARNED_RUN: PASS",
            "campus_power_test":"CAMPUS_POWER_TEST: PASS",
            **{name:"CAMPUS_POWER_TEST: PASS" for name in ["campus_power_windup_write","campus_power_windup_read","campus_power_charge_write","campus_power_charge_read","campus_power_stun_write","campus_power_stun_read"]},
            "bucket_return_test":"BUCKET_RETURN_TEST: PASS", "bucket_result_test":"BUCKET_RESULT_TEST: PASS",
            "bucket_earned":"BUCKET_EARNED_RUN: PASS", "bucket_earned_read":"BUCKET_EARNED_RUN: PASS",
            **{name:"FINALE_TEST: PASS" for name in ["finale_test","finale_write","finale_read"]},
            "homecoming_finale_test":"HOMECOMING_FINALE_TEST: PASS",
            "story_maintenance":"MAINTENANCE_RUN: PASS", "story_finish":"STORY_FINISH_RUN: PASS", "story_finish_read":"STORY_FINISH_RUN: PASS",
            **{name:"MAINTENANCE_TEST: PASS" for name in ["maintenance_test","maintenance_write","maintenance_read","maintenance_link_write","maintenance_link_read"]},
            **{name:"CAMPUS_ENTRY_RUN: PASS" for name in ["campus_entry_q01","campus_entry_q02","campus_entry_relay","campus_entry_power","campus_entry_supply","campus_entry_read"]},
            "workshop_moment_test":"WORKSHOP_MOMENT_TEST: PASS", "workshop_moment_gui":"WORKSHOP_MOMENT_TEST: PASS",
            "workshop_moment_english_gui":"WORKSHOP_MOMENT_TEST: PASS", "workshop_moment_compat":"WORKSHOP_MOMENT_TEST: PASS",
            "first_sortie_run":"FIRST_SORTIE_RUN: PASS", "first_sortie_salvage":"FIRST_SORTIE_RUN: PASS",
            "first_sortie_read":"FIRST_SORTIE_RUN: PASS", "first_sortie_salvage_read":"FIRST_SORTIE_RUN: PASS",
            "first_sortie_return_gui":"FIRST_SORTIE_RUN: PASS", "first_sortie_salvage_gui":"FIRST_SORTIE_RUN: PASS",
            "first_sortie_return_compat":"FIRST_SORTIE_RUN: PASS", "first_sortie_salvage_compat":"FIRST_SORTIE_RUN: PASS",
            "normal_start_test": "NORMAL_START_TEST: PASS", "normal_start_read": "NORMAL_START_TEST: PASS",
            "normal_start_english": "NORMAL_START_TEST: PASS", "normal_start_gui": "NORMAL_START_TEST: PASS",
            "normal_start_english_gui": "NORMAL_START_TEST: PASS", "normal_start_compat": "NORMAL_START_TEST: PASS",
            "ap_ammo_test": "AP_AMMO_TEST: PASS", "ap_ammo_read": "AP_AMMO_TEST: PASS",
            "stash_rotation_test": "STASH_ROTATION_TEST: PASS", "stash_rotation_read": "STASH_ROTATION_TEST: PASS",
            "stash_rotation_gui": "STASH_ROTATION_TEST: PASS",
            "base_manual_ui_test": "BASE_MANUAL_UI_TEST: PASS", "base_manual_ui_gui": "BASE_MANUAL_UI_TEST: PASS",
            "carried_backpack_ui_test": "CARRIED_BACKPACK_UI_TEST: PASS", "carried_backpack_ui_gui": "CARRIED_BACKPACK_UI_TEST: PASS",
            "campus_voice_test": "CAMPUS_VOICE_TEST: PASS", "campus_voice_gui": "CAMPUS_VOICE_TEST: PASS",
            "sortie_guidance_test": "SORTIE_GUIDANCE_TEST: PASS", "sortie_guidance_gui": "SORTIE_GUIDANCE_TEST: PASS",
            "combat_feedback_test": "COMBAT_FEEDBACK_TEST: PASS", "combat_feedback_gui": "COMBAT_FEEDBACK_TEST: PASS",
            "infected_enemy_test": "INFECTED_ENEMY_TEST: PASS", "infected_melee_gui": "INFECTED_ENEMY_TEST: PASS",
            **{name:"WATER_DELIVERY_TEST: PASS" for name in ["water_delivery_test","water_delivery_public_write","water_delivery_public_read","water_delivery_tanker_write","water_delivery_tanker_read"]},
            "waterworks_shot":"WATERWORKS_RUN: PASS",
            "waterworks_test": "WATERWORKS_TEST: PASS", "waterworks_gui": "WATERWORKS_TEST: PASS",
            "waterworks_return_test": "WATERWORKS_RETURN_TEST: PASS", "waterworks_return_read": "WATERWORKS_RETURN_TEST: PASS",
            "waterworks_return_gui": "WATERWORKS_RETURN_TEST: PASS",
            "waterworks_run": "WATERWORKS_RUN: PASS", "waterworks_tanker": "WATERWORKS_RUN: PASS",
            "blockade_checkpoint_write": "BLOCKADE_CHECKPOINT_WRITE: PASS", "blockade_checkpoint_read": "BLOCKADE_CHECKPOINT_READ: PASS",
            "blockade_readability_test": "BLOCKADE_READABILITY_TEST: PASS", "blockade_readability_gui": "BLOCKADE_READABILITY_TEST: PASS",
            "blockade_test": "BLOCKADE_TEST: PASS", "blockade_run": "BLOCKADE_RUN: PASS", "blockade_gui": "BLOCKADE_TEST: PASS",
            "seat_moment_test":"SEAT_MOMENT_TEST: PASS", "training_room_test": "TRAINING_ROOM_TEST: PASS", "training_room_gui": "TRAINING_ROOM_TEST: PASS",
            "records_isolation_test": "RECORDS_ISOLATION_TEST: PASS", "records_isolation_read": "RECORDS_ISOLATION_TEST: PASS",
            "records_isolation_run": "RECORDS_ISOLATION_RUN: PASS", "records_isolation_gui": "RECORDS_ISOLATION_TEST: PASS",
            "camera_cutaway_test": "CAMERA_CUTAWAY_TEST: PASS",
            "camera_cutaway_forward_plus": "CAMERA_CUTAWAY_TEST: PASS", "camera_cutaway_gl_compatibility": "CAMERA_CUTAWAY_TEST: PASS",
        }
        if name in completion_markers:
            passed = passed and completion_markers[name] in text
        if name.startswith("audio_exit_") or name == "main":
            # Production teardown must work without a test-only pre-quit drain.
            passed = passed and not warnings and "Leaked instance:" not in text
            if name.startswith("audio_exit_"):
                passed = passed and "AUDIO_EXIT_PROBE: PASS" in text
        if name == "cold_import":
            # Original Motus FBXs have harmless non-UTF8 metadata; preserve source bytes.
            # Missing textures and every other import warning still fail verification.
            unexpected = [w for w in warnings if not re.fullmatch(
                r"WARNING: FBX: ufbx warning: Bad UTF-8 string \(x\d+\)", w)]
            passed = passed and not unexpected
        row = {"name": name, "command": command, "exit": result.returncode, "pass": bool(passed),
               "errors": errors, "warnings": warnings, "sha256": hashlib.sha256(data).hexdigest()}
        results.append(row)
        (out / "results.json").write_text(json.dumps(results, indent=2))
        print(name, "PASS" if passed else "FAIL", "exit", result.returncode,
              "ERROR", len(errors), "WARNING", len(warnings), flush=True)
        return passed

    if not run("localization_build", []):
        raise SystemExit(1)
    if not run("cold_import", ["--headless", "--editor", "--import"]):
        raise SystemExit(1)
    if args.import_only:
        return
    scenes = sorted((project / "tests").glob("*.tscn"))
    # Reviewed addition: campus north gate; previous126 scenes retained.
    if len(scenes) != 127:
        raise RuntimeError(f"Expected reviewed inventory of 127 test scenes, got {len(scenes)}; review additions/removals")
    if not run("campaign_return_offsets_unit", ["--headless"]):
        raise SystemExit(1)
    for scene in scenes:
        frame_budget = "60000" if scene.stem in {"hideout_camera_test", "hideout_idle_test"} else ("12000" if (scene.stem.startswith("streets_") or scene.stem in {"first_sortie_run", "normal_start_test", "campus_route_input_test", "sortie_guidance_test", "combat_feedback_test", "waterworks_run", "waterworks_test", "water_market_test", "water_delivery_test", "campus_power_test", "bucket_return_test", "bucket_result_test", "training_room_test", "blockade_test", "blockade_journey_test", "maintenance_journey_test", "blockade_run", "blockade_readability_test", "records_isolation_run"}) else "1200")
        if not run(scene.stem, ["--headless", "--fixed-fps", "60", "res://tests/" + scene.name, "--quit-after", frame_budget]):
            raise SystemExit(1)
    for name,flags in [("read",["--read"]),("loud",["--loud"]),("loud_read",["--loud","--read"])]:
        if not run("campus_exit_gate_"+name,["--headless","--fixed-fps","60","res://tests/campus_exit_gate_test.tscn","--"]+flags):raise SystemExit(1)
    for mode in ["read","pending-read"]:
        name="maintenance_shared_read" if mode=="read" else "maintenance_shared_pending_read"
        if not run(name,["--headless","--fixed-fps","60","res://tests/maintenance_shared_test.tscn","--","--"+mode]):raise SystemExit(1)
    for mode in ["write", "read"]:
        if not run("campus_handoff_"+mode,["--headless","--fixed-fps","60","res://tests/campus_handoff_test.tscn","--","--"+mode]):raise SystemExit(1)
    for mode in ["write","read","route-write","route-read","escape"]:
        if not run("medical_runners_"+mode,["--headless","--fixed-fps","60","res://tests/medical_runners_test.tscn","--quit-after","24000","--","--"+mode]):raise SystemExit(1)
    for mode in ["write","read"]:
        if not run("relay_pa_"+mode,["--headless","--fixed-fps","60","res://tests/campus_relay_diversion_test.tscn","--","--"+mode]):raise SystemExit(1)
    for mode in ["write", "read"]:
        if not run("maintenance_steam_"+mode,["--headless","--fixed-fps","60","res://tests/maintenance_journey_test.tscn","--","--"+mode]):raise SystemExit(1)
    for phase in ["chain", "sweep", "gate"]:
        for mode in ["write", "read"]:
            if not run("blockade_"+phase+"_"+mode,["--headless","--fixed-fps","60","res://tests/blockade_journey_test.tscn","--","--"+mode,"--"+phase]):raise SystemExit(1)
    if not run("blockade_street",["--headless","--fixed-fps","60","res://tests/blockade_run.tscn","--","--street"]):raise SystemExit(1)
    for phase in ["windup", "charge", "stun"]:
        for mode in ["write", "read"]:
            if not run("campus_power_"+phase+"_"+mode,["--headless","--fixed-fps","60","res://tests/campus_power_test.tscn","--","--"+mode]+([] if phase=="windup" else ["--"+phase])):
                raise SystemExit(1)
    for branch in ["public", "tanker"]:
        for mode in ["write", "read"]:
            if not run("water_delivery_"+branch+"_"+mode,["--headless","--fixed-fps","60","res://tests/water_delivery_test.tscn","--","--"+mode]+(["--tanker"] if branch=="tanker" else [])):
                raise SystemExit(1)
    if not run("waterworks_shot",["--headless","--fixed-fps","60","res://tests/waterworks_run.tscn","--","--shoot-public"]):
        raise SystemExit(1)
    for mode in ["write", "read"]:
        if not run("blockade_checkpoint_" + mode, ["--headless", "--fixed-fps", "60", "res://tests/blockade_test.tscn", "--", "--"+mode]):
            raise SystemExit(1)
    for name, extra in [("normal_start_read", ["--resume"]), ("normal_start_english", ["--english"])]:
        if not run(name, ["--headless", "--fixed-fps", "60", "res://tests/normal_start_test.tscn", "--"] + extra):
            raise SystemExit(1)
    for name, extra in [("first_sortie_salvage",["--salvage"]), ("first_sortie_read",["--read"]), ("first_sortie_salvage_read",["--salvage","--read"])]:
        if not run(name,["--headless","--fixed-fps","60","res://tests/first_sortie_run.tscn","--"]+extra):
            raise SystemExit(1)
    for branch,flags in [("quiet",[]),("loud",["--loud","--english"])]:
        for suffix,extra in [("",flags),("_read",flags+["--read"])]:
            if not run("campus_gate_earned_"+branch+suffix,["--headless","--fixed-fps","60","res://tools/campus_exit_gate_run.tscn","--"]+extra):raise SystemExit(1)
    for name,step,extra in [("q01","q01",[]),("q02","q02",[]),("relay","campus",[]),("power","campus",[]),("pack","campus",["--pack-only"]),("supply","campus",[]),("read","campus",["--read-complete"]),("bootstrap","campus",["--bootstrap-only"])]:
        if not run("campus_entry_"+name,["--headless","--fixed-fps","60","--script","res://tools/campus_entry_probe.gd","--","--step",step]+extra):
            raise SystemExit(1)
        if name=="q01":
            seed=out/"first_sortie_run_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
            assert json.loads(seed.read_text())["profile"]["successful_sorties"]==2
            dest=out/"medical_intercept_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
            dest.parent.mkdir(parents=True);shutil.copy2(seed,dest)
            (out/"medical_intercept_input.json").write_text(json.dumps({"path":str(seed),"sha256":hashlib.sha256(seed.read_bytes()).hexdigest(),"earned_q01_return":True}))
        if name=="q02":
            seed=out/"first_sortie_run_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
            campaign_extra_returns=q02_extra_returns(json.loads(seed.read_text())["profile"],json.loads((out/"campus_entry_q02_captures/campus_entry.json").read_text()))
            (out/"q02_actual_return_offset.json").write_text(json.dumps({"extra_returns":campaign_extra_returns,"evidence":"campus_entry_q02_captures/campus_entry.json","scope":"Actual retained random loot trips; no profile changes."}))
            dest=out/"relay_diversion_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
            dest.parent.mkdir(parents=True);shutil.copy2(seed,dest)
            (out/"relay_diversion_input.json").write_text(json.dumps({"path":str(seed),"sha256":hashlib.sha256(seed.read_bytes()).hexdigest(),"earned_q02_return":True}))
    for name,extra in [("medical_intercept_earned",[]),("medical_intercept_read",["--read"])]:
        if not run(name,["--headless","--fixed-fps","60","res://tools/medical_intercept_run.tscn","--"]+extra):raise SystemExit(1)
    for name,extra in [("relay_diversion_earned",[]),("relay_diversion_read",["--read-relay"])]:
        if not run(name,["--headless","--fixed-fps","60","res://tools/relay_diversion_run.tscn","--"]+extra):raise SystemExit(1)
    if not run("waterworks_return_read", ["--headless", "res://tests/waterworks_return_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("records_alarm_read", ["--headless", "res://tests/records_alarm_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("records_isolation_read", ["--headless", "res://tests/records_isolation_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("controls_read", ["--headless", "res://tests/control_settings_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("relay_read", ["--headless", "res://tests/relay_operation_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("relay_combat", ["--headless", "--fixed-fps", "60", "res://tests/streets_combat_run.tscn", "--", "--relay"]):
        raise SystemExit(1)
    if not run("waterworks_tanker", ["--headless", "--fixed-fps", "60", "res://tests/waterworks_run.tscn", "--", "--tanker"]):
        raise SystemExit(1)
    for mode in ["base", "battle", "failure", "transition", "recovery"]:
        if not run("quit_" + mode, ["--headless", "--script", "res://tools/p0_exit_probe.gd", "--", mode]):
            raise SystemExit(1)
    for mode in ["music", "effects", "paused"]:
        if not run("audio_exit_" + mode, ["--headless", "--verbose", "--script", "res://tools/audio_exit_probe.gd", "--", mode]):
            raise SystemExit(1)
    for name,flags in [("recovered_carrier_read",["--read"]),("recovered_carrier_world_write",["--write-world"]),("recovered_carrier_world_read",["--world-read"])]:
        if not run(name,["--headless","--fixed-fps","60","res://tests/recovered_carrier_test.tscn","--"]+flags):raise SystemExit(1)
    for name,flags in [("market_write",["--write"]),("market_read",["--read"])]:
        if not run(name,["--headless","--fixed-fps","60","res://tests/water_market_test.tscn","--"]+flags):raise SystemExit(1)
    for name, extra in [("maintenance_write", ["--write"]), ("maintenance_read", ["--read"]), ("maintenance_link_write", ["--link-write"]), ("maintenance_link_read", ["--link-read"])]:
        if not run(name, ["--headless", "--fixed-fps", "60", "res://tests/maintenance_test.tscn", "--"] + extra):
            raise SystemExit(1)
    for name, extra in [("finale_write", ["--write"]), ("finale_read", ["--read"])]:
        if not run(name, ["--headless", "--fixed-fps", "60", "res://tests/finale_test.tscn", "--"] + extra):
            raise SystemExit(1)
    source6=out/"first_sortie_run_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
    assert json.loads(source6.read_text())["profile"]["successful_sorties"]==6+campaign_extra_returns
    dest6=out/"rescue_first_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
    dest6.parent.mkdir(parents=True);shutil.copy2(source6,dest6)
    earned6=out/"rescue_earned_userdata/Godot/app_userdata"/("Bunny Verification "+out.name)/"profile.json"
    earned6.parent.mkdir(parents=True);shutil.copy2(source6,earned6)
    for branch,flags in [("zh",[]),("en",["--english","--rescue-first"])]:
        group="shared_earned_"+branch
        dest=out/(group+"_userdata/Godot/app_userdata")/("Bunny Verification "+out.name)/"profile.json"
        dest.parent.mkdir(parents=True);shutil.copy2(source6,dest)
        for suffix,read_flags in [("",[]),("_read",["--read"])]:
            if not run(group+suffix,["--headless","--fixed-fps","60","res://tools/maintenance_shared_run.tscn","--"]+flags+read_flags):raise SystemExit(1)
    for name, scene, extra in [("rescue_earned","rescue_return_run",[]),("rescue_earned_read","rescue_return_run",["--read"]),("story_rescue_first","maintenance_run",["--rescue-first"]),("story_rescue_first_read","maintenance_run",["--read"]),("story_maintenance", "maintenance_run", []), ("story_finish", "story_finish_run", []), ("story_finish_read", "story_finish_run", ["--read"])]:
        if not run(name, ["--headless", "--fixed-fps", "60", "res://tools/"+scene+".tscn", "--"] + extra):
            raise SystemExit(1)
        if name=="story_maintenance":
            for branch,flags in [("quiet",[]),("loud",["--loud"]),("skip",["--skip-depot"])]:
                for suffix,read in [("",[]),("_read",["--read"])]:
                    if not run("market_earned_"+branch+suffix,["--headless","--fixed-fps","60","res://tools/water_market_run.tscn","--"]+flags+read):raise SystemExit(1)
            for bucket_name,flags in [("bucket_earned",[]),("bucket_earned_read",["--read"])]:
                if not run(bucket_name,["--headless","--fixed-fps","60","res://tools/bucket_return_run.tscn","--"]+flags):raise SystemExit(1)
            for block_name,flags in [("blockade_earned",[]),("blockade_earned_read",["--read"])]:
                if not run(block_name,["--headless","--fixed-fps","60","res://tools/blockade_return_run.tscn","--"]+flags):raise SystemExit(1)
    checkpoint_args = ["--headless", "--fixed-fps", "60", "res://tests/sortie_checkpoint_test.tscn", "--"]
    if not run("checkpoint_write", checkpoint_args + ["--write"]) or not run("checkpoint_read", checkpoint_args + ["--read"]):
        raise SystemExit(1)
    # Kill only our explicitly launched, isolated writer AFTER its durable-save
    # marker and live process handle are verified. This never targets an editor.
    crash_log = out / "checkpoint_crash_writer.log"
    with crash_log.open("wb") as f:
        child = subprocess.Popen([str(args.godot.resolve()), "--path", str(project)] + checkpoint_args + ["--write", "--wait-for-kill"],
                                 env=env, stdout=f, stderr=subprocess.STDOUT,
                                 creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        deadline = time.monotonic() + 90
        while child.poll() is None and time.monotonic() < deadline:
            if "CHECKPOINT_WRITER_READY" in crash_log.read_text(encoding="utf-8", errors="replace"):
                break
            time.sleep(0.1)
        ready = child.poll() is None and "CHECKPOINT_WRITER_READY" in crash_log.read_text(encoding="utf-8", errors="replace")
        if child.poll() is None:
            child.kill()
        child.wait(timeout=10)
        if not ready:
            raise RuntimeError("Checkpoint crash writer did not reach verified live/ready state")
    if not run("checkpoint_crash_read", checkpoint_args + ["--read"]):
        raise SystemExit(1)
    medical_args = ["--headless", "--fixed-fps", "60", "res://tests/medical_treatment_test.tscn", "--"]
    if not run("medical_write", medical_args + ["--write"]) or not run("medical_read", medical_args + ["--read"]):
        raise SystemExit(1)
    campaign_args = ["--headless", "--fixed-fps", "60", "res://tests/campaign_test.tscn", "--"]
    if not run("campaign_write", campaign_args + ["--write"]) or not run("campaign_read", campaign_args + ["--read"]):
        raise SystemExit(1)
    if not run("fitting_read", ["--headless", "--fixed-fps", "60", "res://tests/weapon_fitting_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("recovered_arms_read", ["--headless", "--fixed-fps", "60", "res://tests/recovered_arms_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("ap_ammo_read", ["--headless", "res://tests/ap_ammo_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("stash_rotation_read", ["--headless", "res://tests/stash_rotation_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("supply_art_read", ["--headless", "res://tests/supply_art_v1_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("weapon_art_read", ["--headless", "res://tests/weapon_art_v1_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("campus_read", ["--headless", "res://tests/campus_chapter_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("kit_read", ["--headless", "res://tests/fitting_kit_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("packing_read", ["--headless", "--fixed-fps", "60", "res://tests/ammo_packing_test.tscn", "--", "--read"]):
        raise SystemExit(1)
    if not run("main", ["--headless", "--quit-after", "180"]):
        raise SystemExit(1)
    if args.route:
        for name, scene, extra in [
            ("base_manual_ui_gui", "base_manual_ui_test", ["--capture"]),
            ("carried_backpack_ui_gui", "carried_backpack_ui_test", ["--capture"]),
            ("combat_feedback_gui", "combat_feedback_test", ["--capture"]),
            ("infected_melee_gui", "infected_enemy_test", ["--capture"]),
            ("waterworks_gui", "waterworks_test", ["--capture"]),
            ("training_room_gui", "training_room_test", ["--capture"]),
            ("blockade_gui", "blockade_test", ["--capture"]),
            ("blockade_readability_gui", "blockade_readability_test", ["--capture"]),
            ("records_isolation_gui", "records_isolation_test", ["--capture"]),
            ("stash_rotation_gui", "stash_rotation_test", ["--gui"]),
            ("campus_voice_gui", "campus_voice_test", ["--capture"]),
            ("normal_start_gui", "normal_start_test", []),
            ("normal_start_english_gui", "normal_start_test", ["--english"]),
            ("first_sortie_return_gui", "first_sortie_run", []),
            ("first_sortie_salvage_gui", "first_sortie_run", ["--salvage"]),
            ("waterworks_return_gui", "waterworks_return_test", ["--capture"]),
            ("workshop_moment_gui", "workshop_moment_test", ["--capture"]),
            ("workshop_moment_english_gui", "workshop_moment_test", ["--capture", "--english"]),
            ("sortie_guidance_gui", "sortie_guidance_test", ["--capture"]),
        ]:
            if not run(name, ["--rendering-method", args.renderer, "--audio-driver", "Dummy",
                              "--resolution", "1280x720", "res://tests/" + scene + ".tscn", "--"] + extra, route=True):
                raise SystemExit(1)
    # Graphics-only route evidence: the CI/remote host may have no audio device.
    if args.route:
        if not run("workshop_moment_compat",["--rendering-method","gl_compatibility","--audio-driver","Dummy","--resolution","1280x720","res://tests/workshop_moment_test.tscn","--","--capture"],route=True):
            raise SystemExit(1)
        for name, extra in [("first_sortie_return_compat",[]),("first_sortie_salvage_compat",["--salvage"])]:
            if not run(name,["--rendering-method","gl_compatibility","--audio-driver","Dummy","--resolution","1280x720","res://tests/first_sortie_run.tscn","--"]+extra,route=True):
                raise SystemExit(1)
        if not run("normal_start_compat", ["--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--resolution", "1280x720", "res://tests/normal_start_test.tscn"], route=True):
            raise SystemExit(1)
        for method in ["forward_plus", "gl_compatibility"]:
            if not run("camera_cutaway_" + method, ["--rendering-method", method, "--audio-driver", "Dummy", "--resolution", "1280x720", "res://tests/camera_cutaway_test.tscn", "--", "--capture"], route=True):
                raise SystemExit(1)
    if args.route and not run("route", ["--rendering-method", args.renderer, "--audio-driver", "Dummy", "--resolution", "1280x720",
                                        "--script", "res://tools/phase2b_route_probe.gd"], route=True):
        raise SystemExit(1)
    print(f"ALL TESTS {len(scenes)}/{len(scenes)} PASS; manual input NOT claimed; release permission NOT implied")


if __name__ == "__main__":
    main()
