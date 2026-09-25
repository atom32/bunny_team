# Replaceable Asset Interface

Gameplay data, the controller, and the current character presentation are separated so the visual asset can be replaced without rewriting combat.

## Current character pipeline

- The visible character is the official Unity-chan Battle Costume FBX at `assets/characters/unitychan_battle/unitychan_battle.fbx`.
- The render skeleton has 328 bones, including secondary hair, skirt, mantle, and costume bones.
- A hidden 140-bone Unity-chan animation FBX provides the runtime pose.
- `RetargetModifier3D` transfers shared-bone rotations to the render skeleton.
- Idle, walk, and run clips are loaded from separate official FBX files and normalized into one runtime `AnimationLibrary`.
- The bundled melee weapon is hidden because this project supplies shooter-specific weapons.

The runtime creates these stable socket names: `Chest`, `ShoulderL`, `ShoulderR`, `Backpack`, `HipL`, `HipR`, `HandL`, and `HandR`. Rifle and SMG visuals are currently stowed on the upper back so the neutral Unity-chan animations do not drag a weapon through the floor.

## Replacing the character

1. Import the replacement FBX or GLB and its animation source into Godot.
2. Update `CHARACTER_SCENE`, texture constants, and `CHARACTER_ANIMATION_SCENES` in `scripts/player/player_controller.gd`.
3. Keep the eight socket names stable. Bone names may change, but the `_add_bone_socket` mappings must be updated.
4. Keep local `+Y` as up. The current Unity-chan mesh faces local `+Z`; the retarget wrapper rotates it to the controller convention.
5. Preserve the `CombatAndroidModel`, `CharacterRetarget`, and `CharacterAnimationPlayer` node names used by smoke tests.
6. Run `res://tests/acceptance_smoke.tscn` and visually inspect Hanger and Battle.

The controller, health, collision, loadout data, shooting, and UI do not reference individual mesh parts.

## Equipment replacement

Each item consists of:

- one GLB or `PackedScene` whose local origin is its mount point;
- one `EquipmentDefinition` or `WeaponDefinition` resource with a stable content `id`;
- a `socket_name` matching a player socket;
- optional movement, damage, fire-rate, projectile, and blast-radius values.

Replacing a weapon model only requires changing the `scene` field in its `.tres` resource. Weapon scenes may expose a `Muzzle` marker; firing falls back to the controller aim origin if it is absent.

## Scale and orientation

- Godot units are meters.
- Controller forward is local `-Z`.
- Character up is local `+Y`.
- Weapon muzzle nodes should be named `Muzzle` and point toward local `-Z`.
- Apply transforms before FBX or GLB export.

## License boundary

Unity-chan files remain subject to the Unity-chan License 3.0. The complete license archive is retained under `assets/characters/unitychan_battle/license/`. Do not use these assets as AI image-generation training or input data, and preserve the license package when redistributing the digital asset files.
