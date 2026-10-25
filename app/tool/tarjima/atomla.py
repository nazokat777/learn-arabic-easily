# -*- coding: utf-8 -*-
"""Kitob tarjimasini "atomlar"ga bo'ladi (sarlavha + gap bo'laklari yoki she'r satrlari).

Atomlar — arabcha gaplarga moslashtiriladigan eng kichik o'zbekcha bo'laklar. Ularni
birlashtirib (sarlavha + atomlar) kitobning `translation` matnini aynan qayta hosil qilish
mumkin (bo'shliqlar farqigacha). Chiqish: tool/tarjima/atomlar.json
Ishlatish (app/ papkasida):  python tool/tarjima/atomla.py
"""
import sys, re, io, json, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *

TERM = re.compile(r'[.?!]')
QUOTES = '"\u201d\u00bb'
# gap bo'lagi shunday so'zdan boshlansa — oldingi bo'lakning davomi ("... ?" Deb so'radi.)
CONT = re.compile(r'^[-\u2013\u2014]?\s*["\u201c]?(?:[Dd]e(?:b|di|dilar|bdi|bdilar|ya|yishdi|gan|dim|dik|ding|dingiz|ydi|yman|ysan)|[Ss]o\'radi|[Jj]avob\s+berdi)\b')

def split_prose(text):
    """Nasr matnini . ? ! bo'yicha bo'laklarga ajratadi; yopuvchi qo'shtirnoq oldingi bo'lakda qoladi."""
    text = re.sub(r'\s+', ' ', text).strip()
    parts, buf = [], []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        buf.append(ch)
        if ch in '.?!':
            while i + 1 < n and text[i + 1] in '.?!':
                i += 1
                buf.append(text[i])
            while i + 1 < n and text[i + 1] in QUOTES:
                i += 1
                buf.append(text[i])
            parts.append(''.join(buf).strip())
            buf = []
        i += 1
    rest = ''.join(buf).strip()
    if rest:
        parts.append(rest)
    # davom bo'laklarni oldingisiga qo'shish
    out = []
    for p in parts:
        if out and (CONT.match(p) or re.match(r'^[,;:)\]]', p)):
            out[-1] = out[-1] + ' ' + p
        else:
            out.append(p)
    return out

def split_poem(lines):
    """She'r satrlari: kichik harf bilan boshlangan satr — oldingisining davomi (qatlanib qolgan)."""
    out = []
    for ln in lines:
        ln = re.sub(r'\s+', ' ', ln).strip()
        if not ln:
            continue
        if out and (ln[:1].islower() or ln[:1] == '(') and not re.search(r'[.?!]["\u201d]?$', out[-1]):
            out[-1] += ' ' + ln
        else:
            out.append(ln)
    return out

HERE = os.path.dirname(os.path.abspath(__file__))

def json_or_empty(name):
    fn = os.path.join(HERE, name)
    return json.load(io.open(fn, encoding='utf-8')) if os.path.exists(fn) else {}

def tuzat_satrlar(key, lines, tuzat):
    """tuzat.json: {"1-30": [["eski", "yangi"], ...]} — PDF'dan chiqqan nuqsonlarni tuzatish."""
    lines = list(lines)
    for old, new in tuzat.get(key, []):
        hit = False
        for i, ln in enumerate(lines):
            if old in ln:
                lines[i] = ln.replace(old, new, 1)
                hit = True
                break
        if not hit:
            # ikki satr oralig'ida (masalan, satr oxiridagi defis) — satrlarni birlashtirib almashtiramiz
            for i in range(len(lines) - 1):
                m = lines[i] + ' ' + lines[i + 1]
                if old in m:
                    lines[i:i + 2] = [m.replace(old, new, 1)]
                    hit = True
                    break
        assert hit, 'tuzat topilmadi: %s %r' % (key, old)
    return [ln for ln in lines if ln.strip()]

