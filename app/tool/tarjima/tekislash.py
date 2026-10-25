# -*- coding: utf-8 -*-
"""Arabcha gaplar bilan o'zbekcha atomlarni tekislaydi (Gale–Church usuli + tinish belgilari
+ lug'at mosligi). Natija — har dars uchun "munchoqlar" qatori: "p:q" = p ta ketma-ket arabcha
gap <-> q ta ketma-ket o'zbekcha atom (q=0: kitobda tarjimasi yo'q gap).
Chiqish: tool/tarjima/taklif.json  {"1-5": "1:1*3 2:1 ...", ...}
"""
import sys, re, io, json, os, math
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *

HERE = os.path.dirname(os.path.abspath(__file__))
AR_LETTERS = re.compile(r'[\u0621-\u064A\u0671-\u06D3]')

def ar_len(s):
    return len(AR_LETTERS.findall(strip_d(s)))

def uz_len(s):
    return len(re.sub(r"[^A-Za-z\u2018\u2019'`]", '', s))

def uz_norm(s):
    return re.sub(r"[\u2018\u2019`\u02bb\u02bc]", "'", s).lower()

# o'zbekcha matnning tinish belgisi
def uz_end(s):
    s = s.rstrip('"\u201d\u00bb ')
    return s[-1:] if s else ''

def ar_end(s):
    s = s.rstrip()
    return s[-1:] if s else ''

def punct_cost(ar_sents, uz_atoms):
    """? va ! mosligi."""
    if not uz_atoms:
        return 0.0
    c = 0.0
    a_q = any(ar_end(s) == '\u061f' for s in ar_sents)
    u_q = any(uz_end(s) == '?' for s in uz_atoms)
    a_last_q = ar_end(ar_sents[-1]) == '\u061f'
    u_last_q = uz_end(uz_atoms[-1]) == '?'
    if a_last_q != u_last_q:
        c += 1.2
    elif a_q != u_q:
        c += 0.4
    a_last_x = ar_end(ar_sents[-1]) == '!'
    u_last_x = uz_end(uz_atoms[-1]) == '!'
    if a_last_x != u_last_x:
        c += 0.4
    return c

PREF = re.compile(r'^(?:\u0648|\u0641|\u0628|\u0644|\u0643|\u0633|\u0627\u0644|\u0644\u0644|\u0648\u0627\u0644|\u0641\u0627\u0644|\u0628\u0627\u0644|\u0644\u0644|\u0643\u0627\u0644)+')

def ar_tokens(s):
    toks = re.findall(r'[\u0621-\u064A\u0671-\u06D3]+', strip_d(s))
    return toks

def build_lex(vocab):
    """vocab -> [(arab_asos_variantlari, uzbek_so'z_ildizlari)]"""
    out = []
    for v in vocab:
        a = strip_d(v.get('ar', ''))
        a = re.sub(r'^\u0627\u0644', '', a)
        forms = {a}
        if v.get('pl'):
            forms.add(re.sub(r'^\u0627\u0644', '', strip_d(v['pl'])))
        forms = {f for f in forms if len(f) >= 3}
        stems = set()
        for w in re.findall(r"[A-Za-z']+", uz_norm(v.get('uz', ''))):
            if len(w) >= 4:
                stems.add(w[:max(4, len(w) - 2)])
        if forms and stems:
            out.append((forms, stems))
    return out

def lex_sets(lex, ar, atoms):
    """Har arabcha gap uchun: qaysi lug'at yozuvlari bor; har atom uchun: qaysilarining o'zbekcha ildizi bor."""
    ar_has = []
    for s in ar:
        toks = ar_tokens(s)
        toks = set(toks) | {PREF.sub('', t) for t in toks}
        has = set()
        for k, (forms, stems) in enumerate(lex):
            if any((f in toks) or any(t.startswith(f) or t.endswith(f) for t in toks if len(t) <= len(f) + 3) for f in forms):
                has.add(k)
        ar_has.append(has)
    uz_has = []
    for a in atoms:
        u = uz_norm(a)
        uz_has.append({k for k, (forms, stems) in enumerate(lex) if any(st in u for st in stems)})
    return ar_has, uz_has

BEADS = [(1, 1), (1, 2), (2, 1), (1, 0), (0, 1), (2, 2), (1, 3), (3, 1), (2, 3), (3, 2), (1, 4), (4, 1), (3, 3)]
PRIOR = {(1, 1): 0.0, (1, 2): 1.2, (2, 1): 1.6, (1, 0): 3.0, (0, 1): 3.2, (2, 2): 2.2, (1, 3): 2.4, (3, 1): 3.0,
         (2, 3): 3.0, (3, 2): 3.0, (1, 4): 3.8, (4, 1): 4.2, (3, 3): 3.6}

