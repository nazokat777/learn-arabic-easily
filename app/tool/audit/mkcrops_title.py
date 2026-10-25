# -*- coding: utf-8 -*-
"""Title crops for books 2 and 3: the bold, centred, short Arabic line(s) just above each lesson's first chunk."""
import json, re, io, sys, os
import pymupdf as fitz
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
PDF = {2: DL + r"\mabdaul-qiroat-2.pdf", 3: DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
ARB = re.compile(r'[\u0621-\u064A]')
out = {}
for book in (2, 3):
    doc = fitz.open(PDF[book])
    meta = json.load(open(f"{SP}/chunks/b{book}_meta.json", encoding='utf-8'))
    for k in sorted(meta, key=int):
        n = int(k); ent = meta[k]; chunks = ent['chunks'] if isinstance(ent, dict) else ent
        c0 = chunks[0]; pn = c0['page']; y0 = c0['y0']
        found = None
        for pg, lo, hi in ((pn, 0, y0 + 3), (pn - 1, 300, 842)):
            if pg < 0: continue
            cands = []
            for b in doc[pg].get_text('dict')['blocks']:
                if b.get('type') != 0: continue
                for l in b['lines']:
                    t = ''.join(s['text'] for s in l['spans']).strip()
                    sp = l['spans'][0]
                    yc = (l['bbox'][1] + l['bbox'][3]) / 2; xc = (l['bbox'][0] + l['bbox'][2]) / 2; w = l['bbox'][2] - l['bbox'][0]
                    if not (lo <= yc <= hi): continue
                    if 'Bol' not in sp['font'] or not ARB.search(t): continue
                    if abs(xc - 297) > 45 or w > 330: continue
                    if len(re.sub(r'[^\u0621-\u064A]', '', t)) < 2: continue
                    if 'بسم' in t: continue
                    cands.append((yc, l['bbox'], t))
            if cands:
                cands.sort()
                last = cands[-1]; grp = [last]
                for c in reversed(cands[:-1]):
                    if grp[0][0] - c[0] <= 34: grp.insert(0, c)
                found = (pg, grp); break
        if not found:
            out[(book, n)] = None; print('NOT FOUND', book, n); continue
        pg, grp = found
        ya = min(g[1][1] for g in grp) - 8; yb = max(g[1][3] for g in grp) + 8
        x0 = max(20, min(g[1][0] for g in grp) - 25); x1 = min(575, max(g[1][2] for g in grp) + 25)
        pix = doc[pg].get_pixmap(matrix=fitz.Matrix(6, 6), clip=fitz.Rect(x0, ya, x1, yb))
        fn = f"{SP}/chunks/t/t{book}_l{n:02d}.png"; pix.save(fn)
        out[(book, n)] = fn
print('crops', sum(1 for v in out.values() if v), 'of', len(out))
lines = []
for (book, n), fn in out.items():
    if fn:
        lines.append(f"Book {book} lesson {n}:"); lines.append(f"  image: {fn}"); lines.append("")
open(f"{SP}/tasks/t_batch1.txt", 'w', encoding='utf-8').write("\n".join(lines))
