# Phase 4A — Art asset coverage

Status: PASS — first small batch implemented and validated. Baseline main @955ce1f.
The matrix below preserves the pre-edit inventory; final outcomes are at the end.
Personal/internal demo only. No commercial/public-release investigation in this phase.
Authoritative current player is Phase3D production Unity-chan; older ART_ASSET_INVENTORY
headers predate that migration and are not used to undo it. Existing WIP preserved.

## Visual/technical observations before edits

Reviewed actual1280x720 Phase3D production captures: Hanger01, FieldOffice02 entrance,
SMG04b Terminal. Sources are byte-unchanged since those captures at the current baseline.
Hanger is dominated by a bare wall/platform; FieldOffice has a usable modular shell and
already considerable furniture, but exterior curb/back-of-house has no shared service
vocabulary. Cyan player vs red/pink enemy silhouettes are now distinguishable after3D.
At production top-down distance small cosmetic gun accessories would be almost invisible.
Explosion/trail geometry is opaque-looking luminous spheres; bright pads and flashes can
compete with small actors. Do not call missing FX absent: most events already have effects.

## Coverage matrix

|Category|Current|Gap|Priority|Actual candidate|Action|
|---|---|---|---|---|---|
|Player|Unity-chan37359tris, 5materials,4textures,328bones|Accepted minor hands/clothing limits|Keep|Current production derivative|UNCHANGED|
|Enemy baseline|AvatarSample_A, red tint/chestplate/visor, shared humanoid animations|Less tactical silhouette than player|P1 next|Local Quaternius SciFi.gltf; existing enemy rig|Investigate visually later; not an automatic swap|
|Enemy variants|Basic/heavy definitions share visible base|Heavy distinction mostly size/readout|P2|Existing accent mesh/definition presentation|No new enemy gameplay or rig work in first batch|
|NPC|None|No current gameplay need|P3|None selected|Do not add|
|AR/SMG/Rocket|Kenney blaster-e/g/o, validated grips/axes|Accessories add little at current camera|Keep/P2|Existing weapon models|UNCHANGED; racks later|
|Magazines/ammo props|No dedicated loose magazine presentation|Maintenance dressing optional|P2|Existing container-flat as supply case, not gameplay ammo|Decorative only if used|
|Hanger|Readable character/UI, large empty platform/backwall|No maintenance/storage context|P1|In-project container-flat/tall, pipe, computer-system|Small service prop cluster outside platform|
|Office walls/floor/ceiling/doors/windows|Kenney modules + authored roof/canopy/collision cutaway|Enough structural coverage|Keep|Existing modules|No shell/door rebuild|
|Arena wall/floor/columns/platforms|Procedural large blockout buildings/roads/covers|Sparse repeatable industrial detail|P1/P2|Same service modules at Office exterior|Do not rebuild city/arena|
|Cover/barriers|Existing dressed visual skins, gameplay collision|Functional; avoid visual fake cover|Keep|Existing panel skin|UNCHANGED|
|Storage/containers|Already inside Office; absent around Hanger|Cross-scene reusable vocabulary|P1|Kenney container-flat/tall already in repo|Authored reusable supply stack|
|Machinery/screens|Existing computer-system/screen props|No maintenance identity|P1|Kenney computer-system/wall-switch|Reusable service cabinet, NOT Terminal replacement|
|Pipes/cables/vents|Office pipes; no coherent utility grouping|Larger functional silhouettes|P1/P2|Kenney pipe/pipe-bend|Reusable pipe/service rack; cables/vents later|
|Signs/lights/structure|Office07 labels/strips, Hanger structural beams|Thin identifiers unreadable at distance|P2|Existing Label3D/materials|Large cluster IDs only; no extra neon or lights|
|Loot/pickups|Sphere/crate-like VisualFactory geometry plus label|Object identity weak|P2|Existing supply case candidate|Do not change pickup logic in first batch|
|Extraction|Bright cyan disc/radial markers/label|High luminance dominates adjacent actors|P2|Current cylinder/torus visuals|Defer; extraction untouched|
|Terminal/interactables|Existing block/monitor and interaction UI|Terminal primitive but functional|Excluded|Current Terminal|UNCHANGED by explicit DoD|
|Muzzle/tracer/projectile|Spheres/boxes, bolt, cylinder rocket, dynamic lights|Hard bright blobs, no soft exhaust|P1|Existing effects entrypoints; small authored soft-puff material|Add restrained smoke support, preserve timing|
|Hit/impact/sparks|Flash sphere and4 streak fragments|Readable, geometric|P2|Existing hit effects|Keep in first batch|
|Explosion/smoke/rocket trail|Sphere flash/ring/one smoke sphere/orange trail spheres|No soft low-frequency smoke vocabulary|P1|Small reusable billboard smoke scene/material|Replace only visual smoke/trail geometry, no radius/timing logic changes|
|Damage/dodge feedback|HUD flash, character response, cyan pulse|Covered|Keep|Existing implementation|UNCHANGED|
|UI icons/portrait|Text loadouts/warehouse, no icon set/portrait|Polish rather than current readability blocker|P2|Existing UI; no candidate selected|Later|
|Result presentation|Same production character preview + outcome text|Sparse staging|P2|Existing player/scene|UNCHANGED|

