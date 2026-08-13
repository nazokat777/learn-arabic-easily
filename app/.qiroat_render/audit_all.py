# -*- coding: utf-8 -*-
"""Word-by-word vocab audit across ALL THREE Mabdaul qiroat books.

Read-only. Never import a build script here - they run their merge on import
and rewrite qiroat_lessons.json (that once cut book 2 from 60 lessons to 5).

Anchor: the Cyrillic vocab heading that opens every lesson's table
  book 1 -> 'Сўзларнинг маънолари'   (52 lessons + 1 intro = 53)
  book 2 -> 'Луғатларнинг маънолари' (60 lessons + 1 intro = 61)
  book 3 -> 'Луғатларнинг маънолари' (57 lessons + 1 intro + 1 appendix = 59)
The lesson number is unusable (the embedded font subset garbles digits) and the
Arabic text layer is garbled too, but Cyrillic extracts perfectly - so glosses
are a reliable completeness signal. Book-1 glosses are already Latin.

Column layouts differ, so pairs are found by asking which cells hold Arabic.
"""
import json, re, sys, io, difflib
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BOOKS = {
    1: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-1 (2).pdf", 52),
    2: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-2 (2).pdf", 60),
    3: (r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf", 57),
}
CYR = re.compile(r"[\u0400-\u04FF]")
ARA = re.compile(r"[\u0600-\u06FF]")

_CYR2LAT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': "'",
    'ь': '', 'ы': 'i', 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'ў': "o'", 'ғ': "g'", 'қ': 'q', 'ҳ': 'h', 'ҷ': 'j',
}


def translit(s):
    return "".join(_CYR2LAT.get(c, _CYR2LAT.get(c.lower(), c)) for c in s)


def key(s):
    s = translit(s) if CYR.search(s) else s
    return re.sub(r"[^a-z' ]", "", s.lower()).strip()


def markers(doc):
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
    if not rows or len(rows[0]) < 2:
        return False
    return any(CYR.search(c or "") for r in rows for c in r)


def source_glosses(doc, start, end):
    """Uzbek gloss of every (arabic, gloss) pair in the region's vocab tables."""
    out = []
    for i in range(start[0], min(end[0], doc.page_count - 1) + 1):
        for tbl in doc[i].find_tables().tables:
            if not is_vocab_table(tbl):
                continue
            ty = tbl.bbox[1]
            if (i, ty) <= start or (i, ty) > end:
                continue
            for row in tbl.extract():
                cells = [(c or "").strip().replace("\n", " ") for c in row]
                # pair each Arabic cell with the neighbouring gloss cell
                for j, c in enumerate(cells):
                    if not ARA.search(c):
                        continue
                    gloss = ""
                    for k in (j - 1, j + 1):
                        if 0 <= k < len(cells) and cells[k] and not ARA.search(cells[k]):
                            gloss = cells[k]
                            break
                    out.append(gloss)
    return out


def audit_book(book, ours):
    path, n_lessons = BOOKS[book]
    doc = fitz.open(path)
    m = markers(doc)
    print(f"\n===== BOOK {book}: {len(ours)} lessons in JSON, "
          f"{len(m)} markers in PDF (expect {n_lessons} + intro)")
    if len(m) < n_lessons + 1:
        print("  !! fewer markers than lessons - anchoring unreliable")
        return 0
    marker = {n: m[n] for n in range(1, n_lessons + 1)}

    total = 0
    for n in sorted(ours):
        if n not in marker:
            print(f"  L{n}: no marker")
            continue
        src = source_glosses(doc, marker[n],
                             marker.get(n + 1, (marker[n][0] + 4, 0)))
        mine = [w.get("uz", "") for w in ours[n]["vocab"]]
        mine_keys = [key(x) for x in mine]
        pool = list(mine_keys)
        missing = []
        for g in src:
            k = key(g)
            if not k:
                continue
            if k in pool:
                pool.remove(k)
                continue
            hit = difflib.get_close_matches(k, pool, n=1, cutoff=0.72)
            if hit:
                pool.remove(hit[0])
                continue
            if any(k in mk or mk in k for mk in mine_keys if len(k) > 2):
                continue
            missing.append(g)
        if missing:
            total += len(missing)
            print(f"  L{n}: {len(missing)} unmatched (src {len(src)} vs ours {len(mine)})")
            for g in missing[:8]:
                print(f"        - {g!r}")
    print(f"  book {book} unmatched total: {total}")
    return total


def main():
    data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
    by_book = {}
    for l in data["lessons"]:
        by_book.setdefault(l.get("book", 1), {})[l["num"]] = l

    grand = 0
    for b in (1, 2, 3):
        grand += audit_book(b, by_book.get(b, {}))
    print(f"\nGRAND TOTAL unmatched source glosses: {grand}")


if __name__ == "__main__":
    main()
