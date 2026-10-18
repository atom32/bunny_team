# Weapon Art Pack v1 — authoring and local evidence

See `docs/WEAPON_ART_PACK_V1.md` and `assets/weapons/art_pack_v1/SOURCE.md` for runtime integration, source rights and verification limits.

`build_assets.gd` is an offline native Godot hard-surface authoring source, not a runtime generator or a replacement rifle. It writes only to a separately copied/imported project and refuses the production checkout. Use a new verification snapshot with isolated APPDATA/user://; set `BUNNY_ART_AUTHORING=isolated`, then invoke Godot `--headless --path <isolated project> --script D:/bunny_team/art_source/weapon_art_v1/build_assets.gd`. Review/copy back only the intended generated resource directories, not user data or `.godot`.

The rendered icons come from `tools/weapon_art_v1_probe.tscn`. Set an absolute external `BUNNY_WEAPON_ART_EVIDENCE` path; optional `BUNNY_WEAPON_ART_ICONS=isolated` writes the four icons only in an isolated author copy. Do not use that flag on the production checkout. Normal verification leaves the supplied icons unchanged.

`evidence/` is deliberately Git ignored and retained locally: same-camera before/after, attachment/round/carton views, actual warehouse/character reload/battle screenshots, and original logs/hash manifests. Early failed visual iterations remain in the external session directory; they are not acceptance evidence. No screenshot is a claim of human acceptance or third-party commercial release permission.
