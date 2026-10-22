"""Build a LOCAL_ONLY Windows prototype in a fresh directory outside the checkout.

No uploading, no source/profile mutation. Requires matching official x64 templates.
The private build has a separate application name and explicit QA-only scripts.
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
import zipfile


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
    parser.add_argument("--templates", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--smoke", action="store_true", help="run the exported runtime, never the editor")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    if out.exists() or out.is_relative_to(root):
        parser.error("Output must be a NEW directory outside the repository")
    version = subprocess.check_output([str(args.godot.resolve()), "--version"], text=True).strip()
    template_version = (args.templates / "version.txt").read_text().strip()
    if not version.startswith(template_version + "."):
        parser.error(f"Engine/template mismatch: {version} / {template_version}")
    for kind in ["debug", "release"]:
        if not (args.templates / f"windows_{kind}_x86_64.exe").is_file():
            parser.error("Both Windows x64 templates are required")
    out.mkdir(parents=True)
    project = out / "project"
    manifest = {}
    names = subprocess.check_output(["git", "ls-files", "-co", "--exclude-standard", "-z"], cwd=root).decode().split("\0")
    for name in sorted(set(names)):
        src = root / name
        if not name or not src.is_file():
            continue
        if not src.resolve().is_relative_to(root):
            raise ValueError(f"Source escapes checkout: {name}")
        dest = project / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        manifest[name] = hashlib.sha256(src.read_bytes()).hexdigest()
    (out / "source_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    config = project / "project.godot"
    settings = re.sub(r'^config/name=.*$', 'config/name="Neon Bastion Local Prototype"',
                      config.read_text(encoding="utf-8"), flags=re.M)
    settings = settings.replace("[autoload]", '[autoload]\n\nLocalBuildQA="*res://local_qa/probe.gd"')
    config.write_text(settings, encoding="utf-8")
    qa = project / "local_qa"
    qa.mkdir()
    shutil.copy2(root / "tools/local_build_probe.gd", qa / "probe.gd")
    catalog = (root / "resources/content/content_manifest.tres").read_text(encoding="utf-8")
    references = {}
    for entry in re.findall(r"\[ext_resource ([^\]]+)\]", catalog):
        fields = dict(re.findall(r'(\w+)="([^"]*)"', entry))
        references[fields["id"]] = fields["path"]
    definition_line = next(line for line in catalog.splitlines() if line.startswith("definitions ="))
    ids = []
    for reference in re.findall(r'ExtResource\("([^"]+)"\)', definition_line.split("](", 1)[1]):
        source = root / references[reference].removeprefix("res://")
        ids.append(re.search(r'^id\s*=\s*&?"([^"]+)"', source.read_text(encoding="utf-8"), re.M)[1])
    narrative = root / "resources/narrative/campus_conversations.json"
    (qa / "expected.json").write_text(json.dumps({"items":sorted(ids), "narrative_count":len(json.loads(narrative.read_text(encoding="utf-8"))),
        "narrative_sha256":hashlib.sha256(narrative.read_bytes()).hexdigest()}, indent=2), encoding="utf-8")
    shutil.copy2(root / "tests/streets_combat_run.gd", qa / "campus_route.gd")
    (qa / "campus_route.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://local_qa/campus_route.gd" id="1"]\n[node name="PackagedCampusRoute" type="Node"]\nscript = ExtResource("1")\n', encoding="utf-8")
    shutil.copy2(root / "tests/infected_enemy_test.gd", qa / "melee.gd")
    (qa / "melee.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://local_qa/melee.gd" id="1"]\n[node name="PackagedMeleeCheck" type="Node3D"]\nscript = ExtResource("1")\n', encoding="utf-8")
    shutil.copy2(root / "tests/waterworks_test.gd", qa / "waterworks.gd")
    delivery = (root / "tests/water_delivery_test.gd").read_text(encoding="utf-8").replace("res://tests/waterworks_test.gd", "res://local_qa/waterworks.gd")
    (qa / "water_delivery.gd").write_text(delivery, encoding="utf-8")
    data=(root/"tests/water_market_test.gd").read_text(encoding="utf-8").replace("res://tests/waterworks_test.gd","res://local_qa/waterworks.gd")
    (qa/"water_market.gd").write_text(data,encoding="utf-8")
    data=(root/"tools/water_market_run.gd").read_text(encoding="utf-8").replace("res://tools/story_finish_run.gd","res://local_qa/story_finish.gd")
    (qa/"market_earned.gd").write_text(data,encoding="utf-8")
    shutil.copy2(root / "tests/waterworks_return_test.gd", qa / "water_return.gd")
    shutil.copy2(root / "tests/normal_start_test.gd", qa / "normal_start.gd")
    first_sortie = (root / "tests/first_sortie_run.gd").read_text(encoding="utf-8").replace('res://tests/normal_start_test.gd', 'res://local_qa/normal_start.gd')
    (qa / "first_sortie.gd").write_text(first_sortie, encoding="utf-8")
    for source,name,parent in [("campus_q01_run","campus_q01","first_sortie"),("campus_q02_run","campus_q02","campus_q01"),("campus_chapter_run","campus_chapter","campus_q02")]:
        text=(root/("tests/"+source+".gd")).read_text(encoding="utf-8")
        origin="first_sortie_run" if parent=="first_sortie" else parent+"_run"
        text=text.replace("res://tests/"+origin+".gd","res://local_qa/"+parent+".gd")
        (qa/(name+".gd")).write_text(text,encoding="utf-8")
    route = (root / "tests/waterworks_run.gd").read_text(encoding="utf-8").replace('res://tests/streets_combat_run.gd', 'res://local_qa/campus_route.gd')
    (qa / "water_route.gd").write_text(route, encoding="utf-8")
    shutil.copy2(root / "tests/training_room_test.gd", qa / "training.gd")
    shutil.copy2(root / "tests/workshop_moment_test.gd", qa / "fitting.gd")
    shutil.copy2(root / "tests/seat_moment_test.gd", qa / "seat.gd")
    for source,name,parent in [("tests/bucket_return_test.gd","bucket_moment","seat_moment_test"),("tests/bucket_result_test.gd","bucket_result","waterworks_return_test"),("tools/bucket_return_run.gd","bucket_route","story_finish_run")]:
        text=(root/source).read_text(encoding="utf-8")
        origin="res://tools/" if source.startswith("tools/") else "res://tests/"
        target={"seat_moment_test":"seat","waterworks_return_test":"water_return","story_finish_run":"story_finish"}[parent]
        text=text.replace(origin+parent+".gd","res://local_qa/"+target+".gd")
        (qa/(name+".gd")).write_text(text,encoding="utf-8")

    seat = (root / "tools/seat_return_run.gd").read_text(encoding="utf-8").replace("res://tests/normal_start_test.gd", "res://local_qa/normal_start.gd")
    (qa / "seat_return.gd").write_text(seat, encoding="utf-8")
    shutil.copy2(root / "tests/maintenance_test.gd", qa / "maintenance.gd")
    journey=(root/"tests/maintenance_journey_test.gd").read_text(encoding="utf-8").replace("res://tests/maintenance_test.gd","res://local_qa/maintenance.gd")
    (qa/"maintenance_journey.gd").write_text(journey,encoding="utf-8")
    art=(root/"tests/maintenance_art_test.gd").read_text(encoding="utf-8").replace("res://tests/maintenance_test.gd","res://local_qa/maintenance.gd")
    (qa/"maintenance_art.gd").write_text(art,encoding="utf-8")
    shutil.copy2(root/"tests/seat_moment_test.gd",qa/"seat_base.gd")
    shutil.copy2(root/"tests/bucket_result_test.gd",qa/"bucket_result_base.gd")
    data=(qa/"bucket_result_base.gd").read_text().replace("res://tests/waterworks_return_test.gd","res://local_qa/water_return.gd");(qa/"bucket_result_base.gd").write_text(data)
    for source,name,parent,new_parent in [("tests/rescue_return_test.gd","rescue_moment","tests/seat_moment_test.gd","local_qa/seat_base.gd"),("tests/rescue_result_test.gd","rescue_result","tests/bucket_result_test.gd","local_qa/bucket_result_base.gd"),("tools/rescue_return_run.gd","rescue_earned","tools/maintenance_run.gd","local_qa/maintenance_route.gd")]:
        data=(root/source).read_text(encoding="utf-8").replace("res://"+parent,"res://"+new_parent).replace("res://tests/maintenance_test.gd","res://local_qa/maintenance.gd")
        (qa/(name+".gd")).write_text(data,encoding="utf-8")
    maintenance = (root / "tools/maintenance_run.gd").read_text(encoding="utf-8").replace("res://tests/normal_start_test.gd", "res://local_qa/normal_start.gd")
    (qa / "maintenance_route.gd").write_text(maintenance, encoding="utf-8")
    finale = (root / "tests/finale_test.gd").read_text(encoding="utf-8").replace("res://tests/maintenance_test.gd", "res://local_qa/maintenance.gd")
    (qa / "finale.gd").write_text(finale, encoding="utf-8")
    homecoming = (root / "tests/homecoming_finale_test.gd").read_text(encoding="utf-8").replace("res://tests/finale_test.gd", "res://local_qa/finale.gd")
    (qa / "homecoming.gd").write_text(homecoming, encoding="utf-8")
    story = (root / "tools/story_finish_run.gd").read_text(encoding="utf-8").replace("res://tools/maintenance_run.gd", "res://local_qa/maintenance_route.gd")
    (qa / "story_finish.gd").write_text(story, encoding="utf-8")
    shutil.copy2(root / "tests/blockade_test.gd", qa / "blockade.gd")
    journey=(root/"tests/blockade_journey_test.gd").read_text(encoding="utf-8").replace("res://tests/blockade_test.gd","res://local_qa/blockade.gd")
    (qa/"blockade_journey.gd").write_text(journey,encoding="utf-8")
    earned=(root/"tools/blockade_return_run.gd").read_text(encoding="utf-8").replace("res://tools/story_finish_run.gd","res://local_qa/story_finish.gd")
    (qa/"blockade_earned.gd").write_text(earned,encoding="utf-8")
    route = (root / "tests/blockade_run.gd").read_text(encoding="utf-8").replace('res://tests/streets_combat_run.gd', 'res://local_qa/campus_route.gd')
    (qa / "blockade_route.gd").write_text(route, encoding="utf-8")
    readability = (root / "tests/blockade_readability_test.gd").read_text(encoding="utf-8").replace('res://tests/blockade_test.gd', 'res://local_qa/blockade.gd')
    (qa / "blockade_readability.gd").write_text(readability, encoding="utf-8")
    shutil.copy2(root / "tests/records_isolation_test.gd", qa / "isolation.gd")
    isolation_route = (root / "tests/records_isolation_run.gd").read_text(encoding="utf-8").replace('res://tests/streets_combat_run.gd', 'res://local_qa/campus_route.gd')
    (qa / "isolation_route.gd").write_text(isolation_route, encoding="utf-8")
    shutil.copy2(root / "tests/camera_cutaway_test.gd", qa / "cutaway.gd")
    shutil.copy2(root / "tests/campus_chapter_test.gd", qa / "campus_power_base.gd")
    power = (root / "tests/campus_power_test.gd").read_text(encoding="utf-8").replace("res://tests/campus_chapter_test.gd", "res://local_qa/campus_power_base.gd")
    (qa / "campus_power.gd").write_text(power, encoding="utf-8")
    handoff = (root / "tests/campus_handoff_test.gd").read_text(encoding="utf-8").replace("res://tests/campus_chapter_test.gd", "res://local_qa/campus_power_base.gd")
    (qa / "campus_handoff.gd").write_text(handoff, encoding="utf-8")
    medical = (root / "tests/medical_runners_test.gd").read_text(encoding="utf-8").replace("res://tests/campus_chapter_test.gd", "res://local_qa/campus_power_base.gd")
    (qa / "medical_runners.gd").write_text(medical, encoding="utf-8")
    intercept = (root / "tools/medical_intercept_run.gd").read_text(encoding="utf-8").replace("res://tests/campus_q02_run.gd", "res://local_qa/campus_q02.gd")
    (qa / "medical_intercept.gd").write_text(intercept, encoding="utf-8")
    shutil.copy2(root / "tests/sortie_guidance_test.gd", qa / "sortie_guidance_base.gd")
    shutil.copy2(root / "tests/recovered_arms_test.gd", qa / "recovered_arms.gd")
    shutil.copy2(root / "tests/campus_exit_gate_test.gd", qa / "campus_exit_gate.gd")
    for source, name, parent, target in [
        ("tools/campus_exit_gate_run.gd", "campus_exit_gate_earned", "tests/campus_q01_run.gd", "campus_q01.gd"),
        ("tests/maintenance_shared_test.gd", "maintenance_shared", "tests/maintenance_test.gd", "maintenance.gd"),
        ("tools/maintenance_shared_run.gd", "shared_earned", "tools/maintenance_run.gd", "maintenance_route.gd"),
        ("tests/recovered_carrier_test.gd", "recovered_carrier", "tests/waterworks_test.gd", "waterworks.gd"),
        ("tools/recovered_carrier_run.gd", "carrier_earned", "tools/water_market_run.gd", "market_earned.gd"),
        ("tools/recovered_carrier_use_run.gd", "carrier_use", "tools/recovered_carrier_run.gd", "carrier_earned.gd"),
        ("tests/debrief_guidance_test.gd", "debrief_guidance", "tests/sortie_guidance_test.gd", "sortie_guidance_base.gd"),
        ("tools/recovered_arms_run.gd", "recovered_earned", "tests/campus_q02_run.gd", "campus_q02.gd"),
        ("tests/campus_relay_diversion_test.gd", "relay_diversion", "tests/campus_chapter_test.gd", "campus_power_base.gd"),
        ("tools/relay_diversion_run.gd", "relay_earned", "tests/campus_chapter_run.gd", "campus_chapter.gd"),
        ("tests/campus_packing_test.gd", "campus_packing", "tests/sortie_guidance_test.gd", "sortie_guidance_base.gd"),
        ("tools/campus_packing_run.gd", "packing_earned", "tests/normal_start_test.gd", "normal_start.gd"),
        ("tests/normal_start_wait_test.gd", "normal_start_wait", "tests/normal_start_test.gd", "normal_start.gd"),
    ]:
        data = (root / source).read_text(encoding="utf-8").replace("res://" + parent, "res://local_qa/" + target)
        (qa / (name + ".gd")).write_text(data, encoding="utf-8")
    for name in ["campus_exit_gate", "campus_exit_gate_earned", "maintenance_shared", "shared_earned", "recovered_carrier", "carrier_earned", "carrier_use", "recovered_arms", "recovered_earned", "debrief_guidance", "relay_diversion", "relay_earned", "campus_packing", "packing_earned", "normal_start_wait", "medical_runners", "medical_intercept", "campus_handoff", "water_market", "market_earned", "rescue_moment", "rescue_result", "rescue_earned", "maintenance_art", "maintenance_journey", "finale", "homecoming", "story_finish", "maintenance", "maintenance_route", "seat", "seat_return", "campus_q01", "campus_q02", "campus_chapter", "fitting", "first_sortie", "normal_start", "waterworks", "water_delivery", "bucket_moment", "bucket_result", "bucket_route", "campus_power", "water_return", "water_route", "training", "blockade_journey", "blockade_earned", "blockade", "blockade_route", "blockade_readability", "isolation", "isolation_route", "cutaway"]:
        node_type = "Node3D" if name in ["campus_exit_gate", "campus_exit_gate_earned", "maintenance_shared", "recovered_carrier", "recovered_arms", "relay_diversion", "medical_runners", "campus_handoff", "maintenance_art", "maintenance_journey", "campus_power", "isolation", "cutaway", "maintenance", "finale", "homecoming"] else "Node"
        (qa / (name + ".tscn")).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://local_qa/'+name+'.gd" id="1"]\n[node name="PackagedWaterworks" type="'+node_type+'"]\nscript = ExtResource("1")\n', encoding="utf-8")
    # Runtime references currently stay within assets/, scenes/, scripts/,
    # resources/ and localization/. Raw authoring material is never a build input.
    quote = lambda value: json.dumps(str(value).replace("\\", "/"))
    (project / "export_presets.cfg").write_text('''[preset.0]
name="Windows Local Prototype"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="resources/narrative/*.json,localization/*.json,local_qa/*.json"
exclude_filter="art_source/*,docs/*,tests/*,tools/*,addons/*,scripts/debug/*,scenes/debug/*,scenes/tools/*,scenes/art_showcase/*,resources/editor_catalogs/*"
script_export_mode=2
[preset.0.options]
custom_template/debug=''' + quote(args.templates.resolve() / "windows_debug_x86_64.exe") + '''
custom_template/release=''' + quote(args.templates.resolve() / "windows_release_x86_64.exe") + '''
binary_format/architecture="x86_64"
binary_format/embed_pck=false
application/modify_resources=false
codesign/enable=false
''', encoding="utf-8")
    bundle = out / "LOCAL_ONLY_DO_NOT_UPLOAD"
    bundle.mkdir()
    executable = bundle / "NeonBastion.exe"
    env = dict(os.environ, APPDATA=str(out / "export_userdata"), LOCALAPPDATA=str(out / "export_localdata"))
    results = []
    campaign_extra_returns = 0

    def run(name, command, child_env=env, timeout=600, marker=None):
        if campaign_extra_returns and not name.startswith("packaged_medical_intercept"):
            command = list(command)
            if "--" not in command: command.append("--")
            command.append(f"--campaign-extra-returns={campaign_extra_returns}")
        log = out / (name + ".log")
        with log.open("wb") as f:
            result = subprocess.run(command, cwd=bundle, env=child_env, stdout=f, stderr=subprocess.STDOUT,
                                    timeout=timeout, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        data = log.read_bytes()
        text = data.decode("utf-8", errors="replace").replace("\r\n", "\n")
        errors = re.findall(r"^(?:SCRIPT )?ERROR:.*$", text, re.M)
        warnings = re.findall(r"^WARNING:.*$", text, re.M)
        ok = result.returncode == 0 and not errors and (marker is None or marker in text)
        # Only the two already-known FBX importer metadata warnings are allowed.
        if name == "cold_import":
            ok = ok and not [w for w in warnings if not re.fullmatch(r"WARNING: FBX: ufbx warning: Bad UTF-8 string \(x\d+\)", w)]
        else:
            ok = ok and not warnings and "Leaked instance:" not in text
        row = {"name":name, "command":command, "exit":result.returncode, "pass":bool(ok),
               "errors":errors, "warnings":warnings, "log_sha256":hashlib.sha256(data).hexdigest()}
        results.append(row)
        (out / "build_results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(name, "PASS" if ok else "FAIL", flush=True)
        if not ok:
            raise RuntimeError(f"See {log}")

    engine = [str(args.godot.resolve()), "--headless", "--path", str(project)]
    run("cold_import", engine + ["--editor", "--import"])
    run("campaign_return_offsets_unit", [sys.executable,"-X","utf8","-B",str(project/"tests/test_campaign_return_offsets.py"),"-v"],marker="OK")
    run("runtime_export_unit", [sys.executable, "-X", "utf8", "-B", str(project / "tests/test_runtime_export.py"), "-v"], marker="OK")
    catalog_path = out / "runtime_dependency_catalog.json"
    run("runtime_dependency_catalog", engine + ["--script", "res://tools/runtime_dependency_catalog.gd"],
        dict(env, BUNNY_EXPORT_CATALOG=str(catalog_path)), marker="RUNTIME_DEPENDENCY_CATALOG: PASS")
    inventory_path = out / "runtime_export_inventory.json"
    run("runtime_export_inventory", [sys.executable, "-X", "utf8", "-B", str(project / "tools/runtime_export.py"),
        "--project", str(project), "--catalog", str(catalog_path), "--output", str(inventory_path),
        "--preset", str(project / "export_presets.cfg")], marker="RUNTIME_EXPORT_INVENTORY: PASS")
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    public_inventory = {key: inventory[key] for key in ["version", "purpose", "public_release_approved", "resources", "plain_files", "source_sha256", "license_document_candidates", "companion_license_files", "verification_absent_resources"]}
    (bundle / "runtime_inventory.json").write_text(json.dumps(public_inventory, ensure_ascii=False, indent=2), encoding="utf-8")
    catalog_data = json.loads(catalog_path.read_text(encoding="utf-8"))
    engine_notices = catalog_data["engine_license_text"] + "\n\n" + json.dumps(catalog_data["engine_copyright_info"], ensure_ascii=False, indent=2)
    for name, body in sorted(catalog_data["engine_license_info"].items()): engine_notices += "\n\n" + name + "\n" + body
    (bundle / "ENGINE_LICENSES.txt").write_text(engine_notices, encoding="utf-8")
    with zipfile.ZipFile(bundle / "ASSET_LICENSE_MATERIALS.zip", "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for path, expected_sha in inventory["companion_license_files"].items():
            relative = path.removeprefix("res://")
            license_file = (project / relative).resolve()
            assert license_file.is_relative_to(project.resolve()) and hashlib.sha256(license_file.read_bytes()).hexdigest() == expected_sha
            archive.write(license_file, relative)
        archive.writestr("READ_ME.txt", "Candidate license documents and existing companion license packages only. This is NOT permission to publish all game assets. Public redistribution is not approved.\n")
    run("export_release", engine + ["--export-release", "Windows Local Prototype", str(executable)])
    assert executable.is_file() and executable.with_suffix(".pck").is_file()
    (bundle / "LOCAL_ONLY.txt").write_text("LOCAL PROTOTYPE ONLY - DO NOT UPLOAD OR REDISTRIBUTE.\nAsset permissions are unresolved; this is not an approved public release.\nThe inventory and license materials are NOT legal clearance.\nArcana and CombatGirls are not included. QA scripts are included only in this local build.\nThis build uses a separate local-prototype save directory.\n", encoding="utf-8")
    if args.smoke:
        smoke_env = dict(os.environ, APPDATA=str(out / "smoke_userdata"), LOCALAPPDATA=str(out / "smoke_localdata"))
        binary = [str(executable), "--headless", "--audio-driver", "Dummy"]
        for name, flags in [("quiet", []), ("quiet_read", ["--read"]), ("loud", ["--loud"]), ("loud_read", ["--loud", "--read"])]:
            run("packaged_campus_exit_gate_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "campus_exit_gate"] + flags,
                dict(smoke_env, APPDATA=str(out / "campus_gate_component_userdata"), LOCALAPPDATA=str(out / "campus_gate_component_localdata")), 180, "CAMPUS_EXIT_GATE_TEST: PASS")
        for name, flags in [("component", []), ("read", ["--read"]), ("pending_read", ["--pending-read"])]:
            run("packaged_shared_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "maintenance_shared"] + flags,
                dict(smoke_env, APPDATA=str(out / "shared_component_userdata"), LOCALAPPDATA=str(out / "shared_component_localdata")), 180, "MAINTENANCE_SHARED_TEST: PASS")
        for name, flags in [("component", []), ("read", ["--read"]), ("world_write", ["--write-world"]), ("world_read", ["--world-read"])]:
            run("packaged_carrier_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "recovered_carrier"] + flags,
                dict(smoke_env, APPDATA=str(out / "carrier_component_userdata"), LOCALAPPDATA=str(out / "carrier_component_localdata")), 180, "RECOVERED_CARRIER_TEST: PASS")
        for name, flags in [("component", []), ("read", ["--read"])]:
            run("packaged_recovered_arms_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "recovered_arms"] + flags,
                dict(smoke_env, APPDATA=str(out / "recovered_arms_userdata"), LOCALAPPDATA=str(out / "recovered_arms_localdata")), 180, "RECOVERED_ARMS_TEST: PASS")
        for name, flags in [("component", []), ("write", ["--write"]), ("read", ["--read"])]:
            run("packaged_relay_diversion_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "relay_diversion"] + flags,
                dict(smoke_env, APPDATA=str(out / "relay_diversion_userdata"), LOCALAPPDATA=str(out / "relay_diversion_localdata")), 180, "CAMPUS_RELAY_DIVERSION_TEST: PASS")
        for mode, marker in [("debrief_guidance", "DEBRIEF_GUIDANCE_TEST: PASS"), ("campus_packing", "CAMPUS_PACKING_TEST: PASS"), ("normal_start_wait", "NORMAL_START_WAIT_TEST: PASS")]:
            capture = out / (mode + "_captures"); capture.mkdir()
            run("packaged_" + mode, binary + ["--fixed-fps", "60", "--", "--local-qa", mode],
                dict(smoke_env, APPDATA=str(out / (mode + "_userdata")), LOCALAPPDATA=str(out / (mode + "_localdata")), BUNNY_EVIDENCE=str(capture)), 180, marker)
        for name, flags in [("component", []), ("write", ["--write"]), ("read", ["--read"]), ("route_write", ["--route-write"]), ("route_read", ["--route-read"]), ("escape", ["--escape"])]:
            run("packaged_medical_runners_"+name, binary+["--fixed-fps","60","--","--local-qa","medical_runners"]+flags,
                dict(smoke_env,APPDATA=str(out/"medical_runners_userdata"),LOCALAPPDATA=str(out/"medical_runners_localdata")),180,"MEDICAL_RUNNERS_TEST: PASS")
        for name, flags in [("component", []), ("write", ["--write"]), ("read", ["--read"])]:
            run("packaged_campus_handoff_"+name, binary+["--fixed-fps","60","--","--local-qa","campus_handoff"]+flags,
                dict(smoke_env,APPDATA=str(out/"campus_handoff_userdata"),LOCALAPPDATA=str(out/"campus_handoff_localdata")),180,"CAMPUS_HANDOFF_TEST: PASS")
        for mode in ["inventory", "boot", "write", "read", "legacy"]:
            run("packaged_" + mode, binary + ["--", "--local-qa", mode],
                smoke_env, 180, "LOCAL_BUILD_PROBE: PASS")
        run("packaged_campus_route", binary + ["--fixed-fps", "60", "--", "--local-qa", "campus"],
            dict(smoke_env, APPDATA=str(out / "campus_userdata")), 180, "STREETS_COMBAT_RUN PASS")
        run("packaged_melee", binary + ["--fixed-fps", "60", "--", "--local-qa", "melee"],
            dict(smoke_env, APPDATA=str(out / "melee_userdata")), 180, "INFECTED_ENEMY_TEST: PASS")
        for mode, marker in [("isolation", "RECORDS_ISOLATION_TEST: PASS"), ("isolation_route", "RECORDS_ISOLATION_RUN: PASS")]:
            run("packaged_" + mode, binary + ["--fixed-fps", "60", "--", "--local-qa", mode],
                dict(smoke_env, APPDATA=str(out / (mode + "_userdata"))), 180, marker)
        run("packaged_isolation_read", binary + ["--fixed-fps", "60", "--", "--local-qa", "isolation", "--read"],
            dict(smoke_env, APPDATA=str(out / "isolation_userdata")), 180, "RECORDS_ISOLATION_TEST: PASS")
        run("packaged_cutaway", binary + ["--fixed-fps", "60", "--", "--local-qa", "cutaway"],
            dict(smoke_env, APPDATA=str(out / "cutaway_userdata")), 180, "CAMERA_CUTAWAY_TEST: PASS")
        for mode in ["waterworks", "water_public", "water_tanker"]:
            run("packaged_" + mode, binary + ["--fixed-fps", "60", "--", "--local-qa", mode] + (["--tanker"] if mode == "water_tanker" else []),
                dict(smoke_env, APPDATA=str(out / (mode + "_userdata"))), 180,
                "WATERWORKS_TEST: PASS" if mode == "waterworks" else "WATERWORKS_RUN: PASS")
        for name,flags in [("component",[]),("write",["--write"]),("read",["--read"])]:
            run("packaged_market_"+name,binary+["--fixed-fps","60","--","--local-qa","water_market"]+flags,
                dict(smoke_env,APPDATA=str(out/"water_market_userdata"),LOCALAPPDATA=str(out/"water_market_localdata")),180,"WATER_MARKET_TEST: PASS")
        for extra in [[], ["--read"]]:
            run("packaged_water_return" + ("_read" if extra else ""), binary + ["--fixed-fps", "60", "--", "--local-qa", "water_return"] + extra,
                dict(smoke_env, APPDATA=str(out / "water_return_userdata")), 180, "WATERWORKS_RETURN_TEST: PASS")
        for name, extra, data in [("fresh", [], "normal_start"), ("resume", ["--resume"], "normal_start"), ("english", ["--english"], "normal_start_english")]:
            run("packaged_normal_start_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "normal_start"] + extra,
                dict(smoke_env, APPDATA=str(out / (data + "_userdata"))), 180, "NORMAL_START_TEST: PASS")
        for name, extra, data in [("return", [], "first_sortie"), ("return_read", ["--read"], "first_sortie"), ("salvage", ["--salvage"], "first_sortie_salvage"), ("salvage_read", ["--salvage", "--read"], "first_sortie_salvage")]:
            run("packaged_first_sortie_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "first_sortie"] + extra,
                dict(smoke_env, APPDATA=str(out / (data + "_userdata"))), 180, "FIRST_SORTIE_RUN: PASS")
        for branch, flags in [("quiet", []), ("loud", ["--loud", "--english"])]:
            source1=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
            profile1=json.loads(source1.read_text())["profile"]
            assert profile1["successful_sorties"]==1 and profile1["ar_damage_upgraded"] and not profile1["narrative_slice"]["settled"]["Q01"] and not profile1["sortie_checkpoint"]
            group=out/("campus_gate_"+branch+"_userdata")
            target1=group/"Godot/app_userdata/Neon Bastion Local Prototype/profile.json";target1.parent.mkdir(parents=True);shutil.copy2(source1,target1)
            for suffix, extra in [("", flags), ("_read", flags+["--read"])]:
                capture=out/("campus_gate_"+branch+suffix+"_captures");capture.mkdir()
                if not suffix:(capture/"input_provenance.json").write_text(json.dumps({"path":str(source1),"sha256":hashlib.sha256(source1.read_bytes()).hexdigest()}))
                run("packaged_campus_gate_"+branch+suffix,binary+["--fixed-fps","60","--","--local-qa","campus_exit_gate_earned"]+extra,
                    dict(smoke_env,APPDATA=str(group),LOCALAPPDATA=str(out/("campus_gate_"+branch+"_localdata")),BUNNY_EVIDENCE=str(capture)),180,"CAMPUS_ENTRY_RUN: PASS")
        for name,mode,extra in [("q01","campus_q01",[]),("q02","campus_q02",[]),("relay","campus_chapter",[]),("power","campus_chapter",[]),("pack","campus_chapter",["--pack-only"]),("supply","campus_chapter",[]),("read","campus_chapter",["--read-complete"]),("bootstrap","campus_chapter",["--bootstrap-only"])]:
            if name=="q02":
                source2=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
                profile2=json.loads(source2.read_text())["profile"]
                assert profile2["successful_sorties"]==2 and profile2["narrative_slice"]["settled"]["Q01"] and not profile2["narrative_slice"]["settled"]["Q02"] and not profile2["sortie_checkpoint"]
                target2=out/"medical_seed/profile.json";target2.parent.mkdir();shutil.copy2(source2,target2)
            if name=="relay":
                actual=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
                campaign_extra_returns=q02_extra_returns(json.loads(actual.read_text())["profile"],json.loads((out/"campus_entry_q02_captures/campus_entry.json").read_text()))
                (out/"q02_actual_return_offset.json").write_text(json.dumps({"extra_returns":campaign_extra_returns,"evidence":"campus_entry_q02_captures/campus_entry.json"}))
            if name=="power":
                source4=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
                profile4=json.loads(source4.read_text())["profile"]
                assert profile4["successful_sorties"]==4+campaign_extra_returns and profile4["campus_chapter"]["recorder_returned"] and not profile4["campus_chapter"]["power_returned"] and not profile4["sortie_checkpoint"]
                target4=out/"campus_power_seed/profile.json";target4.parent.mkdir();shutil.copy2(source4,target4)
            if name=="relay":
                source3=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
                profile3=json.loads(source3.read_text())["profile"]
                assert profile3["successful_sorties"]==3+campaign_extra_returns and profile3["narrative_slice"]["settled"]["Q02"] and not profile3["campus_chapter"]["relays_returned"] and not profile3["sortie_checkpoint"]
                target3=out/"campus_relay_seed/profile.json";target3.parent.mkdir();shutil.copy2(source3,target3)
            if name=="supply":
                source5=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
                profile5=json.loads(source5.read_text())["profile"]
                assert profile5["successful_sorties"]==5+campaign_extra_returns and profile5["campus_chapter"]["delivered_armor"] and profile5["campus_chapter"]["delivered_ammo"]==60 and not profile5["campus_chapter"]["finished"] and not profile5["sortie_checkpoint"]
                target5=out/"campus_handoff_seed/profile.json";target5.parent.mkdir();shutil.copy2(source5,target5)
            capture=out/("campus_entry_"+name+"_captures");capture.mkdir()
            run("packaged_campus_entry_"+name,binary+["--fixed-fps","60","--","--local-qa",mode]+extra,
                dict(smoke_env,APPDATA=str(out/"first_sortie_userdata"),BUNNY_EVIDENCE=str(capture)),180,"CAMPUS_ENTRY_RUN: PASS")
        relay_dest=out/"relay_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        relay_dest.parent.mkdir(parents=True);shutil.copy2(out/"campus_relay_seed/profile.json",relay_dest)
        for name, flags in [("earned", []), ("read", ["--read-relay"])]:
            capture=out/("relay_"+name+"_captures");capture.mkdir()
            run("packaged_relay_"+name,binary+["--fixed-fps","60","--","--local-qa","relay_earned"]+flags,
                dict(smoke_env,APPDATA=str(out/"relay_earned_userdata"),LOCALAPPDATA=str(out/"relay_earned_localdata"),BUNNY_EVIDENCE=str(capture)),180,"CAMPUS_ENTRY_RUN: PASS")
        find_dest=out/"recovered_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        find_dest.parent.mkdir(parents=True);shutil.copy2(out/"campus_relay_seed/profile.json",find_dest)
        for name, flags in [("earned", []), ("read", ["--read-find"])]:
            capture=out/("recovered_"+name+"_captures");capture.mkdir()
            run("packaged_recovered_"+name,binary+["--fixed-fps","60","--","--local-qa","recovered_earned"]+flags,
                dict(smoke_env,APPDATA=str(out/"recovered_earned_userdata"),LOCALAPPDATA=str(out/"recovered_earned_localdata"),BUNNY_EVIDENCE=str(capture)),180,"CAMPUS_ENTRY_RUN: PASS")
        medical_dest=out/"medical_intercept_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        medical_dest.parent.mkdir(parents=True);shutil.copy2(out/"medical_seed/profile.json",medical_dest)
        for name, flags in [("earned",[]),("read",["--read"])]:
            capture=out/("medical_intercept_"+name+"_captures");capture.mkdir()
            run("packaged_medical_intercept_"+name,binary+["--fixed-fps","60","--","--local-qa","medical_intercept"]+flags,
                dict(smoke_env,APPDATA=str(out/"medical_intercept_userdata"),LOCALAPPDATA=str(out/"medical_intercept_localdata"),BUNNY_EVIDENCE=str(capture)),180,"CAMPUS_ENTRY_RUN: PASS")
        seed6=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        assert json.loads(seed6.read_text())["profile"]["successful_sorties"]==6+campaign_extra_returns
        dest6=out/"maintenance_rescue_seed/profile.json";dest6.parent.mkdir();shutil.copy2(seed6,dest6)
        shared_seed=json.loads(seed6.read_text())["profile"]
        assert shared_seed["campus_chapter"]["finished"] and not shared_seed["maintenance_rescued"] and not shared_seed["sortie_checkpoint"]
        for language,flags in [("zh",[]),("en",["--english","--rescue-first"])]:
            group=out/("shared_"+language+"_userdata")
            target=group/"Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
            target.parent.mkdir(parents=True);shutil.copy2(seed6,target)
            for stage,extra in [("route",flags),("read",["--read"]+(["--english"] if language=="en" else []))]:
                capture=out/("shared_"+language+"_"+stage+"_captures");capture.mkdir()
                run("packaged_shared_"+language+"_"+stage,binary+["--fixed-fps","60","--","--local-qa","shared_earned"]+extra,
                    dict(smoke_env,APPDATA=str(group),LOCALAPPDATA=str(out/("shared_"+language+"_localdata")),BUNNY_EVIDENCE=str(capture)),180,"MAINTENANCE_RUN: PASS")
        earned6=out/"rescue_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json";earned6.parent.mkdir(parents=True);shutil.copy2(seed6,earned6)
        rescue6=out/"maintenance_rescue_first_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json";rescue6.parent.mkdir(parents=True);shutil.copy2(seed6,rescue6)
        for name,flags in [("component",[]),("write",["--write"]),("read",["--read"])]:
            run("packaged_maintenance_journey_"+name,binary+["--fixed-fps","60","--","--local-qa","maintenance_journey"]+flags,
                dict(smoke_env,APPDATA=str(out/"maintenance_journey_userdata"),LOCALAPPDATA=str(out/"maintenance_journey_localdata")),180,"MAINTENANCE_JOURNEY_TEST: PASS")
        run("packaged_maintenance_art",binary+["--fixed-fps","60","--","--local-qa","maintenance_art"],
            dict(smoke_env,APPDATA=str(out/"maintenance_art_userdata"),LOCALAPPDATA=str(out/"maintenance_art_localdata")),180,"MAINTENANCE_ART_TEST: PASS")
        for mode,marker in [("rescue_moment","RESCUE_RETURN_TEST: PASS"),("rescue_result","RESCUE_RESULT_TEST: PASS")]:
            run("packaged_"+mode,binary+["--fixed-fps","60","--","--local-qa",mode],dict(smoke_env,APPDATA=str(out/(mode+"_userdata")),LOCALAPPDATA=str(out/(mode+"_localdata"))),180,marker)
        for name,flags in [("route",[]),("read",["--read"])]:
            cap=out/("rescue_earned_"+name+"_captures");cap.mkdir()
            run("packaged_rescue_earned_"+name,binary+["--fixed-fps","60","--","--local-qa","rescue_earned"]+flags,dict(smoke_env,APPDATA=str(out/"rescue_earned_userdata"),LOCALAPPDATA=str(out/"rescue_earned_localdata"),BUNNY_EVIDENCE=str(cap)),180,"RESCUE_RETURN_RUN: PASS")
        for name, extra in [("maintenance", []), ("maintenance_write", ["--write"]), ("maintenance_read", ["--read"]), ("maintenance_link_write", ["--link-write"]), ("maintenance_link_read", ["--link-read"])]:
            run("packaged_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "maintenance"] + extra,
                dict(smoke_env, APPDATA=str(out / "maintenance_userdata")), 180, "MAINTENANCE_TEST: PASS")
        for name, extra in [("maintenance_route", []), ("maintenance_route_read", ["--read"])]:
            run("packaged_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "maintenance_route"] + extra,
                dict(smoke_env, APPDATA=str(out / "first_sortie_userdata"), BUNNY_EVIDENCE=str(out)), 180, "MAINTENANCE_RUN: PASS")
        for name,flags in [("route",["--rescue-first"]),("read",["--read"])]:
            cap=out/("rescue_first_"+name+"_captures");cap.mkdir()
            run("packaged_maintenance_rescue_first_"+name,binary+["--fixed-fps","60","--","--local-qa","maintenance_route"]+flags,
                dict(smoke_env,APPDATA=str(out/"maintenance_rescue_first_userdata"),LOCALAPPDATA=str(out/"maintenance_rescue_first_localdata"),BUNNY_EVIDENCE=str(cap)),180,"MAINTENANCE_RUN: PASS")
        for name,flags in [("component",[])]+[(phase+"_"+mode,["--"+mode]+([] if phase=="windup" else ["--"+phase])) for phase in ["windup","charge","stun"] for mode in ["write","read"]]:
            run("packaged_campus_power_"+name,binary+["--fixed-fps","60","--","--local-qa","campus_power"]+flags,
                dict(smoke_env,APPDATA=str(out/"campus_power_userdata")),180,"CAMPUS_POWER_TEST: PASS")
        for name,marker in [("bucket_moment","BUCKET_RETURN_TEST: PASS"),("bucket_result","BUCKET_RESULT_TEST: PASS")]:
            run("packaged_"+name,binary+["--fixed-fps","60","--","--local-qa",name],dict(smoke_env,APPDATA=str(out/(name+"_userdata"))),180,marker)
        bucket_seed=out/"first_sortie_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        assert json.loads(bucket_seed.read_text())["profile"]["successful_sorties"]==7+campaign_extra_returns
        for branch, flags in [("courier", []), ("freight", ["--freight"])]:
            group = out / ("carrier_" + branch + "_userdata")
            target = group / "Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
            target.parent.mkdir(parents=True); shutil.copy2(bucket_seed, target)
            for suffix, read in [("", []), ("_read", ["--read"])]:
                cap = out / ("carrier_" + branch + suffix + "_captures"); cap.mkdir()
                run("packaged_carrier_earned_" + branch + suffix, binary + ["--fixed-fps", "60", "--", "--local-qa", "carrier_use"] + flags + read,
                    dict(smoke_env, APPDATA=str(group), LOCALAPPDATA=str(out / ("carrier_" + branch + "_localdata")), BUNNY_EVIDENCE=str(cap)), 240, "RECOVERED_CARRIER_RUN: PASS")
        for branch,flags in [("quiet",[]),("loud",["--loud"]),("skip",["--skip-depot"])]:
            group=out/("market_earned_"+branch+"_userdata")
            target=group/"Godot/app_userdata/Neon Bastion Local Prototype/profile.json";target.parent.mkdir(parents=True);shutil.copy2(bucket_seed,target)
            for suffix,read in [("",[]),("_read",["--read"])]:
                cap=out/("market_earned_"+branch+suffix+"_captures");cap.mkdir()
                run("packaged_market_earned_"+branch+suffix,binary+["--fixed-fps","60","--","--local-qa","market_earned"]+flags+read,
                    dict(smoke_env,APPDATA=str(group),LOCALAPPDATA=str(out/("market_earned_"+branch+"_localdata")),BUNNY_EVIDENCE=str(cap)),240,"WATER_MARKET_RUN: PASS")
        bucket_dest=out/"bucket_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        bucket_dest.parent.mkdir(parents=True);shutil.copy2(bucket_seed,bucket_dest)
        for name,flags in [("bucket_earned",[]),("bucket_earned_read",["--read"])]:
            capture=out/(name+"_captures");capture.mkdir()
            run("packaged_"+name,binary+["--fixed-fps","60","--","--local-qa","bucket_route"]+flags,
                dict(smoke_env,APPDATA=str(out/"bucket_earned_userdata"),BUNNY_EVIDENCE=str(capture)),180,"BUCKET_EARNED_RUN: PASS")
        for name, extra in [("finale", []), ("finale_write", ["--write"]), ("finale_read", ["--read"])]:
            run("packaged_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "finale"] + extra,
                dict(smoke_env, APPDATA=str(out / "finale_userdata")), 180, "FINALE_TEST: PASS")
        for name, extra in [("homecoming", []), ("homecoming_english", ["--english"])]:
            run("packaged_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "homecoming"] + extra,
                dict(smoke_env, APPDATA=str(out / (name + "_userdata"))), 180, "HOMECOMING_FINALE_TEST: PASS")
        for name, extra in [("story_finish", []), ("story_finish_read", ["--read"])]:
            run("packaged_" + name, binary + ["--fixed-fps", "60", "--", "--local-qa", "story_finish"] + extra,
                dict(smoke_env, APPDATA=str(out / "first_sortie_userdata"), BUNNY_EVIDENCE=str(out)), 180, "STORY_FINISH_RUN: PASS")
        for name,extra in [("water_shot",["--shoot-public"])]:
            run("packaged_"+name,binary+["--fixed-fps","60","--","--local-qa","water_public"]+extra,
                dict(smoke_env,APPDATA=str(out/(name+"_userdata")),BUNNY_EVIDENCE=str(out)),180,"WATERWORKS_RUN: PASS")
        for name,extra in [("water_delivery",[]),("water_delivery_public_write",["--write"]),("water_delivery_public_read",["--read"]),("water_delivery_tanker_write",["--write","--tanker"]),("water_delivery_tanker_read",["--read"])]:
            run("packaged_"+name,binary+["--fixed-fps","60","--","--local-qa","water_delivery"]+extra,
                dict(smoke_env,APPDATA=str(out/"water_delivery_userdata")),180,"WATER_DELIVERY_TEST: PASS")
        run("packaged_training", binary + ["--fixed-fps", "60", "--", "--local-qa", "training"],
            dict(smoke_env, APPDATA=str(out / "training_userdata")), 180, "TRAINING_ROOM_TEST: PASS")
        run("packaged_fitting", binary + ["--fixed-fps", "60", "--", "--local-qa", "fitting"],
            dict(smoke_env, APPDATA=str(out / "fitting_userdata")), 180, "WORKSHOP_MOMENT_TEST: PASS")
        run("packaged_seat", binary + ["--fixed-fps", "60", "--", "--local-qa", "seat"],
            dict(smoke_env, APPDATA=str(out / "seat_userdata")), 180, "SEAT_MOMENT_TEST: PASS")
        for name,flags in [("component",[])]+[(phase+"_"+mode,["--"+mode,"--"+phase]) for phase in ["chain","sweep","gate"] for mode in ["write","read"]]:
            run("packaged_blockade_journey_"+name,binary+["--fixed-fps","60","--","--local-qa","blockade_journey"]+flags,
                dict(smoke_env,APPDATA=str(out/"blockade_journey_userdata")),180,"BLOCKADE_JOURNEY_TEST: PASS")
        run("packaged_blockade_street",binary+["--fixed-fps","60","--","--local-qa","blockade_route","--street"],
            dict(smoke_env,APPDATA=str(out/"blockade_street_userdata")),180,"BLOCKADE_RUN: PASS")
        block_source=out/"bucket_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        block_dest=out/"blockade_earned_userdata/Godot/app_userdata/Neon Bastion Local Prototype/profile.json"
        block_dest.parent.mkdir(parents=True);shutil.copy2(block_source,block_dest)
        for name,flags in [("blockade_earned",[]),("blockade_earned_read",["--read"])]:
            capture=out/(name+"_captures");capture.mkdir()
            run("packaged_"+name,binary+["--fixed-fps","60","--","--local-qa","blockade_earned"]+flags,
                dict(smoke_env,APPDATA=str(out/"blockade_earned_userdata"),BUNNY_EVIDENCE=str(capture)),180,"BLOCKADE_EARNED_RUN: PASS")
        for mode, marker in [("blockade", "BLOCKADE_TEST: PASS"), ("blockade_route", "BLOCKADE_RUN: PASS"), ("blockade_readability", "BLOCKADE_READABILITY_TEST: PASS")]:
            run("packaged_" + mode, binary + ["--fixed-fps", "60", "--", "--local-qa", mode],
                dict(smoke_env, APPDATA=str(out / (mode + "_userdata"))), 180, marker)
    files = {p.name:{"bytes":p.stat().st_size,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in bundle.iterdir() if p.is_file()}
    (out / "local_build_manifest.json").write_text(json.dumps({"visibility":"LOCAL_ONLY_DO_NOT_UPLOAD", "public_release_approved":False,
        "engine":version, "template_version":template_version, "files":files, "results":results}, indent=2), encoding="utf-8")
    print("LOCAL ONLY BUILD READY:", executable, flush=True)


if __name__ == "__main__":
    main()
