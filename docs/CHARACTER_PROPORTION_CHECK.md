# Unity-Chan proportion check — 2026-09-27

**No evidence of shortened legs or altered body proportions.** This was analysis,
not a character-edit task. The short-leg impression is plausible, not dismissed:
the coat/skirt hides the upper thigh, equipment enlarges the upper-body silhouette,
and camera elevation plus the rotated/overlapping stance changes screen-space length.
These are visual interpretations, not proof of one exclusive cause.

## Source → production

Blender 5.2.2 read-only import of the official main + separate-head FBX, compared to
`assets/characters/unitychan_battle/battle_presentation.glb`. Object-space vertices
were transformed to common rest/world space, accounting for the documented 180°
heading conversion. Per-mesh nearest-position comparison avoids mistaking glTF's
split UV/normal vertices for new shape. All **24 character meshes** matched to a
maximum position delta **5.962443197e-07 m** (~0.0006 mm). Blender's imported bone-widget
Icosphere is not a GLB character mesh and is excluded. This is a positional comparison,
not a claim that vertex/index serialization is byte-identical across formats.

| Rest segment | Official FBX (m) | Production GLB (m) |
|---|---:|---:|
| LeftUpLeg -> LeftLeg | 0.344999914 | 0.344999769 |
| LeftLeg -> LeftFoot | 0.360000075 | 0.360000027 |
| RightUpLeg -> RightLeg | 0.344999907 | 0.344999702 |
| RightLeg -> RightFoot | 0.360000052 | 0.360000147 |
| Hips -> Head | 0.479767236 | 0.479767116 |

Both thighs remain ~34.5 cm, both shins ~36 cm. Production GLB SHA-256:
`32e030e3aa4dea44f699bd7ce260a87c6ea9d5f4c0ea4c5eaedd6e823a335e0f`.
Original source hashes are recorded in `art_source/unitychan_battle_legacy/recovery_manifest.json`.

## Actual Hanger instance (Godot 4.7.2)

All Player/Body/source/retarget/display-skeleton ancestor local and global scales
were `(1,1,1)`. Retarget does not copy position or scale. Posed bone segment lengths
remain the same; measured hip-to-ankle vertical projections:

| Leg | Rest (m) | Hanger idle (m) | Knee angle, idle |
|---|---:|---:|---:|
| Left | 0.703050 | 0.701684 | 174.920° |
| Right | 0.703050 | 0.693950 | 176.647° |

Idle flexion accounts for only ~1.4 mm / 9.1 mm of vertical loss in this sampled pose;
it is not significant bone shortening. The Hanger perspective camera (39° FOV)
looks downward by roughly 14°. The top-down combat view foreshortens further.
Production-camera and orthographic idle/rest images were inspected; captures and
temporary read-only probes remain local, not part of the push.

Existing dodge presentation briefly applies whole-body `(0.9,1.06,0.9)` then restores
scale. This pre-existing effect is not a shortened-leg idle transform; it was not edited.
No new pose, camera or lighting changes were made for production.

## Master portability, not character editing

The previously uncommitted Blender master has the same geometry/rig/actions fingerprint
as the HEAD master. Its recorded Phase 3B custom material/equipment properties are
retained. This sync additionally corrects four broken image filepaths to sibling-relative
official PNGs. Reopen/save comparison preserves geometry/rig/actions fingerprint:
`5b634b02c3fe19b70323717e204bd7d46a65b6f8b593c6de308d11cb1364bf38`.
Exact before/after path and file hashes: `art_source/unitychan_battle_derivative/master_portability.json`.

Character geometry modified: **NO**. Character textures/material semantics modified:
**NO**. Runtime GLB modified: **NO**. Official source modified: **NO**.
Procedural character generation/remodeling: **NONE**.
