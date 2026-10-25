# -*- coding: utf-8 -*-
import json, re, io, sys, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و'})
def sk(s): return ''.join(re.sub(r'[^\u0621-\u064A\s]', ' ', DIAC.sub('', s.replace('[?]', '')).translate(TR)).split())
d = json.load(open('assets/content/qiroat_lessons.json', encoding='utf-8'))
b = 1; prev = 0; idx = {}
for l in d['lessons']:
    if l['num'] < prev: b += 1
    prev = l['num']; idx[(b, l['num'])] = l
rows = {}
for line in open(f"{SP}/trans/titles.txt", encoding='utf-8').read().splitlines():
    if '\t' not in line: continue
    k, t = line.split('\t', 1); bk, n = k.strip().split('-'); rows[(int(bk), int(n))] = t.strip()
ok = 0; bad = []
for (bk, n), t in sorted(rows.items()):
    app = idx[(bk, n)].get('titleAr') or ''
    if sk(app) == sk(t): ok += 1
    else: bad.append((bk, n, app, t))
print('titles', len(rows), 'equal', ok, 'different', len(bad))
for x in bad:
    a, t = sk(x[2]), sk(x[3])
    ops = [f"{tag}[{a[i1:i2]}→{t[j1:j2]}]" for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, t, autojunk=False).get_opcodes() if tag != 'equal']
    print(f"  {x[0]}-{x[1]}: APP {x[2]}   BOOK {x[3]}   {' '.join(ops)}")
missing = [(bk, n) for (bk, n) in idx if bk in (2, 3) and (bk, n) not in rows]
print('missing in agent file:', missing)
