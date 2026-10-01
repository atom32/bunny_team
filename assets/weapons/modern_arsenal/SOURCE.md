# Modern firearms

- Author: Quaternius.
- Pack: [Ultimate Guns Pack](https://quaternius.com/packs/ultimategun.html).
- License published by author: CC0 1.0 Universal.
- Retrieved: 2026-09-29. Original Blender files and SHA-256 hashes are retained in `art_source/modern_arsenal/sources/` and `download_manifest.json`.
- Official download folder: https://drive.google.com/drive/folders/12V-mHNB6bnW2WzgpJfRBQd-TG4pOO3yx
- Selected originals: AssaultRifle_1, SubmachineGun_1, Pistol_1, Shotgun_1, SniperRifle_1.

Project adaptations: graphite/steel/field-polymer PBR materials, shoulder stocks on the rifle and SMG, meter-scale export and authored grip/muzzle markers. The LMG is a project-authored derivative of AssaultRifle_1 with a box magazine, longer heavy barrel, muzzle brake and folded bipod; it is not an additional original model in the pack. Game names are generic, not claims of exact real-world replicas.

Rebuild from the repository root with Blender:

```
blender --background --factory-startup --disable-autoexec --python art_source/modern_arsenal/build_models.py
```

The authoring directory has `.gdignore`; only the GLBs in this directory enter the runtime import pipeline. Weapons use their own materials, without the previous Blaster Kit palette remap. Character assets and animation sources are unchanged.
