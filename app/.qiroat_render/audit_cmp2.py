# -*- coding: utf-8 -*-
import io, json, re
from collections import Counter
ink = {int(k): v for k, v in json.load(io.open("nahv_ink.json", encoding="utf-8")).items()}
d = json.load(io.open(r"D:\LEARN ARABIC EASILY\app\assets\content\nahv_lessons.json", encoding="utf-8"))
ls = sorted(d["lessons"], key=lambda l: (l["book"], l["page"], l["num"]))

# Faqat qoidadan iborat, manbadagidek qisqa darslar (avval tekshirilgan)
BILINGAN = {(2,21),(2,45),(3,36),(4,28),(4,50),(4,51),(4,53)}

def arab(l):
    parts = [l.get("rule", {}).get("ar", "")]
    for b in l.get("blocks", []):
        parts.append(b.get("ar", ""))
        if b.get("intro"): parts.append(b["intro"].get("ar", ""))
        for it in b.get("items", []): parts.append(it.get("ar", ""))
    for e in l.get("exercise", []): parts.append(e.get("ar", ""))
    for t in l.get("tables", []):
        parts.append(json.dumps(t, ensure_ascii=False))
    return len(re.findall(r"[\u0600-\u06FF]", "".join(p or "" for p in parts)))

# Sahifani nechta dars bo'lishadi
bosh = Counter((l["book"], l["page"]) for l in ls)
natija = []
for i, l in enumerate(ls):
    p0 = l["page"]
    nx = ls[i+1] if i+1 < len(ls) else None
    p1 = max(p0, nx["page"] - 1) if (nx and nx["book"] == l["book"]) else p0
    # birinchi sahifa bo'linadi, qolganlari to'liq
    siyoh = ink.get(p0, 0) / bosh[(l["book"], p0)]
    for p in range(p0 + 1, p1 + 1):
        siyoh += ink.get(p, 0)
    ch = arab(l)
    natija.append((ch / siyoh if siyoh else 0, l["book"], l["num"], p0, p1, ch, int(siyoh)))

natija.sort()
print("%-6s %-5s %-5s %-9s %-7s %-7s %s" % ("nisbat","kitob","dars","sahifa","belgi","siyoh","izoh"))
n = 0
for r, b, num, p0, p1, ch, s in natija:
    if (b, num) in BILINGAN: continue
    n += 1
    if n > 25: break
    print("%.3f  %-5d %-5d %-9s %-7d %-7d" % (r, b, num, ("%d-%d"%(p0,p1)) if p1>p0 else str(p0), ch, s))
ort = sum(x[0] for x in natija)/len(natija)
print("\no'rtacha: %.3f" % ort)
