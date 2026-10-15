"""Derive a clothed adult reference without changing geometry, rig or texture pixels.

python tools/derive_subject.py --archive <Standard.zip> --sex female --output <NEW directory>
This is a close-fitting material coverall, NOT a new loose-clothing mesh.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import struct
import zipfile

ARCHIVE_SHA = "fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40"
PREFIX = "Universal Base Characters[Standard]/Base Characters/Godot - UE/"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--sex", choices=["male", "female"], required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output must be new; never overwrite imported sources")
    if hashlib.sha256(args.archive.read_bytes()).hexdigest() != ARCHIVE_SHA:
        parser.error("Unexpected Standard archive revision; review provenance first")
    name = "Superhero_" + args.sex.title() + "_FullBody"
    with zipfile.ZipFile(args.archive) as z:
        raw = z.read(PREFIX + name + ".gltf")
        base = json.loads(raw)
        binary = z.read(PREFIX + base["buffers"][0]["uri"])
        args.output.mkdir(parents=True)
        (args.output / base["buffers"][0]["uri"]).write_bytes(binary)
        for image in base["images"]:
            uri = image["uri"]
            if PREFIX + uri not in z.namelist():
                uri = uri.replace("_Normal_png.png", "_Normal.png")
                image["uri"] = uri
            (args.output / uri).write_bytes(z.read(PREFIX + uri))
        license_name = "Universal Base Characters[Standard]/License_Standard.txt"
        (args.output / "LICENSE.txt").write_bytes(z.read(license_name))
    (args.output / "subject_base.gltf").write_text(json.dumps(base, indent=2), encoding="utf-8")
    derived = copy.deepcopy(base)

    def values(index):
        accessor = base["accessors"][index]
        view = base["bufferViews"][accessor["bufferView"]]
        size = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[accessor["type"]]
        fmt = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}[accessor["componentType"]] * size
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        stride = view.get("byteStride", struct.calcsize("<" + fmt))
        return [struct.unpack_from("<" + fmt, binary, offset + i * stride) for i in range(accessor["count"])]

    body = next(m for m in derived["meshes"] if m["name"] == "Superhero_" + args.sex.title())
    primitive = body["primitives"][0]
    positions = values(primitive["attributes"]["POSITION"])
    joints = values(primitive["attributes"]["JOINTS_0"])
    weights = values(primitive["attributes"]["WEIGHTS_0"])
    indices = [x[0] for x in values(primitive["indices"])]
    names = [base["nodes"][i]["name"] for i in base["skins"][0]["joints"]]
    categories = []
    for position, js, ws in zip(positions, joints, weights):
        bone = names[js[max(range(4), key=lambda j: ws[j])]]
        skin = bone in {"Head", "neck_01", "hand_l", "hand_r"} or bone.startswith(("index_", "middle_", "ring_", "pinky_", "thumb_"))
        categories.append(2 if position[1] < .13 else (0 if skin else 1))
    partitions = [[], [], []]
    for at in range(0, len(indices), 3):
        triangle = indices[at:at + 3]
        votes = [categories[i] for i in triangle]
        category = max(range(3), key=lambda c: (votes.count(c), -c))
        partitions[category].extend(triangle)
    material_start = len(derived["materials"])
    for label, color in [("Exposed skin", [.38, .21, .12, 1]), ("Clinical coverall", [.12, .3, .4, 1]), ("Soft shoes", [.055, .065, .08, 1])]:
        derived["materials"].append({"name": label, "pbrMetallicRoughness": {"baseColorFactor": color, "metallicFactor": 0, "roughnessFactor": .93}})
    blob = bytearray(binary)
    body["primitives"] = []
    for category, selected in enumerate(partitions):
        if not selected:
            continue
        blob.extend(b"\0" * ((-len(blob)) % 4))
        offset = len(blob)
        blob.extend(struct.pack("<" + "I" * len(selected), *selected))
        view = len(derived["bufferViews"])
        derived["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(selected) * 4, "target": 34963})
        accessor = len(derived["accessors"])
        derived["accessors"].append({"bufferView": view, "componentType": 5125, "count": len(selected), "type": "SCALAR", "min": [min(selected)], "max": [max(selected)]})
        part = copy.deepcopy(primitive)
        part.update(indices=accessor, material=material_start + category)
        body["primitives"].append(part)
    derived["buffers"][0].update(uri="subject_clothed.bin", byteLength=len(blob))
    (args.output / "subject_clothed.bin").write_bytes(blob)
    (args.output / "subject_clothed.gltf").write_text(json.dumps(derived, indent=2), encoding="utf-8")
    provenance = {
        "author": "Quaternius", "source": "https://quaternius.itch.io/universal-base-characters",
        "official_page": "https://quaternius.com/packs/universalbasecharacters.html",
        "edition": "Standard / free", "license": "CC0-1.0", "cost": 0, "access_date": "2026-10-15",
        "archive_sha256": ARCHIVE_SHA, "selected_source": PREFIX + name + ".gltf",
        "source_gltf_sha256": hashlib.sha256(raw).hexdigest(),
        "target": "adult " + args.sex, "triangle_partitions": [len(p) // 3 for p in partitions],
        "changes": ["Fix missing normal texture URI", "Body index partitions only; positions, weights, bind skeleton and original texture pixels unchanged", "Material coverall is not loose cloth geometry", "No teen or paid Source assets"],
        "derivative_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in args.output.iterdir() if p.is_file() and p.name != "LICENSE.txt"},
    }
    (args.output / "SOURCE.json").write_text(json.dumps(provenance, indent=2), encoding="utf-8")
    (args.output / "SOURCE.md").write_text("# Adult subject reference\n\nCC0 Quaternius free Standard, adult " + args.sex + ".\n\nSee SOURCE.json for exact archive and derived-file hashes. The clinical coverall is a close-fitting material partition, not a newly modeled garment. All original rig, weights and geometry are retained.\n", encoding="utf-8")
    print("SUBJECT_DERIVATIVE: PASS", args.sex, [len(p) // 3 for p in partitions])


if __name__ == "__main__":
    main()
