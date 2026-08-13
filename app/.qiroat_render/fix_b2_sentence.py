# -*- coding: utf-8 -*-
"""Audit fix: one sentence missing from BOOK 2 lesson 56 (الْبَبْغَاءُ).

Found by audit_sentences.py, which counts every sentence terminator (. ؟ ! ؛)
rather than full stops alone. That widening mattered: book 1's lesson 10 had
lost a sentence ending in ؟ that a stop-only count could never see.

Book 2 lessons 49 and 60 also showed one extra source mark each, but those are
their TITLES («مَنْ عَلَّمَ؟», «أَيُّ الثَّلَاثَةِ أَشَدُّ حُمْقًا؟») which we store in
titleAr, not in reading - false positives, nothing to fix.

Re-read from the page image at Matrix(7,7):
    فَيُسْمَعُ لَهَا ضَجِيْجٌ شَدِيْدٌ. [وَهُوَ يَعِيْشُ عَلَى أَثْمَارِ الأَشْجَارِ.] وَالْكَرْزُ الْبَرِّيُّ …
"""
import json, sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"
TEXT = "وَهُوَ يَعِيْشُ عَلَى أَثْمَارِ الأَشْجَارِ."
AFTER = "فَيُسْمَعُ لَهَا ضَجِيْجٌ شَدِيدٌ."


def main():
    data = json.load(open(PATH, encoding="utf-8"))
    lesson = next(l for l in data["lessons"]
                  if l.get("book") == 2 and l["num"] == 56)
    r = lesson["reading"]
    if f"{AFTER} {TEXT}" in r:
        print("already present, nothing to do")
        return
    assert AFTER in r, "anchor sentence not found"
    lesson["reading"] = r.replace(AFTER, f"{AFTER} {TEXT}", 1)
    print(f"book2 L56: + {TEXT}")

    c = Counter(l.get("book", 1) for l in data["lessons"])
    assert c[1] == 52 and c[2] == 60 and c[3] == 57, f"book counts wrong: {dict(c)}"
    json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
              ensure_ascii=False, indent=2)
    print("ok:", dict(sorted(c.items())))


if __name__ == "__main__":
    main()