def align(ar, atoms, lex, c, s2, sher):
    n, m = len(ar), len(atoms)
    ar_has, uz_has = lex_sets(lex, ar, atoms)
    INF = 1e18
    al = [ar_len(s) for s in ar]
    ul = [uz_len(s) for s in atoms]
    cal = [0]
    for x in al: cal.append(cal[-1] + x)
    cul = [0]
    for x in ul: cul.append(cul[-1] + x)
    prior = dict(PRIOR)
    if sher:
        prior[(1, 2)] = 0.2
        prior[(1, 1)] = 0.6
        prior[(1, 3)] = 1.6
    best = [[INF] * (m + 1) for _ in range(n + 1)]
    back = [[None] * (m + 1) for _ in range(n + 1)]
    best[0][0] = 0.0
    for i in range(n + 1):
        for j in range(m + 1):
            b = best[i][j]
            if b >= INF:
                continue
            for (p, q) in BEADS:
                i2, j2 = i + p, j + q
                if i2 > n or j2 > m:
                    continue
                l1 = cal[i2] - cal[i]
                l2 = cul[j2] - cul[j]
                if p == 0:
                    cost = prior[(p, q)] + 0.05 * l2
                elif q == 0:
                    cost = prior[(p, q)] + 0.03 * l1
                else:
                    delta = (l2 - c * l1) / math.sqrt(max(l1, 3) * s2)
                    cost = prior[(p, q)] + 0.5 * min(delta * delta, 14.0)
                    cost += punct_cost(ar[i:i2], atoms[j:j2])
                    A = set().union(*ar_has[i:i2]); U = set().union(*uz_has[j:j2])
                    h = len(A & U); ms = len(A - U)
                    cost += -0.9 * min(h, 4) + 0.35 * min(ms, 4)
                tot = b + cost
                if tot < best[i2][j2]:
                    best[i2][j2] = tot
                    back[i2][j2] = (i, j, p, q)
    beads = []
    i, j = n, m
    while (i, j) != (0, 0):
        pi, pj, p, q = back[i][j]
        beads.append((p, q))
        i, j = pi, pj
    beads.reverse()
    return beads, best[n][m]

def beads_str(beads):
    out = []
    k = 0
    while k < len(beads):
        r = 1
        while k + r < len(beads) and beads[k + r] == beads[k]:
            r += 1
        out.append('%d:%d' % beads[k] + ('*%d' % r if r > 1 else ''))
        k += r
    return ' '.join(out)

def parse_beads(s):
    beads = []
    for tok in s.split():
        m = re.fullmatch(r'(\d+):(\d+)(?:\*(\d+))?', tok)
        assert m, tok
        beads += [(int(m.group(1)), int(m.group(2)))] * int(m.group(3) or 1)
    return beads

def estimate_params(les, atoms):
    """c va s2 ni 1:1 mos (soni teng, nasr) darslardan baholash."""
    rat = []
    for l in les:
        key = '%d-%d' % (l.get('book', 1), l['num'])
        a = atoms[key]
        ar = split_sentences(l['reading'])
        if a['kind'] == 'nasr' and len(ar) == len(a['atoms']):
            rat += [(ar_len(x), uz_len(y)) for x, y in zip(ar, a['atoms'])]
    sa = sum(x for x, _ in rat); su = sum(y for _, y in rat)
    c = su / sa
    var = sum(((y - c * x) ** 2) / max(x, 3) for x, y in rat) / len(rat)
    return c, var

def main():
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    les = load()['lessons']
    atoms = json.load(io.open(os.path.join(HERE, 'atomlar.json'), encoding='utf-8'))
    c, s2 = 1.511, 12.952   # ko'rib chiqilgan takliflar bilan bir xil bo'lishi uchun qotirilgan (estimate_params natijasi)
    print('c=%.3f s2=%.3f' % (c, s2))
    import hashlib
    res = {}
    old = json.load(io.open(os.path.join(HERE, 'taklif.json'), encoding='utf-8')) if os.path.exists(os.path.join(HERE, 'taklif.json')) else {}
    oldh = json.load(io.open(os.path.join(HERE, 'taklif_h.json'), encoding='utf-8')) if os.path.exists(os.path.join(HERE, 'taklif_h.json')) else {}
    newh = {}
    same = diff = 0
    for l in les:
        key = '%d-%d' % (l.get('book', 1), l['num'])
        a = atoms[key]
        ar = split_sentences(l['reading'])
        h = hashlib.md5(json.dumps([ar, a['atoms'], a['kind'], round(c, 3), round(s2, 3)], ensure_ascii=False).encode('utf-8')).hexdigest()
        newh[key] = h
        if key in old and oldh.get(key) == h:
            res[key] = old[key]
            beads = parse_beads(res[key])
        else:
            lex = build_lex(l['vocab'])
            beads, cost = align(ar, a['atoms'], lex, c, s2, a['kind'] == 'sher')
            res[key] = beads_str(beads)
        if len(ar) == len(a['atoms']):
            if all(b == (1, 1) for b in beads): same += 1
            else: diff += 1
    io.open(os.path.join(HERE, 'taklif.json'), 'w', encoding='utf-8', newline='\n').write(
        json.dumps(res, ensure_ascii=False, indent=1) + '\n')
    print('teng sonli darslar: DP hammasini 1:1 deb topdi:', same, ' boshqacha:', diff)

if __name__ == '__main__':
    main()
