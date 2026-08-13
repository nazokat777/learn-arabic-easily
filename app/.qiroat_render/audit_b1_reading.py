# -*- coding: utf-8 -*-
"""Reading-completeness audit for BOOK 1 - the one book the other audits miss.

Why book 1 needs its own tool:
  * Its pages carry writing-practice lines made of dots and a translation
    exercise AFTER each vocab table, so the book-3 trick of "everything between
    the previous vocab table and this one is the reading" scoops up the previous
    lesson's exercises and produces nonsense (audit_punct reported -1060 dots).
  * Its lesson numbers do not extract reliably either: the embedded font renders
    the digit 0 as 1, so lesson 10 reads "11", 20 reads "21", and so on.

So the reading region is bounded from BOTH sides:
    start = the standalone number line nearest ABOVE the lesson's vocab heading
            (that is the lesson header, whatever digits it claims to be)
    end   = the vocab heading itself
Everything between is the title + reading passage, with the previous lesson's
exercises left outside.

Compares Arabic LETTER counts (diacritics stripped, spelling variants folded)
because ligature garbling reorders letters but preserves them.
"""
import json, re, sys, io, unicodedata
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-1 (2).pdf"
JSON_PATH = "assets/content/qiroat_lessons.json"
CYR = re.compile(r"[\u0400-\u04FF]")
LETTER = re.compile(r"[\u0621-\u063F\u0641-\u064A\u066E-\u06D3]")
TRANS = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
                       "ى": "ي", "ئ": "ي", "ؤ": "و", "ة": "ه"})


def letters(s):
    return len(LETTER.findall(
        unicodedata.normalize("NFKC", s).translate(TRANS)))


def lines(doc, page_idx):
    for blk in doc[page_idx].get_text("dict")["blocks"]:
        if blk.get("type") != 0:
            continue
        for line in blk["lines"]:
            yield line["bbox"][1], "".join(s["text"] for s in line["spans"])


def main():
    doc = fitz.open(PDF)

    # Two kinds of lesson-start anchor, because neither alone covers all 52:
    # the big standalone number (missing on e.g. lesson 11's page) and the
    # «الدَّرْسُ ...» title line (garbled beyond recognition on some pages).
    markers, anchors = [], []
    for i in range(doc.page_count):
        foot = doc[i].rect.height - 90
        for y, t in lines(doc, i):
            s = t.strip()
            if "аънолар" in t:
                markers.append((i, y))
            elif (re.fullmatch(r"\d{1,2}", s) and y < foot) \
                    or "دَّرْس" in s or "الدَّر" in s:
                anchors.append((i, y))
    anchors.sort()

    data = json.load(open(JSON_PATH, encoding="utf-8"))
    ours = {l["num"]: l for l in data["lessons"] if l.get("book", 1) == 1}
    marker = {n: markers[n] for n in range(1, 53)}   # markers[0] is the intro

    print(f"markers {len(markers)} | lesson-start anchors {len(anchors)}\n")
    print(f"{'L':>3} | {'letters src':>11} {'ours':>6} {'%':>7} | "
          f"{'stops src':>9} {'ours':>5} {'d':>4} | verdict")
    bad_letters, bad_stops = [], []
    for n in sorted(ours):
        end = marker[n]
        above = [p for p in anchors if p < end]
        start = above[-1] if above else (end[0], 0)

        src, src_stops = 0, 0
        for i in range(start[0], end[0] + 1):
            for y, t in lines(doc, i):
                if (i, y) <= start or (i, y) >= end:
                    continue
                if CYR.search(t) or "arabic.uz" in t:
                    continue
                n_letters = letters(t)
                src += n_letters
                # Count stops only on lines that actually carry Arabic. The
                # blank writing rules are pure dots ("..............") and would
                # otherwise add ~1060 phantom full stops per lesson.
                if n_letters:
                    src_stops += t.count(".")
        mine = letters(ours[n].get("titleAr", "")) + letters(ours[n]["reading"])
        mine_stops = ours[n]["reading"].count(".")
        pct = (mine - src) / src * 100 if src else 0
        dstop = mine_stops - src_stops

        # Book 1's text layer is very lossy (it drops 7-45% of letters), so the
        # letter check only catches gross losses. Full stops extract exactly,
        # and these lessons are lists of short sentences, so a missing sentence
        # shows up as a missing full stop - that is the sharper signal here.
        okL, okS = pct >= -3, dstop >= 0
        if not okL:
            bad_letters.append(n)
        if not okS:
            bad_stops.append((n, src_stops, mine_stops))
        print(f"{n:>3} | {src:>11} {mine:>6} {pct:>+6.1f}% | "
              f"{src_stops:>9} {mine_stops:>5} {dstop:>+4} | "
              f"{'ok' if okL and okS else '<<< CHECK'}")

    print(f"\nletters shorter than source : {bad_letters or 'none'}")
    print(f"full stops missing          : "
          f"{[f'L{n} (src {s}, ours {m})' for n, s, m in bad_stops] or 'none'}")


if __name__ == "__main__":
    main()
