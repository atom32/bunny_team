"""Trace selected local-build roots, imported dependencies, script class symbols and paths.

No source art changes, implicit license grants, scene execution or network requests.
The result is an explicit local-only export inventory, not a legal clearance report.
"""
import argparse
from collections import deque
import hashlib
import json
from pathlib import Path
import re


EXCLUDED = ('art_source/', 'docs/', 'tests/', 'tools/', 'addons/', 'scripts/debug/',
            'scenes/debug/', 'scenes/tools/', 'scenes/art_showcase/', 'resources/editor_catalogs/')
TEXT_TYPES = {'.gd', '.tscn', '.tres', '.gdshader', '.gdshaderinc'}
# Both filename-based runtime lookups are present in production scripts. Keep whole families.
DYNAMIC_FAMILIES = {'res://assets/animations/mocap_online_rifle/':'.tres', 'res://scenes/props/supply_art_v1/':'.tscn'}
SHOWCASE_ROOTS = {'res://scenes/presentation/bunny_master/master_shot.tscn'}
VERIFY_ABSENT = ('res://assets/characters/vrm_avatar/avatar_sample_a.glb',)
LICENSE_BUNDLES = {'res://assets/characters/unitychan_battle/':'assets/characters/unitychan_battle/license'}
TOKENS = re.compile(
    r'(?P<comment>\#[^\n]*)|(?P<string>r?(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'))'
    r'|(?P<identifier>\b[^\W\d]\w*\b)'
)


def script_tokens(text):
    """Ignore comments and quoted UI prose when finding global class references."""
    identifiers, strings = set(), []
    for match in TOKENS.finditer(text):
        if match.lastgroup == 'identifier':
            identifiers.add(match.group())
        elif match.lastgroup == 'string':
            token = match.group()
            if token.startswith('r'): token = token[1:]
            quote = 3 if token.startswith(('"""', "'''")) else 1
            strings.append(token[quote:-quote])
    return identifiers, strings


def allowed(path):
    return path.startswith('res://') and not path.removeprefix('res://').startswith(EXCLUDED)


