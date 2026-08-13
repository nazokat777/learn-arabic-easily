# -*- coding: utf-8 -*-
"""Audit fix: three sentences missing from BOOK 1 readings.

Found by audit_b1_reading.py, which bounds each lesson's reading between its
header and its vocab heading (so the previous lesson's exercises stay out) and
then compares FULL-STOP counts. Book 1's text layer loses 7-45% of its letters,
so letter counts are too blunt here - but full stops extract exactly, and these
lessons are lists of short sentences, so a dropped sentence is a dropped stop.

Each sentence re-read from the page image at Matrix(7-8) before inserting, and
inserted at the exact position the book prints it.
"""
import json, sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"

# lesson -> list of (text to insert, the text it must follow)
INSERTS = {
    # p17: "أَبِي يَكْتُبُ." is printed TWICE - once after "هَذَا أَبِي." and
    # again after "أَنْتَ تُطِيعُ مُعَلِّمَكَ." Only the first was transcribed.
    8: [("أَبِي يَكْتُبُ.", "أَنْتَ تُطِيعُ مُعَلِّمَكَ.")],
    # p20: two sentences skipped mid-paragraph.
    10: [("مَنْ هُوَ فِي الْجُنَيْنَةِ؟", "لِمَ فَتَحْتَ الشُّبَّاكَ؟"),
         ("شَرِبْتُ فِنْجَانًا شَايًا.", "أَيْنَ الْمِلْحُ؟")],
}


def main():
    data = json.load(open(PATH, encoding="utf-8"))
    for num, items in INSERTS.items():
        lesson = next(l for l in data["lessons"]
                      if l.get("book", 1) == 1 and l["num"] == num)
        for text, after in items:
            r = lesson["reading"]
            # Test the PAIR, not the sentence alone: lesson 8 prints
            # "أَبِي يَكْتُبُ." twice, so "is it present anywhere" would wrongly
            # decide the second occurrence was already transcribed.
            if f"{after} {text}" in r:
                print(f"L{num}: already present, skipped — {text}")
                continue
            assert after in r, f"L{num}: anchor not found — {after}"
            lesson["reading"] = r.replace(after, f"{after} {text}", 1)
            print(f"L{num}: + {text}")

    c = Counter(l.get("book", 1) for l in data["lessons"])
    assert c[1] == 52 and c[2] == 60 and c[3] == 57, f"book counts wrong: {dict(c)}"

    json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
              ensure_ascii=False, indent=2)
    print("ok:", dict(sorted(c.items())))


if __name__ == "__main__":
    main()
