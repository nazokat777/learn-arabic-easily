# -*- coding: utf-8 -*-
"""Side-by-side: source vocab rows vs our stored entries, for one lesson.
Read-only. Usage: python .qiroat_render/inspect_lesson.py <book> <num>
"""
import json, re, sys, io, difflib
import fitz

sys.path.insert(0, ".qiroat_render")
# import first: audit_all re-wraps sys.stdout, which would close ours
from audit_all import (BOOKS, markers, is_vocab_table, key, CYR, ARA)
# audit_all already reconfigured sys.stdout to UTF-8; re-wrapping here would
# close the shared underlying buffer.

book, num = int(sys.argv[1]), int(sys.argv[2])
path, n_lessons = BOOKS[book]
doc = fitz.open(path)
m = markers(doc)
marker = {n: m[n] for n in range(1, n_lessons + 1)}
start = marker[num]
end = marker.get(num + 1, (start[0] + 4, 0))

data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
lesson = next(l for l in data["lessons"]
              if l.get("book", 1) == book and l["num"] == num)

print(f"BOOK {book} LESSON {num} - {lesson.get('titleAr','')}")
print(f"region: p{start[0]} .. p{end[0]}   ours: {len(lesson['vocab'])} entries\n")

print("--- SOURCE TABLES ---")
for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
    for tbl in doc[i].find_tables().tables:
        if not is_vocab_table(tbl):
            continue
        ty = tbl.bbox[1]
        if (i, ty) <= start or (i, ty) > end:
            continue
        print(f"  [table on page idx {i}, y {round(ty)}-{round(tbl.bbox[3])}, "
              f"{len(tbl.extract())} rows x {len(tbl.extract()[0])} cols]")
        for r, row in enumerate(tbl.extract()):
            cells = [(c or "").strip().replace("\n", " ") for c in row]
            has_ar = [bool(ARA.search(c)) for c in cells]
            print(f"    r{r:<2} " + " | ".join(
                (f"AR:{c[:20]}" if a else c[:26]) for c, a in zip(cells, has_ar)))

print("\n--- OURS ---")
for j, w in enumerate(lesson["vocab"]):
    pl = f"  (pl {w['pl']})" if w.get("pl") else ""
    print(f"  {j:<3} {w['ar'][:38]:<40} {w['uz']}{pl}")
