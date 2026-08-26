# -*- coding: utf-8 -*-
"""Add book 2's Uzbek translation of each reading (PDF pages 104-158).

Book 2 carries the same kind of translation section as book 1, but it is
labelled differently - just «N-дарс» followed by the Uzbek title and text,
with no word «таржима» anywhere. That is why an earlier check for «таржима»
concluded, wrongly, that book 2 had no translations at all. Lesson 60's block
(«Учтасидан қайсиси аҳмоқликда кучлироқ?») matches the stored Arabic title
أَيُّ الثَّلَاثَةِ أَشَدُّ حُمْقًا؟ exactly, which is what confirmed it.

Each «N-дарс» heading appears twice: once over the Uzbek translation and once
over the Arabic answer key to that lesson's exercise. Keeping only Cyrillic
lines drops the answer key, since its Arabic is garbled in the text layer.

The printed numbers are NOT reliable: the book mislabels lesson 20's
translation as «21-дарс» and lesson 57's as «56-дарс». So blocks are numbered
by their ORDER in the section, not by the label. That order is sound - exactly
60 blocks carry text, and spot checks line up with the stored Arabic titles
(19 «Кучук» = الكَلْبُ, 20 «Ўйин» = اللَّعِبُ, 57 «Тошбақа ва икки ўрдак» =
السُّلَحْفَاةُ وَالْبَطَّتَانِ, 58 «Кит» = الْحُوتُ).
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import fitz

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-2 (2).pdf"
LESSONS = Path("assets/content/qiroat_lessons.json")
FIRST_PAGE = 103          # 0-asosli: 104-sahifa

CYR = re.compile(r"[\u0400-\u04FF]")
HEAD = re.compile(r"^(\d{1,2})\s*[-–]\s*дарс", re.I)

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
    """(y, x) bo'yicha tartiblangan satrlar — bir qatordagi bo'laklar
    aralashib ketmasligi uchun x ham hisobga olinadi."""
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
    blocks, cur = [], None
    for t in flat:
        if HEAD.match(t):
            blocks.append([])
            cur = blocks[-1]
            continue
        if cur is not None and CYR.search(t):
            cur.append(t)
    texts = [re.sub(r"\s+", " ", " ".join(b)).strip() for b in blocks]
    kept = [t for t in texts if len(t) > 60]      # arabcha javob bloklari bo'sh chiqadi
    return {i + 1: t for i, t in enumerate(kept)}


def main() -> int:
    tr = extract()
    short = [n for n in range(1, 61) if len(tr.get(n, "")) < 60]
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
        if L.get("book") == 2 and L["num"] in tr:
            L["translation"] = translit(tr[L["num"]])
            n += 1
    LESSONS.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                       encoding="utf-8", newline="\n")
    lens = sorted(len(v) for v in tr.values())
    print(f"qo'shildi: {n} ta   uzunlik {lens[0]}..{lens[-1]}")
    print("1-dars:", translit(tr[1])[:80])
    print("60-dars:", translit(tr[60])[:80])
    return 0


if __name__ == "__main__":
    sys.exit(main())
