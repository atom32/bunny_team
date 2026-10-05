
## Phase 4B — Unity-Chan Visual Fidelity Recovery

2026-09-26. **PASS — source-faithful geometry retained; active material semantics recovered.**
This is a bounded visual recovery, not a redesign or a claim of pixel-identical Unity UTS rendering.
Start: main @ 10e9d822b2f9c67c7d61bc5885dee9002b746f0b (Phase 4A), containing Phase 3D 955ce1f.
Existing migration/import/authoring WIP was snapshotted and preserved, not reset or committed.

### Source verification / objective geometry comparison

- Official package source/meta: **68/68 hashes match** recovery_manifest.json.
- Production and derivative GLB still equal the original build_report.json conversion SHA-256:
  `32e030e3aa4dea44f699bd7ce260a87c6ea9d5f4c0ea4c5eaedd6e823a335e0f`.
- Blender master byte hash unchanged from this phase's starting WIP. No save/re-export was made.
- Read-only Blender 5.2.2 imports compare official main FBX + separate head FBX against runtime GLB.
  Comparison accounts for the already documented 180-degree heading normalization and cm→m/object
  transform baking. Index IDs and bone palette IDs are not semantic identities: compare triangle
  corners and named influences, not raw ordinal arrays.

| Mesh | Official vertices → GLB | Triangle index count, both | Maximum position delta (m) | UV delta | Maximum normal angle |
|---|---:|---:|---:|---:|---:|
| head_Def | 2014 → 2370 | 10422 | 1.22e-7 | 0 | 0.652° |
| headNose | 26 → 64 | 144 | 2.39e-7 | 0 | 0.020° |
| eyeBall | 202 → 322 | 1080 | 3.62e-7 | 7.46e-9 | 0.028° |
| eyeHighLightShape | 120 → 120 | 648 | 3.62e-7 | 7.46e-9 | 0.020° |

**Face geometry: IDENTICAL in shape/topology within conversion floating-point tolerance; not
byte-identical vertex buffers.** Export splits UV/normal seams, accounting for increased vertex
counts. Oriented position/UV triangle multisets match after 2e-6 m corner matching; zero unmatched
corners. A naive rounded-coordinate hash differs at rounding boundaries; that diagnostic is retained,
not concealed. All 18 head morphs plus Basis match within 1.22e-7 m. No facial feature moved.
Head/nose/eye weight deltas by semantic bone name are zero. Full named palettes and accessor/index
counts are in geometry_comparison.json and material_verification.json.

Four hair meshes also match topology/UV/positions (largest delta 5.97e-7 m). Existing import-normal
differences reach 0.890°; hairFront's existing named-weight conversion delta reaches 0.000614.
These are pre-existing conversion differences, not Phase 4B edits or proof of literal buffer identity.

Tangents: production GLB contains no TANGENT accessor. Godot's existing import generates tangents.
The read-only Blender MikkTSpace diagnostic can differ up to 180°/sign at degenerate or ambiguous
position/UV corner matches; it is NOT an authored tangent equality certificate. No active original
character material enables a normal map or tangent-based high-color highlight. These derived-tangent
diagnostics are therefore not a reason to reshape/re-export the face. No normal/tangent correction
was necessary or performed. Re-audit tangents if normal mapping is ever enabled.

### Head, nose and eye assembly

Original prefab mapping was re-read, including material/texture GUIDs and FBX file IDs. The selected
head is head_Def from the separate head FBX; nose is the original headNose. Both use face3_main,
as do eyeBall and eyeHighLightShape. There is no missing separate eye-albedo asset to invent.
The prefab's head/nose rest-world assembly is identity within ~1.8e-7 m. The established derivative
encodes their rigid Character1_Head attachment with equivalent one-bone weight 1.0. Eye meshes retain
their original named skin influences. Original geometry relationship, scale, UVs, winding and morph
positions pass comparison. No new parent/scale/rotation/binding correction was indicated or applied.

### Root cause / material reconstruction

The old production shader used only base color, a generic softened diffuse response and double-sided
culling for face/hair/skin; body/accessories remained generic PBR. It omitted the original shade-color
and shading-grade maps. This produced smooth sculpt-like facial/hair shadows, pale flat irises and
different highlights, despite the original geometry being intact. Lighting-only neutral comparisons
did not restore the missing authored bands. The production light response also differed from UTS.

