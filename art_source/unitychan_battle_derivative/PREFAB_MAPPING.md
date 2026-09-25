# Official Prefab mapping

Generated from original prefab and Unity .meta file IDs; material/texture GUIDs in build_report.json and recovery_manifest.json.

| Prefab object | FBX mesh | Material | Derivative |
|---|---|---|---|
| headNose | headNose | face3_main | included |
| hairSide | hairSide | Unity2016_C_Hair_Spow | included |
| eyeHighLightShape | eyeHighLightShape | face3_main | included |
| shoesExtend | shoesExtend | Unity2016_C_Add | included |
| horn | horn | Unity2016_C_Body | included |
| hairFront | hairFront | Unity2016_C_Hair_Spow | included |
| 01_kohaku_A_head | head_Def | face3_main | included |
| legs | legs | Unity2016_C_Skin | included |
| frill | frill | Unity2016_C_Add | included |
| eyeBall | eyeBall | face3_main | included |
| cuffs | cuffs | Unity2016_C_Body | included |
| kwep_exebreaker | kwep_exebreaker | Unity2016_Wep | excluded bundled melee weapon; use existing game weapon contract |
| hairBack | hairBack | Unity2016_C_Hair_Spow | included |
| belt | belt | Unity2016_C_Add | included |
| skin | skin | Unity2016_C_Skin | included |
| hairUnder | hairUnder | Unity2016_C_Hair_Spow | included |
| scarf | scarf | Unity2016_C_Body | included |
| pants | pants | Unity2016_C_Body | included |
| shirt | shirt | Unity2016_C_Body | included |
| collar | collar | Unity2016_C_Body | included |
| wristband | wristband | Unity2016_C_Body | included |
| body | body | Unity2016_C_Body | included |
| shoes | shoes | Unity2016_C_Body | included |
| armcover | armcover | Unity2016_C_Add | included |
| mantle | mantle | Unity2016_C_Add | included |

24 SkinnedMeshRenderer + 1 MeshRenderer/MeshFilter (nose). After excluding bundled melee weapon: 24 meshes.
Separate head and rigid nose follow Character1_Head via equivalent one-bone skin; all original deforming meshes retain weights.
Head prefab rest-world transform is identity within floating-point tolerance. No duplicated face or discarded nose.
