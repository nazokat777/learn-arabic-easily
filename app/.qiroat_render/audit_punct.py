# -*- coding: utf-8 -*-
"""Punctuation audit across all three books - the check letter counts CANNOT do.

A dropped full stop merges two sentences without changing a single letter, so
audit_b3_letters.py is blind to it. But the PDF text layer extracts PUNCTUATION
cleanly even though the Arabic letters are garbled, so comparing '.' counts per
lesson finds exactly that class of omission.

In book 3 this surfaced four poems missing the author line the book prints under
them. Run it for books 1 and 2 too.

Read-only.
"""
import json, re, sys, io
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BOOKS = {
    1: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-1 (2).pdf", 52),
    2: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-2 (2).pdf", 60),
    3: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf", 57),
}
CYR = re.compile(r"[\u0400-\u04FF]")
# the page header "www.arabic.uz" carries 2 dots on every page - never content
HEADER = "arabic.uz"


def markers(doc):
    out = []
    for i in range(doc.page_count):
        for blk in doc[i].get_text("dict")["blocks"]:
            if blk.get("type") != 0:
                continue
            for line in blk["lines"]:
                if "аънолар" in "".join(s["text"] for s in line["spans"]):
                    out.append((i, line["bbox"][1]))
    return out


def gt(pos, i, y):
    return (i, y) > pos


def is_vocab_table(t):
    rows = t.extract()
    if not rows or len(rows[0]) < 2:
        return False
    return any(CYR.search(c or "") for r in rows for c in r)


def vocab_bottom(doc, marker, n):
    start = marker[n]
    end = marker.get(n + 1, (start[0] + 4, 0))
    last = start
    for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
        for t in doc[i].find_tables().tables:
            if not is_vocab_table(t):
                continue
            if not gt(start, i, t.bbox[1]) or gt(end, i, t.bbox[1]):
                continue
            if (i, t.bbox[3]) > last:
                last = (i, t.bbox[3])
    return last


def region_lines(doc, start, end):
    """Non-Cyrillic, non-header lines of the reading area, skipping vocab tables."""
    for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
        page = doc[i]
        skip = [t.bbox for t in page.find_tables().tables if is_vocab_table(t)]
        for blk in page.get_text("dict")["blocks"]:
            if blk.get("type") != 0:
                continue
            for line in blk["lines"]:
                y0 = line["bbox"][1]
                if not gt(start, i, y0) or gt(end, i, y0):
                    continue
                if any(b[1] - 2 <= y0 <= b[3] + 2 for b in skip):
                    continue
                t = "".join(s["text"] for s in line["spans"])
                if CYR.search(t) or HEADER in t:
                    continue
                yield i, round(y0), t


def audit(book, ours):
    path, n_lessons = BOOKS[book]
    doc = fitz.open(path)
    m = markers(doc)
    if len(m) < n_lessons + 1:
        print(f"BOOK {book}: only {len(m)} markers, skipping")
        return []
    marker = {n: m[n] for n in range(1, n_lessons + 1)}

    flagged = []
    for n in sorted(ours):
        start = vocab_bottom(doc, marker, n - 1) if n > 1 else (3, 0)
        end = (marker[n][0], marker[n][1] - 6)
        src = sum(t.count(".") for _, _, t in region_lines(doc, start, end))
        mine = ours[n]["reading"].count(".")
        if src != mine:
            flagged.append((n, src, mine))
    print(f"\n===== BOOK {book}: {len(flagged)} / {len(ours)} lessons differ")
    for n, s, mi in flagged:
        print(f"  L{n:<3} source {s:<3} ours {mi:<3} ({mi - s:+d})")
        if mi < s:   # we dropped something - show the source lines with dots
            st = vocab_bottom(doc, marker, n - 1) if n > 1 else (3, 0)
            en = (marker[n][0], marker[n][1] - 6)
            for i, y, t in region_lines(doc, st, en):
                if "." in t and (t.strip().startswith("(") or len(t.strip()) < 45):
                    print(f"        idx={i} y={y} {t.strip()[:50]!r}")
    return flagged


def main():
    data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
    by_book = {}
    for l in data["lessons"]:
        by_book.setdefault(l.get("book", 1), {})[l["num"]] = l
    total = 0
    for b in (1, 2, 3):
        total += len(audit(b, by_book.get(b, {})))
    print(f"\nlessons with a punctuation delta: {total}")


if __name__ == "__main__":
    main()
