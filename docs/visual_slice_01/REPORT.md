# Visual Slice 01 — Weapon & Field Office Art Upgrade

Status: **Visual Upgrade Partially Complete — Asset Quality Limited**

The bounded art integration is implemented and regression-clean. The selected CC0 assets provide a coherent low-poly sci-fi pass, but the current kit/VRM combination, basic lighting and stylized launcher do not justify claiming final production art quality. Direct WASD Field Office manual acceptance is still outstanding. No second map or gameplay framework was added.

## Weapon Assets

All three use Kenney's [Blaster Kit 2.1](https://kenney.nl/assets/blaster-kit), **CC0 1.0**, binary glTF (`.glb`) wrapped by the existing weapon `.tscn` scenes. Commercial use/modification is allowed; attribution is optional and retained. Original package license, download URL and SHA-256 are kept beside the assets.

| Identity | Final selected asset | Usable | Mesh triangles | Presentation |
|---|---|---|---:|---|
| AR / Assault Rifle | `blaster-e.glb` | Yes | 802 | Stock, magazine, optic and long barrel; original AR muzzle/grip coordinates retained |
| SMG / Vector SMG | `blaster-g.glb` | Yes | 618 | Compact receiver; original identity and socket retained |
| Rocket / Breach Launcher | `blaster-o.glb` | Yes | 664 | Stylized four-tube silhouette; existing single-projectile behavior/ammo unchanged |

Model-facing axis, scale and fit live in the three weapon scenes. `WeaponDefinition.scene` remains the only identity-to-scene mapping. No model paths or weapon-ID lists were added to PlayerController. Procedural placeholder model builders were replaced by imported geometry; existing muzzle flash behavior remains.

SMG/Rocket previously appeared upright with raised arms. The existing CharacterCombatRig now also tracks socket visuals using its existing pose/IK targets. Their original parent sockets and `uses_combat_rig` values remain unchanged. `has_weapon()` continues to distinguish the existing combat-mounted AR from the legacy socket weapons, preserving production muzzle, recoil and reload paths. No animation framework was added.

## Environment Assets

