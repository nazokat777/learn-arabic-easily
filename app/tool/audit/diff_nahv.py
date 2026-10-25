# -*- coding: utf-8 -*-
"""Diff blind Nahv page transcriptions (trans/n_pNNN.txt) against nahv_lessons.json Arabic text.
usage: diff_nahv.py BOOK PAGE_FROM PAGE_TO     (pages = printed/PDF page numbers; observed pages must exist)
Expected = every Arabic string of the lessons overlapping the pages (title, rule, blocks, list items, exercises, tables), in lesson order.
Word-level skeleton diff (diacritics/alif/hamza-seat/ya-maqsura normalised), moved blocks (footnotes) detected, head/tail trimmed."""
import sys, re, json, io, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
APP = "assets/content/nahv_lessons.json"
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه'})
ARB = re.compile(r'[\u0621-\u064A]')
def nw(w): return re.sub(r'[^\u0621-\u064A]', '', DIAC.sub('', w).translate(TR))
def words(text):
    out = []
    for w in re.split(r'\s+', text):
        w = w.replace('[?]', '')
        n = nw(w)
        if n: out.append((n, w))
    return out
def arabic_strings(l):
    out = [('title', l.get('titleAr') or '')]
    r = l.get('rule') or {}
    if r.get('ar'): out.append(('rule', r['ar']))
    for b in l.get('blocks', []):
        if b['type'] == 'para': out.append(('para', b['ar']))
        else:
            if b.get('intro') and b['intro'].get('ar'): out.append(('intro', b['intro']['ar']))
            for it in b.get('items', []): out.append(('item', it['ar']))
    for e in l.get('exercise', []): out.append(('exercise', e['ar']))
    for tb in l.get('tables', []) or []:
        if tb.get('titleAr'): out.append(('tabletitle', tb['titleAr']))
        for r2 in tb.get('rows', []):
            cells = r2.get('cells') if isinstance(r2, dict) else r2
            for c in cells or []:
                if ARB.search(c): out.append(('cell', c))
    return out
book, p1, p2 = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
d = json.load(open(APP, encoding='utf-8'))
L = sorted([l for l in d['lessons'] if l['book'] == book], key=lambda l: l['num'])
exp = []   # (norm, raw, lesson num, kind)
for i, l in enumerate(L):
    start = l['page']; end = L[i + 1]['page'] if i + 1 < len(L) else start + 1
    if start > p2 or end < p1: continue
    for kind, s in arabic_strings(l):
        for n, w in words(s): exp.append((n, w, l['num'], kind))
obs = []   # (norm, raw, page)
for p in range(p1, p2 + 1):
    fp = f"{SP}/trans/n_p{p:03d}.txt"
    if not os.path.exists(fp): print('missing page file', p); continue
    for line in open(fp, encoding='utf-8').read().splitlines():
        if line.startswith('###') or not line.strip(): continue
        for n, w in words(line): obs.append((n, w, p))
A = [e[0] for e in exp]; B = [o[0] for o in obs]
sm = difflib.SequenceMatcher(None, A, B, autojunk=False)
ops = [o for o in sm.get_opcodes()]
# trim head/tail: drop leading/trailing non-equal ops
while ops and ops[0][0] != 'equal': ops.pop(0)
while ops and ops[-1][0] != 'equal': ops.pop()
# collect diffs
diffs = []
for tag, i1, i2, j1, j2 in ops:
    if tag == 'equal': continue
    diffs.append([tag, i1, i2, j1, j2])
def ctx(seq, i, k=4, side=0): return ' '.join(seq[x][1] for x in range(max(0, i - k), min(len(seq), i + k)))
# move detection among delete (expected-only) and insert (observed-only) blocks
dels = [x for x in diffs if x[0] == 'delete' and x[2] - x[1] >= 3]
inss = [x for x in diffs if x[0] == 'insert' and x[4] - x[3] >= 3]
moved = []; used_i = set()
for dd in dels:
    wa = A[dd[1]:dd[2]]
    best = (0, None)
    for k, ii in enumerate(inss):
        if k in used_i: continue
        r = difflib.SequenceMatcher(None, wa, B[ii[3]:ii[4]], autojunk=False).ratio()
        if r > best[0]: best = (r, k)
    if best[1] is not None and best[0] >= 0.6:
        used_i.add(best[1]); moved.append((dd, inss[best[1]], best[0]))
moved_ids = {id(m[0]) for m in moved} | {id(m[1]) for m in moved}
print(f"book {book} pages {p1}-{p2}: expected words {len(exp)}, observed words {len(obs)}, diff blocks {len(diffs)}, moved blocks {len(moved)}")
nreal = 0
for tag, i1, i2, j1, j2 in diffs:
    if any(id(x) in moved_ids for x in [[tag, i1, i2, j1, j2]]): pass
    d_ = [tag, i1, i2, j1, j2]
for dd in diffs:
    tag, i1, i2, j1, j2 = dd
    if id(dd) in moved_ids: continue
    nreal += 1
    app = ' '.join(e[1] for e in exp[i1:i2]); book_ = ' '.join(o[1] for o in obs[j1:j2])
    les = sorted({e[2] for e in exp[i1:i2]} or ({exp[min(i1, len(exp) - 1)][2]} if exp else set()))
    pg = sorted({o[2] for o in obs[j1:j2]} or ({obs[min(j1, len(obs) - 1)][2]} if obs else set()))
    print(f"[{tag}] lesson {les} page {pg} …{ctx(exp, i1)}…\n     APP : {app}\n     BOOK: {book_}")
for dd, ii, r in moved:
    a = ' '.join(e[1] for e in exp[dd[1]:dd[2]]); b = ' '.join(o[1] for o in obs[ii[3]:ii[4]])
    sub = difflib.SequenceMatcher(None, A[dd[1]:dd[2]], B[ii[3]:ii[4]], autojunk=False)
    sd = [t for t in sub.get_opcodes() if t[0] != 'equal']
    print(f"[moved block r={r:.2f}] lesson {exp[dd[1]][2]} -> page {obs[ii[3]][2]} words {dd[2]-dd[1]} inner diffs {len(sd)}")
    for tag, i1, i2, j1, j2 in sd:
        print(f"     inner {tag}: APP {' '.join(e[1] for e in exp[dd[1]+i1:dd[1]+i2])} | BOOK {' '.join(o[1] for o in obs[ii[3]+j1:ii[3]+j2])}")
print('REAL DIFF BLOCKS', nreal)
