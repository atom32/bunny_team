# Phase 3B material diagnosis — in progress

Baseline: main ec5f18d, Godot 4.7.2. New isolated WIP snapshot imported with 0 ERROR /
0 WARNING; 68 official asset/meta hashes match. No production edits. Three Phase3A3
presentation scripts/data copied unchanged into the isolated spike. Prior poses and tests
remain untouched. Master/GLB not modified at this checkpoint.

## Current parameters / diagnosis

`material_trials/materials_before.json` records actual imported Godot StandardMaterial3D,
not assumed Blender values. Five materials: roughness .8, metallic 0, specular .5,
emission disabled, no mesh-wide material override; four sRGB base textures. Hair has no
texture. Hair GLB linear base factor (.863157,.658375,.417885) correctly imports as Godot
sRGB (.9373,.8314,.6784). No evidence of an accidental extra gamma conversion. UTS shade/
grade/spec textures are not mapped to roughness or metallic. No invented hair texture.

Existing Hanger has directional light energy 1.25 + cyan-white spot energy 2.6, ambient
.8; scene requests Filmic. No lighting/exposure/camera changes in these experiments.
The baseline diffuse contribution saturates pale skin/hair under this lighting. Setting
specular to zero alone makes no meaningful improvement, so glossy reflection is not the
primary cause. No emission is present to remove. This is a diffuse/material-response vs
existing lighting mismatch, not proof of a missing source albedo.

## Single-variable screening (not final material approval)

All comparisons freeze the same Hanger character/animation, same Rifle/loadout, camera,
lighting and exposure. Three rendered frames settle overrides before each PNG. Full
1280x720 images plus exact fixed image-region crops, not camera zoom. Latest runner uses
separate APPDATA/LOCALAPPDATA profiles; initial exploratory captures without that isolation
were superseded. Existing user profile was not deliberately edited or deployed.

- Face/skin specular .5 -> 0: no useful highlight recovery; reject as sole fix.
- Hair specular .5 -> 0: no useful recovery; reject as sole fix.
- Separate face/skin albedo multipliers .75/.55: remain too pale under key light.
- Face/skin .35: too dark/cool in shadow; reject, do not approve gray face.
- Face/skin .45: candidate only; eye/face detail recovers but cool tint needs verification.
- Hair .75: still pale; .55 recovers strand/color blocking; .35 too dark. .55 candidate.
- Combined .45 face/.55 hair is a preview of individually screened candidates, NOT accepted
  final material. Original hue ratios are retained but lower sRGB factors imply a larger
  linear reflectance change; conversion must be explicit when transferring to Blender.

Evidence: `material_trials/` and `material_probe.log` (exit 0). Changes are temporary
surface overrides in the isolated diagnostic script only. No permanent material choice
has been made. Do not carry these candidate factors straight into production.

Next: verify candidate under existing Field Office illumination before deciding whether
albedo modulation is suitable, or whether a minimal standard diffuse response change is
needed. Face must not become gray. Once P0 is actually accepted, persist in Blender master
without touching bones/weights/poses, export derivative and evaluate equipment/Hanger/
Field Office before regression. Do not reopen weapon pose authoring.


## Cross-scene review and response diagnostics (continuation)

Field Office same-state before/candidate pairs now exist at production 1280x720 camera
and explicitly labeled diagnostic front-oblique camera. Tree is paused only during these
comparison images to preserve identical pose/lighting; normal route then resumes. Both
views preserve their respective before/after cameras. Initial close view showed mostly
back hair; superseded by body-relative front-oblique view, not used to judge facial color.
The .45 skin/.55 hair albedo candidate is **rejected for skin**: Field Office frontal
shadow turns it excessively dark/gray. Hair highlights improve, but this alone is not P0
completion. No Blender/master/export change accepted yet.

Built-in diffuse toon mode alone still clips in Hanger. A small isolated shader response
experiment was therefore justified after standard material parameter tests, not used as
an unexplained generic toon replacement. `soft_diffuse_trial.gdshader` retains source
albedo/texture, normal-dependent lighting, ambient, attenuation/shadows; no emission,
new lights, camera dependence or source texture changes. It bounds per-light diffuse
response using irradiance/(1+peak), with gain .2 and a broad smooth normal ramp. This is
an experimental stylized material response, not a 1:1 UTS port. It is not integrated yet.

Diagnostic controls prove overrides apply: `zero_light_diagnostic` produces black skin/
hair when both ambient and direct are disabled. `ambient_only_diagnostic` retains flat
brown shaded coloration; `soft_no_ambient_diagnostic` isolates direct response. These
controls are intentionally unsuitable final materials and will NOT be integrated.
A .45 bounded direct gain plus ambient still looked too pale; .2 has more headroom and
preserves warmer source color in Hanger. Current `combined_soft` screenshot is .2 gain.
Awaiting corresponding Field Office soft_response review before acceptance.

