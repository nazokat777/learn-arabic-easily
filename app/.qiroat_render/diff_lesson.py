# -*- coding: utf-8 -*-
"""Which letters differ between the PDF source region and our stored reading?

A missing phrase shows up as a cluster of letters present in the source but not
in ours. Usage: python .qiroat_render/diff_lesson.py 28 [3 18 ...]
"""
import json, re, sys, io, unicodedata
from collections import Counter
import fitz

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PDF = r"C:\Users\User\Downloads\Telegram Desktop\mabdaul-qiroat-3 (2).pdf"
CYR = re.compile(r"[\u0400-\u04FF]")
LETTER = re.compile(r"[\u0621-\u063F\u0641-\u064A\u066E-\u06D3]")
TRANS = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
                       "ى": "ي", "ئ": "ي", "ؤ": "و", "ة": "ه"})


def norm(s):
    return unicodedata.normalize("NFKC", s).translate(TRANS)


def counter(s):
    return Counter(LETTER.findall(norm(s)))


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


def region_text(doc, start, end):
    chunks = []
    for i in range(start[0], end[0] + 1):
        page = doc[i]
        skip = [t.bbox for t in page.find_tables().tables if is_vocab_table(t)]
        for blk in page.get_text("dict")["blocks"]:
            if blk.get("type") != 0:
                continue
            for line in blk["lines"]:
                y0 = line["bbox"][1]
                if (i, y0) <= start or (i, y0) > end:
                    continue
                if any(b[1] - 2 <= y0 <= b[3] + 2 for b in skip):
                    continue
                t = "".join(s["text"] for s in line["spans"])
                if CYR.search(t):
                    continue
                if LETTER.search(t):
                    chunks.append((i, round(y0), t))
    return chunks


def main():
    nums = [int(a) for a in sys.argv[1:]] or [28]
    doc = fitz.open(PDF)
    data = json.load(open("assets/content/qiroat_lessons.json", encoding="utf-8"))
    ours = {l["num"]: l for l in data["lessons"] if l.get("book") == 3}
    m = find_markers(doc)
    marker = {n: m[n] for n in range(1, 58)}

    for n in nums:
        start = marker[n - 1] if n > 1 else (3, 0)
        chunks = region_text(doc, start, marker[n])
        src = " ".join(c[2] for c in chunks)
        mine = ours[n].get("titleAr", "") + " " + ours[n].get("reading", "")
        cs, cm = counter(src), counter(mine)
        only_src = cs - cm
        only_mine = cm - cs
        print(f"=== L{n}  src={sum(cs.values())} ours={sum(cm.values())} "
              f"diff={sum(cm.values())-sum(cs.values()):+d}")
        print(f"  letters only in SOURCE (possible omission): "
              f"{dict(only_src.most_common(12))}  total {sum(only_src.values())}")
        print(f"  letters only in OURS: "
              f"{dict(only_mine.most_common(12))}  total {sum(only_mine.values())}")
        print(f"  source lines: {len(chunks)}  pages {chunks[0][0]}..{chunks[-1][0]}"
              if chunks else "  (no source lines)")
        # per-line letter tally helps spot a whole line we never transcribed
        print("  line letter counts:",
              [(c[0], c[1], len(LETTER.findall(norm(c[2])))) for c in chunks])
        print()


if __name__ == "__main__":
    main()
