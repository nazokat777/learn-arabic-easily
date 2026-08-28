# -*- coding: utf-8 -*-
"""Check that every piece of Arabic the app can speak has an audio file.

Runs over all content the UI offers a listen button for:
  qiroat darslari  - lug'at so'zi, matn jumlasi, matndagi har bir so'z
  alifbo           - harf nomi, harf+harakat bo'g'ini, harakat nomi/misoli
  mashqlar         - vocabulary.json so'zlari

Pairs with audit_audio_silence.py: this one asks «fayl bormi», that one asks
«eshitiladimi». A gap in either means a learner taps and hears nothing.

Exit code 1 if anything is missing, so it can gate a commit.
"""
import json, re, sys, io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

sys.path.insert(0, str(Path(__file__).parent))
TERM = ".؟!؛?"
RUN_ON = ".؟!؛"
ARABIC = re.compile(r"[؀-ۿݐ-ݿ]+")
# Diqqat: ARABIC bo'lagi tinish belgilarini ham qamraydi (masalan «؛»),
# shuning uchun HARF borligini alohida tekshiramiz - aks holda yolg'iz
# nuqta-vergul ham "so'z" deb ovozga yuboriladi va edge-tts xato beradi.
LETTER = re.compile(r"[ء-يٱ-ۓ]")
FATHA, DAMMA, KASRA = "َ", "ُ", "ِ"


def split_sentences(reading: str) -> list[str]:
    """lib/arabic.dart splitSentences bilan bir xil."""
    out = []
    for line in reading.split("\n"):
        line = line.strip()
        if not line:
            continue
        buf, i = "", 0
        while i < len(line):
            buf += line[i]
            if line[i] in TERM:
                while i + 1 < len(line) and line[i + 1] in RUN_ON:
                    i += 1
                    buf += line[i]
                if buf.strip():
                    out.append(buf.strip())
                buf = ""
            i += 1
        if buf.strip():
            out.append(buf.strip())
    return out


def head(s: str) -> str:
    return re.split(r"[،,]", s)[0].strip()


def load_manifests() -> dict:
    man = {}
    for m in ("vocab", "sentence", "word", "alifbo", "extra"):
        p = Path(f"assets/audio/{m}_manifest.json")
        if p.exists():
            for k, v in json.loads(p.read_text(encoding="utf-8")).items():
                man[k] = f"{m}:{v}"
    return man


def needed() -> dict:
    """Matn -> qayerda ishlatilishi (xato xabari uchun)."""
    want = {}
    lessons = json.loads(Path("assets/content/qiroat_lessons.json").read_text(encoding="utf-8"))
    for L in lessons["lessons"]:
        # 1-kitob darslarida «book» kaliti yozilmagan — ilova ham `?? 1` deb o'qiydi.
        where = f"{L.get('book', 1)}-kitob {L['num']}-dars"
        for s in split_sentences(L["reading"]):
            want.setdefault(s, f"{where} jumla")
            for w in (x for x in ARABIC.findall(s) if LETTER.search(x)):
                want.setdefault(w, f"{where} so'z")
        for v in L["vocab"]:
            want.setdefault(head(v["ar"]), f"{where} lug'at")
        # Mashq javobi - jumlasi ham, ichidagi so'zlari ham tinglanadi.
        for sent in split_sentences(L.get("exerciseAnswer", "")):
            # Arabcha harfsiz parcha (masalan qo'shtirnoq + nuqta) ovozlanmaydi.
            if not LETTER.search(sent):
                continue
            want.setdefault(sent, f"{where} javob jumlasi")
            for w in (x for x in ARABIC.findall(sent) if LETTER.search(x)):
                want.setdefault(w, f"{where} javob so'zi")
        # Grammatika jadvallari - har bir arabcha katak tinglanadi.
        for t in L.get("tables", []):
            for row in t["rows"]:
                for cell in row["cells"]:
                    if LETTER.search(cell):
                        want.setdefault(cell.strip(), f"{where} jadval")

    letters = json.loads(Path("assets/content/letters.json").read_text(encoding="utf-8"))["letters"]
    for L in letters:
        want.setdefault(L["name_ar"], "alifbo harf nomi")
        for sign in (FATHA, KASRA, DAMMA):
            want.setdefault(L["ar"] + sign, "alifbo bo'g'in")
    for h in json.loads(Path("assets/content/harakat.json").read_text(encoding="utf-8"))["harakat"]:
        want.setdefault(h["name_ar"], "harakat nomi")
        want.setdefault(h["example_ar"], "harakat misoli")

    for w in json.loads(Path("assets/content/vocabulary.json").read_text(encoding="utf-8"))["words"]:
        want.setdefault(head(w["ar"]), "mashqlar lug'ati")

    nahv = Path("assets/content/nahv_lessons.json")
    if nahv.exists():
        for L in json.loads(nahv.read_text(encoding="utf-8"))["lessons"]:
            pairs = [L.get("rule", {})]
            for b in L.get("blocks", []):
                pairs.append(b)
                if b.get("intro"):
                    pairs.append(b["intro"])
                pairs.extend(b.get("items", []))
            for pr in pairs:
                for s in split_sentences(pr.get("ar", "")):
                    if not LETTER.search(s):
                        continue
                    want.setdefault(s, f"nahv {L['num']}-dars")
                    for w in (x for x in ARABIC.findall(s) if LETTER.search(x)):
                        want.setdefault(w, f"nahv {L['num']}-dars so'zi")
    return want


def main() -> int:
    man, want = load_manifests(), needed()
    missing = [(t, src) for t, src in want.items() if t not in man]
    print(f"ovoz kerak: {len(want)}   ovoz fayli bor: {len(man)}")
    print(f"yetishmayotgan: {len(missing)}")
    for t, src in missing[:40]:
        print(f"  {src:24} {t!r}")
    if len(missing) > 40:
        print(f"  … yana {len(missing) - 40} ta")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
