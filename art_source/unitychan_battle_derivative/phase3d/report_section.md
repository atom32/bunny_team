
## Phase 3D — Production Player Presentation Switch

**Technical production migration: PASS**
**Public release authorization: NOT ASSESSED**
**Enemy AvatarSample_A licensing: BLOCKED**

Normal production Player now preloads the validated battle_presentation.glb and instantiates
scripts/presentation/unitychan/presentation_adapter.gd. These are the only two Player code
changes. Gameplay ownership, collision, identity, save schema, weapon definitions and enemy
are unchanged. No environment switch/demo scene needed. Old avatar remains for rollback.
Existing CombatAvatarModel/Body/UpperBodyAim plus eight semantic mounts form the presentation
contract; no fake CharacterPresentation/Face nodes or renamed gameplay concepts added.

### Test-contract migration (separate from production reference changes)

Old Face mesh-name/AABB assertion replaced by adapter visual integrity contract: all24
skinned meshes, all37359 triangles, authored head3474 triangles with finite nonzero bounds.
Mesh-specific knowledge stays inside the adapter, not generic Player tests. Eight semantic
mounts now explicitly checked; animation/IK/equipment tests retained. Old VRM wording updated,
no unrelated tests changed. This protects complete geometry rather than merely checking a
node exists. Runtime adapter data preserves the validated manually authored poses.

### Validation

- Production regression33/33; ACCEPTANCE_SMOKE PASS, MAIN exit0. Relevant Presentation,
  WorldTraversal, VisualSlice, ResultReturn, save/load and weapon suites all pass.
- Production vs legacy270 deterministic weapon samples: origin/direction delta0, reload and
  state flags identical. WeaponDefinition/weapon logic untouched.
- Normal production Hanger/Field Office graphical routes, Rifle/Rocket and SMG/Rocket:
  all32 checks each PASS including actual Dodge, Terminal, extraction, Result→Hanger.
  Production cameras1280x720; automated input/API, not manual. Mission objectives not all
  completed; extraction/result—not full mission completion—is the verified outcome.
- Real existing production profile copied byte-for-byte for safe validation (source/hash in
  save_provenance.json). Both routes load that data, commit/save, then restart another process
  and reload. Full profile/owned IDs/loadout match; independent warehouse merge check passes.
  Original user save hash remains unchanged. Schema has no Person ID; none invented.
- Animation contract24 weapon/state combinations PASS through the existing AnimationTree:
  Idle/Walk/Run/Run+Shoot/Recoil/Reload/Hit/Dodge. Finite bones/integrity checked; captures in
  phase3d/animation. Accepted prior minor sliding/intersection remains, no pose redesign.
- Official68 source/meta hashes unchanged; runtime GLB equals derivative; old avatar unchanged.
- Initial adapter integrity-helper parse errors were corrected with explicit Array/AABB types;
  retained initial logs. No real gameplay failure workaround. Known ObjectDB exit warnings
  remain in some tests; not claimed warning-free.

### Rollback / files / Git

Rollback not triggered: no acceptance criterion failed after helper compilation correction.
Old asset remains untouched. A rollback would restore only Player's two presentation reference
expressions and their matching test contract; do not discard other WIP.

Production changes: scripts/player/player_controller.gd (two references);
scripts/presentation/unitychan/ (validated adapters + integrity query);
assets/characters/unitychan_battle/battle_presentation.glb(.import) and presentation/ data.
Test migration: tests/acceptance_smoke.gd only. Evidence/report: phase3d/ and this section.
No Terminal/enemy/official source changes. Existing Phase3B/3C/import/migration WIP excluded
from the dedicated commit. No push. Commit identity is recorded in phase3d/commit_receipt.json
and the final response (receipt written after commit, avoiding self-referential commit hash).
