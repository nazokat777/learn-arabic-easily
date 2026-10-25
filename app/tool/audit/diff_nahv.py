# -*- coding: utf-8 -*-
"""Diff blind Nahv page transcriptions (trans/n_pNNN.txt) against nahv_lessons.json Arabic text.
usage: diff_nahv.py BOOK PAGE_FROM PAGE_TO     (pages = printed/PDF page numbers; observed pages must exist)
Expected = every Arabic string of the lessons overlapping the pages (title, rule, blocks, list items, exercises, tables), in lesson order.
Word-level skeleton diff (diacritics/alif/hamza-seat/ya-maqsura normalised); head/tail trimmed; text that only moved
(footnotes, lists printed elsewhere) is paired up and reported with its inner diffs only.
Every observed word carries its location 'page.strip:line/lines' so the line can be cropped with nzl.py."""
import sys, re, json, io, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
APP = "assets/content/nahv_lessons.json"
DIAC = re.compile(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه'})
ARB = re.compile(r'[ء-ي]')
DAGGER = 'ٰ'


def nw(w, dagger_as_alif=False):
    if dagger_as_alif: w = w.replace(DAGGER, 'ا')
    s = re.sub(r'[^ء-ي]', '', DIAC.sub('', w).translate(TR))
    return s.replace('ءا', 'ا')   # Uthmani hamza+alif for alif-madda


# one-word printed headings the app keeps as a UI label, not as text (an 'insert' of only these is not a defect)
HEADINGS = {'تمرين', 'تمرينات', 'تطبيق', 'اسئله', 'اسيله'}


def words(text):
    out = []
    # the transcriber puts spaces inside « » and after a tatweel prefix (بـ «X»): glue them, spacing is not a defect
    text = re.sub(r'([«﴿])\s+', r'\1', text)
    text = re.sub(r'\s+([»﴾])', r'\1', text)
    text = re.sub('ـ\\s+', 'ـ', text)
    for w in re.split(r'\s+', text):
        w = w.replace('[?]', '')
        n = nw(w)
        if n: out.append((n, w))
    return out


def strip_cites(line, st):
    """Quranic citations «[ يوسف : ٥١ ]» printed inline are deliberately not kept in the app (like page references)"""
    out = []
    for ch in line:
        if st[0]:
            if ch == ']': st[0] = False
            continue
        if ch == '[': st[0] = True; continue
        out.append(ch)
    return ''.join(out)


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
        for col in tb.get('columns') or []:
            for seg in re.findall(r'[ء-يً-ٰٟـ ]*[ء-ي][ء-يً-ٰٟـ ]*', col):
                out.append(('colhead', seg))
        for r2 in tb.get('rows', []):
            cells = r2.get('cells') if isinstance(r2, dict) else r2
            for c in cells or []:
                if ARB.search(c): out.append(('cell', c))
    return out


book, p1, p2 = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
d = json.load(open(APP, encoding='utf-8'))
L = sorted([l for l in d['lessons'] if l['book'] == book], key=lambda l: (l['page'], l['num']))   # printed order (2/2 'foyda' precedes 2/1 on p77/78)
exp = []   # (norm, raw, lesson num, kind)
for i, l in enumerate(L):
    start = l['page']; end = L[i + 1]['page'] if i + 1 < len(L) else start + 1
    if start > p2 or end < p1: continue
    for kind, s in arabic_strings(l):
        for n, w in words(s): exp.append((n, w, l['num'], kind))
obs = []   # (norm, raw, 'page.strip:line/lines')
missing = []
for p in range(p1, p2 + 1):
    fp = f"{SP}/trans/n_p{p:03d}.txt"
    if not os.path.exists(fp): missing.append(p); continue
    strips = {}; cur = 0; cite = [False]
    for line in open(fp, encoding='utf-8').read().splitlines():
        if line.startswith('###'):
            m_ = re.search(r'(\d+)', line); cur = int(m_.group(1)) if m_ else cur + 1; strips.setdefault(cur, []); continue
        if not line.strip(): continue
        line = strip_cites(line.replace('[?]', ''), cite)
        if not line.strip(): continue
        strips.setdefault(cur, []).append(line)
    for sn in sorted(strips):
        lines = strips[sn]
        for li, line in enumerate(lines, 1):
            ws = words(line)
            for wi, (n, w) in enumerate(ws, 1): obs.append((n, w, f"{p}.{sn}:{li}/{len(lines)}@{wi}/{len(ws)}"))
if missing: print('missing page files:', missing)
A = [e[0] for e in exp]; B = [o[0] for o in obs]
sm = difflib.SequenceMatcher(None, A, B, autojunk=False)
ops = [o for o in sm.get_opcodes()]
# trim head/tail: drop leading/trailing non-equal ops
while ops and ops[0][0] != 'equal': ops.pop(0)
while ops and ops[-1][0] != 'equal': ops.pop()


def benign(i1, i2, j1, j2):
    """spacing-only, a printed exercise heading (تمرين …), or the same words except Quranic dagger-alif spelling"""
    if i1 == i2 and j2 > j1 and B[j1] in HEADINGS and (j2 - j1) <= 4: return True
    if i2 > i1 and j1 == j2 and all(exp[k][3] == 'title' for k in range(i1, i2)): return True   # app title composed from the contents list, not printed on the page
    if ''.join(A[i1:i2]) == ''.join(B[j1:j2]): return True
    if i2 - i1 == j2 - j1 and all(A[i1 + k] == B[j1 + k] or A[i1 + k] == nw(obs[j1 + k][1], True) for k in range(i2 - i1)): return True
    return False


REJ = set()   # flags already judged FALSE (transcriber misread / style): 'app skeleton words|book skeleton words'
_rp = os.environ.get('AUDIT_REJECTS', f"{SP}/nahv_rejects.txt")
if os.path.exists(_rp): REJ = {l.strip() for l in open(_rp, encoding='utf-8') if l.strip()}


def sig(i1, i2, j1, j2): return ' '.join(A[i1:i2]) + '|' + ' '.join(B[j1:j2])


diffs = []   # [tag, i1, i2, j1, j2]
for tag, i1, i2, j1, j2 in ops:
    if tag == 'equal': continue
    if benign(i1, i2, j1, j2): continue
    if sig(i1, i2, j1, j2) in REJ: continue
    if tag == 'insert' and all(b in HEADINGS for b in B[j1:j2]): continue
    diffs.append([tag, i1, i2, j1, j2])

# move detection: any expected-only run of >=3 words (delete, or the expected side of a replace) paired with an
# observed-only run of >=3 words of ANOTHER diff block
segA = [(k, x[1], x[2]) for k, x in enumerate(diffs) if x[2] - x[1] >= 3]
segB = [(k, x[3], x[4]) for k, x in enumerate(diffs) if x[4] - x[3] >= 3]
moved = []; usedA = set(); usedB = set()
cands = []
for ka, a1, a2 in segA:
    for kb, b1, b2 in segB:
        if ka == kb: continue
        r = difflib.SequenceMatcher(None, A[a1:a2], B[b1:b2], autojunk=False).ratio()
        if r >= 0.6: cands.append((r, ka, a1, a2, kb, b1, b2))
for r, ka, a1, a2, kb, b1, b2 in sorted(cands, reverse=True):
    if ka in usedA or kb in usedB: continue
    usedA.add(ka); usedB.add(kb); moved.append((ka, a1, a2, kb, b1, b2, r))

print(f"book {book} pages {p1}-{p2}: expected words {len(exp)}, observed words {len(obs)}, diff blocks {len(diffs)}, moved blocks {len(moved)}")


def ctx(seq, i, k=4): return ' '.join(seq[x][1] for x in range(max(0, i - k), min(len(seq), i + k)))


nreal = 0
for k, (tag, i1, i2, j1, j2) in enumerate(diffs):
    if k in usedA: i2 = i1          # its expected side was found elsewhere
    if k in usedB: j2 = j1
    if i1 == i2 and j1 == j2: continue
    if benign(i1, i2, j1, j2) or sig(i1, i2, j1, j2) in REJ: continue
    nreal += 1
    tg = 'replace' if (i2 > i1 and j2 > j1) else ('delete' if i2 > i1 else 'insert')
    app = ' '.join(e[1] for e in exp[i1:i2]); book_ = ' '.join(o[1] for o in obs[j1:j2])
    les = sorted({e[2] for e in exp[i1:i2]} or ({exp[min(i1, len(exp) - 1)][2]} if exp else set()))
    loc = [o[2] for o in obs[j1:j2]] or ([obs[min(j1, len(obs) - 1)][2]] if obs else [])
    loc_s = loc[0] if len(loc) == 1 else (f"{loc[0]} .. {loc[-1]}" if loc else '?')
    print(f"[{tg}] lesson {les} @ {loc_s} …{ctx(exp, i1)}…\n     APP : {app}\n     BOOK: {book_}")
for ka, a1, a2, kb, b1, b2, r in moved:
    a = ' '.join(e[1] for e in exp[a1:a2]); b = ' '.join(o[1] for o in obs[b1:b2])
    sub = difflib.SequenceMatcher(None, A[a1:a2], B[b1:b2], autojunk=False)
    sd = [t for t in sub.get_opcodes() if t[0] != 'equal' and not benign(a1 + t[1], a1 + t[2], b1 + t[3], b1 + t[4])
          and sig(a1 + t[1], a1 + t[2], b1 + t[3], b1 + t[4]) not in REJ]
    print(f"[moved r={r:.2f}] lesson {exp[a1][2]} -> {obs[b1][2]} words {a2-a1} inner diffs {len(sd)}")
    for tag, i1, i2, j1, j2 in sd:
        nreal += 1
        print(f"     inner {tag} @ {obs[b1 + j1][2] if b1 + j1 < len(obs) else '?'}: APP {' '.join(e[1] for e in exp[a1+i1:a1+i2])} | BOOK {' '.join(o[1] for o in obs[b1+j1:b1+j2])}")
print('REAL DIFF BLOCKS', nreal)
