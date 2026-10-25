# -*- coding: utf-8 -*-
"""Vocabulary-table chunk generator for books 1-3.
Lesson n's vocab tables = vocab tables (any Cyrillic cell) located after the vocab heading n (маъно... marker) and before heading n+1.
Chunks of ROWS rows each -> chunks/v<book>/lNN_cK.png + chunks/v<book>_meta.json   usage: mkcrops_vocab.py BOOK"""
import sys, re, json, os
import pymupdf as fitz
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
import os; DL = os.environ.get("AUDIT_PDFS", r"C:\Users\User\Downloads\Telegram Desktop")
BOOKS = {1: (DL + r"\mabdaul-qiroat-1.pdf", 52), 2: (DL + r"\mabdaul-qiroat-2.pdf", 60), 3: (DL + r"\Mabdaul qiroat 3 chi kitob.pdf", 57)}
CYR = re.compile(r'[\u0400-\u04FF]')
Z = 3.0
ROWS = int(os.environ.get("VROWS", "7"))

def page_lines(doc, pn):
    out = []
    for b in doc[pn].get_text("dict")["blocks"]:
        if b.get("type") != 0: continue
        for l in b.get("lines", []):
            t = "".join(s["text"] for s in l["spans"])
            out.append((fitz.Rect(l["bbox"]), t))
    return out

def run(book):
    path, nl = BOOKS[book]
    doc = fitz.open(path)
    marks = []
    for i in range(doc.page_count):
        for r, t in page_lines(doc, i):
            if "аънолар" in t: marks.append((i, r.y0))
    print("book", book, "markers", len(marks), file=sys.stderr)
    # lesson n heading = marks[n-1] for book 1? (book 1 marks: one per lesson) ; books 2/3 had marks[0] = lesson 1? check count
    # audit_sentences uses marker[n] = m[n] for n in 1..nl (m[0] is an extra marker before lesson 1) in books 2/3; book 1 -> inspect
    heading = {n: marks[n] for n in range(1, nl + 1)}   # marks[0] is an extra heading before lesson 1 (same convention as audit_sentences.py)
    meta = {}
    os.makedirs(f"{SP}/chunks/v{book}", exist_ok=True)
    tcache = {}
    def tables(pn):
        if pn not in tcache:
            res = []
            for t in doc[pn].find_tables().tables:
                rows = t.extract()
                if rows and len(rows[0]) >= 2 and any(CYR.search(c or "") for r in rows for c in r):
                    res.append(t)
            tcache[pn] = res
        return tcache[pn]
    for n in range(1, nl + 1):
        start = heading[n]
        end = heading.get(n + 1, (doc.page_count, 0))
        out = []; k = 0
        for pn in range(start[0], min(end[0], doc.page_count - 1) + 1):
            for t in tables(pn):
                if (pn, t.bbox[1]) <= start or (pn, t.bbox[1]) >= end: continue
                rows = t.rows
                for a in range(0, len(rows), ROWS):
                    grp = rows[a:a + ROWS]
                    y0 = min(r.bbox[1] for r in grp) - 3; y1 = max(r.bbox[3] for r in grp) + 3
                    k += 1
                    pix = doc[pn].get_pixmap(matrix=fitz.Matrix(Z, Z), clip=fitz.Rect(t.bbox[0] - 3, y0, t.bbox[2] + 3, y1))
                    fn = f"{SP}/chunks/v{book}/l{n:02d}_c{k}.png"
                    pix.save(fn)
                    out.append({"file": fn, "page": pn, "y0": y0, "y1": y1, "x0": t.bbox[0] - 3, "x1": t.bbox[2] + 3, "rows": len(grp)})
        meta[n] = out
        print(book, n, "chunks", len(out), "rows", sum(c['rows'] for c in out), file=sys.stderr)
    json.dump(meta, open(f"{SP}/chunks/v{book}_meta.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

if __name__ == "__main__":
    run(int(sys.argv[1]))
