# -*- coding: utf-8 -*-
"""nrejall.py BOOK P1 P2 -- register EVERY flag diff_nahv.py currently prints for that window as 'judged false'
(use only after every flag was looked at: fixed ones are gone from the diff already, the rest are structure/spelling-style/misreads)."""
import os, re, subprocess, sys
env = {**os.environ, 'PYTHONIOENCODING': 'utf-8'}
out = subprocess.run([sys.executable, 'tool/audit/diff_nahv.py'] + sys.argv[1:4], capture_output=True, env=env).stdout.decode('utf-8')
lines = out.splitlines(); pairs = []; i = 0
while i < len(lines):
    if lines[i].startswith('[') and not lines[i].startswith('[moved'):
        a = lines[i + 1].split('APP :', 1)[1].strip(); b = lines[i + 2].split('BOOK:', 1)[1].strip(); pairs.append((a, b)); i += 3
    elif lines[i].strip().startswith('inner '):
        m = re.match(r'\s*inner \w+ @ \S+: APP (.*) \| BOOK (.*)$', lines[i]); pairs.append((m.group(1).strip(), m.group(2).strip())); i += 1
    else: i += 1
args = [x for p in pairs for x in p]
if args:
    r = subprocess.run([sys.executable, 'tool/audit/nrej.py'] + args, capture_output=True, env=env)
print(len(pairs), 'flags registered')
