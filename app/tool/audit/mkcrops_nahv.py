# -*- coding: utf-8 -*-
"""Strips of Nahv pages (scanned, 1-based printed page numbers == PDF page).
usage: mkcrops_nahv.py PAGE_FROM PAGE_TO  -> chunks/n/pNNN_cK.png + chunks/n_meta.json (merged)
Each page: text region y in [38,640] pt, cut into strips of ~STRIP pt at ink valleys."""
import sys, json, os
import numpy as np
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; PDF = os.path.join(os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop"), "durus-an-Nahviyya-1-2-3-4-qismlar.pdf")
Z = 4.16            # native scan resolution
Y0, Y1 = 36.0, 641.0
STRIP = 205.0       # target strip height in pt (~9 lines)
a, b = int(sys.argv[1]), int(sys.argv[2])
doc = fitz.open(PDF)
mf = f"{SP}/chunks/n_meta.json"
meta = json.load(open(mf, encoding='utf-8')) if os.path.exists(mf) else {}
for p in range(a, b + 1):
    pg = doc[p - 1]
    full = pg.get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(0, Y0, pg.rect.width, Y1), colorspace=fitz.csGRAY)
    arr = np.frombuffer(full.samples, dtype=np.uint8).reshape(full.height, full.width)
    dark = (arr < 140).sum(axis=1).astype(float)          # ink per pixel row
    # smooth over 5 px
    sm = np.convolve(dark, np.ones(5) / 5, mode='same')
    ink_rows = np.where(sm > 3)[0]
    if len(ink_rows) == 0:
        meta[str(p)] = []; continue
    top, bot = max(0, ink_rows[0] - 12), min(full.height, ink_rows[-1] + 14)
    height_pt = (bot - top) / Z
    n = max(1, int(round(height_pt / STRIP)))
    cuts = [top]
    for k in range(1, n):
        target = top + (bot - top) * k / n
        lo, hi = int(target - 90), int(target + 90)
        seg = sm[lo:hi]; j = int(np.argmin(seg)); cuts.append(lo + j)
    cuts.append(bot)
    out = []
    for k in range(n):
        y0 = cuts[k]; y1 = cuts[k + 1]
        img = fitz.Pixmap(full, 0)  # placeholder to keep API simple
        clip_pt = fitz.Rect(0, Y0 + y0 / Z, pg.rect.width, Y0 + y1 / Z)
        pix = pg.get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip_pt, colorspace=fitz.csGRAY)
        fn = f"{SP}/chunks/n/p{p:03d}_c{k + 1}.png"
        pix.save(fn); out.append({"file": fn, "y0": clip_pt.y0, "y1": clip_pt.y1})
    meta[str(p)] = out
    print(p, 'strips', n, [round((c) / Z) for c in cuts])
json.dump(meta, open(mf, 'w', encoding='utf-8'), indent=1)
