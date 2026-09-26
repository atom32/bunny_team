# Unity-chan Player runtime presentation

Official Unity Technologies Japan Battle Costume 1.1 derivative, Unity-chan License 3.0.
Copyright Unity Technologies Japan. No endorsement. Public release authorization NOT
ASSESSED; no commercial clearance. No AI use. Existing license PDFs/credit logos retained
in assets/characters/unitychan_battle/license and art_source/unitychan_battle_derivative/License.

Authoritative derivative: art_source/unitychan_battle_derivative/battle_master.blend and
battle_presentation.glb. Runtime GLB byte-identical to validated derivative, 37359 triangles,
24 skinned meshes, head3474 triangles. Official source unchanged. Phase3A3 pose/finger data,
Phase3B material/mount profiles; scripts/presentation/unitychan consumes those data.

validate_visual_integrity checks complete skinned geometry and head; implementation names
stay in adapter, not gameplay/test node contracts. Semantic mounts unchanged. Gameplay
shot-origin parity: phase3d/contract/comparison.json, 270 samples exact.
