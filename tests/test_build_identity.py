"""Pure source fingerprint tests; no engine, profiles, Git writes or networking."""
import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / "tools/build_local_windows.py"
spec = importlib.util.spec_from_file_location("local_builder", path)
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class BuildIdentityTest(unittest.TestCase):
    def test_order_independent(self):
        first = {"scripts/a.gd":"a"*64, "project.godot":"b"*64}
        self.assertEqual(builder.build_identity(first), builder.build_identity(dict(reversed(list(first.items())))))

    def test_docs_do_not_change_playable_version(self):
        first = {"scripts/a.gd":"a"*64}
        second = {**first, "docs/report.md":"b"*64}
        self.assertEqual(builder.build_identity(first), builder.build_identity(second))

    def test_wip_changes_and_added_deleted_inputs_change_version(self):
        first = {"scripts/a.gd":"a"*64}
        for other in [{"scripts/a.gd":"b"*64}, {**first,"assets/b.png":"b"*64}, {}]:
            self.assertNotEqual(builder.build_identity(first), builder.build_identity(other))

    def test_digest_is_not_head_or_user_identity(self):
        stamp = builder.build_identity({"scripts/a.gd":"a"*64})
        self.assertEqual(set(stamp), {"format","id","source_sha256","packaged"})
        self.assertEqual(len(stamp["source_sha256"]),64)
        self.assertEqual(stamp["id"],"nb-"+stamp["source_sha256"][:16])
        self.assertTrue(stamp["packaged"])


if __name__ == "__main__":
    unittest.main()
