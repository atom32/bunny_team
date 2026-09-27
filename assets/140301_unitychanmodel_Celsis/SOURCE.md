# Restored Unity-Chan animation texture dependencies

Migration repair only, 2026-09-25. These are **original TGA files**, not generated
stand-ins or redesigned character textures. The historical directory name is
required by the unchanged relative references in the existing FBX files.

- Author/publisher: Unity Technologies Japan K.K.
- Release page: https://unity3d.jp/unity-chan_contents/releaseNote.php?id=UnityChan&lang=en
- Download: https://unity3d.jp/unity-chan_contents/download.php?id=UnityChan&v=1.2.1
- Version: UnityChan 1.2.1, official release date 2017-02-15.
- Archive: UnityChan_1_2_1.unitypackage, 116356812 bytes.
- Archive SHA-256: `383723c5081b5d674ed9f95cb6518a3119a936ed98f9a52893898441d03a7dce`.
- Exact source paths: `Assets/UnityChan/Models/UnityChanShader/Texture/<filename>`.
- All six local animation FBXs match files in this archive by SHA-256.
- License: Unity-chan License 3.0 (current terms); not CC0. Full license/logo
  bundle is retained at `assets/characters/unitychan_battle/license/`.
- Guideline: https://unity3d.jp/unity-chan_contents/guideline.php?lang=en
- Attribution: © Unity Technologies Japan/UCL. Retain the license bundle with
  redistributed digital assets; no AI image-generation training/input use.

| Original file | SHA-256 |
|---|---|
| FO_SKIN1.tga | 3cf5fa4a636c2b60f4100c83ebd9d9f63fd632d8d2796a9db4079227bd7b3223 |
| face_00.tga | a7ca18718ddb6404a7ddcd717593b70d248285511a6dc38670342f54e1e6957f |
| eyeline_00.tga | 0da601df8457c855af953ee76e414d38fde39fa6d12b1cf94019e0ea1fbd2d80 |
| eye_iris_L_00.tga | ca54d4aafc2c5f43179d4dc3c5e10e8ae806264fb90e1b2d76eb5d67de12ebc8 |
| eye_iris_R_00.tga | 75c924ac7328f5e1b4b919d90046b4451d21b82215a937f711c896323bff7394 |

Keep all five Godot `.import` sidecars under version control. Without them, a
fresh 4.7.2 scan can preload active FBX scenes before texture importer settings
exist, emit load errors and extract redundant PNGs. Do not solve this by copying
`.godot` caches. With these source files/settings, a truly fresh import passed
with zero ERROR/WARNING; the FBX settings and binary files were not modified.
