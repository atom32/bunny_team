# Menu polish and debug-assisted quest playthrough — 2026-10-07

Presentation: charcoal/olive panels, warm sand accents, square borders, clear task entry, narrative/base-development sections and read-only field facts in debrief. Gameplay and settlement rules are unchanged.

The recording runs production scenes with an isolated Godot profile. Combat AI and operator physics are disabled; the driver teleports to interaction points, bypasses the tutorial and deployment cinematic, and grants two ordinary fabric items. Dressing purchases, field interactions, suspend/resume, extraction, result return and base submissions use production paths. No quest completion flags are injected. The recording continuously displays its debug-assisted method.

Route: main menu → settings → base/task board → loadout/supply menus → Q01 (two actual exit plaques) → successful return → Q02 (pharmacy batch; suspend/resume; successful return; material handover) → Q04 (fixed receipt + matching pharmacy record; successful return; submission) → chain A hard stop → free sortie.

Files: `playthrough.mp4` (H.264/AAC), `captures/` (screen checks), `playtest.json` (checks and final profile), `recording.log`, isolated `recording_driver.gd` and its scene template. The driver is not integrated into the shipped game. To rerun, copy the driver into `tools/menu_recording_driver.gd` and the scene into `tools/menu_recording_driver.tscn` in an imported isolated snapshot with a unique project name; adjust the driver OUT path. Run Godot with `--write-movie playthrough.avi --fixed-fps 30 --disable-vsync res://tools/menu_recording_driver.tscn`, then transcode the AVI with ffmpeg.

Baseline verification: all 62 existing scenes and cross-process recovery checks passed in `/tmp/bunny-menu-20261007`. Final palette adjustments are checked again with relevant UI/narrative regressions and the recorded graphics route. This is not an unassisted combat playtest.

Final results: 66/66 recorded route checks, 22 screenshots, 10/10 final UI/narrative regressions. MP4: 124.7 seconds, 1280×720, 30 FPS, H.264 video/AAC audio, 22,564,271 bytes. The decoded MP4 frame was visually checked against the captured game UI. Q04 completion and a subsequent free sortie generated no next narrative task.
