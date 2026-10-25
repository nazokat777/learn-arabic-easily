# -*- coding: utf-8 -*-
"""Vowel-level companion of diff_nahv.py: for every word the skeleton diff aligned one-to-one ('equal' opcodes) compare the
explicit harakat of the app word with the explicit harakat the blind transcriber wrote for the same word.
usage: diff_nahv_vowel.py BOOK PAGE_FROM PAGE_TO [--ends] [--max N]
 - a letter is compared only if BOTH words carry a vowel mark (fatha/damma/kasra/sukun/tanween) on it and they differ;
 - a shadda the transcriber saw on a letter the app word has none on is reported too (the app may have dropped it);
 - --ends: only conflicts on the LAST letter (case endings = the grammar-relevant ones).
Every flag prints the observed location 'page.strip:line/lines@word/words' (crop it with nzl.py) and the app context.
Needs AUDIT_SP (trans/n_pNNN.txt) like diff_nahv.py. The transcribers auto-complete vowels, so every flag must be
checked on the page image before the app is touched (expect roughly half of them to be transcriber slips)."""
import sys, re, json, io, os, difflib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
SP = os.environ.get("AUDIT_SP", "tool/audit/work")
APP = "assets/content/nahv_lessons.json"
FATHA, DAMMA, KASRA, SUKUN, SHADDA = 'َ', 'ُ', 'ِ', 'ْ', 'ّ'
FATHATAN, DAMMATAN, KASRATAN = 'ً', 'ٌ', 'ٍ'
VOWELS = {FATHA, DAMMA, KASRA, SUKUN, FATHATAN, DAMMATAN, KASRATAN}
DIAC = re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه'})
ARB = re.compile('[ء-ي]')
MARKS = re.compile('[ً-ٟ]')
DAGGER = 'ٰ'


def nw(w):
    s = re.sub('[^ء-ي]', '', DIAC.sub('', w).translate(TR))
    return s.replace('ءا', 'ا')


def letters(w):
    """[(base letter, set of marks)] for the Arabic base letters of a raw word (hamza-alif ligatures untouched)"""
    out = []
    for ch in w:
        if ARB.match(ch): out.append([ch, set()])
        elif MARKS.match(ch) and out: out[-1][1].add(ch)
    return out


def words(text):
    text = re.sub(r'([«﴿])\s+', r'\1', text)
    text = re.sub(r'\s+([»﴾])', r'\1', text)
    text = re.sub('ـ\\s+', 'ـ', text)
    return [(nw(w.replace('[?]', '')), w.replace('[?]', '')) for w in re.split(r'\s+', text) if nw(w.replace('[?]', ''))]


def strip_cites(line, st):
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
    for bi, b in enumerate(l.get('blocks', [])):
        if b['type'] == 'para': out.append((f'blocks[{bi}].ar', b['ar']))
        else:
            if b.get('intro') and b['intro'].get('ar'): out.append((f'blocks[{bi}].intro', b['intro']['ar']))
            for ii, it in enumerate(b.get('items', [])): out.append((f'blocks[{bi}].items[{ii}].ar', it['ar']))
    for ei, e in enumerate(l.get('exercise', [])): out.append((f'exercise[{ei}].ar', e['ar']))
    return out


def merge_word(app_raw, obs_raw, diffs):
    """app word with the conflicting vowel marks replaced by the transcriber's (shadda added where only the transcriber has it)"""
    la, lb = letters(obs_raw), None
    fix = {pos: kind for pos, kind, _, _ in diffs}
    obs_l = letters(obs_raw)
    out = []; k = -1
    i = 0
    chars = list(app_raw)
    while i < len(chars):
        ch = chars[i]
        if ARB.match(ch):
            k += 1; out.append(ch)
            j = i + 1; marks = []
            while j < len(chars) and MARKS.match(chars[j]): marks.append(chars[j]); j += 1
            if k in fix:
                obs_marks = obs_l[k][1]
                if fix[k] == 'shadda':
                    marks = [SHADDA] + [m for m in marks if m != SHADDA]
                else:
                    keep = [m for m in marks if m not in VOWELS]
                    marks = ([SHADDA] if SHADDA in marks or SHADDA in obs_marks else []) + [m for m in keep if m != SHADDA] + sorted(obs_marks & VOWELS)
            out.extend(marks); i = j
        else:
            out.append(ch); i += 1
    return ''.join(out)


