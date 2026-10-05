# Sitting animation continuation — 2026-10-04

Isolated verification only; NOT installed as production Hideout idle.

## Source and scope
Uses the unchanged parent UAL1_Standard.glb, source SHA-256
69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997.
Same retained CC0 license/provenance as parent SOURCE.json; no new download or purchase.
New disposable copy of current D:/bunny_team, excluding .git/.godot/art_source:
C:/Users/admin/AppData/Local/Temp/bunny_sitting_probe_7c722d07/project.
APPDATA/LOCALAPPDATA isolated; no real saves touched.
No existing project files overwritten; all durable additions are in this new subdirectory.

## Experiments
1. baseline_driver.gd: existing 22-body-bone rotational transfer with Sitting_Idle and Sitting_Talking.
   Visual check exposes floating pelvis/feet: target pelvis y=0.985687, toes y~0.427m.
   A seated clip cannot be integrated with the old rotation-only probe unchanged.
2. height_only_driver.gd: apply source authored pelvis vertical displacement to preview actor height,
   scaled by target/source rest hip-to-foot vertical distance (1.040251).
   No local bone translation, scale, mesh, material, or pose tuning.
3. probe.gd: additionally map 30 existing target finger bones to matching authored source chains.
   Total 52 mapped target bones; unmapped source leaf/root bones do not imply full 65-bone mapping.
   Source animation is sampled manually by seek + advance(0), as in original probe.

Each run: Godot 4.7.2 OpenGL, 60fps, 480 sampled frames, two clips.
Final run: finite rotations PASS, no bone scale PASS, exit 0, no ERROR/WARNING in playback log.
Toe bone world y range over 480 frames: 0.0370077–0.0380329m.
This is a bone-marker metric, NOT a shoe-sole or collision-contact guarantee.
Target pelvis y=0.595425m. Debug seat top y=0.50m; seat is a simple environment box,
not final Hideout furniture. No seated entry/exit, forward root transfer or IK implemented.

## Visual review / remaining acceptance
Inspected idle front, idle oblique and talking front screenshots.
Authored height transfer removes obvious stand-height floating; character appears supported
near the debug seat and shoes close to the floor. No mesh-level contact certification.
Talking brings hands very close together at chest height; hand/finger interpenetration remains
an acceptance risk. Finger mapping is a technical trial, not approved final hand art.
Source/target proportions and high heels differ. Need detailed shoe/seat clearance, loop boundary,
chair sizing and hand intersection checks before production. No crossed-arms clip confirmed.
No claim of artistic acceptance or 59/59 regression rerun; production was not modified.

## Reproduce
Copy current project to a fresh external temp directory (exclude .git/.godot/art_source).
Copy parent UAL1_Standard.glb to res://probe_free/source.glb and selected driver to
res://probe_free/probe.gd. Set APPDATA and LOCALAPPDATA to disposable directories,
BUNNY_EVIDENCE to a writable evidence directory. Import with Godot --headless --editor --import.
Run --path <copy> --script res://probe_free/probe.gd --rendering-method gl_compatibility
--fixed-fps 60 --resolution 1280x720 --write-movie <output.avi> --quit-after 600.
Transcode using FFmpeg h264_nvenc. Do not run this driver against production saves/project.

## Evidence / integrity
Final evidence/preview.mp4, front/oblique PNGs, three playback logs, contact JSONs.
80 non-.import character files hash-identical between current project and disposable copy.
Import-generated .import files excluded from that metric; do not equate it with previous
170-file historical check. Existing git short-status entry count remained 551, since additions
sit beneath an already untracked directory; status count alone is not an integrity proof.
No commit, push, cleanup, Unity install, purchases, or production idle integration.
