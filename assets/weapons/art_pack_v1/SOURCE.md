# Weapon Art Pack v1 — sources, rights and modifications

2026-10-15. Runtime baseline: existing `weapon.assault_rifle_01`, MoCap Online M4 (Motus Digital LLC). No new third-party model/texture download and no AI image/model service used.

## Existing licensed source — not CC0

- Original model/maps: `../mocap_m4/M4_Rifle_01.fbx`, `M4_Rifle_01.fbm/{M4DF2048,M4NM2048,M4AO2048,M4SP2048}.jpg`.
- Original supplied provenance/checksums remain in `../mocap_m4/SOURCE.md` and `checksums.json`; all five bytestrings unchanged.
- Author: Motus Digital LLC / MoCap Online; supplied by the user in the Demo Pack. Official [demo listing](https://mocaponline.itch.io/mocap-online-demo), [Standard License](https://mocaponline.com/pages/standard-license), [legal index](https://mocaponline.com/pages/legal), checked 2026-10-15. Do not relicense as CC0 or treat this project as permission to redistribute a general-purpose M4 asset pack. Existing project license restrictions and release review still apply.
- `m4_finish.gdshader/.tres` reuse original UVs and all four maps. They add a clean coated/metal/polymer PBR response; not new AI textures. The original geometry remains loaded directly in the existing `Art/Model/M4` node.
- `existing_magazine_reference.res` extracts the largest connected magazine region (96 source vertices / 48 original triangles) for the standalone reference/icon only. No new body topology is substituted into the production rifle. This derivative and the rendered AR/quickloader icons inherit the M4 source restrictions.

## New project-authored portions

The suppressor shell/collar, optical housing/lenses/rail adapter/covers/fasteners, rubber quick-pull boot/loop, carton and external cartridge reference were authored specifically for this project in `art_source/weapon_art_v1/build_assets.gd`. They use explicit beveled profiles/native ArrayMesh surfaces, not another game's models or branded replicas. Materials are native project-authored PBR Resources. These original portions are internal project assets; this record does not assign a new public/CC0 license on behalf of the project owner.

The offline builder saves static mesh/scene resources. It is not a gameplay procedural weapon generator and does not replace the detailed M4 with primitives. They are first-pass authored hard-surface presentation components, not a claimed externally generated high-poly hero asset. No functional weapon internals are modeled.

- Quickloader: original magazine retained on weapon; conforming rubber boot and pull loop render only for existing `quickloader` fitting. Separate `quickloader_magazine.tscn` combines its original magazine reference for inspection/icon rendering.
- Suppressor: short reflex/over-barrel appearance ending within 6mm of the existing authored muzzle. The logical muzzle, shot origin and collision never move.
- Optic: a compact observation optic. Installing it visually masks the factory sight via a per-instance shader parameter; the original mesh/markers remain intact. No two optics stacked together, no gameplay zoom/reticle addition.
- Ammo: `ammo_556_box.tscn` and `ammo_556_round.tscn` are display-only references for existing `ammo.556_standard`; original ammunition icon, quantity rules and entity behavior remain unchanged.

Transparent AR/kit PNGs are rendered from the actual scene assets by `tools/weapon_art_v1_probe.gd` in an isolated author project. New suppressor/optic icons contain only the project-authored component; AR/quickloader renders include the above licensed source. No retouching or generated raster material is introduced. Native `.png.import` configurations are retained for repeatable cold imports.

Carton labels reuse the existing `resources/fonts/game_ui.tres` / `assets/fonts/noto_sans_sc/NotoSansSC.ttf` UI font under its retained SIL Open Font License 1.1 (`assets/fonts/noto_sans_sc/OFL.txt`). No bundled engine fallback font is embedded or newly redistributed.

The derivative/modification/source hash list is `ASSET_HASHES.json`; the implementation and validation scope is `docs/WEAPON_ART_PACK_V1.md`.
