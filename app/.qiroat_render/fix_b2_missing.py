# -*- coding: utf-8 -*-
"""Audit fix: three vocab entries missing from BOOK 2.

Found by audit_all.py (every Cyrillic source gloss matched against our JSON),
then each row re-read from the page image at Matrix(5,5):

  L9  p17 row 'келмоқ'      -> أَتَى، يَأْتِي، اِئْتِ، اِتْيَانٌ
  L16 p30 last row          -> اِنْطَلَقَ، يَنْطَلِقُ، اِنْطَلِقْ، اِنْطِلاَقٌ  (жўнамоқ)
                               إِذَنْ                                        (ундай бўлса)

L16's row sits alone at the top of the following page - the same cross-page
spill that hid L27's last row in book 3.
"""
import json, sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"
data = json.load(open(PATH, encoding="utf-8"))

ADD = {
    9: [{"ar": "أَتَى، يَأْتِي، اِئْتِ، اِتْيَانٌ", "uz": "kelmoq"}],
    16: [{"ar": "اِنْطَلَقَ، يَنْطَلِقُ، اِنْطَلِقْ، اِنْطِلاَقٌ", "uz": "jo'namoq"},
         {"ar": "إِذَنْ", "uz": "unday bo'lsa"}],
}

for num, words in ADD.items():
    lesson = next(l for l in data["lessons"]
                  if l.get("book") == 2 and l["num"] == num)
    have = {w["ar"] for w in lesson["vocab"]}
    for w in words:
        if w["ar"] not in have:
            lesson["vocab"].append(w)
    print(f"book2 L{num}: {len(lesson['vocab'])} entries")

# guard against the build-script accident that once cut book 2 to 5 lessons
from collections import Counter
c = Counter(l.get("book", 1) for l in data["lessons"])
assert c[1] == 52 and c[2] == 60, f"book counts wrong: {dict(c)}"

json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
          ensure_ascii=False, indent=2)
print("ok:", dict(sorted(c.items())))
