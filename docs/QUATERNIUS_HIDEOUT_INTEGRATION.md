# Quaternius Hideout integration — 2026-10-04

User explicitly requested integration after isolated preview.

## Installed
- Menu / Overview / Operations / Workshop: free CC0 Quaternius Idle.
- Rest: Sitting_Idle at dedicated visual seat (9.4, 0, 2.2), with authored pelvis height transfer.
- 52 rotation mappings: 22 body + 30 fingers. No character geometry, texture, material or scaling edits.
- Hanger restores original equipment position, animation tree, modifiers and weapon visibility.
- Preview rebuild retains section-selected playback; profile/loadout/save contracts unchanged.
- Existing pixiv idle/source kept; Talking is not installed due to close-hand acceptance risk.
- Chair/light are environment-only. No gameplay owner, collider, combat or save schema changes.

## Verification
Fresh isolated verification: C:/Users/admin/AppData/Local/Temp/bunny_quaternius_final_20261004.
59/59 scene tests PASS; cross-process checkpoint/medical/campaign/fitting/packing checks PASS.
Main exit 0, known ObjectDB leaked-instance warning; cold import exit 0,
0 ERROR / 2 existing FBX UTF-8 warnings. No assertions removed or weakened.
Extended existing hideout_idle_test covers seat height, 52 mappings, unchanged hip local translation,
standing/equipment location restoration, seated preview replacement and unchanged profile serialization.
First verification exposed a GDScript inferred-string parse error; fixed with explicit String type.
Test's initial zero-translation assumption corrected to compare original target pose translation
(Godot target pose positions are not necessarily zero). Fresh final suite passed after both fixes.

Forward+ 1280x720 actual Hideout scene captures inspected: menu backdrop, Rest, equipment.
Overview screenshot also retained. Rendering used isolated user directories.
All 170 current character asset files hash-identical to pre-integration disposable snapshot.
Loop endpoint max quaternion difference approximately 0.04 degrees; not artistic certification.
Durable captures/results/scoped diff: art_source/free_animation_probe/sitting_20261004/integration/.
Scoped pre-edit backups: C:/Users/admin/AppData/Local/Temp/bunny_sitting_probe_7c722d07/integration_backup.
No reset, cleanup, staging, commit, push, purchases or Unity installation.

## Limitations
Section pose/location changes are immediate, not walk-to-chair or seated entry/exit animation.
Foot markers and inspected seat appearance do not certify mesh-level contact/collision.
High-heel contact, final lighting/chair art and loop artistic quality remain polish work.
No crossed-arms clip or Talking animation acceptance is claimed.
Historical parent probes assume the old body-only adapter; use the preserved isolated baseline
or this integration renderer when reproducing after the production adapter changed to 52 mappings.

## Files changed for this integration
scripts/presentation/slice/hideout_idle.gd; scripts/presentation/slice/hideout.gd;
tests/hideout_idle_test.gd; new assets/animations/quaternius_hideout;
new integration evidence/docs and appended current Handoff section. Prior unrelated WIP preserved.
