# Alpha entrance / Hideout implementation — 2026-10-04

## Implemented
- Main menu: longer-lens, near-eye-level full-body framing, restrained camera drift, readable grounded silhouette; no character rescaling or mesh/material edits.
- Hideout: shared compact shell, panelled floor, overhead services, equipment deck, workshop, operations console, partitioned personal corner, deployment door. Reuses existing presentation assets; newly authored geometry is environment-only and has no collision.
- All bays stay visible across camera destinations instead of disappearing when another section is selected.
- Overview exposes the base first. Existing campaign panel opens through Operations / Contracts; starter onboarding remains available and automatically appears when initial loadout selection is needed.
- Existing loadout, medical/ammo packing, supplies, contracts, deployment and return owners remain unchanged.
- Chinese copy added for the new navigation and signs.

## Verification
- Fresh isolated full regression: 58/58 scene tests PASS; acceptance_smoke PASS. No test assertions removed or weakened.
- Main exit 0.
- Cold import: 0 ERROR, 2 existing FBX Bad UTF-8 warnings (not warning-free).
- Existing automated Field Office route: 13/13 PASS, extraction/result reached. This route is not a completed combat mission or manual play.
- New rendered entrance check: 13 checks PASS (normal menu-to-base transition, contract toggle, five camera sections, valid preview and equipment UI visibility).
- Rendered campaign/UI and cross-process save/load: 43 write checks + 15 read checks PASS; exact profile IDs/progress/credits/materials preserved.
- Character asset comparison against previous verified snapshot: 170 shared assets/characters files, zero changed hashes.
- Actual screenshots inspected: menu, overview, equipment bay and personal corner. Other section captures retained.

Full verification directory:
`C:/Users/admin/AppData/Local/Temp/bunny_entrance_final_20261004`

Rendered campaign evidence:
`C:/Users/admin/AppData/Local/Temp/bunny_entrance_20261004/campaign_verified`

Screenshots:
`D:/bunny_team/art_source/alpha_entrance_20261004/`

## Files touched in this implementation
- scripts/presentation/slice/boot.gd
- scripts/presentation/slice/hideout.gd
- localization/zh_CN.json
- localization/zh_CN.tres (generated with existing localization builder)
- tools/campaign_probe.gd (opens the real contract drawer before UI checks; assertions retained)
- this report

Existing WIP was backed up before touching shared files. No reset, cleanup, staging, commit or push.

## Remaining quality work
This is the first implemented entrance/base composition, not final art acceptance or completion of Alpha. The interior still uses simple modular surfaces; operations/workshop detail, warm personal-area dressing, contextual lighting and menu pose direction can improve further. The large packing/supply panels remain existing functional interfaces. Character appearance and assets are untouched. No new combat, economy, inventory or save system was introduced.
