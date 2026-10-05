# Neon Bastion

A Godot 4.7.2 single-player high-angle urban extraction shooter, currently moving from a vertical slice toward [Alpha 0.1](docs/ALPHA_0_1.md). The current loop is `Opening / Menu -> Hideout -> Hanger -> Battle -> Result -> Hideout`. The full Alpha is still in progress.

After the tutorial, Operations offers Records Run or [Restore the Relay](docs/alpha_0_1/RELAY_OPERATION.md). Repair two sites under local noise/interruptible 12-second work, then extract; records remain optional for another exit. Both operations can advance the final base contract.

Keyboard/mouse bindings can be changed from Main Menu settings or pause, saved per device, and restored to defaults. Live prompts follow the chosen keys; existing controller bindings remain intact. See [controls](docs/alpha_0_1/CONTROLS.md).

Streets records now trigger a visible, pause/save-aware 25-second local alarm: nearby guards investigate the terminal while extraction stays available. See [event rules and verification](docs/alpha_0_1/RECORDS_ALARM.md); audio is still a placeholder, and full Alpha playtesting remains outstanding.

The first sortie now has an authored [First Mission](docs/FIRST_MISSION.md): select Bunny and AR + SMG, learn movement/aim/fire, defeat the first PMC, reload/search, investigate the terminal, choose extra salvage or extraction, then bring materials to Workshop for one permanent AR damage upgrade (20 → 22, +10%) and the second sortie. Its 8–10 minute newcomer pacing target still needs a human timing pass.

Armor now offers a real [mobility/protection tradeoff](docs/ARMOR_TRADEOFF.md): Recon Shell has 10% incoming damage reduction and weighs 3kg; Bulwark Plate has 40% reduction, weighs 8kg and moves slower. Equipment and battle HUD show Mobility, Protection and Carry Weight.

The armory contains a pistol, SMG, assault rifle, shotgun, sniper rifle, LMG and RPG launcher, with modern models, distinct firing/reload behavior and five ammunition calibers. Equip two owned weapons in the Hanger; Operations lets you choose exact ammunition totals including magazines; defaults are three magazines per equipped weapon, while remaining stock stays at base. New profiles receive finite AR/SMG equipment and supplies, not the whole arsenal; existing possessions are preserved without automatic weapon reissue. Workshop supply supports buying, selling and material barter. Death or abandonment loses carried equipment and ammunition, while base stock and credits remain safe. See [the Alpha rules](docs/ALPHA_0_1.md) and [weapon overview](docs/MODERN_ARSENAL.md).

The playable prototype now uses the imported Artoria Bunny Suit with its scarf hidden. The arena includes imported human PMC patrols and KITE drones, including their death presentations. See [the model trial and evidence](docs/ARTORIA_BUNNY_TRIAL.md) for visual and licensing limits.

The [original narrative production package](docs/narrative/README.md) contains twelve chapters, eight bosses, eight important adult women, eighteen key scenes, five relationship scenes, five endings and a complete first-chapter script. This is a design deliverable; those campaign chapters are not implemented in the current demo.

Recovery includes safe save replacement with backups, corrupt-save recovery and a shared pause/abandon/return/quit flow. Magazines consume carried ammunition and count toward weight. **Suspend** saves the current sortie; **Resume Sortie** restores its ammo, loot, enemies and mission state after restarting. Automatic checkpoints occur every two simulation seconds; schema 1/2/3 profiles migrate to schema 4 without losing possessions. See [recovery behavior, validation and limitations](docs/alpha_0_1/SUSPEND.md).

Medical supplies are actual carried items: buy dressings/medkits in Workshop or find them in Streets containers, then choose how many to pack in Operations. `H` uses a dressing (up to 40 HP / 2.5s); `J` uses a medkit (up to 100 HP / 5s). Remain still: movement, combat, damage or interaction interrupts treatment without consuming the dose. Completion spends one item and releases its carry weight. Pending treatment survives suspend/resume. See [medical rules and evidence](docs/alpha_0_1/MEDICAL.md).

Hideout Overview now has a five-step [persistent contract chain](docs/alpha_0_1/CAMPAIGN.md) after First Mission: recon extractions, material deliveries and survival-confirmed kills unlock medkit assembly, AP ammunition crafting and an equipment purchase discount. Claims consume actual warehouse materials and save rewards atomically; failure keeps previously earned progress/facilities, not carried gear. Result shows a preview until Return settles it. The final contract has an explicit endpoint while free sorties remain available. This is not yet the full Alpha content/pacing target.

Desktop rendering now uses Forward+ with 4× MSAA, a shared AgX lighting/reflection profile and restrained SSAO/glow. A Compatibility fallback remains available with `--rendering-method gl_compatibility`. Artoria remains a temporary model; its original textures/geometry were not rewritten by this rendering pass.

## Controls

Enemy perception now uses facing/range/line-of-sight and an acquisition delay. Walls and closed doors block sight even when camera occlusion makes them transparent. Footsteps, gunfire, doors, explosions and alarms create localized hearing observations; Shift precision walking is quieter. Enemies investigate, search last-known locations, then return to local patrol instead of tracking hidden players forever. Perception and footstep cadence persist with the sortie. See [rules and validation](docs/alpha_0_1/PERCEPTION.md). Streets now assigns guards, patrols, flankers and pressure units: they hold territory, choose reachable side firing positions or close distance using observed information, not stat buffs. Duties and flank plans survive suspend/resume. See [tactical roles](docs/alpha_0_1/TACTICS.md). Coordinated squads and sustained human balancing remain pending.

