"""Build the offline, metre-scale campus database from licensed OSM + Mapzen HGT.

No imagery is traced. Run with --osm map.osm --hgt N39E117.hgt.gz.
Coordinates are WGS84 local east/north metres (Godot z points south); no GCJ offset.
The database, unlike the game code, is distributed under ODbL 1.0.
"""
import argparse
import array
import collections
import gzip
import hashlib
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/geography/weijin"
SOURCE = ROOT / "art_source/weijin_geography"
ORIGIN = [117.16465, 39.10915]
# WGS84 tangent-plane radii at the origin. The error over this campus is < 0.2 m.
PHI = math.radians(ORIGIN[1])
A, E2 = 6378137.0, 6.69437999014e-3
N = A / math.sqrt(1 - E2 * math.sin(PHI) ** 2)
M = A * (1 - E2) / (1 - E2 * math.sin(PHI) ** 2) ** 1.5
MX, MY = math.pi / 180 * N * math.cos(PHI), math.pi / 180 * M


def project(lon, lat):
    return [round((lon - ORIGIN[0]) * MX, 3), round((ORIGIN[1] - lat) * MY, 3)]


def inside(p, poly):
    result = False
    for a, b in zip(poly, poly[1:] + poly[:1]):
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]:
            result = not result
    return result


def tags(element):
    return {t.get("k"): t.get("v") for t in element.findall("tag")}


def number(value, fallback):
    try:
        return float(str(value).replace(" m", "").split(";")[0])
    except (ValueError, TypeError):
        return fallback


