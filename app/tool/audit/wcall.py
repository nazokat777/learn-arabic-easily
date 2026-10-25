# -*- coding: utf-8 -*-
"""wcall.py BOOK LESSON QUERY [z=12] [pad=40] [occ=1] : search the text layer in ALL chunks of a lesson, crop the occ-th hit."""
import sys, re, json, io, pymupdf as fitz
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ة': 'ه'})
def sk(s): return re.sub(r'[^ء-ي]', '', DIAC.sub('', s).translate(TR)).replace('لا', 'ال')
book, n, query = sys.argv[1], int(sys.argv[2]), sys.argv[3]
Z = 12.0; PAD = 40.0; occ = 1
for a in sys.argv[4:]:
    if a.startswith('z='): Z = float(a[2:])
    elif a.startswith('pad='): PAD = float(a[4:])
    elif a.startswith('occ='): occ = int(a[4:])
meta = json.load(open(f"{SP}/chunks/b{book}_meta.json", encoding="utf-8"))
ent = meta[str(n)]; chunks = ent["chunks"] if isinstance(ent, dict) else ent
doc = fitz.open(PDFS[book]); q = sk(query)
hits = []
for ci, ch in enumerate(chunks, 1):
    pg = doc[ch["page"]]
    ws = [w for w in pg.get_text("words") if ch["y0"] - 4 <= (w[1] + w[3]) / 2 <= ch["y1"] + 4]
    ws.sort(key=lambda w: (w[1] + w[3]) / 2); lines = []
    for w in ws:
        yc = (w[1] + w[3]) / 2
        if lines and abs(lines[-1][0] - yc) < 7: lines[-1][1].append(w)
        else: lines.append([yc, [w]])
    for yc, L in lines:
        frs = sorted(L, key=lambda w: -(w[0] + w[2]) / 2); s = ""; owner = []
        for w in frs:
            t = sk(w[4]); s += t; owner += [w] * len(t)
        for m in re.finditer(re.escape(q), s):
            sel = owner[m.start():m.end()]
            hits.append((ci, ch["page"], yc, min(w[0] for w in sel), max(w[2] for w in sel), s[max(0, m.start() - 6): m.end() + 6]))
print(f"{book}-{n} '{query}': hits {len(hits)}", [(h[0], round(h[2]), h[5]) for h in hits][:6])
if len(hits) >= occ:
    ci, pgn, yc, x0, x1, ctx = hits[occ - 1]
    pix = doc[pgn].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(max(0, x0 - PAD), yc - 17, min(595, x1 + PAD), yc + 17))
    fn = f"{SP}/zoom/wa_{book}_{n}_{q[:6]}_{occ}.png"; pix.save(fn); print(fn, pix.width, pix.height)
