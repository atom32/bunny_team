# Weijin campus geographic database

Retrieved 2026-10-23 for a metre-scale reconstruction of Tianjin University's
Weijin Road campus. This is an offline dataset, not a streamed basemap.

## Data and permission

- **© OpenStreetMap contributors.** `campus.json` is a derivative geographic
  database made available under **ODbL 1.0**. Copyright/attribution:
  https://www.openstreetmap.org/copyright . License text:
  https://opendatacommons.org/licenses/odbl/1-0/ and
  `licenses/ODbL-1.0.txt` in the repository.
- Redistributable original OSM response: `art_source/weijin_geography/campus.osm.gz`.
  Request, SHA256, derived hash and counts: `SOURCE.json` in this directory.
- **Mapzen Terrain Tiles**, accessed 2026-10-23 from
  https://registry.opendata.aws/terrain-tiles/ . Tile `skadi/N39/N39E117.hgt.gz`.
  Regional SRTM/GMTED terrain data courtesy of the **U.S. Geological Survey**.
  Source attribution and terms are preserved in `TERRAIN_ATTRIBUTION.md`.
  The original HGT archive is retained beside the OSM archive.
- Existing CC0 Poly Haven grass, paving, asphalt and roofing are reused with
  their existing source records in `assets/environment/campus/SOURCE.md` and
  `assets/environment/polyhaven_streets/SOURCE.md`.
- The university's public map and campus description were consulted for the
  named campus/lakes, not copied into textures or redistributed:
  https://yx.tju.edu.cn/jztd/cx/201806/t20180602_307319.htm and
  https://yx.tju.edu.cn/tdfc/xyfgwjl/ . No Google/Baidu satellite tiles are traced.

## What is measured / what is not

- Boundary: OSM `way/48165383`; WGS84 tangent-plane projection with local
  x=east, z=south, y=up. One Godot unit is one metre. No horizontal compression,
  no latitude/longitude treated as metres, no GCJ-02 offset, no vertical exaggeration.
- Source coordinates/corner counts are preserved in all retained ways: **467**
  building outlines (428 with vertices inside campus; 39 context outlines),
  **242** road ways including the surrounding collar, **4** lakes, **54** mapped
  green areas and **43** sport/playground outlines. A way is not necessarily a
  complete road or a distinct physical building.
- OSM does not supply heights for 455 retained building ways. They have explicit
  `height_source: estimated`; 12 use mapped storeys. Facades, roofs, planting,
  lane paint and most road widths are illustrative, not photogrammetry.
- Elevation is regional ~1 arc-second (~30 m) data, filtered with a source 5×5
  median then one 3×3 local-grid mean to reduce building/canopy/quantisation
  artefacts. A 12 m mesh or 24 m sampled grid **does not create 12/24 m survey
  accuracy**. The datum is subtracted only for local-world numerical stability.
- Original lake plan outlines are retained. Water levels, bank walls and depths
  have not been surveyed; the rendered bank treatment is an explicit estimate.
- Only 2 individual trees are mapped. Other trees are separately named
  `Illustrative*` in the scene and do not constitute an inventory of actual trees.
- No real interior survey/floorplan is available. The buildings are solid
  exterior shells. Legacy fictional interiors/quest coordinates are not stretched
  or silently claimed to belong to the real campus.

The geographic database is independently licensed; it does not relicense game
code, characters or other existing assets. Preserve these source files, database
access, attribution and license notice when distributing the map.

## Art revision 2

The campus-wide architectural, foliage, bank and street-furniture pass reuses the
project's existing procedural deciduous leaves and CC0 Poly Haven surface assets.
There are no new satellite textures, downloaded buildings, stock trees or changed
OSM coordinates. Scene `roof_art_records`, `tree_art_placements` and
`art_placements` distinguish source labels/roof tags from inferred art.
`PHYSICS_BASELINE.json` records the independently rebuilt first-stage collision
fingerprint. The visual additions do not create gameplay collision or real
interior floorplans. See `docs/streets/WEIJIN_ART_2026-10-23.md` for scope and proof.
