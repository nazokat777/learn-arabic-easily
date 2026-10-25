# -*- coding: utf-8 -*-
"""vz.py BOOK LESSON CHUNK ROW COL [z=8]  -> zoom/vz_<book>_<lesson>_<chunk>_<row>_<col>.png
ROW is 1-based within the chunk's rows (as in the chunk image), COL: 4 = rightmost Arabic cell (first entry), 2 = left Arabic cell."""
import sys, json, io, pymupdf as fitz
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDF = {1: DL + r"\mabdaul-qiroat-1.pdf", 2: DL + r"\mabdaul-qiroat-2.pdf", 3: DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
book, n, c, r, col = [int(x) for x in sys.argv[1:6]]
Z = 8.0
for a in sys.argv[6:]:
    if a.startswith('z='): Z = float(a[2:])
meta = json.load(open(f"{SP}/chunks/v{book}_meta.json", encoding='utf-8'))[str(n)]
ch = meta[c - 1]
doc = fitz.open(PDF[book]); pg = doc[ch['page']]
for t in pg.find_tables().tables:
    if abs(t.bbox[0] - (ch['x0'] + 3)) < 2 and t.bbox[1] - 3 <= ch['y1'] and t.bbox[3] + 3 >= ch['y0']:
        rows = [row for row in t.rows if row.bbox[1] >= ch['y0'] - 1 and row.bbox[3] <= ch['y1'] + 1]
        row = rows[r - 1]
        cells = [cc for cc in row.cells]
        # cells are listed left-to-right: [cyr, ar, cyr, ar]
        idx = {2: 1, 4: 3}.get(col, col - 1)
        bb = cells[idx]
        if bb is None: print('cell None'); sys.exit(1)
        clip = fitz.Rect(bb[0], bb[1], bb[2], bb[3])
        pix = pg.get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip)
        fn = f"{SP}/zoom/vz_{book}_{n}_{c}_{r}_{col}.png"; pix.save(fn); print(fn, pix.width, pix.height, [round(v) for v in bb]); break
else:
    print('table not found')
