param(
    [string]$IsolatedProject,
    [string]$Godot = 'E:/Godot/Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
if (-not $IsolatedProject) { throw 'Supply the Phase 3A isolated validation project, NOT the production project.' }
$project = (Resolve-Path -LiteralPath $IsolatedProject).Path
if ($project -eq 'D:\bunny_team') { throw 'Do not stage the probe into production.' }
if (-not (Test-Path -LiteralPath "$project/assets/characters/unitychan_battle/battle_presentation.glb")) { throw 'Expected derivative validation copy not found.' }
Copy-Item -LiteralPath "$PSScriptRoot/static_probe.gd" -Destination "$project/tools/phase3a1_static_probe.gd"
Copy-Item -LiteralPath "$PSScriptRoot/poses.json" -Destination "$project/tools/phase3a1_poses.json"
$env:BUNNY_EVIDENCE = $PSScriptRoot
$env:APPDATA = Join-Path (Split-Path $project) 'static_userdata'
$env:LOCALAPPDATA = Join-Path (Split-Path $project) 'static_localdata'
& $Godot --path $project --rendering-method gl_compatibility --resolution 1280x720 --script res://tools/phase3a1_static_probe.gd *> "$PSScriptRoot/static.log"
$result = $LASTEXITCODE
"GODOT_EXIT=$result" | Add-Content -LiteralPath "$PSScriptRoot/static.log"
Get-Content -LiteralPath "$PSScriptRoot/static.log"
exit $result
