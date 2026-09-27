# Third-Party Assets

## Unity-chan Battle Costume

- Runtime animation FBXs: `assets/characters/unitychan_battle/animations/`; original hidden source rig/animation data retained.
- Legacy/reference model: `art_source/unitychan_battle_legacy/unitychan_battle.fbx` (byte-identical relocation, excluded from Godot import by `.gdignore`). It is not the visible runtime character.
- Restored original texture dependencies: `assets/140301_unitychanmodel_Celsis/sourceimages/`; exact source/hash/license record in adjacent `SOURCE.md`.
- Character: Unity-chan Battle Costume
- Publisher: Unity Technologies Japan K.K.
- Source: https://unity3d.jp/unity-chan_contents/releaseNote.php?id=TPK-Hmnd-Kohaku_A&lang=en
- Animation source: https://unity3d.jp/unity-chan_contents/releaseNote.php?id=UnityChan&lang=en
- License: Unity-chan License 3.0
- License guideline: https://unity3d.jp/unity-chan_contents/guideline.php?lang=en
- Bundled license files: `assets/characters/unitychan_battle/license/`
- Required corporate-use notation: `© Unity Technologies Japan/UCL`

Production Player renders the official-source-derived Battle Costume GLB at
`assets/characters/unitychan_battle/battle_presentation.glb` through the existing
presentation adapter and retarget. The raw legacy FBX is retained outside runtime
import scope; recovered immutable authoring files live under
`art_source/unitychan_battle_legacy/official_1_1/`. Phase 2B restored five missing
original TGA dependencies from the official UnityChan 1.2.1 package; all six local
animation FBXs match that package by SHA-256. No animation or rig was rewritten
by that repair. Phase 4E KITE-07 uses neither the old VRM nor its humanoid rig;
AvatarSample_A remains a rollback/reference asset, not the production character.
This development sync is not commercial release clearance.

The Unity-chan license package must remain alongside the character files when the digital assets are redistributed. The license also prohibits using the character as AI image-generation training or input data.

## Quaternius Ultimate Modular Women Pack

- Retained reference file: `assets/characters/quaternius_scifi/SciFi.gltf`
- Character variant: SciFi
- Author: Quaternius
- Source: https://quaternius.com/packs/ultimatemodularwomen.html
- License: CC0 1.0 Universal / Public Domain Dedication
- License text: `assets/characters/quaternius_scifi/LICENSE.txt`

This earlier low-poly candidate remains in the asset folder for provenance but is no longer the visible player character.

## Visual Slice 01 — Kenney assets

- Author: Kenney, https://kenney.nl
- Building/props: [Space Station Kit 1.0](https://kenney.nl/assets/space-station-kit), 16 selected GLBs.
- Weapons: [Blaster Kit 2.1](https://kenney.nl/assets/blaster-kit), blaster-e / blaster-g / blaster-o only.
- License: CC0 1.0; personal/commercial game use and modifications permitted; attribution optional.
- Licenses: `assets/environment/kenney_space_station_kit/LICENSE.txt` and `assets/weapons/kenney_blaster_kit/LICENSE.txt`.
- Exact source download URLs and hashes are in the adjacent `SOURCE.md` files. Original GLBs/palettes are retained unchanged; presentation placement and palette remap are project-authored.