def bol(key, atoms, bolish):
    """bolish.json: {"2-5": ["...shu matndan keyin bo'l"]} — bitta atomni ikkiga ajratadi."""
    atoms = list(atoms)
    for sub in bolish.get(key, []):
        idx = [i for i, a in enumerate(atoms) if sub in a]
        assert len(idx) == 1, 'bolish: %s %r -> %d ta atom' % (key, sub, len(idx))
        i = idx[0]
        pos = atoms[i].index(sub) + len(sub)
        left, right = atoms[i][:pos].strip(), atoms[i][pos:].strip()
        assert left and right, "bolish: bosh qism %s %r" % (key, sub)
        atoms[i:i + 1] = [left, right]
    return atoms

def sarlavha_ol(key, lines, sarlavha):
    """sarlavha.json: {"2-24": "sarlavha matni"} — avtomatik aniqlanmagan sarlavhani satrlardan ajratadi."""
    t = sarlavha.get(key)
    if not t:
        return None, lines
    acc = ''
    for n, ln in enumerate(lines, 1):
        acc = (acc + ' ' + ln).strip()
        if acc == t:
            return t, lines[n:]
        assert t.startswith(acc), 'sarlavha mos emas: %s %r vs %r' % (key, t, acc)
    raise AssertionError('sarlavha topilmadi: %s' % key)

def classify(l, lines):
    ar = split_sentences(l['reading'])
    ar_term = sum(1 for s in ar if re.search(r'[.؟!؛?]$', s))
    title = None
    if len(lines) >= 2 and not TERM.search(lines[0]) and len(lines[0].split()) <= 6 and lines[1][:1].isupper():
        title = lines[0]
    body = lines[1:] if title else lines
    up = sum(1 for x in body if x[:1].isupper())
    frac = up / max(1, len(body))
    term_frac = sum(1 for x in body if re.search(r'[.?!]["\u201d]?$', x)) / max(1, len(body))
    sher = (ar_term < len(ar) * 0.6) or (frac > 0.8 and term_frac < 0.5)
    return sher, title, body

def main():
    sat = json.load(io.open(os.path.join(os.path.dirname(__file__), 'satrlar.json'), encoding='utf-8'))
    les = load()['lessons']
    res = {}
    tuzat = json_or_empty('tuzat.json')
    bolish = json_or_empty('bolish.json')
    sarlavha = json_or_empty('sarlavha.json')
    for l in les:
        key = '%d-%d' % (l.get('book', 1), l['num'])
        lines = tuzat_satrlar(key, sat[key], tuzat)
        t0, lines0 = sarlavha_ol(key, lines, sarlavha)
        sher, title, body = classify(l, lines0 if t0 else lines)
        if t0:
            title = t0
        atoms = split_poem(body) if sher else split_prose(' '.join(body))
        atoms = bol(key, atoms, bolish)
        # tekshiruv: sarlavha + atomlar == (tuzatilgan) translation (bo'shliqsiz)
        joined = ' '.join(([title] if title else []) + atoms)
        a = re.sub(r'\s+', '', joined)
        tr = l['translation']
        for old, new in tuzat.get(key, []):
            assert old in tr, 'translationda topilmadi: %s %r' % (key, old)
            tr = tr.replace(old, new, 1)
        b = re.sub(r'\s+', '', tr)
        assert a == b, key
        res[key] = {'kind': 'sher' if sher else 'nasr', 'title': title, 'atoms': atoms}
    io.open(os.path.join(os.path.dirname(__file__), 'atomlar.json'), 'w', encoding='utf-8', newline='\n').write(
        json.dumps(res, ensure_ascii=False, indent=1) + '\n')
    nsher = sum(1 for v in res.values() if v['kind'] == 'sher')
    print('she\'r:', nsher, 'nasr:', len(res) - nsher, 'sarlavhali:', sum(1 for v in res.values() if v['title']))
    return res

if __name__ == '__main__':
    main()
