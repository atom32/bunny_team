# Neon Bastion

A Godot 4.7.2 high-angle urban action-shooter demo. The current loop is `Opening / Menu -> Hideout -> Hanger -> Battle -> Result -> Hideout`.

The first sortie now has an authored [First Mission](docs/FIRST_MISSION.md): select Bunny and AR + SMG, learn movement/aim/fire, defeat the first PMC, reload/search, investigate the terminal, choose extra salvage or extraction, then bring materials to Workshop for one permanent AR damage upgrade (20 → 22, +10%) and the second sortie. Its 8–10 minute newcomer pacing target still needs a human timing pass.

Armor now offers a real [mobility/protection tradeoff](docs/ARMOR_TRADEOFF.md): Recon Shell has 10% incoming damage reduction and weighs 3kg; Bulwark Plate has 40% reduction, weighs 8kg and moves slower. Equipment and battle HUD show Mobility, Protection and Carry Weight.

The armory contains a pistol, SMG, assault rifle, shotgun, sniper rifle, LMG and RPG launcher, with modern models, distinct firing/reload behavior and five ammunition calibers. Pick any two weapons in the Hanger; matching ammunition is carried automatically with a bounded allowance, while extra stock stays at base. Existing saves receive the added arsenal on load. See [the weapon overview and validation](docs/MODERN_ARSENAL.md).

The playable prototype now uses the imported Artoria Bunny Suit with its scarf hidden. The arena includes imported human PMC patrols and KITE drones, including their death presentations. See [the model trial and evidence](docs/ARTORIA_BUNNY_TRIAL.md) for visual and licensing limits.

The [original narrative production package](docs/narrative/README.md) contains twelve chapters, eight bosses, eight important adult women, eighteen key scenes, five relationship scenes, five endings and a complete first-chapter script. This is a design deliverable; those campaign chapters are not implemented in the current demo.

The P0 recovery pass adds safe save replacement with backups, corrupt-save recovery, deployment errors that keep the UI available, and a shared pause/abandon/return/quit flow. Magazines now consume carried ammunition and count toward weight. Continue resumes the saved warehouse and loadout at base; an interrupted mission is not a mid-mission save. See the [updated demo audit](docs/DEMO_READINESS_2026-09-28.md).

Desktop rendering now uses Forward+ with 4× MSAA, a shared AgX lighting/reflection profile and restrained SSAO/glow. A Compatibility fallback remains available with `--rendering-method gl_compatibility`. Artoria remains a temporary model; its original textures/geometry were not rewritten by this rendering pass.

## Controls

- `WASD` / left stick: move
- Hold `Shift`: precision walk; sniper extends the observation view
- Mouse / right stick: aim independently
- Left mouse / right trigger: fire
- `R`: reload
- `Q`: switch primary / secondary weapon
- `E`: interact / extract
- `Space` / gamepad south button: dodge
- `Esc`: close loot/settings first, otherwise pause/resume; the pause menu offers return, abandon and quit
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

Run all 37 regression scenes, five quit subprocess checks and Main in an isolated copy and profile with:

```sh
python3 tools/verify_migration.py --godot /Applications/Godot.app/Contents/MacOS/Godot --output /tmp/bunny-verification-new
```

The output directory must not already exist. Weapon source and licensing records are linked from `THIRD_PARTY_ASSETS.md`.

### Spatial warehouse

The Hanger warehouse now uses a 12-column grid with item footprints, thumbnails baked from the equipped weapon/equipment scenes, and selected-item details. Drag items to free cells; press **R** while dragging or select **Rotate**. Double-click gear to equip, or drop it onto a compatible equipment selector. Drag the selector's **item icon** back into the warehouse to unequip; drag between occupied weapon slots to swap. Clicking the selector name still opens the equipment list. **Sort** repacks unequipped items.

Positions and orientation are part of the existing profile save. Older saves receive positions on opening; stale or overlapping positions are repaired without changing item ownership. Equipped instances remain owned by the same inventory and are displayed only in the equipment area. The warehouse grid grows vertically for recovered loot; the existing 1000 kg inventory limit remains the capacity rule. No nested containers or additional progression systems are introduced.

Validation: `godot --path . tools/stash_probe.tscn` drives mouse drags, R rotation, weapon swaps, armor equip, English/Chinese switching, save/reload and layout at 1280×720, 1920×1080 and 1440×900. Re-bake model thumbnails with `godot --path . tools/stash_icons.tscn`, then reimport assets.