All five character materials now use the same small source-specific UTS subset. `inspect_materials.py`
verifies **60 source/profile checks** for original PNG hashes, colors, thresholds and active semantics.
No texture was painted, generated, resized, recompressed or replaced.

| Runtime material / surface | Base source | Shade source | Grade source | Parameters |
|---|---|---|---|---|
| face3_main / head, nose, eyes | face3_main.png | face3_main_sub.png + face3_main_Shd2.png | face3_main_spow.png | steps .5/.51; white multipliers |
| Hair_Spow / all hair | **no base texture**, original constant (.93725497,.8313726,.6784314) | original first shade (.53333336,.4901961,.48235297) | Hair_Spow.png | first step .5 |
| Skin | skin.png | Skin_Shd.png | skin_spow.png | first step .5 |
| Body / clothes, horns | Body.png | Body_Shd.png | Body_spow.png | first step .65 |
| Add / accessories | Add.png | Add_Shd.png | Add_Spow.png | first step .65 |

Filenames above omit common `kohaku_A_` prefix. All sample UV0, original scale 1 / offset 0.
Original PNG import metadata marks these maps sRGB, including grade; grade R selects a shading band,
**not** albedo/roughness/metallic/ORM/normal data. Original active five materials are opaque, back-culled,
depth-writing, normal-map disabled, HighColor power 0, rim/MatCap/GI 0, active emissive map default black.
Serialized stale _MainTex/_EmissionMap references do not occur in the active shader closure.
No invented metallic/specular/emission maps. Original sixth Unity2016_Wep belongs to the excluded
bundled melee weapon; existing AR/SMG/Rocket and equipped gameplay gear materials were not changed.

Shader implements half-Lambert × grade × original system-shadow factor; original two shade masks,
colors and thresholds; opaque back culling. No vertex function, mesh displacement, procedural facial
detail, PBR highlights or new eye geometry. The eyes now use their original shared face shade maps,
recovering the authored iris color separation. Hair uses original constant colors, not a fake albedo.

### Color management / lighting isolation / explicit limitations

The neutral scene uses a fixed white directional light (energy 1), gray background, fixed cameras,
linear tone mapper and identical pose. It captures old production, source-equation subset, and final
game-adapted material separately. `source_semantics` means **our rendering of the recovered equations**,
NOT an independent official Unity screenshot. Exact authoring scene lighting/project color-space is
not shipped. Three genuine 128px package previews were extracted from the already verified local
archive, with hashes recorded; their resolution is insufficient for pixel-parity face certification.
No Unity installation or unrelated download was performed.

The new shader initially exposed an sRGB/light-space mismatch: a .5 custom DIFFUSE_LIGHT swatch became
.7373, whereas .5 ALBEDO/StandardMaterial swatches became .502. The final shader explicitly converts
painted sRGB colors into linear light output on Compatibility; original texture bytes remain intact.
Do not confuse this rejected trial with proof that the old shader had that same specific gamma bug.

Another rejected trial looked correct with one neutral light but clipped face/hair white in Hanger.
Isolation showed the separate shadowed directional/local-light passes adding after tone mapping;
max(DIFFUSE_LIGHT, ...) inside one pass cannot cap their final sum. The final game adaptation uses
the existing directional key for these five character paints and normalizes excessive key energy.
It deliberately does **not** reproduce UTS ForwardAdd/local accent response. Local scene/equipment
lighting, WorldEnvironment, exposure, cameras and all Phase 4A decoration/VFX remain unchanged.
Hanger and Field Office both already have the required directional key. A future local-light-only
scene needs a separate presentation review; this is not a universal toon shader framework.

Full UTS outline extrusion, engine GI/fog parity and Forward+/Mobile fidelity are not claimed. No
outline geometry was generated. This phase verifies the source-faithful active painted/shade subset
and visible improvement, not identical output from two different renderers.

### Visual / runtime acceptance

- Neutral frontal / 3/4 / side: inspected; original facial silhouette, nose and hairline retained;
  authored cel bands, iris shading and hair colors restored; no floating/recessed eye assembly or
  glossy PBR face highlight introduced. Hanger before/after no longer clips hair/skin to pure white.
