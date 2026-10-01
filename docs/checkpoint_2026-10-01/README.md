# 2026-10-01 checkpoint verification

The Git-visible project was copied outside the checkout without `.godot`, with a
unique application name to isolate `user://`. Original MCO animation FBXs are
preserved under an ignored source directory; portraits use the same tracks baked
as Animation-only resources to avoid absent demo pistol textures.

- Cold import: exit 0, **0 errors**, 2 known `ufbx Bad UTF-8 string` warnings from
  original FBX metadata. Original model bytes are preserved. These exact warnings
  are recognized by the verifier; missing resources and other warnings still fail.
- **43/43 test scenes pass**, with zero script/runtime errors in the final runs.
- **5/5 actual quit subprocess paths pass**: base, battle, failure, transition,
  save recovery.
- Main entry exits 0 with no errors; one known ObjectDB exit warning remains.
- Actual graphical warehouse probe passes mouse drag, R rotation, gear swaps,
  armor equip, bilingual refresh, isolated save/reload and multiple aspect ratios.

During verification, older smoke assertions were updated for armor mitigation and
compact completed-objective display; traversal measures horizontal distance rather
than world X after the camera change. The warehouse summary node name remains
available to existing callers. New test teardown uses the established audio cleanup
helper, and all scene suites emit an explicit PASS/FAIL marker. Streets tests have a
larger frame budget. Final checks resumed in the same imported isolated copy after
these corrections; `results.json` records each actual invocation and log hash.

These are automated checks, not a measured first-time player session, a final
visual-standard approval or a target-platform performance certification.
