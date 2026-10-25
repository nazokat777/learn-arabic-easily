# -*- coding: utf-8 -*-
import json, re, io, sys, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و'})
ARB = re.compile(r'[\u0621-\u064A]'); CYR = re.compile(r'[\u0400-\u04FF]')
def sk(s): return re.sub(r'[^\u0621-\u064A]', '', DIAC.sub('', s.replace('[?]', '')).translate(TR))
d = json.load(open('assets/content/qiroat_lessons.json', encoding='utf-8'))
for l in d['lessons']:
    if not l.get('tables') or l['num'] > 52: continue
    n = l['num']
    p = f"{SP}/trans/t1_l{n:02d}.txt"
    if not os.path.exists(p): print('missing', p); continue
    A = []   # app rows: list of arabic-cell skeleton lists
    for tb in l['tables']:
        A.append(('HEADER', [sk(c) for c in tb['columns'] if ARB.search(c)]))
        for r in tb['rows']:
            cells = r['cells'] if isinstance(r, dict) else r
            A.append((tb['title'], [sk(c) for c in cells if ARB.search(c)]))
    B = []
    for line in open(p, encoding='utf-8').read().splitlines():
        if line.startswith('###') or not line.strip(): continue
        cells = [c.strip() for c in line.split(' | ')]
        B.append([sk(c) for c in cells if ARB.search(c) and not CYR.search(c)])
    A = [(t, x) for t, x in A if x]; B = [x for x in B if x]
    def rs(a, b): return difflib.SequenceMatcher(None, ' '.join(a), ' '.join(b), autojunk=False).ratio()
    cand = sorted(((rs(a[1], b), i, j) for i, a in enumerate(A) for j, b in enumerate(B)), reverse=True)
    ui = set(); uj = set(); pairs = []
    for r, i, j in cand:
        if r < 0.4 or i in ui or j in uj: continue
        ui.add(i); uj.add(j); pairs.append((i, j, r))
    bad = []
    for i, j, r in sorted(pairs):
        if A[i][1] != B[j]:
            diffs = []
            for k in range(max(len(A[i][1]), len(B[j]))):
                x = A[i][1][k] if k < len(A[i][1]) else ''; y = B[j][k] if k < len(B[j]) else ''
                if x != y: diffs.append(f"cell{k+1}: APP[{x}] BOOK[{y}]")
            bad.append(f"  row {i+1} ({A[i][0][:20]}): " + '; '.join(diffs))
    unA = [i for i in range(len(A)) if i not in ui]; unB = [j for j in range(len(B)) if j not in uj]
    print(f"== 1-{n}: app rows {len(A)}, agent rows {len(B)}, matched {len(pairs)}, differing {len(bad)}, app-unmatched {len(unA)}, agent-unmatched {len(unB)}")
    for b in bad: print(b)
    for i in unA: print('  APP-ONLY row', i + 1, A[i])
    for j in unB: print('  AGENT-ONLY', B[j])