## Gap prioritization (not model complexity)

Scores1–5: impact/reuse/visibility; cost1 low–5 high.
1. Shared industrial props:4/5/4/cost2. Three reusable silhouettes can connect Hanger/Office.
2. Soft rocket/explosion smoke:4/5/5/cost2. Frequent combat feedback; no particle framework.
3. Enemy silhouette replacement:4/3/4/cost5. Current enemy already distinct after player
   migration; local SciFi rig mismatch is established. Not required to force a risky second
   character migration into the first batch. Record candidate, retain behavior/model now.
4. Outdoor architecture:5/5/4/cost5. Defer rebuild; decorate bounded service area only.
5. UI/icons/weapon accessories:2/3/3/cost3. Later.

## First batch selected (pre-implementation record)

- Supply stack: existing Kenney flat/tall cases, restrained painted metal/ID accents.
- Service cabinet: existing computer-system/wall-switch, machinery prop with no interaction.
- Pipe/service rack: existing pipe/bend with small support details, no collision.
- One reusable soft-smoke material/helper used by current explosion/trail presentation.
- Reuse props in Hanger background and Office exterior margins; no door/route/Terminal edits.

These are real in-project sources, not invented asset pack names. Candidate source:
assets/environment/kenney_space_station_kit/SOURCE.md and selected GLBs. No new downloads,
no license investigation, no AI workflow. Existing mature assets first. Blender inspection
will record dimensions/axes/origin/materials/normals; no character skeleton re-export.
No automatic universal palette conversion; each material remains controlled/non-glossy.

## Budget and validation plan

Source mesh metrics/hashes: art_source/visual_coverage_4a/existing_prop_metrics.json.
Limit first batch to3 prop scenes and a few instances per location; no collision/navigation
nodes in decorative assets. Reuse material/mesh resources, keep texture budget tiny. Record
final triangles/materials/instances/draw implications after authoring, not guesses as facts.

Keep Phase3D Player/weapon/scene and gameplay baseline hashes. After implementation:33tests,
normal production Hanger→Office→Terminal→enemy encounter→switch/reload/Dodge→extraction→
Result→Hanger, real-save-copy restart validation. Before/after production-camera evidence
and FX fixed view; no manual acceptance claim. Dedicated Phase4A commit only, no push.

## Next coverage after first batch

Enemy tactical silhouette spike (separate rig/muzzle parity gate), then exterior modules,
loot visual identity, then icons. Terminal stays untouched this phase. Do not chase full
asset completion; first batch must be visibly useful and reusable before expanding.

## Source processing checkpoint (historical)

Blender5.2.2 LTS inspection completed for all6 selected existing GLBs: normals finite,
no cameras/lights/unwanted object types. Actual dimensions in blender_source_inspection.json
(BlenderZ-up): flat case0.66x1.09x0.60m; tallcase0.60x0.60x0.90m; computer0.90x0.69x0.60m;
pipe height0.50m. Sources20–176tris each, one material/image. Do not inflate triangle count
without useful shape detail. No asset originals modified or character skeletons exported.
Next: fixed small Blender assemblies, then visual-only Godot wrappers and restrained smoke.
No runtime edits yet; acceptance/regression belongs after integration, not this inventory.

## First batch implementation checkpoint (historical)

