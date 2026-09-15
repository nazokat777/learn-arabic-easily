# -*- coding: utf-8 -*-
"""«Harflarni ulash» darsiga 6- va 7-bosqich: MAD HARFLARI va MURAKKAB
SO'ZLAR — faqat INSON ovozi tasdiqlangan so'zlardan.

Manba so'zlar: ilova lug'ati (vocabulary.json, qiroat darslari) — arabchasi
va ma'nosi qo'lda yozilmaydi. Ovoz: assets/audio/kalima_manifest.json
(Lingua Libre yozuvlari, whisper bilan tekshirilgan — gen_kalima_audio.py).

So'z PAUZA shaklida ko'rsatiladi (tanvinsiz: كِتَاب) — so'zlovchi aynan
shunday aytadi; matn bilan ovoz bir-biriga mos bo'lsin («xato o'qimasin»).

Tanlov:
  6 — mad: so'zda cho'ziq unli bor (fatha+ا, zamma+و, kasra+ي), shadda yo'q;
      qisqadan uzunga tartiblanadi.
  7 — murakkab: shadda, yoki ikki sukun/uch bo'g'inli uzun so'zlar,
      yoki hamza shakllari (أ إ ئ ؤ ء) — o'quvchi ko'p qoqiladigan joylar.
Har bosqichda ma'no/arabcha takrorlanmaydi (test uchun), ≥ 4 so'z.
"""
import json, re, sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
HAR = re.compile(r"[ً-ْٰـ]")
TANVIN_OXIR = re.compile(r"[ًٌٍَُِْ]+$")
FATHA, DAMMA, KASRA, SUKUN, SHADDA = "َ", "ُ", "ِ", "ْ", "ّ"


def bare(s): return HAR.sub("", s).strip()
def pauza(s): return TANVIN_OXIR.sub("", s.strip())


def bolaklar(w):
    out = []
    for ch in w:
        if HAR.match(ch) and out:
            out[-1] += ch
        elif ch.strip():
            out.append(ch)
    return out


def mad_bor(w):
    b = bolaklar(w)
    for i in range(1, len(b)):
        asos, belgi = b[i][0], b[i][1:]
        if belgi.replace(SUKUN, ""):
            continue
        old = b[i - 1][1:]
        if (asos == "ا" and FATHA in old) or (asos == "و" and DAMMA in old) or (asos == "ي" and KASRA in old):
            return True
    return False


def murakkab(w):
    b = bare(w)
    return (SHADDA in w) or any(h in b for h in "أإئؤء") or (w.count(SUKUN) >= 2) or len(b) >= 6


# --- lug'at ---
cand = {}
def qosh(ar, uz, pri):
    ar = ar.split("،")[0].strip(); uz = uz.strip()
    if not ar or not uz or " " in ar:
        return
    k = bare(ar)
    if k in cand and cand[k][2] <= pri:
        return
    cand[k] = (ar, uz, pri)

for w in json.loads(Path("assets/content/vocabulary.json").read_text(encoding="utf-8"))["words"]:
    qosh(w["ar"], w["uz"], 0)
for L in json.loads(Path("assets/content/qiroat_lessons.json").read_text(encoding="utf-8"))["lessons"]:
    for w in L.get("vocab", []):
        qosh(w.get("ar", ""), w.get("uz", ""), L.get("book", 1))

kalima = json.loads(Path("assets/audio/kalima_manifest.json").read_text(encoding="utf-8"))
ulash = json.loads(Path("assets/content/ulash.json").read_text(encoding="utf-8"))
eski = {bare(w["ar"]) for s in ulash["stages"] if s["num"] <= 5 for w in s["words"]}

# Ovozi bor, ma'nosi qisqa (bitta ma'no) so'zlar.
bor = []
for k, (ar, uz, _) in cand.items():
    p = pauza(ar)
    if p in kalima and len(uz) <= 22 and "," not in uz and ";" not in uz:
        bor.append((p, uz))

def tanla(shart, n, band):
    ro = sorted((p, uz) for p, uz in bor if shart(p) and bare(p) not in band)
    ro.sort(key=lambda x: len(bare(x[0])))
    out, uzlar, arlar = [], set(), set()
    for p, uz in ro:
        if uz in uzlar or p in arlar:
            continue
        # Bosqich ichida ma'no bo'yicha takror yo'q; ism turkumi ustun (ot).
        out.append({"ar": p, "uz": uz}); uzlar.add(uz); arlar.add(p)
        if len(out) >= n:
            break
    return out

band = set(eski)
mad = tanla(lambda p: mad_bor(p) and SHADDA not in p, 20, band)
band |= {bare(w["ar"]) for w in mad}
mur = tanla(lambda p: murakkab(p), 20, band)

yangi = [
    {"num": 6, "title": "Mad harflari — cho'ziq unlilar", "titleAr": "حُرُوفُ الْمَدِّ",
     "explain": "Uch harf ba'zan tovush emas, CHO'ZISH vazifasini bajaradi: fathadan "
                "keyingi «ا» — «aa», zammadan keyingi «و» — «uu», kasradan keyingi «ي» — «ii». "
                "Bu harflar ko'k rangda: ularni ikki barobar cho'zib o'qing. So'zlar oxirgi "
                "harakatsiz (to'xtash shaklida) berilgan — ovozda ham shunday.",
     "focus": "mad", "words": mad},
    {"num": 7, "title": "Murakkab so'zlar", "titleAr": "كَلِمَاتٌ صَعْبَةٌ",
     "explain": "Shadda (harf ikki marta o'qiladi: «سُكَّر» — suk-kar), ketma-ket sukunlar, "
                "hamzaning turli shakllari (أ إ ئ ؤ ء) va uzun so'zlar — o'quvchi eng ko'p "
                "qoqiladigan joylar. Avval o'zingiz o'qing, keyin ovoz bilan solishtiring.",
     "focus": "murakkab", "words": mur},
]
for st in yangi:
    if len(st["words"]) < 4:
        raise SystemExit(f"{st['num']}-bosqichda so'z kam: {len(st['words'])}")
ulash["stages"] = [s for s in ulash["stages"] if s["num"] <= 5] + yangi
Path("assets/content/ulash.json").write_text(json.dumps(ulash, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
for st in yangi:
    print(st["num"], len(st["words"]), [w["ar"] for w in st["words"]])
