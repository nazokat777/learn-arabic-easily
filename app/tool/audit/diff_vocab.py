# -*- coding: utf-8 -*-
"""Diff blind vocab-cell transcriptions (trans/v<B>_l<NN>.txt) against the app's vocab entries.
usage: diff_vocab.py BOOK|ALL [N ...]   -> prints a report; writes diff_v<BOOK>.txt"""
import sys, re, json, io, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
APP = "assets/content/qiroat_lessons.json"
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه', 'ۃ': 'ة'})
def sk(s): return re.sub(r'[^\u0621-\u064A\s]', ' ', DIAC.sub('', s.replace('[?]', '')).translate(TR))
def toks(s): return sk(s).split()
def flat(s): return ''.join(toks(s))
d = json.load(open(APP, encoding='utf-8'))
b = 1; prev = 0; idx = {}
for l in d['lessons']:
    if l['num'] < prev: b += 1
    prev = l['num']; idx[(b, l['num'])] = l
def agent_cells(book, n):
    p = f"{SP}/trans/v{book}_l{n:02d}.txt"
    if not os.path.exists(p): return None
    cells = []; chunk = 0; unc = 0
    for line in open(p, encoding='utf-8').read().splitlines():
        line = line.strip()
        m = re.match(r'###\s*chunk\s*(\d+)', line)
        if m: chunk = int(m.group(1)); continue
        if line.startswith('###'): continue
        if not line: continue
        cells.append((line, chunk))
    return cells
def sim(a, b): return difflib.SequenceMatcher(None, a, b, autojunk=False).ratio()
def align(A, B):
    """Order-independent greedy assignment on skeleton similarity (the app regroups entries: nouns first, verbs last).
    Returns list of (i or None, j or None)."""
    cand = []
    for i in range(len(A)):
        for j in range(len(B)):
            if A[i] == B[j]: r = 1.0
            else: r = sim(A[i], B[j])
            if r >= 0.5: cand.append((r, i, j))
    cand.sort(key=lambda x: -x[0])
    ui = set(); uj = set(); pairs = []
    for r, i, j in cand:
        if i in ui or j in uj: continue
        ui.add(i); uj.add(j); pairs.append((i, j))
    out = [(i, j) for i, j in pairs]
    out += [(i, None) for i in range(len(A)) if i not in ui]
    out += [(None, j) for j in range(len(B)) if j not in uj]
    return sorted(out, key=lambda t: (t[0] if t[0] is not None else 10**6, t[1] if t[1] is not None else 10**6))
def ops(a, b):
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False); r = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag != 'equal': r.append(f"{tag}[{a[max(0,i1-3):i1]}|{a[i1:i2]}→{b[j1:j2]}|{a[i2:i2+3]}]")
    return ' '.join(r)
which = sys.argv[1]; only = [int(x) for x in sys.argv[2:]]
books = [1, 2, 3] if which == 'ALL' else [int(which)]
tot = {'cells': 0, 'exact': 0, 'reorder': 0, 'diff': 0, 'app_only': 0, 'agent_only': 0, 'missing_files': 0}
out_lines = []
def P(s): out_lines.append(s)
for book in books:
    meta = json.load(open(f"{SP}/chunks/v{book}_meta.json", encoding='utf-8'))
    for n in sorted(int(k) for k in meta):
        if only and n not in only: continue
        cells = agent_cells(book, n)
        if cells is None: tot['missing_files'] += 1; continue
        l = idx[(book, n)]
        A = [flat(v['ar'] + ' ' + (v.get('pl') or '')) for v in l['vocab']]
        B = [flat(c[0]) for c in cells]
        pairs = align(A, B)
        # cells split by a page break: agent cell is a prefix of the app entry and a lone agent cell holds the rest
        lone = {j for i, j in pairs if i is None and j is not None}
        fixed = {}
        for i, j in pairs:
            if i is not None and j is not None and A[i] != B[j] and A[i].startswith(B[j]):
                for j2 in sorted(lone):
                    if B[j] + B[j2] == A[i]: fixed[(i, j)] = j2; lone.discard(j2); break
        drop2 = set(fixed.values())
        pairs = [(i, j) for i, j in pairs if not (i is None and j in drop2)]
        probs = []
        for i, j in pairs:
            if (i, j) in fixed:
                tot['cells'] += 1; tot['exact'] += 1; continue
            if i is not None and j is not None:
                tot['cells'] += 1
                if A[i] == B[j]: tot['exact'] += 1; continue
                ta = sorted(toks(l['vocab'][i]['ar'] + ' ' + (l['vocab'][i].get('pl') or ''))); tb = sorted(toks(cells[j][0]))
                if ta == tb: tot['reorder'] += 1; continue
                tot['diff'] += 1
                v = l['vocab'][i]
                probs.append(f"  [diff #{i+1} chunk{cells[j][1]}] APP: {v['ar']} | {v.get('pl') or ''}\n        BOOK: {cells[j][0]}\n        {ops(A[i], B[j])}")
            elif i is not None:
                v = l['vocab'][i]; tot['app_only'] += 1
                probs.append(f"  [app-only #{i+1}] {v['ar']} | {v.get('pl') or ''}")
            else:
                if cells[j][0] == '-': continue
                tot['agent_only'] += 1
                probs.append(f"  [agent-only chunk{cells[j][1]}] {cells[j][0]}")
        P(f"== V{book}-{n}: app {len(A)} entries, agent {len(B)} cells" + ('' if not probs else f", {len(probs)} issues"))
        for p in probs: P(p)
P(f"TOTAL {tot}")
text = '\n'.join(out_lines)
open(f"{SP}/diff_v{which}.txt", 'w', encoding='utf-8').write(text)
print('\n'.join(x for x in out_lines if not x.startswith('== ') or 'issues' in x or True) if len(out_lines) < 400 else '\n'.join(out_lines[-60:]))