Three Blender5.2.2 fixed assemblies now exported/used by runtime wrappers:
supply_stack372tris/3materials/1.60x1.35x1.30m; service_cabinet290tris/4materials/
1.05x0.82x1.55m; pipe_rack408tris/4materials/1.60x0.74x2.10m (dimensions floor/height
converted from BlenderZ-up). Root transforms identity and minimumZ0. No physics/interaction
nodes. Same maintenance cluster instantiated in Hanger background and Office front-right
margin; Terminal/route/collision nodes unchanged. Source GLBs remain byte-identical.

Initial raw palette was too bright/yellow in Hanger and a label overlapped the character.
Rejected that visual state: reduced/recessed Hanger cluster, moved/shrank label, applied
approved .26/.30/.32 linear base-color factor to imported colormap materials ONLY. Blender
preview multiply node was not carried as glTF factor; explicit small service-prop material
adapter applies the same value recorded in Blender material metadata. No universal shader,
new light, player/exposure changes, fake ORM or source texture edits. Final Hanger image
hanger_material_tuned.png reviewed: background functional and quieter than player.

SoftSmoke creates one quad with shared128x128 radial opacity texture; no global RNG/physics.
CombatEffects now uses it only for rocket trail and explosion smoke. Existing event timing,
fade/motion durations, blast logic, projectile, muzzle/hit/telegraph remain unchanged.
FX visual review still pending; do not announce the new smoke accepted yet.

Initial integration regression33/33/main0; both graphical routes + restart PASS. These runs
precede final prop tint/layout tuning. First editor scan reported3 new GLB resources before
import cache creation; subsequent import clean. Keep initial log, not a fake cold-importPASS.
Next: final Office/FX comparisons, final33tests/scope/budget audit then dedicated commit.
No commit/push yet. No Player/weapon/enemy/Terminal edits, no AI or licensing investigation.

## Final Phase 4A result — PASS

Production Player, enemy, AR/SMG/Rocket, Terminal, collision/route, save format, gameplay
and original Unity-chan source remain unchanged. First batch is integrated in the normal
production scenes, not a separate demo. No AI, external pack download, license investigation,
renderer upgrade or character re-export. Unrelated WIP remains uncommitted.

|Category|Final outcome|
|---|---|
|Player|UNCHANGED: production Unity-chan anchor|
|Enemy|UNCHANGED: retained red/pink silhouette; local Quaternius SciFi is a deferred candidate, not an integrated replacement|
|Environment|3 reusable Blender-normalized service props, 2 cluster instances across Hanger/Office|
|Weapons|UNCHANGED: definitions, fire origins, gameplay geometry/behavior, reload/pose contracts|
|VFX|Soft billboard trail/explosion smoke replaces only hard spheres; existing flash/sparks/timings unchanged|
|Hanger|PASS: restrained maintenance background, no camera/player/exposure edits|
|Field Office|PASS: front-right decoration; entrance, traversal, Terminal, exit unaffected in final runs|
|Gameplay|PASS: unchanged 33 suites and two complete graphical extraction routes|
|Save/load|PASS: copied real save → Result commit → process restart, plus independent warehouse merge|

### Budget (observed, not a GPU performance claim)

|Prop|Tris|Material slots|Surfaces|Texture|Instances|
|---|---:|---:|---:|---|---:|
|Supply stack|372|3|6|512² palette|2|
|Service cabinet|290|4|10|512² palette|2|
|Pipe rack|408|4|19|512² palette|2|

Each scene normally renders one cluster: 1,070tris / 35 surfaces + one Label3D. Six total
placements across the two scenes: 2,140tris. No joining/instancing optimization claimed.
Per-pass draw-call upper contribution ≈35 plus label per visible cluster, before culling,
batching or shadow passes; not a measured GPU benchmark. GLBs total154,424bytes, each embeds
one identical7,440-byte PNG. Conservative uncompressed texture estimate:3MiB base /4MiB
with mipmaps before deduplication. New smoke uses one shared128² RGBA texture (~64KiB base),
2tris/1 transparent draw per live puff, no shadow or light. Overdraw still costs fill-rate;
do not increase emission count or lifespan casually. No claims of target-hardware FPS/VRAM.

### Blender → Godot production details

Blender5.2.2 LTS masters retained. Metric/unit1; Z-up→glTFY-up; front -Y→+Z; floor origin,
identity roots; only static mesh objects exported. Source inspection: finite normals, UV
and material references, no camera/light/hidden unrelated geometry. Tangent export enabled
where UVs permit; no normal maps on newly authored detail. Six original GLBs unchanged.
No collisions/navigation/interaction nodes in wrappers (prop_contract.json:5/5).

