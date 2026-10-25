# -*- coding: utf-8 -*-
"""Estimate where a word sits in a lesson's chunk images and render a zoomed crop (3 lines tall) around it.
usage: locate.py BOOK LESSON ANCHOR_WORD [occ=1] [z=6] [win=0.3] [rows=3]
BOOK = 1|2|3|k1|k2. ANCHOR_WORD as in the agent transcription (harakat ok; matched without diacritics).
Global estimate over the whole lesson by character proportion (robust to sentences that spill across chunks)."""
import sys, re, json
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "k1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "k2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و'})
def nz(w): return re.sub(r'[^\u0621-\u064A]', '', DIAC.sub('', w).translate(TR))
book, lesson, anchor = sys.argv[1], int(sys.argv[2]), sys.argv[3]
occ = 1; Z = 6.0; win = 0.3; rows = 3
for a in sys.argv[4:]:
    if a.startswith('occ='): occ = int(a[4:])
    elif a.startswith('z='): Z = float(a[2:])
    elif a.startswith('win='): win = float(a[4:])
    elif a.startswith('rows='): rows = int(a[5:])
metaf = f"{SP}/chunks/{book if book.startswith('k') else 'b' + book}_meta.json"
meta = json.load(open(metaf, encoding='utf-8'))[str(lesson)]
chunks = meta['chunks'] if isinstance(meta, dict) else meta
tp = f"{SP}/trans/{book}_k{lesson:02d}.txt" if book.startswith('k') else f"{SP}/trans/b{book}_l{lesson:02d}.txt"
words = []
for line in open(tp, encoding='utf-8').read().splitlines():
    if re.match(r'\s*###\s*chunk', line) or line.startswith('TITLE:'): continue
    for w in line.split():
        w2 = w.replace('[?]', '')
        if nz(w2): words.append(w2)
target = nz(anchor)
idxs = [i for i, w in enumerate(words) if nz(w) == target]
if len(idxs) < occ:
    print("anchor not found; words:", len(words), "occurrences:", len(idxs)); sys.exit(1)
i = idxs[occ - 1]
cum = [0]
for w in words: cum.append(cum[-1] + len(nz(w)) + 1)
pos = (cum[i] + cum[i + 1]) / 2
tot = cum[-1]
total_lines = sum(max(1, c.get('lines', 1)) for c in chunks)
gl = pos / tot * total_lines             # global line coordinate (float)
gline = min(total_lines - 1, int(gl)); xf = gl - gline
# map global line -> chunk, line within chunk
acc = 0
for ci, c in enumerate(chunks):
    n = max(1, c.get('lines', 1))
    if gline < acc + n:
        ch, ln, nl = c, gline - acc, n; cidx = ci + 1; break
    acc += n
h = (ch['y1'] - ch['y0']) / nl
half = (rows - 1) / 2
y0 = max(0, ch['y0'] + (ln - half) * h - 2)
y1 = ch['y0'] + (ln + 1 + half) * h + 2
xr = 560 - xf * (560 - 38)
xa = max(30, xr - win * (560 - 38)); xb = min(570, xr + win * (560 - 38))
doc = fitz.open(PDFS[book])
pix = doc[ch['page']].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(xa, y0, xb, y1))
fn = f"{SP}/zoom/loc_{book}_{lesson}_{i}.png"
pix.save(fn)
print(fn, pix.width, pix.height, "chunk", cidx, "line", ln + 1, "of", nl, "xfrac", round(xf, 2))