def trace(project, catalog):
    project = Path(project).resolve()
    known = set(catalog['files'])
    classes = {str(row['class']): str(row['path']) for row in catalog['classes']}
    roots = {str(catalog['main_scene']), *catalog['autoloads'], 'res://resources/content/content_manifest.tres'}
    roots.update(p for p in known if p.startswith(('res://scenes/', 'res://local_qa/')) and p.endswith('.tscn') and allowed(p) and p not in SHOWCASE_ROOTS)
    roots.update(p for p in known if p.startswith('res://assets/ui/') and p in catalog['dependencies'])
    # JSON reads use FileAccess rather than ResourceLoader. Existing runtime families remain explicit.
    roots.update(p for p in known if p.endswith('.json') and p.startswith(('res://resources/narrative/', 'res://localization/', 'res://local_qa/')))
    queue = deque((p, '<root>', 'explicit_root') for p in sorted(roots))
    selected, excluded, reasons, missing, directory_literals = set(), set(), {}, set(), set()

    def local(path):
        candidate = (project/path.removeprefix('res://')).resolve()
        if not candidate.is_relative_to(project): raise ValueError('Resource path escapes project: '+path)
        return candidate

    while queue:
        path, parent, reason = queue.popleft()
        if not allowed(path):
            excluded.add((parent, path)); continue
        if path in selected: continue
        file = local(path)
        if not file.is_file():
            if file.is_dir(): directory_literals.add(path)
            else: missing.add((parent,path))
            continue
        selected.add(path);reasons[path] = {'from':parent, 'reason':reason}
        for dependency in catalog['dependencies'].get(path, []):
            queue.append((dependency, path, 'imported_dependency'))
        if file.suffix not in TEXT_TYPES: continue
        text = file.read_text(encoding='utf-8')
        identifiers, strings = script_tokens(text)
        if file.suffix in ('.gdshader', '.gdshaderinc'):
            strings += re.findall(r'^\s*#include\s+"([^"]+)"',text,re.M)
        if file.suffix == '.gd':
            for name in sorted(identifiers & classes.keys()):
                queue.append((classes[name], path, 'global_class:'+name))
        for value in strings:
            for token in value.split(';'):
                token = token.strip()
                if token.startswith('res://'):
                    # Templates/directory prefixes are covered by explicit runtime families, not a project-wide wildcard.
                    if '%' in token or token.endswith('/'):
                        directory_literals.add(token)
                        if token in DYNAMIC_FAMILIES:
                            for member in sorted(known):
                                if member.startswith(token) and member.endswith(DYNAMIC_FAMILIES[token]): queue.append((member,path,'bounded_dynamic_family'))
                        continue
                    queue.append((token, path, 'literal_resource_path'))

    if missing: raise ValueError('Missing referenced files: '+repr(sorted(missing)))
    if str(catalog['main_scene']) not in selected: raise ValueError('Main scene was not selected')
    if set(VERIFY_ABSENT) & selected: raise ValueError('Unexpected review/rollback dependency: '+repr(sorted(set(VERIFY_ABSENT) & selected)))
    license_docs = set()
    for resource in sorted(selected):
        if not resource.startswith('res://assets/'): continue
        folder = local(resource).parent
        while folder.is_relative_to(project/'assets') and folder != project/'assets':
            for child in folder.iterdir():
                if child.is_file() and child.name.upper().startswith(('LICENSE','LICENCE','COPYING','COPYRIGHT','OFL','NOTICE')) and child.stat().st_size < 262144:
                    if child.suffix.lower() in ('', '.txt', '.md'): license_docs.add('res://'+child.relative_to(project).as_posix())
            folder = folder.parent
    selected.update(license_docs)
    for path in license_docs: reasons.setdefault(path, {'from':'<asset ancestor>', 'reason':'license_text_candidate'})
    resources = sorted(p for p in selected if p in catalog['dependencies'])
    plain = sorted(selected-set(resources))
    hashes = {p:hashlib.sha256(local(p).read_bytes()).hexdigest() for p in sorted(selected)}
    companion_files = set(license_docs)
    for family, folder in LICENSE_BUNDLES.items():
        if any(path.startswith(family) for path in selected):
            companion_files.update('res://'+p.relative_to(project).as_posix() for p in (project/folder).rglob('*')
                                   if p.is_file() and p.suffix not in ('.import','.uid') and not p.name.startswith('.'))
    return {'version':1, 'purpose':'LOCAL_ONLY selected runtime dependency inventory; NOT rights approval',
            'public_release_approved':False, 'verification_absent_resources':list(VERIFY_ABSENT), 'roots':sorted(roots), 'resources':resources, 'plain_files':plain,
            'license_document_candidates':sorted(license_docs), 'selection_reasons':reasons, 'source_sha256':hashes,
            'companion_license_files':{p:hashlib.sha256(local(p).read_bytes()).hexdigest() for p in sorted(companion_files)},
            'excluded_existing_developer_references':[list(row) for row in sorted(excluded)],
            'directory_or_template_literals':sorted(directory_literals),
            'omitted_resources':sorted(set(catalog['dependencies'])-selected), 'dynamic_families':DYNAMIC_FAMILIES, 'showcase_not_forced_as_roots':sorted(SHOWCASE_ROOTS)}


def apply_preset(preset, inventory):
    preset = Path(preset)
    text = preset.read_text(encoding='utf-8')
    assert 'export_filter="all_resources"' in text
    files = 'PackedStringArray('+','.join(json.dumps(p) for p in inventory['resources'])+')'
    text = text.replace('export_filter="all_resources"', 'export_filter="resources"\nexport_files='+files, 1)
    # Plain license/JSON data must be explicitly included by the exporter.
    include = ','.join(p.removeprefix('res://') for p in inventory['plain_files'])
    text = re.sub(r'^include_filter="[^"]*"$', lambda m:'include_filter='+json.dumps(include), text, count=1, flags=re.M)
    preset.write_text(text, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--preset', type=Path)
    args = parser.parse_args()
    inventory = trace(args.project, json.loads(args.catalog.read_text(encoding='utf-8')))
    args.output.write_text(json.dumps(inventory, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    if args.preset: apply_preset(args.preset, inventory)
    print('RUNTIME_EXPORT_INVENTORY: PASS /',len(inventory['resources']),'resources /',len(inventory['plain_files']),'plain files')


if __name__ == '__main__': main()
