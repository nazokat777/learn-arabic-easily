# -*- coding: utf-8 -*-
"""Add book 2's exercises to the lessons.

Unlike book 1, book 2 does not number its exercises («N-машқ»); each lesson
simply ends with an instruction line («Қуйидаги сўзларни араб тилига таржима
қилинг.») followed by Uzbek sentences. So the lesson each exercise belongs to
has to be worked out from its position on the page.

Anchor: the vocabulary heading «Луғатларнинг маънолари», one per lesson - the
same anchor audit_all.py uses. Order inside a lesson is reading -> vocabulary
-> exercise, so an exercise lying between heading k and heading k+1 belongs to
lesson k. Heading 0 is the book's intro, so heading k maps to lesson k.

Only 40 of the 60 lessons carry an exercise - that is how the book is.
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import fitz

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-2 (2).pdf"
LESSONS = Path("assets/content/qiroat_lessons.json")

CYR = re.compile(r"[\u0400-\u04FF]")
INSTR = re.compile(r"Қуйидаги", re.I)
STOP_LINE = re.compile(r"(аънолар|машқ|Луғатларнинг)", re.I)

_CYR2LAT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': "'",
    'ь': '', 'ы': 'i', 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': "o'", 'ғ': "g'", 'қ': 'q', 'ҳ': 'h', 'ҷ': 'j',
}


def translit(s: str) -> str:
    out = []
    for c in s:
        low = c.lower()
        if low in _CYR2LAT:
            lat = _CYR2LAT[low]
            out.append(lat.capitalize() if c.isupper() and lat else lat)
        else:
            out.append(c)
    return "".join(out)


def lines_of(page):
    """(y, matn) - sahifadagi har bir satr, jadval kataklarisiz."""
    cells = set()
    for t in page.find_tables().tables:
        for row in t.extract():
            for c in row:
                for l in (c or "").split("\n"):
                    if l.strip():
                        cells.add(l.strip())
    out = []
    for blk in page.get_text("dict")["blocks"]:
        if blk.get("type") != 0:
            continue
        for line in blk["lines"]:
            txt = "".join(s["text"] for s in line["spans"]).strip()
            if txt and txt not in cells and txt != "www.arabic.uz":
                out.append((line["bbox"][1], txt))
    return sorted(out)


def main() -> int:
    doc = fitz.open(PDF)
    pages = [lines_of(doc[i]) for i in range(doc.page_count)]

    # dars boshlanishlari: lug'at sarlavhasi (0-chisi kirish)
    heads = [(i, y) for i, ls in enumerate(pages) for y, t in ls if "аънолар" in t]
    print(f"lug'at sarlavhalari: {len(heads)} ta")

    found = {}
    for i, ls in enumerate(pages):
        for y, t in ls:
            if not INSTR.search(t):
                continue
            before = [k for k, (pi, py) in enumerate(heads) if (pi, py) < (i, y)]
            if not before:
                continue
            lesson = before[-1]           # 0 = kirish, k = k-dars
            if lesson < 1 or lesson in found:
                continue
            # matnni shu joydan keyingi to'xtashgacha yig'amiz
            buf, started = [], False
            for j in range(i, min(i + 3, len(pages))):
                for yy, tt in pages[j]:
                    if j == i and yy < y:
                        continue
                    if started and STOP_LINE.search(tt):
                        break
                    if CYR.search(tt):
                        buf.append(tt)
                    started = True
                else:
                    continue
                break
            found[lesson] = re.sub(r"\s+", " ", " ".join(buf)).strip()

    print(f"topilgan mashqlar: {len(found)} ta, darslar: {sorted(found)[:12]} ...")
    short = [n for n, t in found.items() if len(t) < 40]
    if short:
        print(f"XATO: juda qisqa: {short}")
        return 1

    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    count = {}
    for L in data["lessons"]:
        count[L.get("book", 1)] = count.get(L.get("book", 1), 0) + 1
    assert count == {1: 52, 2: 60, 3: 57}, count

    n = 0
    for L in data["lessons"]:
        if L.get("book") == 2 and L["num"] in found:
            L["exercise"] = translit(found[L["num"]])
            n += 1
    LESSONS.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                       encoding="utf-8", newline="\n")
    lens = sorted(len(v) for v in found.values())
    print(f"2-kitobga qo'shildi: {n} ta mashq, uzunlik {lens[0]}..{lens[-1]}")
    k = sorted(found)[0]
    print(f"namuna ({k}-dars):", translit(found[k])[:100])
    return 0


if __name__ == "__main__":
    sys.exit(main())
