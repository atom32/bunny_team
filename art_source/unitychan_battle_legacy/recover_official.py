"""Recover official Battle Costume 1.1 sources; never write into runtime assets.

Usage: python recover_official.py <downloaded-unitypackage>
Requires only Python's standard library. Original FBX and metadata stay untouched.
"""
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys
import tarfile

EXPECTED = "12f1365e5e2eb82e2a0e3ddb5d105c690518a8404a1c33fb0027800436096c2c"
MODEL = "Assets/UnityChanTPK/Models/01_kohaku_A/"
ROOT = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write_exact(path, data):
    if path.exists():
        if path.read_bytes() != data:
            raise RuntimeError(f"Refusing to overwrite changed file: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def main():
    archive = Path(sys.argv[1])
    assert sha(archive.read_bytes()) == EXPECTED, "Unexpected package version/hash"
    entries = {}
    with tarfile.open(archive, "r:gz") as tar:
        for member in tar.getmembers():
            if not member.name.endswith("/pathname"):
                continue
            path = tar.extractfile(member).read().decode().strip()
            parts = PurePosixPath(path)
            assert not parts.is_absolute() and ".." not in parts.parts
            guid = member.name.rsplit("/", 1)[0]
            try:
                data = tar.extractfile(guid + "/asset").read()
            except KeyError:
                continue  # Unity directory entry, not an asset.
            meta = tar.extractfile(guid + "/asset.meta").read()
            entries[guid] = {"path": path, "data": data, "meta": meta}

    by_path = {e["path"]: e for e in entries.values()}
    selected = {p for p in by_path if p.startswith(MODEL)}
    # Preserve the actual shader and its package-local include closure as evidence.
    shader_path = "Assets/UnityChanTPK/Toon/Shader/Toon_ShadingGradeMap.shader"
    pending = [shader_path]
    while pending:
        p = pending.pop()
        if p in selected:
            continue
        selected.add(p)
        for include in re.findall(r'#include\s+"([^"]+)"', by_path[p]["data"].decode()):
            candidate = str(PurePosixPath(p).parent / include)
            if candidate in by_path:
                pending.append(candidate)
    selected.add("Assets/UnityChanTPK/Toon/Shader/README.TXT")
    records = []
    for p in sorted(selected):
        e = by_path[p]
        for suffix, data in [("", e["data"]), (".meta", e["meta"])]:
            write_exact(ROOT / "official_1_1" / (p + suffix), data)
        records.append({"path": p, "sha256": sha(e["data"]),
                        "meta_sha256": sha(e["meta"]), "bytes": len(e["data"])})

    materials = []
    for p in sorted(selected):
        if not p.endswith(".mat"):
            continue
        content = by_path[p]["data"].decode()
        shader_guid = re.search(r'm_Shader: .*guid: ([a-f0-9]+)', content)[1]
        shader = entries[shader_guid]
        properties = shader["data"].decode().split("SubShader", 1)[0]
        slots = []
        for slot, guid in re.findall(r'- (\w+):\s*\n\s*m_Texture: \{fileID: \d+, guid: ([a-f0-9]+)', content):
            resolved = entries.get(guid)
            declared = bool(re.search(r'\b' + re.escape(slot) + r'\s*\(', properties))
            slots.append({"slot": slot, "guid": guid,
                          "path": resolved["path"] if resolved else None,
                          "shader_property": declared})
        materials.append({"path": p, "shader": shader["path"], "textures": slots})

    prefab = by_path[MODEL + "Prefabs/01_kohaku_A.prefab"]["data"].decode()
    renderers = []
    for block in re.split(r'\n--- !u!', prefab):
        mesh = re.search(r'm_Mesh: \{fileID: (\d+), guid: ([a-f0-9]+)', block)
        if not mesh or "m_Materials:" not in block:
            continue
        mat_block = block.split("m_Materials:", 1)[1].split("  m_", 1)[0]
        renderers.append({"mesh_file_id": mesh[1], "fbx": entries[mesh[2]]["path"],
                          "materials": [entries[g]["path"] for g in re.findall(r'guid: ([a-f0-9]+)', mat_block)]})
    main_fbx = by_path[MODEL + "01_kohaku_A.fbx"]["data"]
    assert sha(main_fbx) == sha((ROOT / "unitychan_battle.fbx").read_bytes())
    missing_active = [s for m in materials for s in m["textures"] if s["shader_property"] and not s["path"]]
    report = {"source": "https://unity3d.jp/unity-chan_contents/download.php?id=TPK-Hmnd-Kohaku_A&v=1.1",
              "access_date": "2026-09-25", "archive_sha256": EXPECTED,
              "archive_bytes": archive.stat().st_size, "legacy_fbx_identical": True,
              "files": records, "materials": materials, "prefab_renderers": renderers,
              "missing_declared_shader_textures": missing_active,
              "scope": "Source dependency recovery only; no Godot/Blender/animation acceptance"}
    write_exact(ROOT / "recovery_manifest.json", (json.dumps(report, indent=2) + "\n").encode())
    print(json.dumps({"files": len(records), "png": sum(p.endswith('.png') for p in selected),
                      "materials": len(materials), "renderers": len(renderers),
                      "missing_active": len(missing_active), "legacy_fbx_identical": True}))
    assert not missing_active, "Official shader texture dependency unresolved"


if __name__ == "__main__":
    main()
