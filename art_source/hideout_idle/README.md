# Pixiv idle — Hideout presentation

Source: https://github.com/pixiv/ChatVRM/blob/b542aa00e19dccf9fc48ba340cf7eee011d2329a/public/idle_loop.vrma
Author/publisher: pixiv Inc.
License: MIT, Copyright (c) 2023 pixiv Inc. Full license retained here and with source.
Access: 2026-10-04.
Original SHA-256: ace95ba6dcc0bdf2ed1081c002332b4184441117c8d543b6f642b3d2c5cf99be

The repository distributes the animation under its MIT license with no separate animation terms found. This does not license any character model. Only the animation was downloaded; no ChatVRM application, AI service, avatar or generated character is used.

Conversion: art_source/hideout_idle/convert.py reads original glTF rotation tracks, accumulates the source hierarchy and resamples 22 humanoid global rotations at 30 Hz. Original duration 10.37508297s. Translation/scale are not transferred, preserving the target's limb lengths and proportions. Runtime adapter performs rest-space A/T and forward-axis conversion; unmapped fingers/accessories retain their authored local rest. No manual per-bone pose tuning, new character mesh, texture, AI processing or generated motion.

Runtime scope: scripts/presentation/slice/hideout_idle.gd, only installed by Hideout. Menu/Overview/Operations/Workshop/Rest use unarmed idle and hidden equipped presentation. Hanger inspection restores the existing weapon preview, rig and animation tree. Inventory/equipment remain owned and equipped; nothing is unequipped or saved by this adapter.

This is a gentle unarmed standing idle, NOT a newly authored seductive, seated, leaning or stretching animation. Those require suitable authored clips and separate contact acceptance.

## Implementation / 2026-10-04
- Production menu and Hideout non-equipment sections now use the sourced unarmed idle. The equipment bay keeps the existing armed preview.
- Added a Hideout-owned adapter, not a PlayerController branch. It temporarily suspends preview combat animation/IK and restores their original state when viewing equipment. Preview replacement after loadout edits is handled explicitly.
- No automatic character turntable in off-duty mode. Only the existing camera drift remains.
- Original duration/rhythm retained; translation/scale deliberately excluded from retargeting. No finger animation was present in the source; original target finger rest is retained (no invented finger curls).
- New hideout_idle_test validates playback, no bone scaling, no turntable, rig/weapon restoration, preview rebuilding and unchanged profile data. Existing UI initializes stash layout before the idle test baseline is taken.
- Test inventory increases from 58 to 59 by this real new test. Existing 58 tests/assertions are unchanged; verification runner's inventory guard updated explicitly.
- 1280x720 rendered entrance/section check: 13 checks PASS.
- 12-second/720-frame loop capture: maximum consecutive left-upper-arm quaternion step 0.07913 degrees. This metric only checks continuity, not artistic quality. Four still frames were inspected for posture/contact/deformation.
- Evidence: evidence/idle_preview.mp4 and idle_060/300/600/660.png.
- No gameplay, PlayerController, inventory, save schema, character geometry, textures or material changes. No AI generation. Existing WIP retained; no commit/push.

### Remaining
This completes a natural unarmed standing-idle baseline, not the full living-area animation set. Sitting, leaning, stretching or a more characterful/flirtatious idle have NOT been implemented. The current clip is subtle and neutral. Section changes restore poses directly rather than blending between unrelated animation sources; no cinematic transition is claimed.

### Final regression
Fresh isolated build: C:/Users/admin/AppData/Local/Temp/bunny_idle_final_20261004
59/59 test scenes PASS (58 existing + new Hideout idle contract test).
Cross-process medical/campaign/checkpoint/save readers PASS. Main exit 0.
Cold import 0 ERROR / 2 existing FBX Bad UTF-8 warnings.
170 character asset hashes unchanged versus the previous entrance checkpoint.
No commit or push.
