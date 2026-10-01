# First Mission / Home Signal

2026-09-30. The normal Boot → Hideout route now offers one authored first sortie.
Select **Bunny**, select **AR + SMG**, then accept the operation. Older schema-1
profiles retain their inventory and receive the first-mission prompt.

Manual Hanger selection also qualifies: put AR in PRIMARY WEAPON and SMG in
SECONDARY WEAPON, open MISSION TERMINAL, then CONFIRM DEPLOYMENT. Deployment
validates the equipped weapons rather than requiring the Overview SELECT BUNNY
button's bookkeeping flag. Successful first deployment records that selection.

The authored encounter reuses the existing South Access / Field Office geometry,
but has a separate area and mission definition. It contains one initial PMC and
one alarm response of two patrols plus one heavy. Subsequent sorties use the
existing operation; there is no campaign, mission generator, or quest framework.

| Beat | Player action and consequence |
| --- | --- |
| Base | Select Bunny, confirm AR + SMG and deploy. |
| Move / aim / shoot | Travel 3m, change aim direction, then fire a real round. The PMC remains hidden, non-colliding and inactive until the training shot. |
| First PMC | Defeat the patrol. Its death position receives a supply case with one guaranteed Salvage Core. |
| Reload / search | Complete a real reload; open the case with E and TAKE the core. A reload or pickup performed early still counts. |
| Terminal | Follow the destination marker and compass bearing to the Field Office. E begins an 8s investigation; leaving interaction range cancels it. |
| Alarm | The terminal completes the mission and starts a 12s response countdown. Combat and the countdown remain live during the route choice. |
| First choice | Extract with one core, or visit the northern cache for two additional cores. Choosing salvage never locks extraction. |
| Extraction | E opens the return link. Stay within interaction range for 8s; leaving cancels. Enemies remain active. |
| Debrief | Shows exact recovered cores and their warehouse destination. Return saves the settlement and opens Workshop. |
| Workshop | Spend one warehouse core on the single AR weapon upgrade. Future sorties deal 22 base damage instead of 20 (+10%). The second-sortie loadout button appears. |

## P1 / One growth system

The only purchase is **1 Salvage Core → Workshop → AR damage +10%**. It is a
permanent, one-time upgrade of the AR weapon type, works in either weapon slot,
and applies to future sortie snapshots. It does not alter shared weapon resources
or increase SMG damage. Carried capacity stays at 100kg. Workshop shows 20 → 22;
loadout details show the new damage and battle HUD marks the AR with +10% DMG.
There are no additional levels, recipes, armor/backpack upgrades, or skill trees.

Earlier profiles that purchased the P0 Field Pack upgrade migrate that purchase
to the AR upgrade without another material charge; the obsolete capacity bonus is
removed. New saves persist only `ar_damage_upgraded` for this purchase.

## Pacing target

Target **8–10 minutes for a new player**, including equipment selection, learning
controls, finding the terminal, weighing the optional detour, and installing the
upgrade. This is a design target, **not a measured human-playthrough result**.
Experienced players can finish sooner; tutorial progress follows actions and
there are no artificial ten-minute waits. Only investigation and extraction use
short, cancellable timers. A first-time player timing pass remains necessary to
tune travel, combat and reading time.

## Persistence and failure

The profile adds three optional booleans (`bunny_selected`,
`first_mission_completed`, `ar_damage_upgraded`) without changing schema 1.
Completion is published only after a completed first mission is durably settled.
Failure or abandonment leaves the first sortie available and recovers no loot.
The upgrade stages its cost and flag in a copied profile; a failed save changes
neither materials nor damage. Repeated return or upgrade cannot duplicate
loot or charge twice. Reloading preserves progress and the upgraded weapon damage.

## Verification

`tests/first_mission_test.tscn` exercises both routes through the actual battle,
terminal, extraction and Result → Hideout transition. It verifies preparation
buttons, real ammo consumption/reload, hidden and active encounters, cancellation,
exact loot counts (1 / 3), save failure atomicity, repeat safety, progress reload,
death retry, and a real next-sortie AR hitscan dealing 22 damage with SMG damage unchanged. It drives encounters programmatically;
it does not measure human difficulty or elapsed gameplay time.

The test passed in both headless and graphical Forward+ runs. Graphical captures
were inspected for base, training, route choice, debrief and Workshop layout.
Ten relevant existing regression scenes also passed: profile, save, sortie
session, outcome, result return, loadout decisions, threat escalation, objective
world, P0 flow and P0 recovery. Logs and screenshots are in `docs/first_mission/`.
The migration runner now expects 38 test scenes; a full cold migration run was
not performed for this change.

P1 validation additionally passed damage-packet and weapon-switching regressions,
plus profile/save/loadout/session checks. Both branch tests verify a real upgraded
AR hit for 22 damage, an unchanged SMG hit, unchanged shared weapon data and
100kg cargo capacity. The updated graphical Workshop capture was inspected.

Manual Hanger deployment regression (2026-10-01): actual weapon-selection signals, Mission Terminal, Confirm Deployment and entry into the playable First Mission pass without clicking Select Bunny. Full First Mission regression also passes. Evidence: hanger_manual_deploy.log and deploy_regression.log. The focused test has two ObjectDB cleanup warnings at process exit; its route assertions all pass.
