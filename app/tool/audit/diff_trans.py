# -*- coding: utf-8 -*-
"""Diff blind transcriptions (trans/bB_lNN.txt) against the app's reading text.
usage: python diff_trans.py BOOK N [N ...]   (or ALL)   -> prints report (utf-8)"""
import sys, re, json, difflib, io, os
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
APP = "assets/content/qiroat_lessons.json"
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
PUNCT = re.compile(r'[.؟?،,؛;:!\-–—()\[\]«»"“”\'‘’…]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه', 'ۃ': 'ة'})

def norm_word(w):
    w = DIAC.sub('', w).translate(TR)
    w = PUNCT.sub('', w)
    return w

def words(text):
    out = []
    for w in re.split(r'\s+', text):
        w = w.replace('[?]', '')
        nw = norm_word(w)
        if nw:
            out.append((nw, w))
    return out

TERM = ".؟!؛?"; RUN_ON = ".؟!؛"
def split_sentences(reading):
    out = []
    for line in reading.splitlines():
        line = line.strip()
        if not line: continue
        buf = ""; i = 0
        while i < len(line):
            buf += line[i]
            if line[i] in TERM:
                while i + 1 < len(line) and line[i + 1] in RUN_ON:
                    i += 1; buf += line[i]
                t = buf.strip()
                if t: out.append(t)
                buf = ""
            i += 1
        t = buf.strip()
        if t: out.append(t)
    return out

def app_words_with_sentence(text):
    res = []
    for si, sent in enumerate(split_sentences(text), 1):
        for nw, ow in words(sent):
            res.append((nw, ow, si))
    return res

def load_app(book):
    d = json.load(open(APP, encoding='utf-8'))
    res = {}
    b = 1; prev = 0
    for l in d['lessons']:
        if l['num'] < prev:
            b += 1
        prev = l['num']
        if b == book:
            res[l['num']] = l
    return res

def load_trans(book, n):
    p = f"{SP}/trans/b{book}_l{n:02d}.txt" if not str(book).startswith('k') else f"{SP}/trans/{book}_k{n:02d}.txt"
    if not os.path.exists(p):
        return None
    txt = open(p, encoding='utf-8').read()
    chunks = []   # (chunk_no, text)
    cur = 1; buf = []
    for line in txt.splitlines():
        m = re.match(r'\s*###\s*chunk\s*(\d+)', line)
        if m:
            cur = int(m.group(1)); continue
        if line.strip() and not line.strip().startswith('TITLE:'):
            buf.append((cur, line.strip()))
    return buf

def terminators(text):
    # returns list of (norm sentence words tuple, terminator char) per sentence
    sents = re.split(r'(?<=[.؟?!])\s+', text.strip())
    res = []
    for s in sents:
        t = s.strip()
        if not t:
            continue
        m = re.search(r'[.؟?!]\s*$', t)
        res.append((tuple(w for w, _ in words(t)), m.group(0).strip().replace('?', '؟') if m else ''))
    return res

def report(book, n, app, out, field='reading'):
    tr = load_trans(book, n)
    if tr is None:
        out.append(f"== B{book} L{n}: NO TRANSCRIPTION"); return 0
    awx = app_words_with_sentence(app[field])
    aw = [(x[0], x[1]) for x in awx]
    asent = [x[2] for x in awx]
    tw = []; tchunk = []
    for ch, line in tr:
        for nw, ow in words(line):
            tw.append((nw, ow)); tchunk.append(ch)
    a = [x[0] for x in aw]; b = [x[0] for x in tw]
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    diffs = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            continue
        ctx_a = ' '.join(x[1] for x in aw[max(0, i1 - 3):i1])
        ctx_b = ' '.join(x[1] for x in aw[i2:i2 + 3])
        ch = tchunk[j1] if j1 < len(tchunk) else (tchunk[-1] if tchunk else 0)
        if j1 == j2 and j1 > 0:
            ch = tchunk[j1 - 1]
        sno = asent[i1] if i1 < len(asent) else (asent[-1] if asent else 0)
        diffs.append((tag, ctx_a, ' '.join(x[1] for x in aw[i1:i2]), ' '.join(x[1] for x in tw[j1:j2]), ctx_b, ch, sno))
    # punctuation: compare terminator per sentence when word tuples equal
    ta = terminators(app[field])
    tt = terminators(' '.join(l for _, l in tr))
    sm2 = difflib.SequenceMatcher(None, [x[0] for x in ta], [x[0] for x in tt], autojunk=False)
    punct = []
    for tag, i1, i2, j1, j2 in sm2.get_opcodes():
        if tag == 'equal':
            for k in range(i2 - i1):
                if ta[i1 + k][1] != tt[j1 + k][1]:
                    punct.append((i1 + k + 1, ta[i1 + k][1], tt[j1 + k][1], ' '.join(ta[i1 + k][0][:6])))
    unc = sum(l.count('[?]') for _, l in tr)
    out.append(f"== B{book} L{n}: app words {len(a)}, trans words {len(b)}, diffs {len(diffs)}, punct {len(punct)}, uncertain {unc}")
    for tag, ca, aa, bb, cb, ch, sno in diffs:
        out.append(f"  [{tag} s#{sno} chunk{ch}] …{ca} «APP: {aa}» «BOOK: {bb}» {cb}…")
    for s, pa, pb, ws in punct:
        out.append(f"  [punct sentence #{s}] app '{pa}' vs book '{pb}'  ({ws})")
    return len(diffs) + len(punct)

def main():
    bk = sys.argv[1]
    iskey = bk.startswith('k')
    book = int(bk[1:]) if iskey else int(bk)
    field = 'exerciseAnswer' if iskey else 'reading'
    apps = load_app(book)
    ns = sorted(apps) if sys.argv[2] == 'ALL' else [int(x) for x in sys.argv[2:]]
    out = []
    tot = 0
    for n in ns:
        tot += report(bk if iskey else book, n, apps[n], out, field)
    path = f"{SP}/diff_{bk if iskey else 'b' + str(book)}.txt"
    open(path, 'w', encoding='utf-8').write('\n'.join(out) + f"\nTOTAL {tot}\n")
    print(path, tot)

main()
