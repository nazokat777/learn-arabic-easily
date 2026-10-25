# -*- coding: utf-8 -*-
"""whisper_new.py : transcribe every UNTRACKED clip in assets/audio/{sentences,mashq} and compare with its text."""
import json, re, sys, io, subprocess, difflib
from pathlib import Path
from faster_whisper import WhisperModel
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; ROOT = Path(os.environ.get("AUDIT_APP", "."))
HAR = re.compile(r'[\u064B-\u0652\u0670\u0640]')
def norm(s):
    s = HAR.sub('', s)
    s = re.sub(r'[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = re.sub(r'[^\u0621-\u064A\s]', ' ', s)
    return ' '.join(s.split())
out = subprocess.run(['git', 'status', '--short', '--untracked-files=all', 'assets/audio'], cwd=ROOT, capture_output=True).stdout.decode('utf-8', 'replace')
new = [l[3:].strip().replace('"', '') for l in out.splitlines() if l.startswith('??')]
sets = {'sentences': 'sentence_manifest.json', 'mashq': 'mashq_manifest.json'}
rev = {}
for d, mf in sets.items():
    m = json.load(open(ROOT / 'assets/audio' / mf, encoding='utf-8'))
    for text, fn in m.items(): rev[(d, fn)] = text
model = WhisperModel('small', device='cpu', compute_type='int8')
rows = []
for p in new:
    parts = p.split('/')
    if len(parts) < 4 or parts[2] not in sets: continue
    d, fn = parts[2], parts[3]
    text = rev.get((d, fn))
    if text is None: rows.append((0.0, fn, '(no manifest text)', '')); continue
    segs, _ = model.transcribe(str(ROOT / p), language='ar', beam_size=5)
    heard = ' '.join(x.text for x in segs).strip()
    r = difflib.SequenceMatcher(None, norm(text), norm(heard)).ratio()
    rows.append((r, fn, text, heard))
rows.sort()
for r, fn, text, heard in rows:
    print(f'{r:.2f}\t{fn}\t{text}\n\t\t\t{heard}')
print('TOTAL', len(rows), 'low(<0.7):', sum(1 for x in rows if x[0] < 0.7))
