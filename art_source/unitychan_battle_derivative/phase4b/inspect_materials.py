"""Read original Unity YAML/GUIDs; verify the runtime profile, never rewrite art."""
from pathlib import Path
import json, re, hashlib, struct

D = Path(__file__).resolve().parent
R = D.parents[2]
P = R / 'art_source/unitychan_battle_legacy/official_1_1'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
guid = {}
for meta in P.rglob('*.meta'):
    match = re.search(r'^guid: (\w+)', meta.read_text(encoding='utf-8'), re.M)
    if match: guid[match[1]] = meta.with_suffix('')
profile = read(R / 'assets/characters/unitychan_battle/presentation/material_profile.json')
records, checks = {}, {}
mapping = {'base_texture':'_BaseMap', 'shade1_texture':'_1st_ShadeMap',
           'shade2_texture':'_2nd_ShadeMap', 'grade_texture':'_ShadingGradeMap'}
color_mapping = {'base_color':'_BaseColor', 'shade1_color':'_1st_ShadeColor', 'shade2_color':'_2nd_ShadeColor'}
float_mapping = {'shade1_step':'_1st_ShadeColor_Step', 'shade2_step':'_2nd_ShadeColor_Step',
                 'shade1_feather':'_1st_ShadeColor_Feather', 'shade2_feather':'_2nd_ShadeColor_Feather'}
for path in sorted(P.rglob('*.mat')):
    text = path.read_text(encoding='utf-8')
    floats = {k:float(v) for k,v in re.findall(r'^    - (_\w+): ([-\d.eE+]+)$', text, re.M)}
    colors = {k:[float(v) for v in re.findall(r'[rgba]: ([-\d.eE+]+)', value)]
              for k,value in re.findall(r'^    - (_\w+): \{(r: [^}]+)\}', text, re.M)}
    textures = {}
    for slot, block in re.findall(r'    - (_\w+):\n((?:      [^\n]*\n)+)', text):
        tex_guid = re.search(r'm_Texture: \{[^}]*guid: (\w+)', block)
        if not tex_guid: continue
        resolved = guid.get(tex_guid[1])
        textures[slot] = {'guid':tex_guid[1], 'path':str(resolved.relative_to(P)) if resolved else None}
        if resolved:
            meta = Path(str(resolved)+'.meta').read_text(encoding='utf-8')
            textures[slot].update(sha256=sha(resolved), sRGBTexture=int(re.search(r'sRGBTexture: (\d)',meta)[1]),
                                  scale=re.search(r'm_Scale: (.*)',block)[1], offset=re.search(r'm_Offset: (.*)',block)[1])
    records[path.stem] = {'path':str(path.relative_to(P)), 'sha256':sha(path), 'textures':textures,
                          'floats':floats, 'colors':colors, 'keywords':re.search(r'm_ShaderKeywords: (.*)',text)[1]}
    name = 'Battle_'+path.stem
    if name not in profile: continue  # Bundled melee weapon deliberately excluded.
    params = profile[name]
    for key,original in mapping.items():
        source = textures.get(original,{}).get('path')
        runtime = params.get(key)
        checks[name+'/'+key] = (not runtime and not source) or bool(runtime and source and sha(R/runtime.removeprefix('res://'))==sha(P/source))
    for key,original in color_mapping.items(): checks[name+'/'+key] = params[key]==colors[original]
    for key,original in float_mapping.items(): checks[name+'/'+key] = params[key]==floats[original]
    checks[name+'/active_subset'] = all(floats.get(k,0)==v for k,v in {
        '_CullMode':2,'_Is_NormalMap':0,'_HighColor_Power':0,'_RimLight':0,'_MatCap':0,'_GI_Intensity':0,
        '_Set_SystemShadowsToBase':1,'_Tweak_SystemShadowsLevel':0,'_Is_1st_ShadeColorOnly':0,
        '_Is_LightColor_Base':1,'_Is_LightColor_1st_Shade':1,'_Is_LightColor_2nd_Shade':1}.items())
raw = (R/'assets/characters/unitychan_battle/battle_presentation.glb').read_bytes()
gltf = json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
meshes = {}
for node in gltf['nodes']:
    if 'mesh' not in node: continue
    mesh = gltf['meshes'][node['mesh']]
    meshes[node['name']] = {'primitives':[{'attributes':{k:gltf['accessors'][v] for k,v in p['attributes'].items()},
        'indices':gltf['accessors'][p['indices']], 'material':gltf['materials'][p['material']]['name']}
        for p in mesh['primitives']], 'morph_weights':mesh.get('weights',[]),
        'skin_joint_names':[gltf['nodes'][i]['name'] for i in gltf['skins'][node['skin']]['joints']] if 'skin' in node else []}
result = {'checks':checks, 'materials':records, 'glb_meshes':meshes,
          'note':'Reports only. Texture hashes must equal original PNGs. Original Unity project color-space/lighting not shipped.'}
(D/'material_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(len(checks),'source-to-profile checks;',all(checks.values()))
raise SystemExit(0 if all(checks.values()) else 1)