Godot Compatibility differs in color handling from the linear HDR renderers; do not
silently change renderer or infer linear socket factors from sRGB inspector values:
https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html
https://github.com/godotengine/godot-docs/blob/master/tutorials/shaders/shader_reference/spatial_shader.rst
(access 2026-09-26). This supports explicit renderer verification, not claiming a
specific engine bug from the screenshots. The actual renderer remains OpenGL Compatibility.

All experiments are derivative probe files and isolated runtime overrides. Shader and
albedo experiments are not final approved changes. Official package, production code,
master geometry/rig/poses, GLB, tests and all gameplay contracts remain untouched.


### Latest cross-scene result

The latest normal route completed exit 0 with all checks true, including Terminal objective,
real Q switching/reload, extraction and Result. Comparison-only pause was released before
continuing. `office_diagnostic_before.png` vs `office_diagnostic_soft_response.png` are the
same frozen pose/camera in that run: the white hair hotspot is recovered while original
face/skin shadow color stays much closer to baseline than with .45 albedo darkening.
Hanger `combined_soft` likewise retains source hues with more diffuse headroom. The .2
bounded diffuse response is selected for the next **integration candidate**, not final
Phase3B acceptance. Preserve ambient; do not integrate the black/ambient-only diagnostic
controls. No new lights, changed exposure, fake albedo or shade-to-ORM conversion.

Next safe work: encode response parameters/material identification in the editable Blender
master and derivative presentation adapter, retaining source color/texture and all rig/pose
fingerprints. Then equipment visibility (currently a front-obscuring pack), Hanger/Office
full-body verification, performance counters, unchanged regression and final report. The
current master and GLB hashes still equal Phase3A3 baseline. No active process remains.


## Integration checkpoint

`author_material_profile.py` stores response settings as named editable custom properties
on the three Blender materials, and exports `material_profile.json`. Principled base colors
and textures remain untouched fallback preview; it does not claim Blender/Godot shader
parity. `anime_surface.gdshader` consumes these settings through derivative adapter.
GLB remains the identical geometry/material source; no unnecessary rig re-export.
Save/reload fingerprint verifies mesh positions/topology/weights, bone rest/pose matrices
and animation channels unchanged (5b634b02c3fe19b70323717e204bd7d46a65b6f8b593c6de308d11cb1364bf38).
Master hash changes only for presentation metadata. Original Phase3A3 master hash remains
in phase3a3/master_export.json; it should not equal this intentionally updated master.

Equipment root cause: torso-bone local X/Z point opposite the old character equipment
frame. Backpack body-local z was -0.1345 (front), Chest +0.1601 (back). The authored
`GodotEquipmentFrameCorrection` master property maps Chest/Backpack to local Y 180 degrees;
`mount_profile.json` drives a one-time socket transform correction, rotating offset and
visual basis together. No rename/rebind, geometry rebuild, collision or weapon/IK socket
change. `equipment_before/` and `equipment_after/` show same front/back/side framing.
Backpack now sits behind torso; chest/arms/weapon silhouette is visible. Minor hair/pack
contact remains, not a reason to redo geometry. Hanger production camera unchanged.

Regression completed: 32/33, only legacy Face assertion; main exit 0. Rifle route passes.
Initial SMG route timed out returning at (-6.94,30.08), health >220; all prior Terminal/
switch/reload checks passed. Another graphical probe ran concurrently and may have cleared
held input on focus loss. Preserve `route_SMG_initial_timeout`; solo fresh-profile replay
is required before accepting SMG, rather than changing gameplay collision or route rules.

Performance counters collected but TIME_PROCESS repeats a startup value across the short
sampling interval; do not publish that as steady-state frame time. Warm up >2 seconds and
sample wall-frame intervals alone after graphics jobs finish. Geometry remains 37359 tris,
328 bones, 5 materials and 4 base textures; RGBA8+mip estimate is 72,701,268 bytes (~69.3 MiB).
No quality reduction, new texture, scene light or exposure change.

Solo SMG replay completed exit 0, all checks true, without changing route or gameplay code.
Initial failure remains recorded; concurrent graphical focus interference is consistent
with the evidence, not conclusively proven. All launched jobs are now terminal.

Final result: Demo Presentation Candidate PASS. Final matched captures and warm performance
reviewed; all processes finished. Current README top section and completion_audit supersede
intermediate pending statuses. No production promotion or commit/push in Phase3B.
