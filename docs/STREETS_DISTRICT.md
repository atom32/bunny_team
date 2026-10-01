# Old Town / Streets-inspired district

The requested first implementation is playable: an original residential/shop district, randomized deployment and route assignments, indoor loot, and a camera that fades occluders while retaining its angle. The visual direction uses worn masonry/plaster, muted colours, shop fronts, courtyards, service routes and abandoned cars. It is a procedural prototype, not finished Tarkov-level art. No Tarkov assets were copied.

## Deployment and routes

After the completed First Mission, presentation mode deploys to street_district / streets_recon. The original First Mission and legacy fixture remain available.

- Six perimeter spawn candidates, chosen per sortie RNG.
- Four named extraction candidates; the two farthest from the selected spawn are assigned and usable. Others are invisible and reject extraction.
- Records in one of four interiors, plus a survey in the opposite courtyard.
- Four indoor high-value loot points, eight indoor ordinary candidates and six outdoor ordinary candidates. Ordinary points have a 65% enable chance.
- Initial PMC candidates must be at least 24 m from the player. Nearby reserve candidates remain inactive; no reinforcement event is authored for this district.
- Four enterable shops with two entrances each, partitions and furniture. Background residential blocks are closed.
- M toggles a schematic map showing the player, task assignments and assigned exits. Gameplay continues while it is open.

Office: archive folders, wood floor, filing cabinet and desk/monitor. Pharmacy: tile floor, medicine cartons and bottles. Lobby: checker stone floor, mailboxes, parcels and bench. Workshop: stained concrete, parts shelves, tools and tires. Solid furniture participates in collision and navigation.

## Camera

The battle camera retains its initial basis as its position follows the player/aim. Three camera-to-character rays fade obstructing architecture and tree canopies to transparency 0.88, then restore original mesh transparency. Collision remains active. Camera-only canopy Areas do not block ordinary firing rays; trunks do.

## Visual implementation and sources

Residential frontages have varied plaster/brick surfaces, plinths, pilasters, floor bands, balconies, doors, address signs, awnings and boarded windows. Original sedans include sloped cabin glass, wheels, mirrors, lamps and rust details; their cabin collision blocks shoulder-height fire. Eight trees use tapered branches, instanced leaves and fallen leaves. Roads include curb grime, damp/oil patches and debris.

Nine original 1K Poly Haven maps provide diffuse, OpenGL normal and roughness for Asphalt 02, Wall Bricks Plaster and Painted Plaster Wall. Authors Rob Tuytel and Amal Kumar; CC0. Exact URLs/hashes: assets/environment/polyhaven_streets/checksums.json. Physical tile scales, mipmaps, normal import flags and anisotropic filtering are applied. Attribution: assets/environment/polyhaven_streets/SOURCE.md and THIRD_PARTY_ASSETS.md.

## M4 grip adjustment

The supplied M4 uses runtime scale 0.9 and a calibrated offset that moves it forward from the torso. Final display-skeleton IK fits the right palm to the inclined grip and the left palm to the handguard without changing local bone positions. Corrected right-hand handedness closes the fingers around the grip. Four left-finger targets and thumb targets improve wrapping; left contacts release during reload. Reload lowering and RPG reach are calibrated for Bunny's shorter arms.

MCO clips remain portrait samples; gameplay locomotion still uses the existing animation source. Original character/weapon files are unchanged.

The idle CPU skin-surface probe checks actual weighted vertices against 8758 M4 triangles. Both palms have vertices within 0.1 mm of the surface; the right thumb's nearest surface distance improved from 42.1 mm to 2.7 mm. Rest-coordinate reconstruction error is 0.061 mm. These unsigned distances establish proximity, not absence of penetration or complete finger-pad/stock contact. Current close-up: m4_grip_right.png.

## Verification (2026-10-01)

- 24 seeded layouts cover all six spawns and paths to tasks, assigned exits and every enabled loot point. Unassigned extraction rejects interaction. Tests also cover actual objective/extraction transitions, M toggle, car/trunk collision, canopy bullet pass-through, occluder fade/restoration and fixed camera basis.
- Actual player capsule traversal passes one representative route through tasks, another indoor high-value loot location and an exit. This route test disables input processing/AI and excludes enemies from collision; it verifies architecture traversal only.
- Six combat-active runs (seeds 1, 2, 3, 5, 8, 11) cover all six spawns, all four records interiors, all four high-value loot interiors and all four exit locations. Each finishes both objectives, recovers an item, reloads and extracts; recovered item instances reach the in-memory warehouse through the actual outcome commit. Runs fire 25–31 shots and kill 8–10 PMCs each. No failures.
- Combat runs retain actual Input movement/aim/fire, player physics, enemy AI/collision, hitscan damage, ammunition and cooldowns. No invulnerability or direct enemy damage calls. Pickup/task/extraction contracts are invoked at reached locations; loot-window buttons are not exercised. The bot aims perfectly and takes no damage in these runs, so this does not validate human difficulty or fun. No user save is written.
- Seven weapons pass idle/walk/full-reload/scaled-dodge contact checks (28 weapon/state combinations), preserving local bone positions and finite transforms.
- Fifteen static rifle samples and First Mission/modern arsenal regressions passed earlier in this implementation.
- Actual battle-scene renders include overview, four interiors, facade, vehicle, tree and route map. Navigation has 3230 polygons, below the default 4096-poly search limit.

Evidence: docs/streets/*.log and *.png. combat_seed_*.log records the six routes; dynamic_grip.log and hand_surface.log record the final contact checks. combat_run.log/combat_visual.log and combat_*.png retain the earlier graphical seed-907 route.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/streets_layout_test.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --fixed-fps 60 --path . tests/streets_walk_test.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --fixed-fps 60 --path . tests/streets_combat_run.tscn -- --combat-seed 1
/Applications/Godot.app/Contents/MacOS/Godot --path . tools/streets_probe.tscn
/Applications/Godot.app/Contents/MacOS/Godot --path . tools/dynamic_grip_probe.tscn -- --right-hand-detail
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tools/hand_surface_probe.tscn
```

Further quality work remains in bespoke building/prop assets, landmark differentiation, full finger/stock contact and human combat balancing. These are explicitly outside the evidence provided by the integration tests.
