# Authored campus migration

2026-10-14: fixed campus geometry, colliders, navigation, groups and author points were packed into `scenes/areas/campus/static_world.tscn` in an isolated copy of the original checkpoint. This scene is now the editable source, not a disposable preview. `street_district.tscn` inherits it and retains per-sortie runtime configuration.

The original builder scripts are retained verbatim under `legacy_source/` as `.gd.txt`, excluded from Godot via `.gdignore`; they are not called by the game. No runtime regeneration command overwrites author edits.

The retained layout signature is `c4e3ec3400b044b5bde27fd85a2f313990db3a3d97224e58a02b8e23e225ab71`. Deliberate geometry/navigation changes require a reviewed new compatibility baseline, not blind re-export of the legacy scripts.

Tool usage and current evidence: `docs/CONTENT_TOOLS_IMPLEMENTATION.md` and `docs/content_tools_2026-10-14_validation.json`. Locally retained captures/logs are not imported as game assets.
