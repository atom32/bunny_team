# Quaternius Hideout presentation clips
Source: https://quaternius.itch.io/universal-animation-library
Edition: Universal Animation Library Standard, CC0-1.0. License retained alongside this file.
Original source/hash: art_source/free_animation_probe/SOURCE.json (acquired 2026-10-04).

idle.json contains only Idle and Sitting_Idle, sampled at 30 Hz (76/51 samples) by
art_source/free_animation_probe/sitting_20261004/bake.gd using native Godot GLB animation playback.
52 semantic global rotation deltas from source rest (22 body + 30 fingers).
Height is authored pelvis vertical displacement normalized to source rest hip-to-foot height.
Runtime applies height only to seated preview actor world position, scaled to target rest height.
No model data, target bone lengths/scales, hand-authored pose rotations or gameplay changes.
Standing preview keeps equipment deck anchor; Rest uses seat at (9.4,0,2.2).
Hanger restores original preview position, animation driver, rig visibility and rest poses.
Menu/Overview/Operations/Workshop use Idle; Rest uses Sitting_Idle. Talking is not shipped.
Pixiv assets remain preserved; only the Hideout adapter's selected animation source changes.
Section changes are direct presentation pose changes, not seated entry/exit transitions.
See docs/QUATERNIUS_HIDEOUT_INTEGRATION.md for verification and limitations.
