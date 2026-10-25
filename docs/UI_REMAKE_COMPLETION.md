# Remake completion gates

Objective: finish the player-facing UI/UX remake, not merely apply a new palette.
Keep combat, finite inventory, narrative progression and save ownership intact.

## Required scope / authoritative proof

| Surface | Required outcome | Proof required |
| --- | --- | --- |
| Menu/settings/base | Clear entry, current task, consistent navigation, usable preferences | Rendered bilingual screens and normal-start/settings/navigation tests |
| Equipment/storage/packing | Inspect then replace, real comparisons, quantities and shortages | Native selection/replacement/packing tests and conservation/save-failure regressions |
| Contacts/trade/delivery | Active contact/tab visible; costs, availability and delivery feedback clear | Bilingual trade/quest captures; finite buy/sell/delivery and failure tests |
| Combat HUD/tutorial/map | Objective, health, ammo/reload, medical state and controls legible; centre clear | Actual gameplay renders; resize, bindings, disclosure/no-click-fire and combat-feedback tests |
| Loot/backpack | Carried versus cache separated; live danger explicit; weight/exchange guards visible | Native take/exchange/swap/close and conservation tests; rendered full/empty/overweight cases |
| Result | Survival versus objective completion, rewards still pending, recoveries/losses clear; return always reachable | Success/failure/abandon/debrief renders plus save/retry/return/once-only settlement tests |
| Pause/recovery/feedback | Consistent style, safe primary action, overflow scrollable, no hidden destructive choice | Bilingual real menu captures; pause/resume/suspend/recovery/feedback tests |
| Narrative/transitions/training | Same visual language without altering story timing or callbacks | Representative actual rendered scenes and story/training regressions |

## Cross-cutting acceptance

- Existing uncommitted work is preserved; no schema/economy/AI/level changes.
- Chinese and English, 1280x720 plus larger desktop/aspect-ratio checks.
- Long content is scrollable rather than clipped over another action.
- Keyboard focus, rebinding hints, click isolation and disabled reasons work.
- No fabricated numbers, automatic purchases/rewards, or settlement on inspection.
- No new forced decorative animation; state changes remain immediate.
- Screenshots are actual Godot rendering; fixtures are labeled, not human-play claims.
- A requirement is complete only after inspecting its current code and matching
  rendered/runtime evidence. A narrowly passing test does not prove all surfaces.

Status at creation: first two slices verified; remaining gates are open.

## Final audit — 2026-10-23

**All UI-remake gates above are proven complete for the current desktop source.**
The following is scope-specific evidence, not a claim that the whole game has
completed content/art/release or human acceptance. No new EXE/ZIP was requested
or generated. Existing uncommitted gameplay and motion work remains intact.

Machine records: [validation.json](ui_remake_2026-10-23/complete/validation.json).
UI source fingerprints: [ui_source_sha256.json](ui_remake_2026-10-23/complete/ui_source_sha256.json).
Full isolated logs/captures: `D:/tmp/bunny_ui_remake_full_20261023/`.

| Gate | Current implementation inspected | Matching proof / verdict |
| --- | --- | --- |
| Menu/settings/base | `boot.gd`, `hideout.gd`: clear entry, task/preflight, safe scrolling briefs and separate actions | Native base 77 checks; bilingual menu/overview/section renders; fresh entry and complete normal-start loop. PASS |
| Equipment/storage/packing | `hanger_ui.gd`, `loadout_inspector.gd`, `medical_packing.gd`: explicit destination, real stats, shortage, stock and focus/scroll retention | Native loadout 50 checks; ammo/medical/alarm conservation, save failures, stash and packing regressions. PASS |
| Contacts/trade/delivery | Selected contact and trade/request tab visible; unaffordable total disabled with reason; real transaction feedback; delivery viewport retained | Bilingual trade/quest renders; campaign 187, campus packing 44 and supply/transaction coverage; current guidance native 264 checks includes contact shortcuts. PASS |
| Combat/tutorial/map | Large magazine and separate reserve; actual reload progress, empty-magazine action, medical progress, low-health cue; no duplicated current request in map hint | Final completion UI 154 native checks, real scene renders, map input open/close, HUD multi-aspect bounds, combat feedback and medical tests. PASS |
| Loot/backpack | Fixed live-combat header; carried/cache columns, exact weight/shortfall, contextual take/exchange/swap and keyboard focus | Native cache 101 checks; reviewed bilingual full/overweight and empty renders; cargo exchange and ownership regressions. PASS |
| Result | Scrollable report with fixed pending-save/return footer, survival separate from objective success, real recovery/loss/reward preview; pending/error survives language rebuild | 778 headless/786 native debrief checks; success/failure/abandon/retry renders; actual return and save-failure/once-only settlement tests. PASS |
| Pause/recovery/feedback | Paper/ink menu sheet, bounded scroll, safe focus, persistent controls and local-only form | Bilingual pause/display/controls/language/feedback/recovery/error renders; p0 recovery/flow, checkpoint, feedback and bindings regressions. PASS |
| Narrative/training/transitions | Shared graphite/paper/signal themes, bounded transition captions, high-contrast current training station, unchanged story callbacks/timing | Training native 182, workshop 109, ending 15 checks per rendered run, Chinese and English captures; complete first-sortie transition path. PASS |

### Cross-cutting verification

- 35 relevant headless suites completed successfully. Final new UI coordinator:
  119 headless checks and 154 native rendered/input checks. Reports retain exact
  per-run counts; repeated runs are not counted as extra gameplay.
- Complete fresh first-sortie loop: 84 checks, six actual weapon-fire events,
  normal movement/interactions, physical loot, extraction, saved return and first
  upgrade. Independent process: three checks load the earned profile correctly.
  This synthetic-input route is not presented as a human playtest.
- Chinese/English layouts visually inspected. Bounds verified at 1280x720,
  1440x900, 1920x1080, 1920x1200 and 2560x1080 where applicable.
- Translation source/resource/rebuild tests: three passed. `git diff --check`
  passed for changed remake sources. No new mandatory decorative animation.
- Cut-corner resource fill/edge are exported so style duplication retains their
  values; a regression assertion guards the discovered white-button fallback.
- Supplemental route testing first exceeded the runner's 65s wall limit, then
  exposed a stale `Walk`-only assertion. The current sixteen-direction player
  uses aim-relative strides. The test now samples states only while precision
  input is held and requires a real precision stride plus run/idle. A completed
  504m route rerun passes; no movement or animation runtime was changed.
- Briefing assertions now verify actual scroll-viewport bounds and global
  separation from its contact action. They do not compare coordinates belonging
  to different parents. Existing request/state/conservation checks remain.

### Reviewed screen artifacts

All files below are actual Godot rendering in `ui_remake_2026-10-23/complete/`:

`menu.png`, `overview.png`, `warehouse.png`, `contacts.png`, `combat.png`,
`map.png`, `loot.png`, `loot_empty.png`, `debrief_story.png`,
`debrief_earned.png`, `pause.png`, `recovery.png`, `training.png`, `ending.png`.

`debrief_earned.png` is from the normal first-sortie route. Other staged previews
use explicit finite fixtures; their values are not fabricated player progress.
The `.gdignore` keeps documentation screenshots out of game asset imports.
