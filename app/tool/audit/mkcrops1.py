# -*- coding: utf-8 -*-
"""Book-1 reading-text chunk generator.
For each lesson: anchor = bold-18 digit line == lesson number; reading = Arabic text-layer lines after
the title until the exercise heading ('машқ') or vocab heading ('аънолар'), across pages.
Writes chunk PNGs (<=5 visual lines each) + chunks/b1_meta.json."""
import sys, re, json, os
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; PDF = os.path.join(os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop"), "mabdaul-qiroat-1.pdf")
AR = re.compile(r'[\u0600-\u06FF\uFB50-\uFEFF]')
CYR = re.compile(r'[\u0400-\u04FF]')
Z = 2.9
LINES_PER_CHUNK = 5
doc = fitz.open(PDF)

def page_lines(pn):
    out = []
    for b in doc[pn].get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            t = "".join(s["text"] for s in l["spans"])
            out.append((fitz.Rect(l["bbox"]), t, l["spans"][0]["font"], l["spans"][0]["size"]))
    return out

REP = json.load(open(SP + "/b1crop/report.json", encoding="utf-8"))
START = {int(k): int(v[0][0].split('_p')[1].split('.')[0]) for k, v in REP.items()}

def is_bold(f): return 'Bold' in f

def stop_line(t):
    tl = t.lower()
    return ('машқ' in tl) or ('аънолар' in tl) or ('маъно' in tl and 'сўз' in tl)

def find_title(pn):
    lines = page_lines(pn)
    cyr_heads = [r for r, t, f, s in lines if CYR.search(t) and 'аънолар' in t.lower()]
    cands = []
    for r, t, f, s in lines:
        if is_bold(f) and len(AR.findall(t)) >= 8 and not CYR.search(t):
            if any(abs(r.y0 - c.y0) < 22 for c in cyr_heads):
                continue
            cands.append(r)
    return max(cands, key=lambda r: r.y0) if cands else None

meta = {}
for n in range(1, 53):
    pn0 = START[n]
    tr = find_title(pn0)
    y0 = tr.y1 if tr is not None else 0
    if tr is None:
        print("NO TITLE", n, pn0, file=sys.stderr)
    bands = []
    stop = False
    pn = pn0
    while not stop and pn < doc.page_count:
        lines = sorted(page_lines(pn), key=lambda x: x[0].y0)
        for r, t, f, s in lines:
            if pn == pn0 and r.y0 < y0 - 2:
                continue
            if stop_line(t) and (pn > pn0 or r.y0 > y0):
                stop = True
                break
            if is_bold(f) and len(AR.findall(t)) >= 8 and pn > pn0:
                stop = True
                break
            if is_bold(f):
                continue
            if len(AR.findall(t)) >= 2 and not CYR.search(t):
                bands.append((pn, r))
        pn += 1
        if pn - pn0 > 3:
            break
    # cluster into visual lines per page
    vis = []   # list of (page, y0, y1, x0, x1)
    for pn_, r in bands:
        placed = False
        for v in vis:
            if v[0] == pn_ and abs(((r.y0 + r.y1) / 2) - ((v[1] + v[2]) / 2)) < 11:
                v[1] = min(v[1], r.y0); v[2] = max(v[2], r.y1); v[3] = min(v[3], r.x0); v[4] = max(v[4], r.x1)
                placed = True
                break
        if not placed:
            vis.append([pn_, r.y0, r.y1, r.x0, r.x1])
    vis.sort(key=lambda v: (v[0], v[1]))
    bypage = {}
    for v in vis:
        bypage.setdefault(v[0], []).append(v)
    chunks = []
    for pg_, vs in bypage.items():
        for i in range(0, len(vs), LINES_PER_CHUNK):
            grp = vs[i:i + LINES_PER_CHUNK]
            c0 = (grp[0][1] + grp[0][2]) / 2
            c1 = (grp[-1][1] + grp[-1][2]) / 2
            ya = (((vs[i - 1][1] + vs[i - 1][2]) / 2 + c0) / 2) if i > 0 else grp[0][1] - 7
            yb = ((c1 + (vs[i + LINES_PER_CHUNK][1] + vs[i + LINES_PER_CHUNK][2]) / 2) / 2) if i + LINES_PER_CHUNK < len(vs) else grp[-1][2] + 7
            chunks.append((pg_, ya, yb, len(grp)))
    out = []
    os.makedirs(f"{SP}/chunks/b1", exist_ok=True)
    for k, (pg_, ya, yb, nl) in enumerate(chunks, 1):
        clip = fitz.Rect(38, ya, 560, yb)
        pix = doc[pg_].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip)
        fn = f"{SP}/chunks/b1/l{n:02d}_c{k}.png"
        pix.save(fn)
        out.append({"file": fn, "page": pg_, "y0": ya, "y1": yb, "lines": nl})
    meta[n] = out
    print(n, "pages", pn0, "lines", len(vis), "chunks", len(chunks), file=sys.stderr)
json.dump(meta, open(f"{SP}/chunks/b1_meta.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
