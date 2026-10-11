# Quaternius Hideout presentation clips
Source: https://quaternius.itch.io/universal-animation-library
Edition: Universal Animation Library Standard, CC0-1.0. License retained alongside this file.
Original source/hash: art_source/free_animation_probe/SOURCE.json (acquired 2026-10-04).

idle.json contains only Idle and Sitting_Idle, sampled at 30 Hz (76/51 samples) by
art_source/free_animation_probe/sitting_20261004/bake.gd using native Godot GLB animation playback.
52 semantic global rotation deltas from source rest (22 body + 30 fingers).
Height is authored pelvis vertical displacement normalized to source rest hip-to-foot height.
Runtime transfers seated/transition/walk pelvis height to preview actor world position, scaled to target rest height.
No model data, target bone lengths/scales, hand-authored pose rotations or gameplay changes.
Walking mixes sourced idle shoulders, arms and fingers into the gait for smaller arm
swings and relaxed open hands, and reduces the sourced hip/thigh motion for shorter steps.
Walk playback follows travel distance; seated entry/exit play at 0.78× speed.
Standing destinations are authored for the compact room; Rest uses seat at (2.12,0.045,0.9).
Hanger restores original preview position, animation driver, rig visibility and rest poses.
Menu/Overview/Operations/Workshop use Idle; Rest uses Sitting_Idle. Talking is not shipped.

transitions.json adds Walk_Loop, Sitting_Enter and Sitting_Exit from the same CC0 GLB,
sampled at 30 Hz with the same 52 semantic rotations and normalized pelvis height.
Reproduce with tools/bake_hideout_transitions.gd (Godot GLTFDocument, no extra source import).
Hideout routes the actor through the room aisle at 0.92 m/s, eases turns and speed,
and advances the walk cycle by distance traveled. Each clip blends from the visible
pose over 0.42 s. Rest departure finishes Sitting_Exit before walking; arrival turns
before Sitting_Enter. Camera travels alongside the actor through the doorway at z=1.6, then settles
on the section. Rest camera stays on the actor’s side of the partition.
Rapid navigation and preview replacement retain current position and playback.
Hanger receives its original equipment animation driver after arrival and pose blending.
Pixiv assets remain preserved; only the Hideout adapter's selected animation source changes.
Movement is presentation-only with authored waypoints, not gameplay navigation or foot IK.
See docs/QUATERNIUS_HIDEOUT_INTEGRATION.md for the historical idle-only integration report.
Camera verification: hideout_camera_test samples four body sightlines against
actual wall/door/ceiling triangles throughout all 25 section pairs.
Current transition verification: hideout_idle_test, character_presentation_test and
hanger_first_mission_test pass; rendered walk/entry/exit frames inspected on 2026-10-10.
