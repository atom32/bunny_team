# Alpha playthrough — 2026-10-04

Deliverable: alpha_playthrough.mp4, 1280x720, 60fps, 59.7 seconds, H.264/AAC audio, normal simulation speed.

Automated demonstration, not human play: existing streets_combat_run navigation/visible-enemy aiming and interaction APIs, isolated new profile, seed907; actual production enemies, weapon damage, ammo and collisions. No invulnerability. Starts in sortie, not full Boot onboarding. Captures objectives, firefights, cache inspection, extraction, debrief and return to Hideout. Treatment/economy loss/multi-sortie progression are NOT exercised by this clip.

Verified imported roof_aim_verified_20261003_174831 build. Relevant current controller/visibility/test source hashes matched before recording. Temporary recording driver exists only inside the isolated build, not production scripts/tests. Driver adds cache-panel dwell and Result/Hideout dwell and resumes focus-loss pause; production gameplay unchanged.

Final take4: exit0, run PASS, 29 shots, 1 reload, 9 kills, 10 moved enemies, 1 recovered item, mission complete, 450 reward. Result and Hideout frames inspected. Deterministic automatic aiming is much stronger than human play: zero damage here is not balance acceptance.

Failed attempts retained as logs: first take was focus-paused; take2/3 adapted test/result sequencing incorrectly (outcome created twice / not cached before commit). Final driver caches and reuses existing outcome, shows actual production debrief and return. No production fix was required. First ffmpeg binary lacked libx264 CRF; final encoding used available h264_nvenc and AAC.

No commit/push. Previous continuous development goal remains paused.
