# Phase 5 — Vertical Slice Presentation

Status: **PASS**. Base `main @ 7ddb981`; Godot 4.7.2. No push.

## Play
Normal project launch now enters `scenes/presentation/slice/boot.tscn`.
First boot: 24-second opening (Enter / Skip), then Main Menu. Later boots skip it.
START / CONTINUE opens Hideout; LOADOUT opens its Hanger bay. The five lower
buttons select camera destinations. MISSION TERMINAL → CONFIRM DEPLOYMENT
starts the existing sortie. In battle: E opens a supply case; TAKE calls the
original pickup API; E / Escape closes it. Combat remains live while looting.

## Implemented
- Main Menu: existing Unity-Chan/Hanger backdrop, camera drift, ambience, real
  Music/SFX settings. Opening/settings use a separate `user://presentation.cfg`.
- Hideout: existing Hanger/loadout owner plus Operations, Workshop, Personal
  Quarters. Cutaway cameras and navigation, no new economy or base simulation.
- Deployment: 5-second equipment/transport cue, skippable; fade and 1.8-second
  arrival camera. Early skip during an inbound fade cannot trap deployment.
- Loot: hinged supply cases around existing rolled pickups, contents, real cargo
  capacity, TAKE/empty/success feedback and audio. No new loot table/rolls.
- Extraction: short camera moment within the existing 2.4-second result delay;
  flight-recorder transition, debrief, successful commit/save, welcome-home fade.
- Debrief: actual objectives, survival, carried/recovered cargo, loot, kills and
  damage. Failure labels do not claim lost cargo was recovered.
- Arena: north extension from 112×112 to 112×168 meters, residential courts,
  market alley and industrial service yard, crane/awnings/signs/crosswalks.
  Three old north roads now connect to the extension. Original mission points,
  spawn rules and core geometry remain intact; north/side boundaries and the
  existing navigation mesh were extended, not rescaled.
- Audio: reused existing cues/loop for menu, base, deployment, case open/pickup,
  extraction, debrief and return. No new audio framework or dependencies.

## Verification
- Unmodified existing suite: **33/33 PASS**. Main exit **0**.
- Fresh isolated copy/cache: **0 ERROR / 0 WARNING**; runtime hashes in
  `cold_import/runtime_hashes.json` match this final working snapshot.
- Two serial 1280×720 OpenGL input/API routes: **64/64 each**. Both finish all
  mission objectives, fight normal KITE-07 AI, loot, take damage, use primary +
  Rocket, reload, dodge, extract, debrief, commit and return to Hideout.
- Rifle route: 25 shots / 4 kills / 15 damage. SMG: 44 shots / 3 kills / 9 damage.
- Two real-profile COPY save → process exit → relaunch → load checks: **PASS**;
  complete gameplay serialization preserved. Live personal save is untouched.
- Audio settings / Loadout entry / UI bounds / early deployment skip: **8/8**.
- North navigation connector paths and district composition: **4/4**.
- Visual review: opening/menu, all base bays, loot open/taken, arrival, production
  combat, extraction, mission-complete debrief and return screenshots.
  Arrival is additionally captured after fade-out (`arrival/arrival.png`).
  Graphical automation is not described as manual playtesting.

## Scope / limitations
Player, Unity-Chan geometry/textures/materials/source, KITE-07, weapon definitions,
combat/movement/AI/projectile rules, inventory/save schema, extraction/commit and
identity ownership are unchanged. No character generation or remodeling. Existing
33 tests were not edited. A before-file hash comparison leaves only the seven
intentional existing-file edits; all unrelated pre-existing WIP is preserved.
`project.godot` stages only the main-scene change, not the pre-existing feature
version WIP. Handoff.md and prior reports remain untouched.

This is an internal first-pass presentation, not final production art: Workshop
and Rest are presentation-only; new northern districts have no new mission/loot
or spawn distribution. Audio reuses placeholder cues. Direct standalone Hanger/
Result entry still supports existing component tools; Boot enables the full route.
Known main fast-exit warning: **2 ObjectDB instances**, no script/runtime errors.
Run graphical drivers serially: an early overlapping preview run spoiled mouse
input; serial complete routes passed (raw first-attempt log retained in ignored
`local/`). No gameplay change was made to compensate.

## Files / reproduce
- New runtime: `scripts/presentation/slice/*.gd`, three matching presentation scenes.
- Existing edits: project main scene; Battle adds presentation child; GameState
  presentation transitions; AudioDirector contexts; UrbanArena extension calls/
  boundaries; BattleHUD capacity bounds; ResultUI layout.
- `run_regression.py`: existing 33 scenes + Main, isolated userdata.
- `run_production_routes.py`: full route and separate persistence probe; requires
  a private copy in `local/original_profile.json`. Saves are ignored.
- `menu_contract_probe.gd`, `district_probe.gd`: narrow verification helpers.
- Cold import uses existing `tools/verify_migration.py --import-only` with a NEW
  output directory outside the checkout. This pre-existing WIP tool is not part
  of this commit.
- `comparison.html`: curated visual evidence. Raw reports/logs alongside captures.
