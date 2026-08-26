# -*- coding: utf-8 -*-
"""Add book 3's Uzbek translation of each reading (PDF pages 117-190).

Book 3 has a translation section too - the earlier «book 3 has none» was wrong
for the same reason as book 2: the section never uses the word «таржима».

Two traps here, both found by checking which lesson numbers came out missing:

  * the heading is usually «N-дарс», but three poem lessons (51, 52, 54) are
    headed «N-ҳикоя» instead;
  * one heading is printed without a dash («50 дарс»).

With both allowed, all 57 headings are found and carry their own number, so
the blocks are keyed by the printed number - unlike book 2, whose numbering is
unreliable and had to be taken from block order.
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import fitz

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf"
LESSONS = Path("assets/content/qiroat_lessons.json")
FIRST_PAGE = 116          # 0-asosli: 117-sahifa

CYR = re.compile(r"[\u0400-\u04FF]")
HEAD = re.compile(r"^(\d{1,2})\s*[-–—]?\s*(дарс|ҳикоя|хикоя)\s*$", re.I)

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


def lines(page):
    """(y, x) bo'yicha tartiblangan satrlar."""
    out = []
    for blk in page.get_text("dict")["blocks"]:
        if blk.get("type") != 0:
            continue
        for line in blk["lines"]:
            t = "".join(s["text"] for s in line["spans"]).strip()
            if t and t != "www.arabic.uz" and not t.isdigit():
                out.append((round(line["bbox"][1]), round(line["bbox"][0]), t))
    return [t for _, _, t in sorted(out)]


def extract() -> dict:
    doc = fitz.open(PDF)
    flat = [t for i in range(FIRST_PAGE, doc.page_count) for t in lines(doc[i])]
    out, cur = {}, None
    for t in flat:
        m = HEAD.match(t)
        if m:
            cur = int(m.group(1))
            out.setdefault(cur, [])
            continue
        if cur is not None and CYR.search(t):
            out[cur].append(t)
    return {n: re.sub(r"\s+", " ", " ".join(v)).strip() for n, v in out.items()}


def main() -> int:
    tr = extract()
    short = [n for n in range(1, 58) if len(tr.get(n, "")) < 60]
    print(f"topilgan tarjima: {len(tr)}   juda qisqa/yo'q: {short}")
    if short:
        return 1

    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    count = {}
    for L in data["lessons"]:
        count[L.get("book", 1)] = count.get(L.get("book", 1), 0) + 1
    assert count == {1: 52, 2: 60, 3: 57}, count

    n = 0
    for L in data["lessons"]:
        if L.get("book") == 3 and L["num"] in tr:
            L["translation"] = translit(tr[L["num"]])
            n += 1
    LESSONS.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                       encoding="utf-8", newline="\n")
    lens = sorted(len(v) for v in tr.values())
    print(f"qo'shildi: {n} ta   uzunlik {lens[0]}..{lens[-1]}")
    for k in (1, 51, 57):
        print(f"  {k}-dars:", translit(tr[k])[:70])
    return 0


if __name__ == "__main__":
    sys.exit(main())
