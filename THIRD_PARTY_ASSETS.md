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

The retained Battle Costume GLB at
`assets/characters/unitychan_battle/battle_presentation.glb` is a previous player
visual. The current player uses the Artoria prototype below; Unity-Chan still
supplies its hidden locomotion driver and animation clips. The raw legacy FBX is retained outside runtime
import scope; recovered immutable authoring files live under
`art_source/unitychan_battle_legacy/official_1_1/`. Phase 2B restored five missing
original TGA dependencies from the official UnityChan 1.2.1 package; all six local
animation FBXs match that package by SHA-256. No animation or rig was rewritten
by that repair. Phase 4E KITE-07 uses neither the old VRM nor its humanoid rig;
AvatarSample_A remains a rollback/reference asset, not the production character.
This development sync is not commercial release clearance.

The Unity-chan license package must remain alongside the character files when the digital assets are redistributed. The license also prohibits using the character as AI image-generation training or input data.

## Quaternius SciFi humanoid (package identity not fully verified)

- Runtime file, reused unchanged from the repository: `assets/characters/quaternius_scifi/SciFi.gltf`
- Character variant: SciFi
- Author: Quaternius
- Source: https://quaternius.com/packs/ultimatemodularwomen.html
- Recorded license: CC0 1.0 Universal / Public Domain Dedication
- Package discrepancy: the existing notice says Ultimate Modular Males while the prior source link says Women. The official Women page also lists CC0, but the local file has not been byte-matched to that archive; do not treat this as a newly completed provenance audit.
- License text: `assets/characters/quaternius_scifi/LICENSE.txt`

The SciFi model and its original skin/animations now provide the PMC patrol enemy. A red ground marker distinguishes hostiles. The authored pistol, movement, firing and death clips are retained. It is not the visible player character.

## Visual Slice 01 — Kenney assets