External: **one** [Kenney Space Station Kit 1.0](https://kenney.nl/assets/space-station-kit), CC0 1.0, 16 selected GLBs. This includes 6 building modules and 10 interior prop types. No other environment pack or HDRI was downloaded.

- Building modules: wall, detailed wall, window wall, floor, detailed floor, closed double door.
- Interior props: table, chair, computer screen, computer system, wall display, flat container, tall container, wall switch, pipe, pipe bend.
- Project-authored additions: roof/fascia, entrance canopy and sign, sealed glazing, locker, file shelf/binders, waste bin, desk lamp, papers, keyboard and ceiling luminaires.
- Existing assets reused: VRM avatar, Unity-Chan Idle_Gun, all enemies, Terminal, loot, extraction, existing sun/Environment and the surrounding authored arena.
- Materials: one shared palette shader, separate office/floor/weapon palette materials, plus a small family for metal, wall, roof, glazing, luminaires and markings. Both palettes are 512 × 512 px. No large textures.

Only 19 GLBs were retained across environment and weapons; source meshes total **337,612 bytes**. The unselected assets and downloaded archives were kept outside the project.

## Field Office

Exterior: modular facade, sealed window panels, full roof at distance, roof vent, canopy, lintel/jambs/thresholds, mounted Field Office sign and entrance light. The visual door follows the existing rotating DoorLeaf.

Interior: dark tiled floor, wall panels, ceiling soffits and 2 luminaires, reception desk/chair/computer, wall display/power panel, storage containers, locker, shelf and restrained desk accessories. Furniture stays against the edges; the tested west combat/traversal lane stays clear.

Cover/Barrier: original shapes and locations remain. Panel inserts, braces, caps and identification bands dress the existing MeshInstance3D nodes. The Barrier's new children inherit its visibility and disappear on destruction. The existing courtyard obstacle inside the room is dressed as a service counter without changing its body.

Lighting: the existing sun and ambient Environment are reused; the office uses **6 local unshadowed lights** in total for ceiling, entrance, terminal and window fill. GL Compatibility remains unchanged. No GI, ray tracing or heavy post-processing was introduced.

Roof: the full visual shell cuts away on approach/inside. The original four-child ceiling frame remains, with slimmer visual members and visible interior soffits/lights. This is a presentation-only cutaway for the current high-angle camera.

Physics: original Field Office StaticBody3D/CollisionShape3D blocks and BoxShape3D resources are **byte-identical** to the pre-change snapshot. No gameplay placement in `prototype_arena.tscn` changed. Window panels are sealed decorations, not new traversal or firing openings. Imported OfficeArt contains no physics bodies.

## Hanger

- Existing Idle_Gun and AnimationTree ping-pong retained.
- Preview starts at a readable three-quarter angle; existing slow rotation remains.
- Key light reduced; new weapon models are shared with Gameplay.
- Warehouse name/category/weight/equipped-state display retained and verified. No inventory feature or UI redesign was added.

## Tests

```text
ALL TESTS: 33/33 PASS, exit code 0, no ERROR / SCRIPT ERROR / : FAIL text
ACCEPTANCE_SMOKE: PASS
RESULT_RETURN_TEST: PASS
PRESENTATION_GAMEPLAY_TEST: PASS
WORLD_TRAVERSAL_TEST: PASS
VISUAL_SLICE_ASSETS_TEST: PASS
MAIN HEADLESS: exit code 0
```

The 33 include the original 32 scenes plus `visual_slice_assets_test`. Of these, 31 contain assertions; the two existing visual acceptance scenes are scripted smoke flows, not automated visual judgments. Those two now auto-advance only in headless mode and clean up on completion, eliminating their prior forced-exit resource errors. Interactive Enter behavior remains unchanged.

The additional test checks Hanger selection/identity, imported render geometry, preserved combat-vs-socket path, active ping-pong idle, Warehouse equipped state, absence of decorative collision, roof visibility, and Barrier child-visual cleanup. It also produces optional actual OpenGL captures.

Main forced shutdown still reports an **ObjectDB warning for AudioStreamWAV/AudioStreamPlaybackWAV**; verbose inspection identifies the playing Music stream. Main exits 0 and reports no script/resource ERROR. Audio lifecycle was not expanded into this art task.

All pre-existing definition `.tres` resources are byte-identical to the handoff snapshot. Combat numbers, ammunition, enemy stats, inventory/profile/loadout data, missions, threat, extraction and sortie lifecycle were not changed.

Logs: `test_logs/results.json`, individual test logs, `main.log`, `presentation_render.log`, `visual_slice_render.log`.

## Manual Acceptance

| Check | Status | Evidence / scope |
|---|---|---|
| Hanger | VERIFIED | Actual native game window: idle/rotation visible; Primary changes update model, name and Warehouse equipped marker; Deploy works |
| AR | VERIFIED | Actual Primary selection in Hanger; imported barrel/stock orientation checked; non-headless gameplay close-up also inspected |
| SMG | VERIFIED | Actual Primary selection in Hanger; compact model and held pose checked; non-headless gameplay close-up inspected |
| Rocket | VERIFIED | Actual Hanger model checked; production Battle Q switch displays Breach Launcher and its model; non-headless close-up inspected |
| Field Office Enter/Exit | NOT VERIFIED | The deterministic non-headless production-input route passes with captures, but a direct WASD manual traversal was not completed |

The native UI session used the same installed Godot 4.6.3 executable in a temporary, locally signed application wrapper solely to distinguish its game window from the already-open editor. The project executable/data/configuration were not exported or changed for the check. UI equipment changes stayed in memory; the session was closed without committing/saving an Outcome.

Native keyboard taps successfully triggered Q, but did not sustain movement for the physics input polling. The direct manual attempt remained near deployment and ended in player death; **it is not counted as Field Office manual acceptance or a successful manual combat route**. No headless result is labeled as manual acceptance.

## Captures

- `captures/office_exterior.png`: presentation camera, complete roof/facade.
- `captures/office_interior.png`: presentation camera, roof cutaway and furniture.
- `captures/hanger_assault_rifle.png`, `hanger_smg.png`, `hanger_rocket_launcher.png`.
- `captures/gameplay_assault_rifle.png`, `gameplay_smg.png`, `gameplay_rocket_launcher.png`: fixed-camera real Battle/player render fixtures.
- `captures/01_outdoor_closed_door.png` through `05_back_outdoors.png`: existing production camera/input route.

The close-up/overview cameras belong only to the capture test. Production Battle camera settings are unchanged. Enemy AI is paused in deterministic capture fixtures; the native UI Deploy session used normal AI.

## Reproduce

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team res://tests/visual_slice_assets_test.tscn --quit-after 1200

VISUAL_SLICE_CAPTURE_DIR=/Users/xudawei/bunny_team/docs/visual_slice_01/captures /Applications/Godot.app/Contents/MacOS/Godot --path /Users/xudawei/bunny_team res://tests/visual_slice_assets_test.tscn --quit-after 1200

PRESENTATION_CAPTURE_DIR=/Users/xudawei/bunny_team/docs/visual_slice_01/captures /Applications/Godot.app/Contents/MacOS/Godot --path /Users/xudawei/bunny_team res://tests/presentation_gameplay_test.tscn --quit-after 1200
```

Stop here. Remaining acceptance is direct Field Office play and an art-quality review, not another map, asset bulk download, gameplay tuning or a new system.
