# -*- coding: utf-8 -*-
"""Add book 1's Uzbek translation of each reading passage (PDF pages 101-142).

The book prints, after the lessons, a translation of every Arabic reading:
«N-дарснинг арабча матнидаги таржима:». The app never carried these, so a
learner could read the passage aloud but had no way to check what it meant.

Two things make this safe to do mechanically, unlike the Arabic:
  * Cyrillic extracts perfectly from these PDFs (only the Arabic layer is
    garbled), so the text is the book's own, not a re-typing.
  * Each block is bounded on both sides - it ends at the NEXT heading,
    «N-дарснинг ўзбекча матнидаги таржима:», which introduces the answer key
    to the Uzbek->Arabic exercise. That key is garbled Arabic and must not be
    picked up.

Headings sometimes break across lines, so the search runs over the whole
document text, never line by line (line-wise matching finds only 38 of 52).

Books 2 and 3 have their own translation sections too - see
add_translations_b2.py / add_translations_b3.py. An earlier note here claimed
they had none; that was wrong. The check had searched for the word «таржима»,
which those books never use: their headings are plain «N-дарс» (and «N-ҳикоя»
for three poem lessons in book 3). Search by STRUCTURE, not by a keyword.
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import fitz

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-1 (2).pdf"
LESSONS = Path("assets/content/qiroat_lessons.json")
FIRST_PAGE = 100  # 0-asosli: 101-sahifa

CYR = re.compile(r"[\u0400-\u04FF]")
START = re.compile(r"дарснинг\s+арабча\s+матнидаги\s+таржима\s*:?", re.I)
STOP = re.compile(r"дарснинг\s+ўзбекча\s+матнидаги\s+таржима\s*:?", re.I)

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


# «Биринчи дарснинг ўзбекча...» sarlavhasi «дарснинг» dan boshlab topiladi,
# shuning uchun undan OLDINGI tartib so'zi blok ichida qolib ketadi. Har bir
# tarjima oxiridan shu so'zlarni olib tashlaymiz.
ORDINALS = {
    "биринчи", "иккинчи", "учинчи", "тўртинчи", "бешинчи", "олтинчи",
    "еттинчи", "саккизинчи", "тўққизинчи", "ўнинчи", "ўн", "йигирма",
    "йигирманчи", "ўттиз", "ўттизинчи", "қирқ", "қирқинчи", "эллик",
    "элликинчи",
}


def strip_next_heading(text: str) -> str:
    words = text.split()
    while words and words[-1].strip(".,:;").lower() in ORDINALS:
        words.pop()
    return " ".join(words)


def clean(seg: str) -> str:
    keep = []
    for line in seg.split("\n"):
        line = line.strip()
        if not line or line == "www.arabic.uz" or line.isdigit():
            continue
        if set(line) <= set("-– "):          # sahifadagi «- 4 -» kabi ajratgichlar
            continue
        if CYR.search(line):                 # garbled arabcha satrlarni tashlaymiz
            keep.append(line)
    return strip_next_heading(re.sub(r"\s+", " ", " ".join(keep)).strip())


def extract() -> list[str]:
    doc = fitz.open(PDF)
    full = "\n".join(doc[i].get_text() for i in range(FIRST_PAGE, len(doc)))
    out, pos = [], 0
    while True:
        m = START.search(full, pos)
        if not m:
            break
        e = STOP.search(full, m.end())
        out.append(clean(full[m.end(): e.start() if e else len(full)]))
        pos = e.end() if e else len(full)
    return out


def main() -> int:
    texts = extract()
    if len(texts) != 52:
        print(f"XATO: 52 emas, {len(texts)} ta tarjima topildi")
        return 1
    short = [i + 1 for i, t in enumerate(texts) if len(t) < 40]
    if short:
        print(f"XATO: juda qisqa bloklar: {short}")
        return 1

    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    count = {}
    for L in data["lessons"]:
        count[L.get("book", 1)] = count.get(L.get("book", 1), 0) + 1
    assert count == {1: 52, 2: 60, 3: 57}, count

    for L in data["lessons"]:
        if L.get("book", 1) == 1:
            L["translation"] = translit(texts[L["num"] - 1])
    LESSONS.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                       encoding="utf-8", newline="\n")
    n = sum(1 for L in data["lessons"] if L.get("translation"))
    print(f"tarjima qo'shildi: {n} ta dars")
    print("namuna (1-dars):", texts[0][:70])
    print("           lotin:", translit(texts[0])[:70])
    return 0


if __name__ == "__main__":
    sys.exit(main())