- Author: Kenney, https://kenney.nl
- Building/props: [Space Station Kit 1.0](https://kenney.nl/assets/space-station-kit), 16 selected GLBs.
- Former weapons, retained as reference: [Blaster Kit 2.1](https://kenney.nl/assets/blaster-kit), blaster-e / blaster-g / blaster-o only. Production weapons now use the modern arsenal below.
- License: CC0 1.0; personal/commercial game use and modifications permitted; attribution optional.
- Licenses: `assets/environment/kenney_space_station_kit/LICENSE.txt` and `assets/weapons/kenney_blaster_kit/LICENSE.txt`.
- Exact source download URLs and hashes are in the adjacent `SOURCE.md` files. Original GLBs/palettes are retained unchanged; presentation placement and palette remap are project-authored.

## Modern arsenal

- Six firearms use selected [Quaternius Ultimate Guns Pack](https://quaternius.com/packs/ultimategun.html) models (CC0). The LMG is an authored derivative of the assault rifle. Source, licenses and modifications: `assets/weapons/modern_arsenal/SOURCE.md`.
- RPG uses the separate textured [Khairul Hidayat launcher](https://opengameart.org/content/low-poly-rocket-launcher). The author offers CC0 on the listing; the archive also contains an MIT notice, retained as received. Provenance: `assets/weapons/khairul_launcher/SOURCE.md`.
- New pistol, shotgun, sniper and LMG sounds are project-authored synthesized cues from `tools/generate_modern_audio.py`, not third-party recordings.

## Artoria Bunny Suit prototype

- Source supplied by the user: `ArtoriaLancer_AllVersion_ARP_MustardUI.blend` in their Downloads folder; source SHA-256 and reproducible conversion scripts are recorded in `art_source/artoria_bunny/README.md`.
- Runtime: `assets/characters/artoria_bunny/bunny_player.glb`, the authored Bunny Suit with scarf disabled, fitted body morphs, reduced hair, a clean 52-joint skin and baked source PBR textures.
- The source file is preserved. This is a prototype visual chosen by the user; no commercial redistribution permission is established by this integration. The inspection found no accompanying model license. Confirm both the model terms and underlying character rights before a release containing this asset.
- This visual is not the original heroine described in the Neon Bastion narrative design. Existing Unity-Chan geometry/textures remain unchanged; its imported animation clips are retained as the current locomotion source with their existing license package.

## MoCap Online Rifle demo

- Publisher: Motus Digital LLC / MoCap Online.
- User-provided official [free demo](https://mocaponline.itch.io/mocap-online-demo): 7 original Rifle animation FBXs, MotusMan_v55 reference skeleton, and the supplied M4 mesh/textures.
- Files and provenance: `assets/animations/mocap_online_rifle/SOURCE.md` and `assets/weapons/mocap_m4/SOURCE.md`.
- License: MoCap Online Standard License, not CC0; [official terms](https://mocaponline.com/pages/legal).
- Animation clips are currently sampled by the isolated Bunny portrait. The supplied M4 mesh/textures also replace the runtime AR model. The demo contains no Rifle reload or firing clip.

## Poly Haven streets textures

- Rob Tuytel / Poly Haven: [Asphalt 02](https://polyhaven.com/a/asphalt_02) and [Wall Bricks Plaster](https://polyhaven.com/a/wall_bricks_plaster).
- Amal Kumar / Poly Haven: [Painted Plaster Wall](https://polyhaven.com/a/painted_plaster_wall).
- Original 1K diffuse, OpenGL normal and roughness JPGs in `assets/environment/polyhaven_streets`; exact source URLs and hashes in `checksums.json`.
- [CC0 license](https://polyhaven.com/license); imported for the original Old Town district.

## Noto Sans SC UI font

- Original variable font from [Google Fonts / Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc), downloaded 2026-10-01.
- Font and original SIL Open Font License 1.1 are included in `assets/fonts/noto_sans_sc`.
- Exact download URLs and SHA256 hashes: `assets/fonts/noto_sans_sc/checksums.json`.
- The font file is unchanged. A separate Godot FontVariation resource selects regular weight (400) for readable Chinese/English UI.

### Warehouse thumbnails

`assets/ui/stash/*.png` are rendered derivatives of the existing weapon and equipment scenes, generated by `tools/stash_icons.gd`. Their source model attribution and licenses remain those recorded above. The ammunition, rocket and salvage SVG icons in the same folder are original project artwork.

## YARD editor authoring plugin

- [YARD v1.3.1](https://github.com/elliotfontaine/yard-godot/releases/tag/v1.3.1), commit `a496be3dfa1279bfdd999950e0936eaac0d84fc3`, integrated 2026-10-14.
- Only `addons/yard`; no demo, binaries or unrelated add-ons. Code MIT; included plugin art/metadata retain their MIT/CC0 SPDX notices. Original LICENSE, REUSE, AUTHORS and license texts are retained in `addons/yard/upstream_notices/`.
- Local compatibility change: skip forced startup icon reimport to avoid Godot 4.7.2 overlapping import tasks. See `addons/yard/UPSTREAM.md`.
- Editor catalogs mirror existing definitions. This plugin does not grant rights to existing character/model/animation assets.

## Service room authoring sample

- `scenes/modules/service_room.tscn` uses the existing Kenney Space Station Kit models and their retained CC0 license, not a newly downloaded restricted room pack.
- The scene, colliders and repair/supply anchors are project-authored. No third-party demo scripts or combat/loot ownership are imported.

## Quaternius adult subject references — 2026-10-15

- Official sources: [Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html), [UAL1](https://quaternius.com/packs/universalanimationlibrary.html). Free Standard only, CC0; no teen or paid Source models.
- Runtime/reference directories: `assets/characters/quaternius_subject/` and `assets/characters/quaternius_subject_female/`; each retains LICENSE.txt and SOURCE.json. Male subject now presents new infected sorties; female is an authoring reference, not a new player or randomly spawned enemy.
- Standard archive SHA256: `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40`. UAL1 GLB SHA256: `69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997`. Original private download-session URLs/cookies are not redistributed.
- Derived coverall/soft-shoe material partitions retain original positions, skin weights and bind skeleton; these are close-fitting material covers, not newly modeled loose clothes. Texture URI repair fixes missing upstream normal names; texture pixels are unchanged.
- Seven target-rest-retargeted clips per adult rig are native AnimationLibrary/BoneMap resources under `resources/presentation/subjects*`. The source animations are universal/unisex authored clips, not verified male/female-performer mocap.
- Heroine young-adult female motion style is project-authored on the existing UnityChan female-character driver, with original UCL requirements and Artoria trial restrictions retained. This does not certify the source character/performer age or grant commercial release clearance. See [exact workflow and limits](docs/MODEL_ANIMATION_AUTHORING.md).

## Project-authored fitting kit icons — 2026-10-15

`assets/ui/supply/quickloader_kit.svg`, `suppressor_kit.svg`, and `observation_optic_kit.svg` are project-authored vector icons, not sourced third-party or AI raster images. Provenance is recorded in `assets/ui/supply/FITTING_KITS.md`; no CC0 attribution is borrowed from unrelated imported packs. Physical inventory kits do not add new rendered weapon attachment meshes or alter existing character/weapon art.

## Campus Batch 2 props — 2026-10-15

The three native campus-action scenes reuse the already-vendored Kenney Space Station Kit `computer-system.glb`, `computer-screen.glb`, and `display-wall.glb` under its existing CC0 provenance. Native screen/indicator geometry and chapter text are project-authored. The experiment recorder icon reuses the existing project data-drive icon; no new provenance or commercial clearance for unrelated character assets is implied. See [implementation and limits](docs/CAMPUS_BATCH2_IMPLEMENTATION.md).

## Weapon Art Pack v1 — 2026-10-15

The existing MoCap Online M4 geometry/maps remain unchanged and keep their existing non-CC0 restrictions. New material interpretation, native accessory surfaces and ammunition display references are documented in [asset source record](assets/weapons/art_pack_v1/SOURCE.md). The standalone magazine subset and rendered M4/quickloader icons inherit the supplied source's rights; no general-purpose redistribution license is added. Other new components use project-authored meshes/materials, not downloaded or AI-generated models/textures. No additional commercial release clearance is implied.
## Field supplies art v1 (2026-10-15)

Sixteen new project-authored supply/food/drink props and their actual-rendered PNG icons: `assets/props/supply_art_v1/SOURCE.md`. No new third-party asset download or generative service; labels reuse the existing Noto Sans SC font and retained SIL OFL. Original project rights are not reassigned to CC0. The reused prior magazine/fitting presentation remains subject to its existing MoCap Online source restrictions.
