# Pinned YARD editor integration

Upstream: https://github.com/elliotfontaine/yard-godot/releases/tag/v1.3.1
Tag: v1.3.1; commit a496be3dfa1279bfdd999950e0936eaac0d84fc3 (2026-10-08).
Only addons/yard is included; no demo, binaries or unrelated frameworks.
Local compatibility patch in plugin.gd: skip startup's forced icon reimport.
Godot 4.7.2 first-scene texture imports otherwise overlap its reimport progress task.
Native SVG import/scale remains enabled; database and editor behavior are unchanged.
Code MIT; plugin metadata/art notices retained under upstream_notices.
Use for editor authoring only. ContentDB and definition.id remain runtime authority.
Do not derive save IDs from filenames or YARD's default registry IDs.
