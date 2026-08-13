# -*- coding: utf-8 -*-
"""Tight completeness audit: ARABIC LETTER COUNTS, book 3.

The PDF's Arabic text layer garbles ligature ORDER but preserves the letters
themselves, so counting bare Arabic letters (diacritics stripped) in a page
region and comparing with our stored text detects a dropped word or paragraph
far more sharply than token counts do.

Region model (see audit_b3.py for why the Cyrillic vocab heading is the anchor):
    marker[n]                    -> lesson n's vocab heading
    vend[n]                      -> bottom of lesson n's last vocab table
    (vend[n-1], marker[n])       -> lesson n's title + reading  (poems included:
                                    poem text lives inside 2-col tables)
"""
import json, re, sys, io, unicodedata
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf"
JSON_PATH = "assets/content/qiroat_lessons.json"
CYR = re.compile(r"[\u0400-\u04FF]")
# Arabic letters only: exclude harakat/tatweel (U+064B..U+0652, U+0640, U+0670)
LETTER = re.compile(r"[\u0621-\u063F\u0641-\u064A\u066E-\u06D3]")


def letters(s):
    s = unicodedata.normalize("NFKC", s)
    # normalise alef/hamza variants and ta-marbuta so spelling variants
    # (أ/ا/إ/آ, ى/ي, ة/ه) never masquerade as missing letters
    trans = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
                           "ى": "ي", "ئ": "ي", "ؤ": "و", "ة": "ه"})
    return len(LETTER.findall(s.translate(trans)))


def find_markers(doc):
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


def is_vocab_table(tbl):
    """A vocab table has 4 columns and Cyrillic glosses. A POEM is also laid out
    as a table (2 columns of hemistichs) but carries no Cyrillic - poem text is
    reading content and must NOT be excluded."""
    rows = tbl.extract()
    if not rows or len(rows[0]) < 3:
        return False
    return any(CYR.search(c or "") for r in rows for c in r)


def region_letters(doc, start, end):
    """Arabic letters between two positions, excluding vocab tables only."""
    n = 0
    for i in range(start[0], end[0] + 1):
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
                if CYR.search(t):
                    continue
                n += letters(t)
    return n


def main():
    doc = fitz.open(PDF)
    data = json.load(open(JSON_PATH, encoding="utf-8"))
    ours = {l["num"]: l for l in data["lessons"] if l.get("book") == 3}
    m = find_markers(doc)
    marker = {n: m[n] for n in range(1, 58)}

    def vocab_bottom(n):
        """Bottom of lesson n's last vocab table - where lesson n+1's text starts."""
        start = marker[n]
        end = marker.get(n + 1, (start[0] + 4, 0))
        last = start
        for i in range(start[0], end[0] + 1):
            for t in doc[i].find_tables().tables:
                if not is_vocab_table(t):
                    continue
                ty0, ty1 = t.bbox[1], t.bbox[3]
                if not gt(start, i, ty0) or gt(end, i, ty0):
                    continue
                if (i, ty1) > last:
                    last = (i, ty1)
        return last

    done = sorted(ours)
    print(f"{'L':>3} | {'src':>6} {'ours':>6} {'diff':>6} {'%':>7} | verdict")
    flagged = []
    for n in done:
        # From the bottom of lesson n-1's vocab table to just above lesson n's
        # own vocab heading (the heading line itself carries Arabic - معاني المفردات -
        # so back off a few points to keep it out of the reading count).
        start = vocab_bottom(n - 1) if n > 1 else (3, 0)
        end = (marker[n][0], marker[n][1] - 6)
        src = region_letters(doc, start, end)
        mine = letters(ours[n].get("titleAr", "")) + letters(ours[n].get("reading", ""))
        d = mine - src
        pct = d / src * 100 if src else 0
        ok = abs(pct) <= 2.0
        if not ok:
            flagged.append((n, src, mine, round(pct, 1)))
        print(f"{n:>3} | {src:>6} {mine:>6} {d:>+6} {pct:>+6.1f}% | "
              f"{'ok' if ok else '<<< CHECK'}")

    print(f"\nreading letter-count mismatches (>2%): {[f[0] for f in flagged] or 'none'}")
    for n, s, mi, p in flagged:
        print(f"   L{n}: source {s} letters, ours {mi} ({p:+}%)")


if __name__ == "__main__":
    main()
