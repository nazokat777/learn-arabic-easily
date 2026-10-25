# -*- coding: utf-8 -*-
"""Books 2/3 reading-text chunk generator.
region(n) = from bottom of lesson n-1 vocab table to lesson n vocab heading; reading lines = Arabic lines in region
(excluding vocab tables, the title (<= 40pt under the bold digit anchor) and the heading's Arabic part)."""
import sys, re, json, os
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
BOOKS = {2: (DL + r"\mabdaul-qiroat-2.pdf", 60), 3: (DL + r"\Mabdaul qiroat 3 chi kitob.pdf", 57)}
AR = re.compile(r'[\u0600-\u06FF\uFB50-\uFEFF]')
CYR = re.compile(r'[\u0400-\u04FF]')
Z = float(os.environ.get("CROP_Z", "2.9"))
LINES_PER_CHUNK = int(os.environ.get("CROP_LINES", "5"))

def page_lines(doc, pn):
    out = []
    for b in doc[pn].get_text("dict")["blocks"]:
        if b.get("type") != 0: continue
        for l in b.get("lines", []):
            t = "".join(s["text"] for s in l["spans"])
            out.append((fitz.Rect(l["bbox"]), t, l["spans"][0]["font"], l["spans"][0]["size"]))
    return out

def is_vocab_table(t):
    rows = t.extract()
    if not rows or len(rows[0]) < 2: return False
    return any(CYR.search(c or "") for r in rows for c in r)

def markers(doc):
    out = []
    for i in range(doc.page_count):
        for r, t, f, s in page_lines(doc, i):
            if "аънолар" in t:
                out.append((i, r.y0))
    return out

_tables = {}
def vocab_tables(doc, i):
    if (id(doc), i) not in _tables:
        _tables[(id(doc), i)] = [t.bbox for t in doc[i].find_tables().tables if is_vocab_table(t)]
    return _tables[(id(doc), i)]

def vocab_bottom(doc, marker, n):
    start = marker[n]
    end = marker.get(n + 1, (start[0] + 4, 0))
    last = start
    for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
        for bb in vocab_tables(doc, i):
            if (i, bb[1]) <= start or (i, bb[1]) > end: continue
            if (i, bb[3]) > last: last = (i, bb[3])
    return last

def run(book):
    path, nl = BOOKS[book]
    doc = fitz.open(path)
    m = markers(doc)
    print("book", book, "markers", len(m), file=sys.stderr)
    marker = {n: m[n] for n in range(1, nl + 1)}
    meta = {}
    os.makedirs(f"{SP}/chunks/b{book}", exist_ok=True)
    for n in range(1, nl + 1):
        start = vocab_bottom(doc, marker, n - 1) if n > 1 else (3, 0)
        end = (marker[n][0], marker[n][1] - 6)
        bands = []
        # picture anchor: first image block inside the region
        img_anchor = None
        for pn in range(start[0], end[0] + 1):
            for blk in doc[pn].get_text("dict")["blocks"]:
                if blk.get("type") == 1:
                    y0_, y1_ = blk["bbox"][1], blk["bbox"][3]
                    if (pn, y0_) > start and (pn, y0_) < end and (y1_ - y0_) > 40:
                        if img_anchor is None or (pn, y0_) < (img_anchor[0], img_anchor[2]):
                            img_anchor = (pn, y1_, y0_)
        for pn in range(start[0], end[0] + 1):
            lines = sorted(page_lines(doc, pn), key=lambda x: x[0].y0)
            tabs = vocab_tables(doc, pn)
            cyr_heads = [r for r, t, f, s in lines if CYR.search(t) and 'аънолар' in t.lower()]
            for r, t, f, s in lines:
                if (pn, r.y0) <= start or (pn, r.y0) >= end: continue
                if any(b[1] - 2 <= r.y0 <= b[3] + 2 for b in tabs): continue
                if CYR.search(t) or len(AR.findall(t)) < 2: continue
                if img_anchor is not None and (pn, r.y0) < (img_anchor[0], img_anchor[1] - 3):
                    continue
                if any(abs(r.y0 - c.y0) < 22 for c in cyr_heads):
                    continue
                bands.append((pn, r))
        anchor = img_anchor
        vis = []
        for pn_, r in bands:
            placed = False
            for v in vis:
                if v[0] == pn_ and abs(((r.y0 + r.y1) / 2) - ((v[1] + v[2]) / 2)) < 11:
                    v[1] = min(v[1], r.y0); v[2] = max(v[2], r.y1); v[3] = min(v[3], r.x0); v[4] = max(v[4], r.x1)
                    placed = True; break
            if not placed:
                vis.append([pn_, r.y0, r.y1, r.x0, r.x1])
        vis.sort(key=lambda v: (v[0], v[1]))
        bypage = {}
        for v in vis: bypage.setdefault(v[0], []).append(v)
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
        for k, (pg_, ya, yb, nlines) in enumerate(chunks, 1):
            clip = fitz.Rect(38, ya, 560, yb)
            pix = doc[pg_].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=clip)
            fn = f"{SP}/chunks/b{book}/l{n:02d}_c{k}.png"
            pix.save(fn)
            out.append({"file": fn, "page": pg_, "y0": ya, "y1": yb, "lines": nlines})
        meta[n] = out
        print(book, n, "pages", start[0], "-", end[0], "lines", len(vis), "chunks", len(chunks), "img" if anchor else "NOIMG", file=sys.stderr)
    json.dump(meta, open(f"{SP}/chunks/b{book}_meta.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

if __name__ == "__main__":
    run(int(sys.argv[1]))
