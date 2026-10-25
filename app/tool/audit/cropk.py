# -*- coding: utf-8 -*-
"""cropk.py BOOK LESSON CHUNK LINE X0 X1 [z=10] -> zoom/ck_<book>_<lesson>_<chunk>_<line>_<x0>.png  (X in absolute PDF points)"""
import sys, json, pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "k1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "k2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
book, n, c, line, x0, x1 = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), float(sys.argv[5]), float(sys.argv[6])
Z = 10.0
for a in sys.argv[7:]:
    if a.startswith("z="): Z = float(a[2:])
meta = json.load(open(f"{SP}/chunks/{book if book.startswith('k') else 'b' + book}_meta.json", encoding="utf-8"))
ent = meta[str(n)]; chunks = ent["chunks"] if isinstance(ent, dict) else ent
ch = chunks[c - 1]; nl = max(1, ch.get("lines", 1)); h = (ch["y1"] - ch["y0"]) / nl
ya, yb = ch["y0"] + (line - 1) * h - 3, ch["y0"] + line * h + 3
doc = fitz.open(PDFS[book])
pix = doc[ch["page"]].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(x0, ya, x1, yb))
fn = f"{SP}/zoom/ck_{book}_{n}_{c}_{line}_{int(x0)}.png"; pix.save(fn); print(fn, pix.width, pix.height)
