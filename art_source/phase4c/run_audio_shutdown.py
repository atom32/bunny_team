"""Fixed-count exit stress check. No retry-until-green or error filtering."""
from pathlib import Path
import json, os, subprocess

D = Path(__file__).resolve().parent
W = json.loads((D / 'workspace.json').read_text())
O = Path(W['output'])
L = D / 'audio_shutdown'
L.mkdir(exist_ok=True)
env = dict(os.environ, APPDATA=str(O / 'audio_userdata'), LOCALAPPDATA=str(O / 'audio_localdata'))
jobs = [('world_interaction', ['res://tests/world_interaction_test.tscn'])] * 20
jobs += [('resource_probe', ['--script', str(D / 'audio_shutdown_probe.gd')])] * 5
rows = []
for i, (name, args) in enumerate(jobs):
    command = ['E:/Godot/Godot_v4.7.2-stable_win64_console.exe', '--path', W['project'], '--headless', '--verbose'] + args
    log = L / f'{i:02d}_{name}.log'
    with log.open('wb') as output:
        result = subprocess.run(command, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=60)
    lines = log.read_text(encoding='utf-8', errors='replace').splitlines()
    errors = [s for s in lines if s.startswith(('ERROR:', 'SCRIPT ERROR:'))]
    row = dict(name=name, exit=result.returncode, errors=errors,
               warnings=[s for s in lines if s.startswith('WARNING:')], command=command)
    for s in lines:
        if s.startswith('AUDIO_SHUTDOWN_PROBE: '):
            row['probe'] = json.loads(s.split(': ', 1)[1])
    row['pass'] = result.returncode == 0 and not errors and ': FAIL' not in '\n'.join(lines)
    if name == 'resource_probe':
        row['pass'] &= bool(row.get('probe')) and all(row['probe']['checks'].values())
    rows.append(row)
    (L / 'results.json').write_text(json.dumps(rows, indent=2), encoding='utf-8')
    print(i, name, row['pass'], flush=True)
raise SystemExit(0 if all(row['pass'] for row in rows) else 1)
