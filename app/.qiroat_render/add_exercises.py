# -*- coding: utf-8 -*-
"""Add book 1's 52 exercises («N-машқ») to the lessons.

Each lesson ends with an exercise: a short instruction plus Uzbek sentences to
translate into Arabic. The app never carried them. The Arabic answer key that
the book prints later is in the garbled text layer and is NOT taken from here.

The blocks are bounded by the next «N-машқ» heading, but that is not enough:
the grammar tables (lesson 3) and the number tables (lesson 52) sit between two
exercises, and their Cyrillic cells were being swallowed into the exercise
text. So every line that belongs to a TABLE CELL on that page is dropped -
tables are already stored separately under the lesson's `tables`.

Exercise N belongs to lesson N (checked against the page image for 26).
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import fitz

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-1 (2).pdf"
LESSONS = Path("assets/content/qiroat_lessons.json")
LAST_LESSON_PAGE = 100          # tarjimalar shu sahifadan boshlanadi

CYR = re.compile(r"[\u0400-\u04FF]")
START = re.compile(r"(\d+)\s*[-–]\s*маш[кқ]\s*:?", re.I)
VOCAB = re.compile(r"Сўзларнинг\s+маънолари", re.I)

# Jadval KATAKLARI filtrdan o'tadi, lekin sarlavhasi va yon yozuvlari katak
# emas - ular mashq matniga yopishib qolardi. Mashq shu joyda tugaydi.
# Qidiruv QATOR bo'yicha to'xtatiladi: kalit so'z sarlavha o'rtasida
# uchrasa, sarlavhaning boshi mashq matnida qolib ketardi.
STOP_LINE = re.compile(
    r"(замирлар|Сонлар|сонларнинг\s+ишлатилиши|шахс|Араб\s+тилида\s+ноль|БОБ"
    r"|Баранов|феълнинг\s+боблари|Сўзларнинг\s+маънолари|Луғатларнинг)", re.I)

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


def page_text_without_tables(page) -> str:
    """Sahifa matni, jadval kataklaridagi satrlarsiz."""
    cells = set()
    for t in page.find_tables().tables:
        for row in t.extract():
            for c in row:
                for line in (c or "").split("\n"):
                    line = line.strip()
                    if line:
                        cells.add(line)
    keep = []
    for line in page.get_text().split("\n"):
        s = line.strip()
        if not s or s in cells or s == "www.arabic.uz" or s.isdigit():
            continue
        if set(s) <= set("-– "):
            continue
        keep.append(s)
    return "\n".join(keep)


def extract() -> dict:
    doc = fitz.open(PDF)
    full = "\n".join(page_text_without_tables(doc[i]) for i in range(LAST_LESSON_PAGE))
    ms = list(START.finditer(full))
    out = {}
    for i, m in enumerate(ms):
        a = m.end()
        b = ms[i + 1].start() if i + 1 < len(ms) else len(full)
        keep = []
        for line in full[a:b].split("\n"):
            line = line.strip()
            if STOP_LINE.search(line):
                break
            if line and CYR.search(line):
                keep.append(line)
        out[int(m.group(1))] = re.sub(r"\s+", " ", " ".join(keep)).strip()
    return out


def main() -> int:
    ex = extract()
    missing = [n for n in range(1, 53) if n not in ex or len(ex[n]) < 40]
    if len(ex) != 52 or missing:
        print(f"XATO: {len(ex)} ta mashq, muammoli: {missing}")
        return 1

    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    count = {}
    for L in data["lessons"]:
        count[L.get("book", 1)] = count.get(L.get("book", 1), 0) + 1
    assert count == {1: 52, 2: 60, 3: 57}, count

    for L in data["lessons"]:
        if L.get("book", 1) == 1:
            L["exercise"] = translit(ex[L["num"]])
    LESSONS.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                       encoding="utf-8", newline="\n")
    lens = sorted(len(v) for v in ex.values())
    print(f"mashq qo'shildi: 52 ta   uzunlik {lens[0]}..{lens[-1]}")
    print("namuna (1):", translit(ex[1])[:90])
    return 0


if __name__ == "__main__":
    sys.exit(main())
