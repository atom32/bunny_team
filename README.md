# Neon Bastion

A small Godot 4.x high-angle urban action-shooter prototype. It implements the complete `Hanger -> Battle -> Result -> Hanger` loop from `Handoff.md` with replaceable placeholder geometry.

## Controls

- `WASD` / left stick: move
- Hold `Shift`: precision walk
- Mouse / right stick: aim independently
- Left mouse / right trigger: fire
- `Space` / gamepad south button: dodge

Open `project.godot` in Godot 4.6 or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/xudawei/bunny_team --editor
```

Run the automated project smoke test with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team res://tests/acceptance_smoke.tscn --quit-after 1200
```

The placeholder asset contract and socket list are documented in `docs/asset_interface.md`.
