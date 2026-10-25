# -*- coding: utf-8 -*-
"""Re-render one chunk region at higher zoom, optionally split into right/left halves.
usage: rechunk.py BOOK LESSON CHUNK [Z=4.5] [parts=2]   (BOOK = 1|2|3|k1)
Output: zoom/rc_<book>_<lesson>_<chunk>_<part>.png  (part 0 = right half, RTL reading order)"""
import sys, json
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "k1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "k2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
book, n, c = sys.argv[1], sys.argv[2], int(sys.argv[3])
Z = 4.5; parts = 2; line = None
for a in sys.argv[4:]:
    if a.startswith("line="): line = int(a[5:])
    elif a.startswith("z="): Z = float(a[2:])
    elif a.startswith("parts="): parts = int(a[6:])
    else:
        # legacy positional: Z then parts
        try:
            v = float(a)
            if v >= 1 and v == int(v) and v <= 4 and "." not in a: parts = int(v)
            else: Z = v
        except ValueError: pass
meta = json.load(open(f"{SP}/chunks/{book if book.startswith('k') else 'b' + book}_meta.json", encoding="utf-8"))
ent = meta[str(int(n))]
chunks = ent["chunks"] if isinstance(ent, dict) else ent
ch = chunks[c - 1]
doc = fitz.open(PDFS[book])
x0, x1 = 38.0, 560.0
w = (x1 - x0) / parts
for k in range(parts):
    xr1 = x1 - k * w + (6 if k > 0 else 0)
    xr0 = xr1 - w - 6
    ya, yb = ch["y0"], ch["y1"]
    if line is not None:
        nl = max(1, ch.get("lines", 1)); h = (yb - ya) / nl
        ya, yb = ya + (line - 1) * h - 3, ya + line * h + 3
    clip = fitz.Rect(max(0, xr0), ya, xr1, yb)
    pix = doc[ch["page"]].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip)
    fn = f"{SP}/zoom/rc_{book}_{int(n)}_{c}_{k}{('_l' + str(line)) if line else ''}.png"
    pix.save(fn)
    print(fn, pix.width, pix.height)
