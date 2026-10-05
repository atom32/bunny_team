# Free animation pipeline probe

2026-10-04. Research/isolated preview only. No production integration.

## Result
- Quaternius Universal Animation Library Standard: free CC0, 43 animation clips, 65 source bones. The free package actually includes Unreal-Godot GLB; no Unity installation or purchase needed.
- Downloaded one 15 MB archive. Preserved only the non-root-motion GLB, original license/readme, provenance hash and verification driver here.
- Godot 4.7.2 imported GLB. Imported names strip the `_Loop` suffix (Idle_Loop -> Idle); do not hard-code source names without listing imported clips.
- OpenGL 1280x720 recording, 480 sampled frames / 8 seconds: Idle and Idle_Talking.
- 22 semantic body bones mapped onto the existing preview character. Source global rotation delta from rest is converted to target rest/forward basis. No authored motion invented. Target translation/scale retained; no geometry/material/texture changes.
- Visually inspected source/target side-by-side at 2 seconds into both clips. Body gestures transfer, but stance is wide and talking hands are close together on this character. This is NOT final Hideout art acceptance.
- Finger chains are NOT retargeted by this probe (target retains rest fingers). No sitting/root-height/seat-contact validation; no promise of crossed-arms clip in this free pack.
- Source and target limb lengths differ; floor/contact correction is not part of this minimal body-rotation proof.
- Final playback log has no ERROR/WARNING. Preliminary attempts caught an imported-name mismatch and inactive mixer; corrected before recording final evidence.

## Reproduce
Use an isolated copy of the current project (with current Hideout idle adapter). Copy UAL1_Standard.glb to res://probe_free/source.glb and probe.gd to res://probe_free/probe.gd, then run editor --headless --import. Set APPDATA and LOCALAPPDATA to disposable folders, BUNNY_EVIDENCE to an output directory. Run Godot --path <isolated copy> --script res://probe_free/probe.gd --rendering-method gl_compatibility --fixed-fps 60 --resolution 1280x720 --write-movie <output.avi> --quit-after 600.

The driver reuses Hideout's preview setup, suspends its idle driver, and shows the source and current character together. It is verification code, not runtime integration. Mainichi Unity muscle clips are not used.

## Scope
No production files, gameplay, tests, character assets, or user WIP modified. Full game regression not rerun because this experiment only runs in a temporary project copy. No commit/push. The proof covers free acquisition -> native Godot import -> body retarget -> graphical playback. Finger/contact/production acceptance remains pending.
