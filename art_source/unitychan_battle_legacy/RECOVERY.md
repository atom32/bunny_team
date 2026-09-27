# Battle Costume Unity-chan — official source recovery

> Historical source-recovery record. The raw source remains excluded/immutable;
> its derivative is now the production Player (Phase 3D/4B). See `Handoff.md`.

2026-09-25. **Source recovery PASS; character integration NOT VERIFIED.**
User selected Battle Costume for a personal demo. Candidate shopping and Terminal
production are not the current task. No gameplay or runtime asset was changed.

## Provenance

- Author/publisher: Unity Technologies Japan K.K.
- Exact release: https://unity3d.jp/unity-chan_contents/releaseNote.php?id=TPK-Hmnd-Kohaku_A&lang=en
- Download: https://unity3d.jp/unity-chan_contents/download.php?id=TPK-Hmnd-Kohaku_A&v=1.1
- Official version 1.1, dated 2018-02-23, Humanoid Edition; shader update UTS 2.0.4 RC1.
- Response filename `01_kohaku_A.unitypackage`; 12,531,513 bytes.
- Archive SHA-256: `12f1365e5e2eb82e2a0e3ddb5d105c690518a8404a1c33fb0027800436096c2c`.
- Main FBX SHA-256: `146f9846b95ba57a726e74ba3da63dfac8774f34db85e46d09d01e5ac8bb4478`.
  This is exactly the existing legacy model, not a different replacement revision.

## Recovered, without rewriting originals

`official_1_1/` retains original package paths and Unity `.meta` GUIDs:

- Main FBX **and separate head FBX**. The official prefab references both; importing
  the main FBX alone is not equivalent to reconstructing the official prefab.
- 20 original PNGs (16 at 2048x2048, 4 at 1024x1024), all decoded by Blender 5.2.2.
- Six Unity materials and one prefab; 24 skinned mesh/material bindings traced.
- The actual shader, its three package-local includes, and original README.
  Unity engine includes are not portable Godot shader dependencies.
- 34 source files plus their original meta sidecars, 8,904,519 asset bytes.
  No unrelated characters, packs, AI models or new dependencies downloaded.

`recovery_manifest.json` contains hashes, material texture GUID resolution and
prefab mesh/material bindings. `recover_official.py` reproduces extraction from the
exact archive, rejects unexpected hashes and refuses to overwrite changed files.
It was run twice successfully to check idempotency.

## What caused the apparent missing resources

1. Seven FBX texture links point to **six distinct Maya authoring PSDs**. Those
   model PSDs are not shipped in official 1.1. They have NOT been recovered, faked,
   renamed from PNG, or removed from the FBX.
2. The official runtime appearance uses PNGs through the Unity prefab/materials,
   rather than those stale Maya paths. All non-null texture GUIDs corresponding to
   properties declared by the actual assigned shader resolve in the official pack.
3. Six `_MainTex` references and one weapon `_EmissionMap` reference remain dangling
   in serialized materials. Neither property is declared or referenced in the
   assigned shader/include closure: these are historical saved-property remnants,
   not proof that the shipped shader is missing its active color textures.
4. Hair's base map is empty by design in the official material; it uses the authored
   `_BaseColor` and a shading-grade texture. Do not invent a missing hair albedo or
   use the grayscale shading-grade map as base color.
5. UTS shade/grade/specular textures are **not automatically PBR roughness/ORM**.
   `_BaseMap` differs from stale `_MainTex`. Preserve original semantics when making
   a separate Blender/Godot material derivative.

## Inspection / remaining gates

- Blender 5.2.2 LTS read-only main-FBX import: 24 meshes, 39,241 triangles,
  seven imported material slots/materials, 328 character bones + 11 weapon bones,
  zero actions. These are main-source statistics, NOT optimized prefab/runtime totals.
- Texture decoding: 20/20 PASS. Details: `blender_source_probe.json`.
- No rest reset, rebind, bone rename, animation edit or FBX re-export performed.
- Existing multiple-bind-pose warnings remain unresolved. Blender importing without
  a warning does NOT establish Godot deformation/animation acceptance.
- Fresh isolated current-project Godot 4.7.2 import after source recovery:
  **exit 0 / ERROR 0 / WARNING 0**. This demonstrates source quarantine remains intact;
  it does NOT verify a newly integrated Battle Costume character.
- Full 33/33 and graphical route remain **Phase 2B historical results**, not rerun:
  this step modified only excluded art source and documentation.
- No new runtime GLB, adapter, production-camera screenshot or gameplay acceptance.

## License boundary

Current official terms: Unity-chan License 3.0, not CC0.
https://unity3d.jp/unity-chan_contents/guideline.php?lang=en
Existing full current license/logo bundle remains at
`assets/characters/unitychan_battle/license/`. Retain it with redistributed assets;
credit `© Unity Technologies Japan/UCL`. Original archive contains older UCL 2.0
material; the official guideline says current terms govern. Personal demo is the
current target, not unrestricted commercial-release certification. No AI image
generation training or input use. Do not imply official endorsement.

## Next bounded step

Reconstruct the official prefab's mesh/material selection in an isolated Blender
derivative, respecting the separate head and original colors. Then verify skin/rest
behavior and retargeting to existing animations before creating a runtime GLB and
player-only presentation adapter. Preserve weapon/IK/mount contracts. Do not change
Gameplay or reactivate the raw FBX just to bypass this step.
