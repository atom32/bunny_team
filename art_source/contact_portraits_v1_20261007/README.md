# Contact portraits V1 — 2026-10-07

Generated using the built-in image_gen tool, one original illustration per adult contact. Full prompts are preserved in prompts.json. This first pass is anime-realism with a strong realistic material/rendering influence; it is a visual prototype rather than locked final character art.

Project assets (original generated RGBA files, copied without modifying pixels):
- assets/ui/contacts/tang_kui_v1.png — source exec-c49dae99-59c5-480d-8085-67ab691c9603.png
- assets/ui/contacts/shen_yanshuang_v1.png — source exec-c2f9f9ee-feed-42f7-a635-da59f1161e65.png
- assets/ui/contacts/su_mi_v1.png — source exec-2848634a-f23c-4ea7-9ca9-38ada1efd595.png

Generated originals remain in /Users/xudawei/.codex/generated_images/01a10b98-7f80-7721-8bf3-21315c65b63c/. Each asset is 1122×1402 with alpha. No existing artwork was overwritten. ContactDefinition now references the three project PNGs. ContactPortrait renders the full image in a 208×220 region and uses an AtlasTexture face crop from the same texture for compact publisher avatars. No separate avatar bitmap, inventory, save field, quest or model was created. Missing art still uses the explicit existing placeholder.

Verification: isolated cold import /tmp/bunny-contact-art-20261007 (0 errors, 2 existing FBX metadata warnings); campaign and Q01/Q02/Q04 regression scenes pass. preview.log records 25/25 real graphic checks for alpha, image mounting, publisher face crop and 720p layout. Screenshots of all three contact trade and quest pages are in captures/. The graphic preview uses a valid Q01-completed display fixture to expose Tang Kui's publisher avatars; it does not grant rewards or save fabricated progress.

Visual observations: character identity cues, uniform illustration lighting and transparent background integrate with the charcoal/olive menus; realistic detail dominates this V1. Tang Kui's orange workwear and curly undercut, Shen Yanshuang's silver hair/medic gear, and Su Mi's black hair/headset/workwear remain recognizable. Tactical workwear styling can be refined later without affecting contact ownership or transaction rules.
