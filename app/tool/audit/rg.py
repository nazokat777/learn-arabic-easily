import sys
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
# usage: rg.py BOOK PAGE x0 y0 x1 y1 [Z]   (absolute PDF points)
book, page = sys.argv[1], int(sys.argv[2])
x0, y0, x1, y1 = map(float, sys.argv[3:7])
Z = float(sys.argv[7]) if len(sys.argv) > 7 else 4
doc = fitz.open(PDFS[book])
pix = doc[page].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(x0, y0, x1, y1))
fn = f"{SP}/zoom/rg_b{book}_p{page}_{int(x0)}_{int(y0)}_{int(x1)}_{int(y1)}.png"
pix.save(fn)
print(fn, pix.width, pix.height)
