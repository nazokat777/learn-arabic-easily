# -*- coding: utf-8 -*-
"""Sentence-count audit for books 2 and 3 - stricter than the earlier passes.

Why this exists: the first punctuation pass counted only full stops. Book 1's
lesson 10 was missing «مَنْ هُوَ فِي الْجُنَيْنَةِ؟», a sentence that ends in a
QUESTION MARK - invisible to a stop-only count. It was caught only because the
same lesson happened to lose a second sentence that did end in a stop. So count
every sentence terminator: . ؟ ! ؛

Letter counts cannot catch a dropped sentence's punctuation, and the extractor's
Arabic is garbled, but punctuation extracts exactly - which is what makes this
work.

Region per lesson (books 2 and 3 have no exercises between reading and vocab):
    start = bottom of the previous lesson's last vocab table
    end   = this lesson's vocab heading, minus a few points so the Arabic in the
            heading «مَعَانِي الْمُفْرَدَات» stays out
Read-only.
"""
import json, re, sys, io
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BOOKS = {
    2: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-2 (2).pdf", 60),
    3: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf", 57),
}
CYR = re.compile(r"[\u0400-\u04FF]")
ARA = re.compile(r"[\u0600-\u06FF]")
TERM = re.compile(r"[.؟!؛]")
HEADER = "arabic.uz"


def lines(doc, i):
    for blk in doc[i].get_text("dict")["blocks"]:
        if blk.get("type") != 0:
            continue
        for line in blk["lines"]:
            yield line["bbox"][1], "".join(s["text"] for s in line["spans"])


def markers(doc):
    out = []
    for i in range(doc.page_count):
        for y, t in lines(doc, i):
            if "аънолар" in t:
                out.append((i, y))
    return out


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
            if (i, t.bbox[1]) <= start or (i, t.bbox[1]) > end:
                continue
            if (i, t.bbox[3]) > last:
                last = (i, t.bbox[3])
    return last


def count(doc, start, end):
    n = 0
    for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
        skip = [t.bbox for t in doc[i].find_tables().tables if is_vocab_table(t)]
        for y, t in lines(doc, i):
            if (i, y) <= start or (i, y) >= end:
                continue
            if any(b[1] - 2 <= y <= b[3] + 2 for b in skip):
                continue
            if CYR.search(t) or HEADER in t:
                continue
            if not ARA.search(t):     # blank rules / stray marks carry no Arabic
                continue
            n += len(TERM.findall(t))
    return n


def main():
    data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
    grand = []
    for book, (path, n_lessons) in BOOKS.items():
        doc = fitz.open(path)
        m = markers(doc)
        marker = {n: m[n] for n in range(1, n_lessons + 1)}
        ours = {l["num"]: l for l in data["lessons"] if l.get("book", 1) == book}

        flagged = []
        for n in sorted(ours):
            start = vocab_bottom(doc, marker, n - 1) if n > 1 else (3, 0)
            end = (marker[n][0], marker[n][1] - 6)
            src = count(doc, start, end)
            mine = len(TERM.findall(ours[n]["reading"]))
            if mine < src:
                flagged.append((n, src, mine))
        print(f"\n===== BOOK {book}: {len(flagged)} / {len(ours)} lessons "
              f"have FEWER sentence marks than the source")
        for n, s, mi in flagged:
            print(f"  L{n:<3} source {s:<3} ours {mi:<3} ({mi - s:+d})")
        grand += [(book, n) for n, _, _ in flagged]
    print(f"\ntotal lessons to check: {len(grand)}")


if __name__ == "__main__":
    main()
