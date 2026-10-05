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
