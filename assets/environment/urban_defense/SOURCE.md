# Security barrier — Phase 4C

- Origin: project-local authored environment geometry. No downloaded asset pack.
- Authoring source: `art_source/phase4c/build_barrier.py`.
- Master: `art_source/phase4c/security_barrier.blend` (Blender 5.2.2 LTS).
- Runtime: `security_barrier.glb`; wrapper: `scenes/presentation/urban_defense/security_barrier.tscn`.
- Units: meters; Blender Z-up → glTF Y-up, `export_yup=true`; identity root, ground origin.
- 1 mesh, 1,100 triangles, 5 simple Principled materials, 0 textures, 0 animations, 0 bones.
- Bounds (Godot): 2.798 × 0.897 × 0.579 m, wholly inside the existing 2.8 × 0.9 × 0.58 m collider.
- No collision or gameplay nodes in the exported asset or wrapper.
- Eight instances replace only the existing cover's visible box. Their original mesh and all physics remain intact.
- Numbers/hazard stripes/panels are geometry; `SEC` is Blender's bundled text converted to mesh. No font file redistributed.
- No character, Unity-Chan source, external character texture or AI workflow is involved.
- Hashes and export metadata: `art_source/phase4c/barrier_export.json`.
- Scope: internal project use; this is not an overall commercial-release license audit.
