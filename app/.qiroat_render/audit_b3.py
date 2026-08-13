# -*- coding: utf-8 -*-
"""Completeness audit for Mabdaul qiroat BOOK 3.

Proves no vocab entry and no reading paragraph was dropped.

Anchoring: the lesson NUMBER in the header is unreliable (the embedded font
subset garbles digits - lesson 39 extracts as "31"), and Arabic is garbled
throughout. But the Cyrillic heading "Луғатларнинг маънолари" that opens every
vocab table extracts perfectly, and there is exactly one per lesson. So:

    markers[n]        -> start of lesson n's vocab table
    (markers[n], markers[n+1])   -> lesson n's vocab tables
    (end of lesson n's vocab, markers[n+1]) -> lesson n+1's reading

Arabic word BOUNDARIES survive the garbling even though letter order does not,
so Arabic token counts are a valid completeness signal for readings.
"""
import json, re, sys, io
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf"
JSON_PATH = "assets/content/qiroat_lessons.json"
CYR = re.compile(r"[\u0400-\u04FF]")
ARA = re.compile(r"[\u0600-\u06FF]")


def find_markers(doc):
    """All 'Луғатларнинг маънолари' positions as (page_idx, y), in order."""
    out = []
    for i in range(doc.page_count):
        for blk in doc[i].get_text("dict")["blocks"]:
            if blk.get("type") != 0:
                continue
            for line in blk["lines"]:
                t = "".join(s["text"] for s in line["spans"])
                if "аънолар" in t:
                    out.append((i, line["bbox"][1]))
    return out


def after(pos, page_idx, y):
    return (page_idx, y) > pos


def vocab_pairs(doc, start, end):
    """Count (ar,uz) pairs in tables between start and end. Cols=[uzA,arB,uzC,arD]."""
    pairs, rows, blank_uz = 0, 0, 0
    for i in range(start[0], end[0] + 1):
        page = doc[i]
        for tbl in page.find_tables().tables:
            ty = tbl.bbox[1]
            if not after(start, i, ty) or after(end, i, ty):
                continue
            for row in tbl.extract():
                if len(row) < 4:
                    continue
                uzA, arB, uzC, arD = [(c or "").strip() for c in row[:4]]
                if not any([uzA, arB, uzC, arD]):
                    continue
                rows += 1
                for ar, uz in ((arD, uzC), (arB, uzA)):
                    if ARA.search(ar):
                        pairs += 1
                        if not CYR.search(uz):
                            blank_uz += 1
    return pairs, rows, blank_uz


def reading_tokens(doc, start, end):
    """Arabic tokens in the prose between two positions, skipping table areas."""
    n = 0
    for i in range(start[0], end[0] + 1):
        page = doc[i]
        boxes = [t.bbox for t in page.find_tables().tables]
        for blk in page.get_text("dict")["blocks"]:
            if blk.get("type") != 0:
                continue
            for line in blk["lines"]:
                x0, y0, x1, y1 = line["bbox"]
                if not after(start, i, y0) or after(end, i, y0):
                    continue
                if any(b[1] - 2 <= y0 <= b[3] + 2 for b in boxes):
                    continue                      # inside a vocab table
                t = "".join(s["text"] for s in line["spans"])
                if CYR.search(t):
                    continue                      # Uzbek helper text
                n += sum(1 for w in t.split() if ARA.search(w))
    return n


def main():
    doc = fitz.open(PDF)
    data = json.load(open(JSON_PATH, encoding="utf-8"))
    ours = {l["num"]: l for l in data["lessons"] if l.get("book") == 3}
    m = find_markers(doc)
    lesson_marker = {n: m[n] for n in range(1, 58)}   # m[0] is the intro sample

    done = sorted(ours)
    print(f"book-3 lessons in JSON: {len(done)}  (nums {done[0]}..{done[-1]})")
    print(f"vocab markers located: {len(m)} (expect 59: 1 intro + 57 lessons + 1 appendix)\n")

    print(f"{'L':>3} | {'vocab src':>9} {'json':>5} {'d':>4} | "
          f"{'read src':>8} {'json':>5} {'d%':>6} | pages")
    bad_v, bad_r = [], []
    for n in done:
        start = lesson_marker[n]
        end = lesson_marker.get(n + 1, (start[0] + 4, 0))
        src_v, rows, blank = vocab_pairs(doc, start, end)
        mine_v = len(ours[n].get("vocab", []))
        dv = src_v - mine_v

        # reading of lesson n sits between marker n-1's tables and marker n
        rstart = lesson_marker[n - 1] if n > 1 else (3, 0)
        src_r = reading_tokens(doc, rstart, start)
        mine_r = len(ours[n].get("reading", "").split())
        dr = (mine_r - src_r) / src_r * 100 if src_r else 0

        fv = "" if abs(dv) <= 1 else " <<V"
        fr = "" if abs(dr) <= 12 else " <<R"
        if abs(dv) > 1:
            bad_v.append(n)
        if abs(dr) > 12:
            bad_r.append(n)
        print(f"{n:>3} | {src_v:>9} {mine_v:>5} {dv:>+4} | "
              f"{src_r:>8} {mine_r:>5} {dr:>+5.0f}% | p{start[0]}-{end[0]}{fv}{fr}")

    print("\n--- field hygiene ---")
    issues = 0
    for n in done:
        r = ours[n].get("reading", "")
        if "  " in r or r != r.strip():
            print(f"  L{n}: whitespace problem"); issues += 1
        for j, w in enumerate(ours[n].get("vocab", [])):
            if not w.get("ar", "").strip() or not w.get("uz", "").strip():
                print(f"  L{n} vocab[{j}]: empty field"); issues += 1
            if CYR.search(w.get("uz", "")):
                print(f"  L{n} vocab[{j}]: untransliterated Cyrillic"); issues += 1
            if ARA.search(w.get("uz", "")):
                print(f"  L{n} vocab[{j}]: Arabic in uz field"); issues += 1
    print(f"  {issues} hygiene issue(s)")

    print(f"\nvocab-count mismatches : {bad_v or 'none'}")
    print(f"reading-length outliers: {bad_r or 'none'}")


if __name__ == "__main__":
    main()
