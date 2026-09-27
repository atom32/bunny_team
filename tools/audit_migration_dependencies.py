"""Read-only Phase 2B trace: FBX material links, source references and VRM metadata.

Usage: python tools/audit_migration_dependencies.py --output <outside-project.json>
Uses only the Python standard library. Does not import, rewrite or normalize assets.
Arrays are skipped: this audits dependency links, not animation equivalence.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess


def fbx_nodes(path):
    data = path.read_bytes()
    if not data.startswith(b"Kaydara FBX Binary"):
        raise ValueError(f"Not a binary FBX: {path}")
    version = struct.unpack_from("<I", data, 23)[0]
    header = "<QQQB" if version >= 7500 else "<IIIB"
    header_size = struct.calcsize(header)

    def node(pos):
        end, count, _, name_size = struct.unpack_from(header, data, pos)
        if not end:
            return None, pos + header_size
        if end > len(data) or end <= pos:
            raise ValueError("Invalid FBX node boundary")
        pos += header_size
        name = data[pos:pos + name_size].decode()
        pos += name_size
        props = []
        for _ in range(count):
            kind = chr(data[pos])
            pos += 1
            if kind in "YCFDIL":
                fmt = {"Y": "h", "C": "?", "F": "f", "D": "d", "I": "i", "L": "q"}[kind]
                value = struct.unpack_from("<" + fmt, data, pos)[0]
                pos += struct.calcsize(fmt)
            elif kind in "SR":
                size = struct.unpack_from("<I", data, pos)[0]
                pos += 4
                value = data[pos:pos + size].decode(errors="replace") if kind == "S" else "<binary>"
                pos += size
            elif kind in "fdilbc":
                _, _, size = struct.unpack_from("<III", data, pos)
                pos += 12 + size
                value = "<array omitted>"
            else:
                raise ValueError(f"Unsupported FBX property: {kind}")
            props.append(value)
        children = []
        while pos < end - header_size:
            child, pos = node(pos)
            if child:
                children.append(child)
        return {"name": name, "props": props, "children": children}, end

    result, pos = [], 27
    while pos < len(data):
        item, pos = node(pos)
        if not item:
            break
        result.append(item)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
    sources = {}
    for name in tracked:
        path = root / name
        if path.is_file() and path.suffix in {".gd", ".tscn", ".tres", ".godot"}:
            sources[name] = path.read_text(encoding="utf-8-sig")
    report = {"head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root).decode().strip(),
              "scope": "Static references plus raw FBX material graph; not proof of dynamic resource reachability",
              "fbx": []}
    files = list((root / "assets/characters/unitychan_battle").rglob("*.fbx"))
    files += list((root / "art_source/unitychan_battle_legacy").glob("*.fbx"))
    for path in sorted(files):
        nodes = fbx_nodes(path)
        objects = next(n["children"] for n in nodes if n["name"] == "Objects")
        connections = next(n["children"] for n in nodes if n["name"] == "Connections")
        ids = {o["props"][0]: o for o in objects}
        relevant = {key for key, o in ids.items() if o["name"] in {"Material", "Texture", "Video"}}
        rel = path.relative_to(root).as_posix()
        refs = [{"file": name, "line": i, "text": line.strip()}
                for name, text in sources.items() for i, line in enumerate(text.splitlines(), 1)
                if rel in line or path.name in line]
        deps = []
        for obj in objects:
            if obj["name"] not in {"Texture", "Video"}:
                continue
            fields = {n["name"]: n["props"] for n in obj["children"]
                      if n["name"] in {"FileName", "Filename", "RelativeFilename", "Media"}}
            relative = fields.get("RelativeFilename", [""])[0]
            base = root / "assets/characters/unitychan_battle" if "art_source" in path.parts else path.parent
            resolved = (base / relative.replace("\\", "/")).resolve() if relative else None
            deps.append({"type": obj["name"], "id_name": obj["props"], "fields": fields,
                         "resolved_from_original_location": str(resolved) if resolved else None,
                         "exists": resolved.is_file() if resolved else False,
                         "classification": "historical Maya shader metadata" if relative.endswith(".cgfx")
                         else "excluded legacy texture reference" if "art_source" in path.parts else "texture input"})
        links = []
        for c in connections:
            values = c["props"]
            if len(values) > 2 and values[1] in relevant:
                links.append({"link": values, "from": ids[values[1]]["props"],
                              "to": ids.get(values[2], {}).get("props")})
        report["fbx"].append({"file": rel, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                              "references": refs, "texture_video": deps, "material_links": links})
    path = root / "assets/characters/vrm_avatar/avatar_sample_a.glb"
    data = path.read_bytes()
    size, kind = struct.unpack_from("<II", data, 12)
    if kind != 0x4E4F534A:
        raise ValueError("GLB first chunk is not JSON")
    doc = json.loads(data[20:20 + size])
    report["vrm"] = {"sha256": hashlib.sha256(data).hexdigest(),
                     "meta": doc.get("extensions", {}).get("VRM", {}).get("meta", {}),
                     "image_count": len(doc.get("images", [])),
                     "external_images": [x["uri"] for x in doc.get("images", [])
                                         if "uri" in x and not x["uri"].startswith("data:")],
                     "embedded_image_count": sum("bufferView" in x for x in doc.get("images", []))}
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    for item in report["fbx"]:
        print(item["file"], "source references:", len(item["references"]))
    print("Evidence:", args.output.resolve())


if __name__ == "__main__":
    main()
