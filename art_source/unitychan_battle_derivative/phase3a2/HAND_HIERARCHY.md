# Unity-Chan actual hand hierarchy

Inspected from the normalized Blender master, not inferred from a generic rig.

Both sides: ForeArm → Hand. Hand is the wrist/palm orientation control; there is no independent palm joint. Forearm rotation influences wrist approach. Each finger has its own 1 → 2 → 3 → 4 chain. Joints 1–3 have skin weights; terminal 4 has none. Do not curl the terminal bone as if it deformed a phalanx.

The hand mesh supports individual thumb and four-finger posing. Anatomical curl directions must use joint head-to-child-head vectors: imported FBX bone tails do not follow those vectors.

| Bone | Parent | Weighted vertices (>0) |
|---|---|---:|
| `Character1_LeftHand` | `Character1_LeftForeArm` | 435 |
| `Character1_LeftHandThumb1` | `Character1_LeftHand` | 53 |
| `Character1_LeftHandThumb2` | `Character1_LeftHandThumb1` | 50 |
| `Character1_LeftHandThumb3` | `Character1_LeftHandThumb2` | 64 |
| `Character1_LeftHandThumb4` | `Character1_LeftHandThumb3` | 0 |
| `Character1_LeftHandIndex1` | `Character1_LeftHand` | 95 |
| `Character1_LeftHandIndex2` | `Character1_LeftHandIndex1` | 56 |
| `Character1_LeftHandIndex3` | `Character1_LeftHandIndex2` | 67 |
| `Character1_LeftHandIndex4` | `Character1_LeftHandIndex3` | 0 |
| `Character1_LeftHandMiddle1` | `Character1_LeftHand` | 106 |
| `Character1_LeftHandMiddle2` | `Character1_LeftHandMiddle1` | 51 |
| `Character1_LeftHandMiddle3` | `Character1_LeftHandMiddle2` | 64 |
| `Character1_LeftHandMiddle4` | `Character1_LeftHandMiddle3` | 0 |
| `Character1_LeftHandRing1` | `Character1_LeftHand` | 107 |
| `Character1_LeftHandRing2` | `Character1_LeftHandRing1` | 45 |
| `Character1_LeftHandRing3` | `Character1_LeftHandRing2` | 72 |
| `Character1_LeftHandRing4` | `Character1_LeftHandRing3` | 0 |
| `Character1_LeftHandPinky1` | `Character1_LeftHand` | 95 |
| `Character1_LeftHandPinky2` | `Character1_LeftHandPinky1` | 56 |
| `Character1_LeftHandPinky3` | `Character1_LeftHandPinky2` | 64 |
| `Character1_LeftHandPinky4` | `Character1_LeftHandPinky3` | 0 |
| `Character1_RightHand` | `Character1_RightForeArm` | 435 |
| `Character1_RightHandThumb1` | `Character1_RightHand` | 53 |
| `Character1_RightHandThumb2` | `Character1_RightHandThumb1` | 50 |
| `Character1_RightHandThumb3` | `Character1_RightHandThumb2` | 64 |
| `Character1_RightHandThumb4` | `Character1_RightHandThumb3` | 0 |
| `Character1_RightHandIndex1` | `Character1_RightHand` | 95 |
| `Character1_RightHandIndex2` | `Character1_RightHandIndex1` | 56 |
| `Character1_RightHandIndex3` | `Character1_RightHandIndex2` | 67 |
| `Character1_RightHandIndex4` | `Character1_RightHandIndex3` | 0 |
| `Character1_RightHandMiddle1` | `Character1_RightHand` | 106 |
| `Character1_RightHandMiddle2` | `Character1_RightHandMiddle1` | 51 |
| `Character1_RightHandMiddle3` | `Character1_RightHandMiddle2` | 64 |
| `Character1_RightHandMiddle4` | `Character1_RightHandMiddle3` | 0 |
| `Character1_RightHandRing1` | `Character1_RightHand` | 107 |
| `Character1_RightHandRing2` | `Character1_RightHandRing1` | 45 |
| `Character1_RightHandRing3` | `Character1_RightHandRing2` | 72 |
| `Character1_RightHandRing4` | `Character1_RightHandRing3` | 0 |
| `Character1_RightHandPinky1` | `Character1_RightHand` | 95 |
| `Character1_RightHandPinky2` | `Character1_RightHandPinky1` | 56 |
| `Character1_RightHandPinky3` | `Character1_RightHandPinky2` | 64 |
| `Character1_RightHandPinky4` | `Character1_RightHandPinky3` | 0 |
