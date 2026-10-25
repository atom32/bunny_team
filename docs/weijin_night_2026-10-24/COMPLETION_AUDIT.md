# Completion audit — 断电夜线

Objective: 敌人刷新点布置和任务安排，任务指引，还有局内光影，可破坏物品，loot。

| Requirement | Current implementation | Authoritative verification |
| --- | --- | --- |
| Enemy placements/spawns | Four source-ground units, five authored indoor units; guards vs moving patrols, view cone/LOS, locked telegraph; one drop and no reload respawn | 71-check suite verifies clear spawns, fixed counts, return visits, covered/exposed fire, actual damage; normal-input tour fights all nine |
| Mission arrangement | Recover fuse, power/download network record, handover, extract; optional pool plant cache | Native/headless tour completes four stages and optional cache through actual doors and six stair climbs; real loot bank and Profile compared |
| Mission guidance | Stage tracker, N brief/bag, bearing and distance, physical-floor route dashes, M road/floor maps, stairs/exit guidance | 43-check tours validate connected road and furniture-clear floor guidance; actual native map/floorplan screenshots; 71-check suite verifies overview cannot strand actor in aerial mode |
| In-run lighting | Night environment/moon/fog, shadow-casting practical lights, dim indoor fill, powered network illumination; daylight restored | Forward+/Compatibility render fixtures; same-camera network dark/powered PNGs; 71 checks verify environment ownership including same-room entry, real light energy change and restoration |
| Destructibles | Six authored physical crates/wood barrier, independent structural health, one-time debris/loot and released collision | 71-check suite verifies count, structural hits, disabled collider and no duplicate loot; two boxes physically shot in the normal-input full tour |
| Loot | Physical E pickups, ammo/medical consumption, weighted bag, actual partial pickup and discarding, separate task pouch, atomic extraction ledger | 71 checks include production ground remainder, reload, med cancellation, file reload, corrupt protection, failed-write retry, no duplicate extraction, death loss and bank preservation; full tour banks actual recovered parts and drives |

## Verified current results

- Full normal-input tour: native and headless **43 checks / 0 failures**, approximately **4.08km**, **9 encounters**, **6 actual stair climbs**, optional cache and successful extraction. No actor placements, damage packets or mission flags injected in this test.
- Component/physics fixtures: **71 checks / 0 failures** in headless, native Forward+ and native Compatibility. These explicit fixtures are not claimed as traversal evidence. Compatibility did not run the full 4km tour.
- Existing rain relay: **48 full-flow / 83 unit checks**; space compatibility **44**, headless art **39**, entry **18**, old UI **26**, old streets layout **0 failures**, source geography **5 tests**.
- Exterior source data, physics baseline, baked geographic world, legacy static campus, street district and checkpoint hashes match their earlier immutable archives. Current source fingerprints stored alongside this audit.
- Entire legacy Profile compared before/after night success and failure. The new operation never initializes or rewards the old sortie economy.

## Boundaries

Only the marked props are destructible. The ledger is independent; it currently records extracted salvage rather than providing trading/crafting/permanent upgrades. Mid-run tasks and unextracted loot do not persist across process exits. The indoor layouts and inspection robots are fictional game design. No new EXE, minimum-spec guarantee, real audio certification or human-playtime claim.

The new component suite is tests/campus_night_operation_test.tscn. The pre-existing tests/campus_night_test.gd/.tscn retain HEAD content with the native Windows line endings and their original CAMPUS_NIGHT_TEST also passes; its log and preserved hashes are archived separately.