def run(osm, hgt):
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    root = ET.parse(osm).getroot()
    nodes = {n.get("id"): n for n in root.findall("node")}
    positions = {k: project(float(n.get("lon")), float(n.get("lat"))) for k, n in nodes.items()}
    campus = root.find("way[@id='48165383']")
    if campus is None:
        raise ValueError("The real campus boundary way/48165383 is required")
    boundary = [positions[n.get("ref")] for n in campus.findall("nd")][:-1]
    bounds = [min(p[i] for p in boundary) for i in range(2)] + [max(p[i] for p in boundary) for i in range(2)]
    features = {k: [] for k in ["buildings", "roads", "water", "landcover", "pitches", "points"]}
    default_width = {"footway": 2.2, "path": 1.8, "steps": 2.0, "cycleway": 2.5, "service": 5.0, "residential": 7.0, "unclassified": 7.0, "tertiary": 10.0, "secondary": 14.0, "pedestrian": 6.0, "living_street": 5.0, "track": 3.0}
    for w in root.findall("way"):
        t = tags(w)
        points = [positions[n.get("ref")] for n in w.findall("nd") if n.get("ref") in positions]
        if len(points) < 2:
            continue
        # Keep complete source outlines: never rescale, rotate or simplify geometry.
        within = any(inside(p, boundary) for p in points)
        near = any(bounds[0] - 65 < p[0] < bounds[2] + 65 and bounds[1] - 65 < p[1] < bounds[3] + 65 for p in points)
        if not near:
            continue
        entry = {"osm_id": "way/" + w.get("id"), "name": t.get("name", ""), "tags": t, "points": points, "inside_campus": within}
        closed = points[0] == points[-1]
        if closed:
            entry["points"] = points[:-1]
        if t.get("building") and closed and t.get("location") != "underground" and t.get("building") != "construction":
            levels = number(t.get("building:levels"), 4 if within else 6)
            if t.get("building") in ["shed", "garages", "roof", "service"]:
                levels = number(t.get("building:levels"), 1)
            entry.update(height=number(t.get("height"), levels * 3.3), height_source="osm_height" if "height" in t else ("osm_levels" if "building:levels" in t else "estimated"))
            features["buildings"].append(entry)
        elif t.get("natural") == "water" and closed:
            features["water"].append(entry)
        elif t.get("highway") and t["highway"] not in ["construction", "proposed"]:
            if closed:
                entry["points"] = points  # closed road loops retain their closing segment
            entry.update(width=number(t.get("width"), default_width.get(t["highway"], 5.0)), width_source="osm_width" if "width" in t else "estimated_by_road_class")
            features["roads"].append(entry)
        elif t.get("leisure") in ["pitch", "playground", "track"] and closed:
            features["pitches"].append(entry)
        elif closed and (t.get("landuse") in ["grass", "forest", "meadow", "recreation_ground"] or t.get("leisure") in ["park", "garden"] or t.get("natural") in ["wood", "scrub", "grassland"]):
            features["landcover"].append(entry)
    for key, n in nodes.items():
        t = tags(n)
        p = positions[key]
        if inside(p, boundary) and (t.get("name") or t.get("natural") == "tree" or t.get("barrier") == "gate"):
            features["points"].append({"osm_id": "node/" + key, "name": t.get("name", ""), "tags": t, "point": p})
    # HGT is a 1 arc-second regional DEM, NOT a campus survey. A 5x5 median
    # suppresses urban canopy/building artefacts before bilinear interpolation.
    samples = array.array("h")
    samples.frombytes(gzip.decompress(Path(hgt).read_bytes()))
    if __import__("sys").byteorder == "little":
        samples.byteswap()
    size = math.isqrt(len(samples))
    assert size * size == len(samples) and size == 3601, "Expected N39E117 1 arc-second HGT"
    step = 24.0
    x0, z0 = math.floor((bounds[0] - 100) / step) * step, math.floor((bounds[1] - 100) / step) * step
    nx = math.ceil((bounds[2] + 100 - x0) / step) + 1
    nz = math.ceil((bounds[3] + 100 - z0) / step) + 1
    heights = []
    for iz in range(nz):
        for ix in range(nx):
            lon, lat = ORIGIN[0] + (x0 + ix * step) / MX, ORIGIN[1] - (z0 + iz * step) / MY
            sx, sy = round((lon - 117) * (size - 1)), round((40 - lat) * (size - 1))
            values = sorted(samples[(sy + dy) * size + sx + dx] for dy in range(-2, 3) for dx in range(-2, 3))
            if values[0] == -32768:
                raise ValueError("DEM void: refusing to invent elevation")
            heights.append(float(values[12]))
    # One 3x3 averaging pass on the median-filtered grid removes 1m quantisation
    # steps; no noise, vertical exaggeration, invented hills, or flattening to zero.
    heights = [round(sum(heights[j * nx + i] for j in range(max(0,z-1),min(nz,z+2)) for i in range(max(0,x-1),min(nx,x+2))) / ((min(nz,z+2)-max(0,z-1))*(min(nx,x+2)-max(0,x-1))), 3) for z in range(nz) for x in range(nx)]
    datum = sorted(heights)[len(heights) // 2]
    database = {"version": 1, "origin_wgs84": ORIGIN, "metres_per_degree": [MX, MY], "axes": "x east / y up / z south", "horizontal_scale": 1.0, "vertical_exaggeration": 1.0, "boundary_osm_id": "way/48165383", "boundary": boundary, "bounds": bounds, "dem": {"source": "Mapzen Terrain Tiles / N39E117", "nominal_arcseconds": 1, "filter": "5x5 source median + 3x3 grid mean", "datum_m": datum, "origin": [x0, z0], "step_m": step, "columns": nx, "rows": nz, "heights_m": heights}, **features}
    encoded = (json.dumps(database, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
    (OUT / "campus.json").write_bytes(encoded)
    # Retain redistributable raw sources and their hashes for reproducibility.
    (SOURCE / ".gdignore").write_text("", encoding="utf-8")
    (SOURCE / "campus.osm.gz").write_bytes(gzip.compress(Path(osm).read_bytes(), mtime=0))
    (SOURCE / "N39E117.hgt.gz").write_bytes(Path(hgt).read_bytes())
    provenance = {"osm_url": "https://api.openstreetmap.org/api/0.6/map?bbox=117.155,39.100,117.181,39.120", "osm_copyright": "© OpenStreetMap contributors", "database_license": "ODbL-1.0", "license_url": "https://opendatacommons.org/licenses/odbl/1-0/", "osm_sha256": hashlib.sha256(Path(osm).read_bytes()).hexdigest(), "hgt_url": "https://s3.amazonaws.com/elevation-tiles-prod/skadi/N39/N39E117.hgt.gz", "hgt_sha256": hashlib.sha256(Path(hgt).read_bytes()).hexdigest(), "derived_sha256": hashlib.sha256(encoded).hexdigest(), "counts": {k: len(v) for k,v in features.items()}, "campus_buildings": sum(b["inside_campus"] for b in features["buildings"]), "estimated_heights": sum(b["height_source"] == "estimated" for b in features["buildings"]), "dem_range_m": [min(heights), max(heights)], "horizontal_extent_m": [round(bounds[2]-bounds[0], 2), round(bounds[3]-bounds[1], 2)], "limitations": ["OSM is incomplete and not a cadastral survey", "Most building heights and road widths are estimates, each marked in campus.json", "DEM is regional ~30m data, filtered for urban artefacts; not surveyed kerbs, steps, lake depth or engineering grades", "Unmapped interiors, trees and facade details cannot be claimed as surveyed reconstruction"]}
    (OUT / "SOURCE.json").write_text(json.dumps(provenance, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(provenance, ensure_ascii=True, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--osm", required=True, type=Path)
    parser.add_argument("--hgt", required=True, type=Path)
    args = parser.parse_args()
    run(args.osm, args.hgt)