args = [a for a in sys.argv[1:] if not a.startswith('--')]  # --cat=quality|sukun|tanween|shadda|core filters the printed flags (core = everything except pure tanween/plain differences)
ENDS = '--ends' in sys.argv
MAXN = int(sys.argv[sys.argv.index('--max') + 1]) if '--max' in sys.argv else 10 ** 9
if '--max' in sys.argv: args.remove(sys.argv[sys.argv.index('--max') + 1])
book, p1, p2 = int(args[0]), int(args[1]), int(args[2])
d = json.load(open(APP, encoding='utf-8'))
L = sorted([l for l in d['lessons'] if l['book'] == book], key=lambda l: (l['page'], l['num']))
exp = []   # (norm, raw, lesson num, field)
for i, l in enumerate(L):
    start = l['page']; end = L[i + 1]['page'] if i + 1 < len(L) else start + 1
    if start > p2 or end < p1: continue
    for kind, s in arabic_strings(l):
        for n, w in words(s): exp.append((n, w, l['num'], kind))
obs = []
for p in range(p1, p2 + 1):
    fp = f"{SP}/trans/n_p{p:03d}.txt"
    if not os.path.exists(fp): continue
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
A = [e[0] for e in exp]; B = [o[0] for o in obs]
sm = difflib.SequenceMatcher(None, A, B, autojunk=False)
flags = []
for tag, i1, i2, j1, j2 in sm.get_opcodes():
    if tag != 'equal': continue
    for k in range(i2 - i1):
        ea, ob = exp[i1 + k], obs[j1 + k]
        la, lb = letters(ea[1]), letters(ob[1])
        if len(la) != len(lb): continue
        diffs = []
        for pos, ((ca, ma), (cb, mb)) in enumerate(zip(la, lb)):
            va, vb = ma & VOWELS, mb & VOWELS
            if va and vb and va != vb:
                base = {FATHATAN: FATHA, DAMMATAN: DAMMA, KASRATAN: KASRA}
                na, nb = {base.get(x, x) for x in va}, {base.get(x, x) for x in vb}
                kind = 'tanween' if na == nb else ('sukun' if SUKUN in (va | vb) else 'quality')
                diffs.append((pos, kind, ''.join(sorted(va)), ''.join(sorted(vb))))
            elif SHADDA in mb and SHADDA not in ma: diffs.append((pos, 'shadda', '-', SHADDA))
        if not diffs: continue
        last = len(la) - 1
        is_end = any(p == last for p, _, _, _ in diffs)
        if ENDS and not is_end: continue
        g = i1 + k
        same = lambda x: exp[x][2] == exp[g][2] and exp[x][3] == exp[g][3]
        lo = g
        while lo > max(0, g - 3) and same(lo - 1): lo -= 1
        hi = g
        while hi < min(len(exp) - 1, g + 3) and same(hi + 1): hi += 1
        ctxw = [exp[x][1] for x in range(lo, hi + 1)]
        ctx = ' '.join(ctxw)
        merged = merge_word(ea[1], ob[1], diffs)
        flags.append((ob[2], exp[i1 + k][2], exp[i1 + k][3], ea[1], ob[1], is_end, ctx, '/'.join(sorted({d_[1] for d_ in diffs})), ctxw, g - lo, merged))
print(f"book {book} pages {p1}-{p2}: aligned words {sum(i2 - i1 for t, i1, i2, j1, j2 in sm.get_opcodes() if t == 'equal')}, vowel/shadda conflicts {len(flags)}" + (' (case endings only)' if ENDS else ''))
CAT = [a for a in sys.argv if a.startswith('--cat=')]
_jp = [a for a in sys.argv if a.startswith('--json=')]
if _jp:   # --json=PATH writes every flag (incl. pure tanween ones) with the suggested merged word, in print order
    import json as _j
    with open(_jp[0][7:], 'w', encoding='utf-8') as _fh:
        _j.dump([dict(loc=f[0], num=f[1], field=f[2], app=f[3], obs=f[4], end=f[5], kinds=f[7], ctx=f[8], pos=f[9], merged=f[10]) for f in flags], _fh, ensure_ascii=False)
for loc, num, fld, a, b, is_end, ctx, kinds, _cw, _pos, _mg in flags[:MAXN]:
    if CAT and CAT[0][6:] == 'core':
        if kinds == 'tanween': continue
    elif CAT and CAT[0][6:] not in kinds.split('/'): continue
    print(f"{loc}  lesson {num} {fld}  {'END ' if is_end else '    '}[{kinds}] APP {a}  | BOOK {b}   …{ctx}…")
