"""Translation source/build regression; all rebuilds run in temporary projects."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class LocalizationBuildTest(unittest.TestCase):
    def test_source_matches_shipped_resource(self):
        source = json.loads((ROOT / "localization/zh_CN.json").read_text(encoding="utf-8"))
        resource = (ROOT / "localization/zh_CN.tres").read_text(encoding="utf-8")
        rows = re.findall(r'^&("(?:[^"\\]|\\.)*"): &("(?:[^"\\]|\\.)*")', resource, re.M)
        built = {json.loads(key): json.loads(value) for key, value in rows}
        self.assertEqual(len(rows), len(built), "duplicate resource translation keys")
        self.assertEqual(source, built, "rebuilding must not drop or revert runtime translations")

    def test_rebuild_is_reproducible(self):
        with tempfile.TemporaryDirectory(prefix="bunny_translation_") as directory:
            project = Path(directory)
            self._copy_project(project)
            expected = (project / "localization/zh_CN.tres").read_bytes()
            for _ in range(2):
                result = self._build(project)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual((project / "localization/zh_CN.tres").read_bytes(), expected)

    def test_bad_placeholder_does_not_overwrite_resource(self):
        with tempfile.TemporaryDirectory(prefix="bunny_translation_") as directory:
            project = Path(directory)
            self._copy_project(project)
            source = project / "localization/zh_CN.json"
            messages = json.loads(source.read_text(encoding="utf-8"))
            messages["Regression %d"] = "错误占位 %s"
            source.write_text(json.dumps(messages, ensure_ascii=False), encoding="utf-8")
            expected = (project / "localization/zh_CN.tres").read_bytes()
            result = self._build(project)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Interpolation placeholders differ", result.stderr)
            self.assertEqual((project / "localization/zh_CN.tres").read_bytes(), expected)

    def _copy_project(self, project):
        for name in ["tools/build_localization.py", "localization/zh_CN.json", "localization/zh_CN.tres"]:
            target = project / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)

    def _build(self, project):
        return subprocess.run([sys.executable, "-X", "utf8", str(project / "tools/build_localization.py")],
                              capture_output=True, text=True, encoding="utf-8", timeout=30)


if __name__ == "__main__":
    unittest.main()
