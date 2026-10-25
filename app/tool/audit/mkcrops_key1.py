# -*- coding: utf-8 -*-
"""Book-1 exercise-answer (key) chunk generator: Arabic lines after each
'N-чи дарснинг ўзбекча матнидаги таржима' heading, until the next 'арабча матнидаги таржима' heading."""
import sys, re, json, os
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; PDF = os.path.join(os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop"), "mabdaul-qiroat-1.pdf")
AR = re.compile(r'[\u0600-\u06FF\uFB50-\uFEFF]')
CYR = re.compile(r'[\u0400-\u04FF]')
Z = 2.9
LPC = 5
doc = fitz.open(PDF)
events = []
for pn in range(97, doc.page_count):
    ls = []
    for b in doc[pn].get_text("dict")["blocks"]:
        if b.get("type") != 0: continue
        for l in b.get("lines", []):
            t = "".join(s["text"] for s in l["spans"])
            ls.append((fitz.Rect(l["bbox"]), t, l["spans"][0]["font"], l["spans"][0]["size"]))
    ls.sort(key=lambda x: (x[0].y0, x[0].x0))
    # heading groups: BoldItal Cyrillic lines
    hl = [(r, t) for r, t, f, s in ls if 'BoldItal' in f and CYR.search(t)]
    groups = []
    for r, t in hl:
        if groups and r.y0 - groups[-1][1] <= 26:   # same or next heading row
            groups[-1][1] = max(groups[-1][1], r.y0); groups[-1][2] += ' ' + t.strip(); groups[-1][3] = max(groups[-1][3], r.y1)
        else:
            groups.append([r.y0, r.y0, t.strip(), r.y1])
    for y0, _, txt, y1 in groups:
        tl = txt.lower()
        if 'матнидаги' in tl and 'таржима' in tl:
            events.append((pn, fitz.Rect(0, y0, 10, y1), 'head_uz' if 'ўзбекча' in tl else 'head_ar', txt))
    for r, t, f, s in ls:
        if len(AR.findall(t)) >= 2 and not CYR.search(t) and 'Bold' not in f:
            events.append((pn, r, 'arab', t))
events.sort(key=lambda e: (e[0], e[1].y0))
heads = [e for e in events if e[2] == 'head_uz']
print("head_uz count", len(heads), "head_ar count", len([e for e in events if e[2] == 'head_ar']), file=sys.stderr)
meta = {}
os.makedirs(f"{SP}/chunks/k1", exist_ok=True)
k = 0
i = 0
while i < len(events):
    if events[i][2] != 'head_uz':
        i += 1; continue
    k += 1
    j = i + 1
    bands = []
    while j < len(events) and events[j][2] not in ('head_ar', 'head_uz'):
        bands.append((events[j][0], events[j][1])); j += 1
    vis = []
    for pn_, r in bands:
        placed = False
        for v in vis:
            if v[0] == pn_ and abs(((r.y0 + r.y1) / 2) - ((v[1] + v[2]) / 2)) < 11:
                v[1] = min(v[1], r.y0); v[2] = max(v[2], r.y1); placed = True; break
        if not placed: vis.append([pn_, r.y0, r.y1])
    vis.sort(key=lambda v: (v[0], v[1]))
    bypage = {}
    for v in vis: bypage.setdefault(v[0], []).append(v)
    out = []; c = 0
    for pg_, vs in bypage.items():
        for a in range(0, len(vs), LPC):
            grp = vs[a:a + LPC]
            c0 = (grp[0][1] + grp[0][2]) / 2; c1 = (grp[-1][1] + grp[-1][2]) / 2
            ya = (((vs[a - 1][1] + vs[a - 1][2]) / 2 + c0) / 2) if a > 0 else grp[0][1] - 7
            yb = ((c1 + (vs[a + LPC][1] + vs[a + LPC][2]) / 2) / 2) if a + LPC < len(vs) else grp[-1][2] + 7
            c += 1
            pix = doc[pg_].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(38, ya, 560, yb))
            fn = f"{SP}/chunks/k1/k{k:02d}_c{c}.png"
            pix.save(fn)
            out.append({"file": fn, "page": pg_, "y0": ya, "y1": yb, "lines": len(grp)})
    meta[k] = {"head": events[i][3], "page": events[i][0], "chunks": out, "lines": len(vis)}
    print(k, events[i][3][:30], "page", events[i][0], "lines", len(vis), "chunks", len(out), file=sys.stderr)
    i = j
json.dump(meta, open(f"{SP}/chunks/k1_meta.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
