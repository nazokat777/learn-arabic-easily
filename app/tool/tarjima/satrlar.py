# -*- coding: utf-8 -*-
"""Kitob tarjimalarini PDF'dan SATR-SATR qayta oladi (sarlavha va she'r satrlarini
ajratish uchun) va ilovadagi `translation` bilan so'zma-so'z mosligini tekshiradi.

Chiqish: tool/tarjima/satrlar.json  {"1-5": ["satr", ...], ...}  (kitob-dars -> lotin satrlar)
Ishlatish (app/ papkasida):  python tool/tarjima/satrlar.py
"""
import sys, re, io, json, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
import pymupdf as fitz

DL = r"C:\Users\User\Downloads\Telegram Desktop"
PDF = {1: DL + r"\mabdaul-qiroat-1.pdf", 2: DL + r"\mabdaul-qiroat-2.pdf", 3: DL + r"\Mabdaul qiroat 3 chi kitob.pdf"}
FIRST = {1: 100, 2: 103, 3: 116}
CYR = re.compile(r"[\u0400-\u04FF]")
C2L = {'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'j','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'x','ц':'ts','ч':'ch','ш':'sh','щ':'sh','ъ':"'",'ь':'','ы':'i','э':'e','ю':'yu','я':'ya','ў':"o'",'ғ':"g'",'қ':'q','ҳ':'h','ҷ':'j'}
def translit(s):
    out = []
    for c in s:
        low = c.lower()
        if low in C2L:
            lat = C2L[low]
            out.append(lat.capitalize() if c.isupper() and lat else lat)
        else:
            out.append(c)
    return ''.join(out)

ORD = {"биринчи","иккинчи","учинчи","тўртинчи","бешинчи","олтинчи","еттинчи","саккизинчи","тўққизинчи","ўнинчи","ўн","йигирма","йигирманчи","ўттиз","ўттизинчи","қирқ","қирқинчи","эллик","элликинчи"}

def sahifa_satrlari(page):
    out = []
    for blk in page.get_text("dict")["blocks"]:
        if blk.get("type") != 0:
            continue
        for line in blk["lines"]:
            t = "".join(s["text"] for s in line["spans"]).strip()
            if t and t != "www.arabic.uz" and not t.isdigit():
                out.append((round(line["bbox"][1]), round(line["bbox"][0]), t))
    return [t for _, _, t in sorted(out)]

def kitob1():
    START = re.compile(r"дарснинг\s+арабча\s+матнидаги\s+таржима\s*:?", re.I)
    STOP = re.compile(r"дарснинг\s+ўзбекча\s+матнидаги\s+таржима\s*:?", re.I)
    doc = fitz.open(PDF[1])
    full = "\n".join(doc[i].get_text() for i in range(FIRST[1], len(doc)))
    res, pos = [], 0
    while True:
        m = START.search(full, pos)
        if not m: break
        e = STOP.search(full, m.end())
        seg = full[m.end(): e.start() if e else len(full)]
        keep = []
        for line in seg.split("\n"):
            line = line.strip()
            if not line or line == "www.arabic.uz" or line.isdigit(): continue
            if set(line) <= set("-– "): continue
            if CYR.search(line): keep.append(line)
        # keyingi sarlavhaning tartib so'zlarini oxiridan olib tashlash
        while keep:
            w = keep[-1].split()
            while w and w[-1].strip(".,:;").lower() in ORD: w.pop()
            if w:
                keep[-1] = " ".join(w); break
            keep.pop()
        res.append(keep)
        pos = e.end() if e else len(full)
    return {i + 1: v for i, v in enumerate(res)}

def kitob2():
    HEAD = re.compile(r"^(\d{1,2})\s*[-–]\s*дарс", re.I)
    doc = fitz.open(PDF[2])
    flat = [t for i in range(FIRST[2], doc.page_count) for t in sahifa_satrlari(doc[i])]
    blocks, cur = [], None
    for t in flat:
        if HEAD.match(t):
            blocks.append([]); cur = blocks[-1]; continue
        if cur is not None and CYR.search(t): cur.append(t)
    kept = [b for b in blocks if len(re.sub(r"\s+", " ", " ".join(b)).strip()) > 60]
    return {i + 1: b for i, b in enumerate(kept)}

def kitob3():
    HEAD = re.compile(r"^(\d{1,2})\s*[-–—]?\s*(дарс|ҳикоя|хикоя)\s*$", re.I)
    doc = fitz.open(PDF[3])
    flat = [t for i in range(FIRST[3], doc.page_count) for t in sahifa_satrlari(doc[i])]
    out, cur = {}, None
    for t in flat:
        m = HEAD.match(t)
        if m:
            cur = int(m.group(1)); out.setdefault(cur, []); continue
        if cur is not None and CYR.search(t): out[cur].append(t)
    return out

def norm(s):
    return re.sub(r"\s+", " ", s).strip()

if __name__ == '__main__':
    src = {1: kitob1(), 2: kitob2(), 3: kitob3()}
    lessons = load()['lessons']
    res, bad = {}, []
    for l in lessons:
        b, n = l.get('book', 1), l['num']
        satrlar = [translit(x) for x in src[b].get(n, [])]
        res['%d-%d' % (b, n)] = satrlar
        if norm(' '.join(satrlar)) != norm(l['translation']):
            bad.append((b, n))
    print('dars:', len(lessons), '| satrlar bilan matn MOS EMAS:', len(bad), bad[:30])
    json.dump(res, io.open(os.path.join(os.path.dirname(__file__), 'satrlar.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