- Normal Hanger and Field Office cameras remain 1280×720. Additional close-ups are explicitly
  diagnostic. Cameras sample the final head skin at Skeleton3D.skeleton_updated (after modifiers),
  not the temporarily restored pre-modifier pose. No head yaw/pitch is altered to fake the view.
  Neutral frontal/3-4/side captures remain the fixed reference. Production top-down face is only a few pixels, not a
  substitute for that inspection. Same-pose A/B records store camera/player/body matrices.
- Existing AnimationTree: **24 weapon/state combinations PASS** (AR/SMG/Rocket × Idle, Walk, Run,
  Run+Shoot, Recoil, Reload, Hit, Dodge), finite skeletons and complete visual integrity. Prior accepted
  pose/finger rough edges remain; no pose, retarget, IK or animation-state edits.
- Two real-OpenGL normal production routes: **32/32 checks each PASS**, Hanger → Office door/interior
  → Terminal interaction → fire/switch/reload/dodge → original route → extraction → Result → Hanger.
  Normal enemy AI, collision, damage and cameras; no teleport/invulnerability. These are automated
  input/API runs, not manual keyboard acceptance. They verify extraction, not all mission objectives.
- Real existing save copied for isolation; production return/commit/save followed by another-process
  reload: **5/5 checks each PASS**. Full state/owned equipment IDs/loadout preserved, independent
  warehouse merge checks pass. Original user's save hash unchanged; no save schema edits.
- **33/33 existing tests PASS**, including ACCEPTANCE_SMOKE, PRESENTATION_GAMEPLAY_TEST,
  VISUAL_SLICE_ASSETS_TEST and WORLD_TRAVERSAL_TEST. MAIN exit 0. No ERROR / SCRIPT ERROR in final
  runs. Known non-blocking 2-ObjectDB exit warnings remain in some runs; not claimed warning-free.

Evidence: [comparison gallery](phase4b/comparison.html), [final audit](phase4b/final_validation.json),
geometry_comparison.json, material_verification.json, color_probe.json, controlled/, hanger/,
route_Rifle/, route_SMG/, animation/, regression/. Rejected lighting/gamma trials are labeled and
retained. All screenshots are engine renders, not edited/generated character imagery.

### Changes / integrity / Git

Runtime changes only:
1. assets/characters/unitychan_battle/presentation/anime_surface.gdshader — source-specific painted/shade subset.
2. assets/characters/unitychan_battle/presentation/material_profile.json — five original material bindings.
3. scripts/presentation/unitychan/presentation_adapter.gd — deserialize texture/Color parameters only.

Documentation: this section. Analysis/evidence: phase4b/. No Player/gameplay/test/weapon/animation/
collision/route/save/environment/enemy/Terminal changes. No Phase 4A reversal. All tracked starting
file hashes outside these three runtime files and this README remain unchanged, including existing WIP.
Runtime and source textures/meshes remain byte-identical. No fake legacy nodes or weakened tests.

Character geometry modified: **NO**
Character face generated: **NO**
Character textures generated: **NO**
Official source modified: **NO**
Procedural character generation: **NONE**
Character mesh remodeling: **NONE**

Technical visual recovery: PASS. Public release authorization: NOT ASSESSED. Enemy AvatarSample_A
licensing: still BLOCKED. Retain © Unity Technologies Japan/UCL provenance/license/credits; no AI input.
Dedicated Phase 4B commit only; no push. Commit hash is recorded in phase4b/commit_receipt.json and
the final reply after commit (avoids a self-referential hash). Original WIP and real save copies are
excluded from staging. The pre-existing workspace is still not an entirely committed clean-clone baseline.

Reproduction (existing tools, no dependency installation): set BUNNY_PHASE4B to this phase4b folder;
run Blender --background --factory-startup --python compare_geometry.py; python inspect_materials.py;
run Godot --path D:/bunny_team --rendering-method gl_compatibility --resolution 1280x720 --script
material_probe.gd / hanger_probe.gd with isolated APPDATA; then run run_production_routes.py,
run_animation.py and run_regression.py **serially**. workspace.json supplies project/temp-output paths;
route validation needs a safe byte-copy of the existing real save in persistence/original_profile.json.
Finally run verify_final.py. Read-only audits never save Blender/FBX/GLB/PNG art assets.
