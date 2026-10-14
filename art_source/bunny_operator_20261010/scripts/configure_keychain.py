#!/usr/bin/env python3
"""Run manually in a terminal; Apple security prompts for the key without echo."""
import getpass
import subprocess
import sys

SERVICE = 'neon-bastion-tripo-api'
if not sys.stdin.isatty():
    raise SystemExit('Run this helper yourself in an interactive local Terminal.')
print('Paste the API key only into the following hidden macOS security prompt.')
print('The key is stored in your login keychain; never in this project or command arguments.')
# -w LAST deliberately invokes the native hidden password prompt. No key in argv.
code = subprocess.call(['/usr/bin/security', 'add-generic-password', '-a', getpass.getuser(),
                        '-s', SERVICE, '-U', '-w'])
if code:
    raise SystemExit('Keychain setup failed; no key was logged.')
print('Keychain item saved. Tell Codex your credit spending limit; do not send the key.')
