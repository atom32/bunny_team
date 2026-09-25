# Asset Audit

> Current (2026-09-25): Visual Slice 01 assets are integrated. The inventory below records the inherited baseline; the **Visual Slice 01** section is the current selection/licensing ledger. See `docs/visual_slice_01/REPORT.md` for validation and remaining limits.

This audit records what is already available in the repository for the current vertical slice. It separates assets that are usable now from prototype visuals that still need a production-art replacement.

## Character Assets

### VRM avatar

- Asset: `assets/characters/vrm_avatar/avatar_sample_a.glb`
- Textures: `assets/characters/vrm_avatar/*.png`
- License notes: `assets/characters/vrm_avatar/LICENSE-MODELS.md`
- Current use: player presentation in Hanger and gameplay.
- Prototype status: usable now. Redistribution and attribution must follow the model metadata and the bundled license notes.

### Unity-Chan battle character and animations

- Character: `assets/characters/unitychan_battle/unitychan_battle.fbx`
- Animations: `idle.fbx`, `walk.fbx`, `run.fbx`, `slide.fbx`, `damaged.fbx`, and `win.fbx`
- License material: `assets/characters/unitychan_battle/license/`
- Current use: the Hanger preview uses the imported `Idle_Gun` animation through its `AnimationTree`.
- Prototype status: usable now under the bundled Unity-Chan license. The remaining clips are suitable for later presentation work but are not a reason to expand this pass.

### Quaternius sci-fi character

- Asset: `assets/characters/quaternius_scifi/SciFi.gltf`
- License: CC0 1.0, documented in `assets/characters/quaternius_scifi/LICENSE.txt`
- Current use: available as a permissively licensed character source; not required by the current Hanger or Arena flow.
- Prototype status: usable, but currently redundant with the active player presentation.

## Weapon Assets

- Assault Rifle: `scenes/weapons/assault_rifle.tscn`
- SMG: `scenes/weapons/smg.tscn`
- Rocket Launcher: `scenes/weapons/rocket_launcher.tscn`
- Shared visual implementation: `scripts/weapons/weapon_visual.gd`

These are functional procedural prototype scenes built from Godot geometry. They are connected to the real weapon definitions and are suitable for gameplay validation, Hanger preview, aiming, projectile origins, and weapon switching.

No separate production-quality weapon mesh files were found for the Assault Rifle, SMG, or Rocket Launcher. Final presentation still needs dedicated weapon models, materials, and attachment points. The current scenes should not be described as final art.

## Environment Assets

### Available authored and procedural content

- Prototype Arena: `scenes/areas/prototype_arena.tscn`
- Field Office interior: `scenes/areas/prototype_field_office.tscn`
- Door: `scenes/world/door.tscn`
- Cover: `scenes/world/cover_obstacle.tscn`
- Destructible barrier: `scenes/world/destructible_world_object.tscn`
- Procedural urban geometry: `scripts/battle/urban_arena.gd`

These assets are sufficient for a readable gameplay prototype. The Field Office now provides an actual collidable interior with an interactive entrance, cover, a destructible barrier, terminal, enemies, loot, and a rear exit.

No dedicated external modular building kit, interior prop kit, road kit, vegetation kit, or production material library was found. Current architecture and props are gameplay blockout quality.

## Lighting And Sky

The project currently relies on Godot environment setup and procedural lighting, including the world-environment setup in the existing visual factory/runtime code. No HDRI, EXR sky, or dedicated final lighting asset set was found.

This is sufficient for functional readability. A later presentation pass will need an intentional sky/HDRI choice, authored light hierarchy, and production materials, but those are outside the current scope.

## Current Vertical-Slice Readiness

Usable now:

- VRM player presentation.
- Active Hanger idle animation.
- Functional weapon prototype visuals.
- Authored Field Office gameplay interior.
- Door, cover, destructible barrier, objectives, loot, enemies, and extraction.

Still missing for final presentation:

- Production-quality AR, SMG, and Rocket Launcher meshes.
- Modular exterior/interior building and prop set.
- Road, vegetation, and environmental dressing assets.
- Production material library.
- Final sky/HDRI and lighting treatment.

The repository has enough assets to validate the full gameplay and presentation structure without downloading new content. It does not yet contain enough environment and weapon art for a final visual-quality pass.

Open-source replacements may be introduced in a later art pass. Any downloaded asset should be kept with its source URL, author, license text, and attribution requirements; this structural pass did not need an external download.

## Visual Slice 01 — selected external sources (2026-09-25)

The current user request expands the former environment-only spike to three weapon visuals plus the existing Field Office. No new gameplay content is introduced.

| Use | Author / source | License / attribution | Selected format |
|---|---|---|---|
| Building modules and 10 interior prop types | Kenney, [Space Station Kit 1.0](https://kenney.nl/assets/space-station-kit) | CC0 1.0; commercial game use and modifications allowed; credit optional, retained here | glTF 2.0 binary (.glb), 512 px palette |
| AR, SMG, launcher silhouettes | Kenney, [Blaster Kit 2.1](https://kenney.nl/assets/blaster-kit) | CC0 1.0; commercial game use and modifications allowed; credit optional, retained here | glTF 2.0 binary (.glb), palette texture |

Weapon selections: AR = blaster-e (stock, barrel, magazine and optic); SMG = blaster-g (compact receiver); Rocket = blaster-o (four-tube launcher silhouette). These are deliberately stylized sci-fi models, not replicas of real firearms. Only these three weapon models are retained. Model fit and palette are adapted in presentation scenes; the original GLBs remain unmodified. Existing WeaponDefinition.scene is the sole identity-to-presentation mapping.

Building selections: wall, wall-detail, wall-window, floor, floor-detail, door-double-closed. Roof, entrance canopy, fascia, signage and luminaires are authored locally; no second modular set is used. Interior selections: table, chair, computer-screen, computer-system, display-wall, container-flat, container-tall, wall-switch, pipe, pipe-bend. Imported decorations contain no physics bodies. Existing collision geometry remains authoritative; windows are sealed visual panels, not new traversal/shooting openings.

Original license files are retained under each asset directory. Package URLs and SHA-256 are recorded in SOURCE.md beside the selected files. Palette recoloring uses one shared shader and three small materials, without new high-resolution textures. Both original palettes are 512 × 512 px. Existing VRM, Unity-Chan Idle_Gun and AnimationTree ping-pong are reused unchanged. No HDRI downloaded; existing sky/environment is reused with local lighting only.

### Final integration notes

- 19 selected GLBs total: 16 environment/prop assets + 3 weapon models, 337,612 bytes of source mesh files.
- Weapon mesh triangles: AR 802; SMG 618; launcher 664.
- Locally authored additions: sealed opaque glazing (existing walls remain fully collidable), roof/canopy/fascia, 2 ceiling luminaires, locker, file shelf/binders, waste bin and small desk accessories. These reuse the same small material family.
- Imported models face -Z in this project. Source GLB geometry is unchanged; scale/offset live in the three weapon scenes.
- Legacy socket weapons use the existing rig's presentation targets, but keep `uses_combat_rig = false`; their production muzzle and reload paths remain unchanged. All original definition Resources are byte-identical to the handoff baseline.
- Lighting: existing Environment, ambient and sun; 6 local unshadowed office lights total, no HDRI/GI/renderer change.
- Current art is a modest low-poly sci-fi slice. It is not a photoreal firearm/architectural set or a completed final-map art pass.
