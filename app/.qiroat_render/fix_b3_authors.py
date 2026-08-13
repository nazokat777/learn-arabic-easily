# -*- coding: utf-8 -*-
"""Audit fix: four book-3 poems were missing the author line the book prints
under them.

Found by comparing FULL-STOP counts between the PDF text layer and our reading.
Punctuation extracts cleanly even though the Arabic letters are garbled, so a
period we never transcribed shows up as a source/ours mismatch. After excluding
the page header "www.arabic.uz" (2 dots per page) the mismatch dropped from 48
lessons to 5, and chasing those five surfaced the missing attributions.

Each line re-read from the page image at Matrix(10,10).
"""
import json, sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"

# lesson -> author line exactly as the book prints it, appended as its own line
AUTHORS = {
    16: "(أ.ظ. خَيْرُ اللهِ)",
    21: "(ابن الْبارِيَة)",
    29: "(الشيخ عبد العزيز جاويش)",
    33: "(عَبْدُ العَزِيزِ الْجَاوِيش)",
}


def main():
    data = json.load(open(PATH, encoding="utf-8"))
    for num, author in AUTHORS.items():
        lesson = next(l for l in data["lessons"]
                      if l.get("book") == 3 and l["num"] == num)
        if "(" in lesson["reading"]:
            print(f"L{num}: already has an attribution, skipped")
            continue
        lesson["reading"] = lesson["reading"].rstrip() + "\n" + author
        print(f"L{num}: + {author}")

    c = Counter(l.get("book", 1) for l in data["lessons"])
    assert c[1] == 52 and c[2] == 60 and c[3] == 57, f"book counts wrong: {dict(c)}"

    json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
              ensure_ascii=False, indent=2)
    print("ok:", dict(sorted(c.items())))


if __name__ == "__main__":
    main()
