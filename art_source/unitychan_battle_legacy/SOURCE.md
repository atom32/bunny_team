# Unity-Chan Battle Costume — legacy/reference, NOT runtime

> Historical source-recovery record. The raw source remains excluded/immutable;
> its derivative is now the production Player (Phase 3D/4B). See `Handoff.md`.

**Update 2026-09-25:** User selected Battle Costume for a personal demo. Official
1.1 PNG/material/prefab sources are now recovered alongside this archive; see
`RECOVERY.md` and `recovery_manifest.json`. The original FBX remains untouched and
excluded. Raw Maya PSD links and bind-pose acceptance are still unresolved; this
is not a completed runtime replacement. The following records the Phase 2B move.

Phase 2B, 2026-09-25. Moved intact from
`assets/characters/unitychan_battle/unitychan_battle.fbx` with its original
`.import` sidecar. `.gdignore` excludes this source directory from Godot import.
The sidecar intentionally records the old path; it is historical evidence, not
an active import configuration. Do not reactivate without a new dependency audit.

- Publisher: Unity Technologies Japan K.K.
- Original page: https://unity3d.jp/unity-chan_contents/releaseNote.php?id=TPK-Hmnd-Kohaku_A&lang=en
- License: Unity-chan License 3.0; full license files remain at
  `assets/characters/unitychan_battle/license/` in this same repository.
- Attribution: © Unity Technologies Japan/UCL
- No AI image-generation training/input use.
- Proven unused by tracked source path/filename searches and Godot resource
  dependency inspection. Live idle/walk/run/slide FBXs stay at their old paths.
- Six missing Maya PSD references and two multiple-bind-pose warnings are
  preserved in this original file; they are not repaired or hidden by reauthoring.
- Known source warnings: `J_1_R_mantleSide_R`, `J_1_R_midFrillSide_R`.

The original file bytes, rig, animation and material references are unchanged.
See `docs/art_pipeline_validation.log` for relocation hash and audit evidence.
