# Development checkout / 环境同步

2026-09-27. Runtime checkpoint `bc4984b` (Phase 5); this follow-up only synchronizes
required configuration/source/dependency records. Use **Godot 4.7.2**, GL Compatibility.

## Another machine

1. Clone or pull `main`. Before pulling an existing checkout, inspect `git status`;
   preserve its own WIP. Do not copy `.godot` cache or another machine's personal save.
2. From the repository root run (replace `<godot>` with that machine's executable):
   ```text
   <godot> --headless --path . --editor --import
   <godot> --path .
   ```
   Normal entry is `scenes/presentation/slice/boot.tscn`, not the legacy Hanger entry.
3. First launch uses opening/menu; START / CONTINUE enters Hideout. Existing gameplay
   save format is unchanged. Presentation settings use separate `user://presentation.cfg`.
4. Do not remove `assets/140301_unitychanmodel_Celsis/`: the five original TGA files
   and `.import` files fulfill the existing animation FBXs' relative dependencies.
5. The old standalone `unitychan_battle.fbx` plus original sidecar moved byte-for-byte
   to `art_source/unitychan_battle_legacy/`, excluded by `.gdignore`. Do not put it
   back in runtime import scope. This is quarantine, not destruction of original art.
6. Blender **5.2.2 LTS** is only needed for authoring, not running the game. The master
   is `art_source/unitychan_battle_derivative/battle_master.blend`; its four image
   paths resolve relative to the sibling `unitychan_battle_legacy/official_1_1/` tree.
   Do not re-export or regenerate the locked character as a setup step.

## Included / intentionally local

Included: Godot feature level/import configuration, exact required texture sources,
quarantined official source, license/provenance, authoring master, concise historical
migration/readiness records, and reusable dependency/recovery verification tools.
No new gameplay, material shader or model replacement in this sync.
`.gitattributes` prevents line-ending conversion of the 68 immutable official files;
all 68 hashes also match after export from Git, not only in this working directory.

Excluded and preserved locally: unrelated screenshots/recordings, test profile copies,
Blender backup files, trial capture/material scripts, commit receipts, cache and
CRLF-only importer churn. Existing media already in earlier commits is not purged;
there is no history rewrite. Some old report links therefore refer to local-only evidence.

## Verification of portable content

**Result: PASS — fresh import 0 ERROR / 0 WARNING; 33/33; Main exit 0, no warnings in this run.**

See `docs/development_sync_validation.json` for this sync's staged-only snapshot
verification. It exports **the Git index**, not the full working directory, to a new
folder with no `.godot` cache; profiles are isolated. Then cold import, all 33 existing
test scenes and the normal main entry run. Tests/runners/assertions are unchanged.

To repeat manually in a fresh clone:
```text
<godot> --headless --path . --editor --import
<godot> --headless --path . res://tests/acceptance_smoke.tscn --quit-after 1200
<godot> --headless --path . --quit-after 180
```
Run each of the 33 `tests/*.tscn` for the full regression, not only acceptance_smoke.
`tools/verify_migration.py` is retained historical tooling: it includes local WIP in
its snapshot, so it does **not** prove a clean checkout; its optional Phase 2B route
is historical. Current full graphical evidence/tools are under `art_source/phase5/`;
their local executable/workspace paths must be configured on the destination machine.
