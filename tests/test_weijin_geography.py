"""Offline source fidelity; no network, screenshots or invented ground truth."""
import contextlib
import gzip
import hashlib
import importlib.util
import io
import json
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("campus_importer", ROOT / "tools/import_weijin_geography.py")
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)


class GeographySourceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / "assets/geography/weijin"
        cls.data = json.loads((cls.folder / "campus.json").read_text(encoding="utf-8"))
        cls.source = ROOT / "art_source/weijin_geography"
        cls.raw = gzip.decompress((cls.source / "campus.osm.gz").read_bytes())
        cls.osm = ET.fromstring(cls.raw)
        cls.nodes = {n.get("id"): n for n in cls.osm.findall("node")}
        cls.ways = {w.get("id"): w for w in cls.osm.findall("way")}

    def test_all_feature_corners_are_source_coordinates(self):
        count = 0
        for group in ["buildings", "roads", "water", "landcover", "pitches"]:
            for feature in self.data[group]:
                way = self.ways[feature["osm_id"].split("/")[1]]
                points = [importer.project(float(self.nodes[n.get("ref")].get("lon")), float(self.nodes[n.get("ref")].get("lat"))) for n in way.findall("nd")]
                if group != "roads" and points[0] == points[-1]:
                    points.pop()
                self.assertEqual(feature["points"], points, feature["osm_id"])
                count += len(points)
        self.assertGreater(count, 6500)

    def test_whole_campus_scale_and_source_lakes(self):
        b = self.data["bounds"]
        self.assertAlmostEqual(b[2]-b[0], 1395.662, places=2)
        self.assertAlmostEqual(b[3]-b[1], 905.170, places=2)
        self.assertEqual(self.data["horizontal_scale"], 1)
        self.assertEqual(self.data["vertical_exaggeration"], 1)
        self.assertEqual({e["name"] for e in self.data["water"]}, {"敬业湖", "青年湖", "爱晚湖", "友谊湖"})
        self.assertEqual(sum(e["inside_campus"] for e in self.data["buildings"]), 428)

    def test_estimates_are_explicit_not_survey_claims(self):
        buildings = self.data["buildings"]
        self.assertEqual(sum(e["height_source"] == "estimated" for e in buildings), 455)
        for e in buildings:
            self.assertIn(e["height_source"], ["osm_height", "osm_levels", "estimated"])
        for e in self.data["roads"]:
            self.assertIn(e["width_source"], ["osm_width", "estimated_by_road_class"])
        dem = self.data["dem"]
        self.assertEqual(dem["nominal_arcseconds"], 1)
        self.assertEqual(len(dem["heights_m"]), dem["columns"]*dem["rows"])
        self.assertGreater(max(dem["heights_m"])-min(dem["heights_m"]), 2)

    def test_hashes_and_license(self):
        source = json.loads((self.folder / "SOURCE.json").read_text(encoding="utf-8"))
        self.assertEqual(hashlib.sha256(self.raw).hexdigest(), source["osm_sha256"])
        self.assertEqual(hashlib.sha256((self.folder/"campus.json").read_bytes()).hexdigest(), source["derived_sha256"])
        self.assertEqual(hashlib.sha256((self.source/"N39E117.hgt.gz").read_bytes()).hexdigest(), source["hgt_sha256"])
        self.assertIn("Open Database License", (ROOT/"licenses/ODbL-1.0.txt").read_text(encoding="utf-8"))

    def test_rebuild_is_offline_and_reproducible(self):
        old_out, old_source = importer.OUT, importer.SOURCE
        try:
            with tempfile.TemporaryDirectory() as folder:
                folder = Path(folder)
                osm = folder/"source.osm"
                osm.write_bytes(self.raw)
                importer.OUT, importer.SOURCE = folder/"derived", folder/"archive"
                with contextlib.redirect_stdout(io.StringIO()):
                    importer.run(osm, self.source/"N39E117.hgt.gz")
                self.assertEqual((importer.OUT/"campus.json").read_bytes(), (self.folder/"campus.json").read_bytes())
        finally:
            importer.OUT, importer.SOURCE = old_out, old_source


if __name__ == "__main__":
    unittest.main()
