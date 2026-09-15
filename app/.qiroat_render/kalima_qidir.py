# -*- coding: utf-8 -*-
"""Lingua Libre (Wikimedia Commons) da ilova lug'atidagi so'zlar uchun INSON
ovozi bormi — qidiradi va ro'yxat yozadi (build/kalima_topildi.json).

Fayl nomi: «LL-Q13955 (ara)-<so'zlovchi>-<so'z>.wav» — so'z harakatsiz.
Shuning uchun ilova so'zidan harakat olib tashlanadi, tanvin/oxirgi
harakatsiz (pauza) shakli olinadi. Har so'z uchun barcha so'zlovchilar
yig'iladi — keyin eng ko'p so'zi bor so'zlovchi tanlanadi (bir xil ovoz).
"""
import json, re, sys, time, urllib.parse, urllib.request
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "LearnArabicEasily/1.0 (https://nazokat777.github.io/learn-arabic-easily/; shakhalimov7@gmail.com)"}
HARAKAT = re.compile(r"[ً-ْٰـ]")


def get(p):
    p.update(format="json")
    for k in range(6):
        try:
            req = urllib.request.Request(API + "?" + urllib.parse.urlencode(p), headers=UA)
            return json.load(urllib.request.urlopen(req))
        except Exception as e:
            time.sleep(4 * (k + 1))
    return {}


def yalang(ar: str) -> str:
    return HARAKAT.sub("", ar).strip()


def sozlar():
    out = {}
    v = json.loads(Path("assets/content/vocabulary.json").read_text(encoding="utf-8"))["words"]
    for w in v:
        out.setdefault(yalang(w["ar"]), w["ar"])
    u = json.loads(Path("assets/content/ulash.json").read_text(encoding="utf-8"))
    for s in u["stages"]:
        for w in s["words"]:
            out.setdefault(yalang(w["ar"]), w["ar"])
    q = json.loads(Path("assets/content/qiroat_lessons.json").read_text(encoding="utf-8"))["lessons"]
    for l in q:
        for w in l["vocab"]:
            head = re.split(r"[،,]", w["ar"])[0].strip()
            if " " in head or not head:
                continue
            out.setdefault(yalang(head), head)
    return out


def main():
    top = sozlar()
    print("so'zlar:", len(top))
    natija = {}
    dest = Path("build/kalima_topildi.json")
    if dest.exists():
        natija = json.loads(dest.read_text(encoding="utf-8"))
    for i, (y, ar) in enumerate(top.items()):
        if y in natija or len(y) < 2:
            continue
        d = get({"action": "query", "list": "search", "srnamespace": "6", "srlimit": "20",
                 "srsearch": f'intitle:"LL-Q13955 (ara)" intitle:"-{y}.wav"'})
        fayllar = []
        for r in d.get("query", {}).get("search", []):
            t = r["title"]
            m = re.match(r"File:LL-Q13955 \(ara\)-(.+?)-(.+)\.wav$", t)
            if m and m.group(2) == y:
                fayllar.append({"fayl": t, "sozlovchi": m.group(1)})
        natija[y] = {"ar": ar, "fayllar": fayllar}
        if fayllar:
            print(y, [f["sozlovchi"] for f in fayllar])
        if i % 20 == 0:
            dest.write_text(json.dumps(natija, ensure_ascii=False, indent=0), encoding="utf-8")
        time.sleep(0.8)
    dest.write_text(json.dumps(natija, ensure_ascii=False, indent=0), encoding="utf-8")
    bor = {k: v for k, v in natija.items() if v["fayllar"]}
    print("topildi:", len(bor), "/", len(natija))
    from collections import Counter
    c = Counter(f["sozlovchi"] for v in bor.values() for f in v["fayllar"])
    print(c.most_common(10))


if __name__ == "__main__":
    main()
