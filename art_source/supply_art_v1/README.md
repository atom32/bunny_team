# Field supplies — offline authoring

Scope and integration: `docs/SUPPLY_ART_PACK_V1.md`. Provenance: `assets/props/supply_art_v1/SOURCE.md`.

The source `build_assets.gd` refuses `D:/bunny_team` and requires `BUNNY_ART_AUTHORING=isolated`. Run it only in a separate imported project with isolated APPDATA/user://:

```powershell
$env:BUNNY_ART_AUTHORING='isolated'
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path '<isolated copy>' --headless --script 'D:/bunny_team/art_source/supply_art_v1/build_assets.gd'
```

Review and copy only `assets/props/supply_art_v1/` and `scenes/props/supply_art_v1/` back. Native resources are batched by material to avoid a separate production draw/node for every stitch or component. Production never runs this source.

The separate graphical probe renders real props, a native Godot contact sheet, real pickup close-ups, the production warehouse and the resident supplier UI. Set `BUNNY_SUPPLY_EVIDENCE` to an external absolute directory. `BUNNY_SUPPLY_ICONS=isolated` also renders the sixteen PNG icons in the isolated copy and skips production inventory fixtures. Normal evidence runs leave icons unchanged. Copy the generated `.png.import` settings with accepted icons so cold imports can resolve them before autoloads.

`evidence/` is intentionally Git ignored. It retains final captures/logs/manifests locally; early failed import/fixture logs remain in the external session directory, not acceptance evidence. Close-up pickup images hide the existing oversized world labels only in the probe; no production label behavior changes. Tests and screenshots use isolated finite fixtures, not the user's profile and not human acceptance.
