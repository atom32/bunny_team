# MoCap Online Rifle demo selection

Publisher: Motus Digital LLC / MoCap Online.
Source: https://mocaponline.itch.io/mocap-online-demo
Official product: https://mocaponline.com/products/free-mocap-animation-pack
License: https://mocaponline.com/pages/legal (Standard License; not CC0).

Copied from the user-downloaded `MCO_Demo_Pack_v2/FBX` on 2026-09-30.
Selected original FBXs are unchanged. `MotusMan_v55.fbx` provides the
reference T-pose skeleton; the seven Rifle clips are animation sources.
Godot extracted the two embedded MotusMan textures during import.
The supplied rifle-position note is preserved verbatim.

Included clips:
- W2_Stand_Relaxed_Idle_v2
- W2_Stand_Aim_Idle_v2
- W2_Stand_Aim_To_Relaxed
- W2_Walk_Aim_F_Loop
- W2_Jog_Aim_F_Loop
- W2_Walk_Aim_F_Loop_IPC
- W2_Jog_Aim_F_Loop_IPC

There is no reload or firing clip in this Rifle demo selection.
Only the isolated Bunny portrait currently samples these clips. The supplied M4 is used as the portrait weapon; its provenance is recorded in
`assets/weapons/mocap_m4/SOURCE.md`. The runtime AR now also uses the supplied M4 mesh. Gameplay locomotion still uses the existing Unity-Chan source; the MCO clips are sampled in the isolated portrait.
The pack does not contain a bundled EULA text. Official license references
above are retained instead; do not label these files public domain or
redistribute them as a standalone animation pack.

## Portable animation resources (2026-10-01)

The seven original Rifle FBXs are preserved byte-for-byte under `source/`, with
updated relative paths in `checksums.json`. That directory has `.gdignore` because
the demo FBXs reference absent `UE4_Pistol_27A/Sketchfab/MCG_diff.jpg` and
`MCG_spec.jpg`; importing their unused meshes produces missing-texture errors.
Runtime portraits sample the same Animation tracks from adjacent `.tres`
resources, baked using `tools/bake_mco_clips.gd`. No animation key or bone name is
changed. `baked_checksums.json` records each derivative and original source hash.
The MotusMan reference FBX remains imported with its existing embedded textures.
To re-bake, temporarily remove `source/.gdignore`, import, run the bake script,
and restore `.gdignore`; missing pistol-image diagnostics during source import
are expected. These sources remain subject to the original pack license.