Player observation is independent of the high-angle camera: unobserved enemies, their markers and origin VFX are hidden behind real walls/doors or outside the aim-facing field of view. Heard shots/movement provide a short approximate bearing, not a live target marker. Amber reticle feedback shows centerline cover interception. A barrel crossing cover cannot start a shot behind that cover; firing still spends ammunition. See [visibility rules and evidence](docs/alpha_0_1/VISIBILITY.md).

- `WASD` / left stick: move
- Hold `Shift`: precision walk; sniper extends the observation view
- Mouse / right stick: aim independently
- Left mouse / right trigger: fire
- `R`: reload
- `Q`: switch primary / secondary weapon
- `H` / `J`: use carried dressing / medkit; press again to cancel treatment
- `E`: interact / extract
- `Space` / gamepad south button: dodge
- `Esc`: close loot/settings first, otherwise pause/resume; choose suspend/menu/quit to keep the current sortie, or explicitly abandon to accept carried-item loss
- `F11`: toggle fullscreen
- `M`: show/hide the street district route map

Display settings are available from Menu → Settings → Display and Esc → Display.
Windowed resolution options are 1280×720, 1600×900, 1920×1080, 2560×1440 and
3840×2160; fullscreen uses the desktop resolution. Preferences persist in
`user://display.cfg`, independently of the player save. The UI keeps its 1280×720
design scale and expands its anchors for taller/wider aspect ratios.

The playable UI supports Simplified Chinese and English. New main-menu launches
default to Chinese unless a language preference was saved. Switch from Settings
→ Language or Esc → Language; changes take effect immediately and persist in
`user://language.cfg`. Menu, loadout, tutorial, HUD, interaction countdowns, street
map, looting, Workshop and debrief text are localized. Item and mission IDs and
player saves remain language-independent. Noto Sans SC is bundled for Chinese
glyphs. Edit `localization/zh_CN.json`, then run `python3 tools/build_localization.py`
to rebuild the Godot translation resource and validate formatting placeholders.

Combat HUD now places vitals and the active weapon in the bottom corners; the
inactive weapon is a small switch hint. The first-mission tutorial and its route
choice sit along the left edge, and world tutorial markers use a small arrow.
Alert banners expire after three seconds. Street route details appear on the M
map rather than in a permanent large assignment panel.

Open `project.godot` in Godot 4.7.2 or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/xudawei/bunny_team --editor
```

Run all 48 regression scenes, five quit subprocess checks, cross-process/forced-termination sortie recovery, cross-process medical recovery and Main in an isolated copy and profile with:

```sh
python3 tools/verify_migration.py --godot /Applications/Godot.app/Contents/MacOS/Godot --output /tmp/bunny-verification-new
```

The output directory must not already exist. Weapon source and licensing records are linked from `THIRD_PARTY_ASSETS.md`.

### Spatial warehouse

The Hanger warehouse now uses a 12-column grid with item footprints, thumbnails baked from the equipped weapon/equipment scenes, and selected-item details. Drag items to free cells; press **R** while dragging or select **Rotate**. Double-click gear to equip, or drop it onto a compatible equipment selector. Drag the selector's **item icon** back into the warehouse to unequip; drag between occupied weapon slots to swap. Clicking the selector name still opens the equipment list. **Sort** repacks unequipped items.

Positions and orientation are part of the existing profile save. Older saves receive positions on opening; stale or overlapping positions are repaired without changing item ownership. Equipped instances remain owned by the same inventory and are displayed only in the equipment area. The warehouse grid grows vertically for recovered loot; the existing 1000 kg inventory limit remains the capacity rule. No nested containers or additional progression systems are introduced.

Validation: `godot --path . tools/stash_probe.tscn` drives mouse drags, R rotation, weapon swaps, armor equip, English/Chinese switching, save/reload and layout at 1280×720, 1920×1080 and 1440×900. Re-bake model thumbnails with `godot --path . tools/stash_icons.tscn`, then reimport assets.

After restoring the campaign workbench, Workshop offers [instance-owned weapon fittings](docs/alpha_0_1/FITTINGS.md): faster reload versus weight, or reduced enemy gunshot hearing versus weight/slower reload. Fits cost materials, persist with the exact gun and are lost with it; they are not permanent account buffs. Current regression: 51/51. This does not complete the full Alpha.

[Exact ammunition packing](docs/alpha_0_1/PACKING.md) is now part of normal deployment: partial stacks split atomically with the sortie checkpoint so loss never consumes the base remainder. Current full regression: 52/52; production UI-to-battle quantity and restart/loss checks pass. Full Alpha remains in progress.

Streets now has [regional supply pools](docs/alpha_0_1/REGIONAL_LOOT.md): pharmacy medicines, apartment fabric, office electronics/data and repair-shop parts. The M map shows tendencies, not actual loot or hidden actors. Existing sites and layout remain unchanged. Current full regression: 53/53.

[Streets exit choices](docs/alpha_0_1/EXIT_CHOICES.md) now connect a site objective to retreat planning: one assigned exit always permits early retreat, the other opens after recovering the current records. The map explains both conditions. Full regression: 54/54; human multi-sortie balance remains outstanding.