Explicit service-prop tint adapter is required because the preview multiplier was not
exported as glTF baseColorFactor. It affects only these props' colormap materials; existing
scene palette, character, shaders and source PNGs are untouched. Cabinet is scenery, not
Terminal. Do not place no-collision decorations where players should expect cover.

### Visual review and evidence

- Hanger before/after: `art_source/visual_coverage_4a/route_Rifle/01_hanger_*_props.png`.
- Office before/after: `art_source/visual_coverage_4a/route_Rifle/02_entrance_*_props.png`.
- Same1280×720 production cameras/state, new node hidden/shown while simulation is paused.
- Terminal/return evidence: `route_SMG/04b_terminal_interacted.png`, `07_return_hanger.png`.
- Fixed-view FX: `fx/before_rocket_trail.png`, `after_rocket_trail.png`, explosion peak/fade.
- Main actor remains the focal point; muted pipes/cases connect both environments. Office
  dressing stays beside, not inside, the entrance opening. No floating bases observed.
- Initial smoke was too faint: retained billboard scale for the growth tween, strengthened
  radial opacity and trail value. Final trail visibly soft; late explosion smoke is faint
  by design. Flash/ring remain readable; this is modest coverage, not final cinematic FX.

### Final validation

`art_source/visual_coverage_4a/final_validation.json` and its reproduction scripts:
- 33/33 unchanged tests; ACCEPTANCE_SMOKE / PRESENTATION_GAMEPLAY / WORLD_TRAVERSAL /
  VISUAL_SLICE_ASSETS / RESULT_RETURN PASS. Main exit0.
- Rifle+Rocket and SMG+Rocket normal OpenGL routes:32/32 checks each. Hanger→Office door→
  Terminal→switch/fire/reload→exit→Dodge→normal enemy encounter→extraction→Result→Hanger.
- Both restart processes:5/5 checks, exact gameplay serialization; separate Python check
  independently reconstructs warehouse merge, equipment IDs, quantities and loadout.
- Routes include60/105 shots and9/21 incoming damage with normal AI. Both extracted without
  completing all kill/survey goals (0 kills); do not call this full mission completion.
- Original production save hash unchanged; official source68/68 hashes unchanged.
- Only3 pre-existing runtime files changed: Hanger scene, Office scene and CombatEffects.
  Existing tests/Player/enemy/Terminal/weapon/AI/save/collision files byte-unchanged.
- No new route/FX errors or warnings in final runs. Main retains the known2-instance
  ObjectDB exit warning; prop-only probe also emits it. Not warning-free.

One concurrent graphical run timed out at the Office exit. Failed log/JSON/screenshot is
retained in `diagnostic_route_failure/`; cause is NOT established. The identical script
then passed sequentially for both loadouts; no gameplay workaround or assertion relaxation.
Run graphical acceptance alone. Do not describe the timeout as a fixed art defect.
Initial import logged3 missing imported-resource entries before newGLB cache creation;
subsequent warm import succeeds. This phase does not claim a new fresh cold-import PASS.

### Changed files and checkpoint

Existing runtime modifications only:
- `scenes/hanger/hanger.tscn`
- `scenes/areas/prototype_field_office.tscn`
- `scripts/combat/combat_effects.gd` (four visual construction/material lines only)

Added:3GLBs/import recipes + source notice,4presentation scenes,2small helpers/UIDs,
1smoke material,3Blender masters and fixed authoring/verification/evidence under
`art_source/visual_coverage_4a/`, this coverage document. Full source/evidence guide:
`art_source/visual_coverage_4a/README.md`. No unrelated importer churn staged.
Dedicated Phase4A commit required; no push. Commit identity is the commit containing this
report (also recorded in local `commit_receipt.json` after commit, not a self-referential hash).

### Next bounded expansion

1. Separate enemy tactical-silhouette candidate spike, preserving AI/hitbox/muzzle parity.
2. Additional reusable outdoor utility/cover *visuals*, keeping collision independent.
3. Loot identity and optional UI icons only after gameplay-camera readability review.
Terminal is excluded from this phase. No expectation to finish the whole asset inventory.
