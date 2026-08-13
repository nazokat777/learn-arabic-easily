# -*- coding: utf-8 -*-
"""Word-by-word vocab audit for book 3.

For every lesson, pulls each vocab row's Cyrillic Uzbek gloss out of the PDF,
transliterates it, and checks it appears in our stored vocab. Any source gloss
with no counterpart in our JSON is a dropped word.

Cross-page continuation rows (a cell wrapping onto the next page's first row)
are the known false positive - they show up as a short fragment that IS a
substring of the previous entry, so they are folded in rather than reported.
"""
import json, re, sys, io, difflib
import fitz

# NB: do NOT `from build_b2 import translit` - build_b2.py runs its merge at
# import time and would rewrite qiroat_lessons.json (it once wiped book 2 down
# to 5 lessons). The table is inlined here so the audit stays read-only.
_CYR2LAT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': "'",
    'ь': '', 'ы': 'i', 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': "o'", 'ғ': "g'", 'қ': 'q', 'ҳ': 'h', 'ҷ': 'j', 'ъ': "'",
}


def translit(s):
    return "".join(_CYR2LAT.get(ch, _CYR2LAT.get(ch.lower(), ch)) for ch in s)

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf"
CYR = re.compile(r"[\u0400-\u04FF]")
ARA = re.compile(r"[\u0600-\u06FF]")


def key(s):
    s = translit(s.lower()) if CYR.search(s) else s.lower()
    return re.sub(r"[^a-z' ]", "", s).strip()


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


def is_vocab_table(t):
    rows = t.extract()
    if not rows or len(rows[0]) < 3:
        return False
    return any(CYR.search(c or "") for r in rows for c in r)


def source_glosses(doc, start, end):
    """Uzbek glosses of each (ar,uz) pair, in book reading order (right pair first)."""
    out = []
    for i in range(start[0], end[0] + 1):
        for tbl in doc[i].find_tables().tables:
            if not is_vocab_table(tbl):
                continue
            ty = tbl.bbox[1]
            if (i, ty) <= start or (i, ty) > end:
                continue
            for row in tbl.extract():
                if len(row) < 4:
                    continue
                uzA, arB, uzC, arD = [(c or "").strip().replace("\n", " ") for c in row[:4]]
                for ar, uz in ((arD, uzC), (arB, uzA)):
                    if ARA.search(ar):
                        out.append(uz)
    return out


def main():
    doc = fitz.open(PDF)
    data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
    ours = {l["num"]: l for l in data["lessons"] if l.get("book") == 3}
    m = find_markers(doc)
    marker = {n: m[n] for n in range(1, 58)}

    total_missing = 0
    for n in sorted(ours):
        src = source_glosses(doc, marker[n], marker.get(n + 1, (marker[n][0] + 4, 0)))
        mine = [w.get("uz", "") for w in ours[n]["vocab"]]
        mine_keys = [key(x) for x in mine]
        pool = list(mine_keys)

        missing = []
        for g in src:
            k = key(g)
            if not k:
                continue                    # blank gloss in the source
            if k in pool:
                pool.remove(k)
                continue
            hit = difflib.get_close_matches(k, pool, n=1, cutoff=0.72)
            if hit:
                pool.remove(hit[0])
                continue
            # continuation fragment of an already-matched entry?
            if any(k in mk or mk in k for mk in mine_keys if len(k) > 2):
                continue
            missing.append(g)

        if missing:
            total_missing += len(missing)
            print(f"L{n}: {len(missing)} source gloss(es) with no match in ours "
                  f"(src {len(src)} vs ours {len(mine)})")
            for g in missing:
                print(f"      - {g!r}  ->  {key(g)!r}")

    print(f"\nTOTAL unmatched source glosses: {total_missing}")


if __name__ == "__main__":
    main()
