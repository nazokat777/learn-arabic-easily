# -*- coding: utf-8 -*-
"""wc.py BOOK LESSON CHUNK QUERY [z=12] [pad=14] [occ=1] [all]
Find QUERY (skeleton, diacritics ignored) in the PDF text layer of that chunk's region and render a zoomed crop of the matched fragments
(+pad pt each side, full line height). Text-layer letters are mostly right (marks are scrambled), geometry is exact.
Prints candidates (line y, x-range, joined skeleton context)."""
import sys, re, json, io, pymupdf as fitz
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDFS = {"1": DL + r"\mabdaul-qiroat-1.pdf", "k1": DL + r"\mabdaul-qiroat-1.pdf", "2": DL + r"\mabdaul-qiroat-2.pdf", "k2": DL + r"\mabdaul-qiroat-2.pdf", "3": DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ة': 'ه'})
def sk(s): return re.sub(r'[^\u0621-\u064A]', '', DIAC.sub('', s).translate(TR))
book, n, c, query = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
Z = 12.0; PAD = 14.0; occ = 1; show_all = False
for a in sys.argv[5:]:
    if a.startswith('z='): Z = float(a[2:])
    elif a.startswith('pad='): PAD = float(a[4:])
    elif a.startswith('occ='): occ = int(a[4:])
    elif a == 'all': show_all = True
meta = json.load(open(f"{SP}/chunks/{book if book.startswith('k') else 'b' + book}_meta.json", encoding="utf-8"))
ent = meta[str(n)]; chunks = ent["chunks"] if isinstance(ent, dict) else ent
ch = chunks[c - 1]
doc = fitz.open(PDFS[book]); pg = doc[ch["page"]]
ws = [w for w in pg.get_text("words") if ch["y0"] - 4 <= (w[1] + w[3]) / 2 <= ch["y1"] + 4]
# cluster into lines by y center
ws.sort(key=lambda w: (w[1] + w[3]) / 2)
lines = []
for w in ws:
    yc = (w[1] + w[3]) / 2
    if lines and abs(lines[-1]["y"] - yc) < 7: lines[-1]["w"].append(w)
    else: lines.append({"y": yc, "w": [w]})
q = sk(query)
hits = []
for li, L in enumerate(lines):
    frs = sorted(L["w"], key=lambda w: -(w[0] + w[2]) / 2)   # RTL
    s = ""; owner = []
    for w in frs:
        t = sk(w[4])
        s += t; owner += [w] * len(t)
    if show_all: print("LINE", li + 1, round(L["y"]), s)
    for m in re.finditer(re.escape(q), s):
        sel = owner[m.start():m.end()]
        x0 = min(w[0] for w in sel); x1 = max(w[2] for w in sel)
        hits.append((li + 1, L["y"], x0, x1, s[max(0, m.start() - 8):m.end() + 8]))
print("chunk", c, "page", ch["page"], "lines:", len(lines), "hits:", len(hits))
for h in hits: print("  line %d y=%.0f x=[%.0f,%.0f] ctx=%s" % h)
if len(hits) >= occ:
    li, y, x0, x1, ctx = hits[occ - 1]
    clip = fitz.Rect(max(0, x0 - PAD), y - 17, min(595, x1 + PAD), y + 17)
    pix = pg.get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip)
    fn = f"{SP}/zoom/wc_{book}_{n}_{c}_{q[:6]}_{occ}.png"
    pix.save(fn); print(fn, pix.width, pix.height)
