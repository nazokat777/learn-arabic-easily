# -*- coding: utf-8 -*-
"""Generic merge helper for Mabdaul qiroat BOOK 3 lesson batches.

Usage: a batch file defines `new_lessons` (list of dicts with book/num/titleAr/
reading/vocab) and calls merge(new_lessons).

Loads assets/content/qiroat_lessons.json, drops any existing book-3 rows whose
num is in the batch, appends the new rows, sorts by (book, num) and writes back
with indent=2 / ensure_ascii=False / newline='\n'.
"""
import json, sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

PATH = "assets/content/qiroat_lessons.json"


def v(ar, uz, pl=None):
    d = {"ar": ar}
    if pl:
        d["pl"] = pl
    d["uz"] = uz
    return d


def merge(new_lessons, book=3):
    data = json.load(open(PATH, encoding="utf-8"))
    lessons = data["lessons"]
    new_nums = {l["num"] for l in new_lessons}
    before = len(lessons)
    lessons = [l for l in lessons if not (l.get("book") == book and l["num"] in new_nums)]
    removed = before - len(lessons)
    lessons.extend(new_lessons)
    lessons.sort(key=lambda l: (l.get("book", 1), l["num"]))
    data["lessons"] = lessons
    json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
              ensure_ascii=False, indent=2)

    c = Counter(l.get("book", 1) for l in lessons)
    print("removed old dup rows:", removed)
    print("total lessons now:", len(lessons))
    print("by book:", dict(sorted(c.items())))
    for l in new_lessons:
        print(f"  L{l['num']}: vocab={len(l['vocab'])} "
              f"reading_chars={len(l['reading'])} "
              f"newlines={l['reading'].count(chr(10))}")

    # integrity checks
    b = sorted(x["num"] for x in lessons if x.get("book") == book)
    gaps = [n for n in range(1, max(b) + 1) if n not in b]
    print("book", book, "nums:", b[0], "..", b[-1], "gaps:", gaps or "none")
    bad = []
    for l in lessons:
        if not l.get("titleAr") or not l.get("reading") or not l.get("vocab"):
            bad.append((l.get("book"), l.get("num")))
        for w in l.get("vocab", []):
            if not w.get("ar") or not w.get("uz"):
                bad.append((l.get("book"), l.get("num"), "empty vocab field"))
    print("empty/invalid rows:", bad or "none")
