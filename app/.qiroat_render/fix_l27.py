# -*- coding: utf-8 -*-
"""Audit fix: lesson 27 (الْقِرْدُ) was missing the last row of its vocab table.

Found by audit_b3_vocab.py, which matches every Cyrillic source gloss against
our stored entries. The table's final row - [негр, занжий | الزِّنْجِيُّ | ялтироқ | بَرَّاقَةٌ]
at the foot of PDF idx 55 - had been skipped. Arabic re-read from the page
image at Matrix(5,5) before adding.
"""
import json, sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"
data = json.load(open(PATH, encoding="utf-8"))
lesson = next(l for l in data["lessons"] if l.get("book") == 3 and l["num"] == 27)

add = [
    {"ar": "بَرَّاقَةٌ", "uz": "yaltiroq"},
    {"ar": "الزِّنْجِيُّ", "uz": "negr, zanjiy"},
]
have = {w["ar"] for w in lesson["vocab"]}
for w in add:
    if w["ar"] not in have:
        lesson["vocab"].append(w)

json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
          ensure_ascii=False, indent=2)
print("L27 vocab is now", len(lesson["vocab"]), "entries")
