# -*- coding: utf-8 -*-
"""Yakuniy tekislashni yig'adi: qol.json (qo'lda) > taklif.json (DP). Invariantlarni tekshiradi
va har bir guruh uchun ro'yxat qaytaradi: [(arab_boshi, arab_soni, [atom indekslari])]."""
import sys, io, json, os
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
from tekislash import parse_beads
HERE = os.path.dirname(os.path.abspath(__file__))

def load_all():
    les = load()['lessons']
    atoms = json.load(io.open(os.path.join(HERE, 'atomlar.json'), encoding='utf-8'))
    taklif = json.load(io.open(os.path.join(HERE, 'taklif.json'), encoding='utf-8'))
    qol = json.load(io.open(os.path.join(HERE, 'qol.json'), encoding='utf-8'))
    return les, atoms, taklif, qol

def groups_for(key, les_by_key, atoms, taklif, qol):
    l = les_by_key[key]
    ar = split_sentences(l['reading'])
    a = atoms[key]['atoms']
    beads = parse_beads(qol.get(key) or taklif[key])
    assert sum(p for p, _ in beads) == len(ar), key
    assert sum(q for _, q in beads) == len(a), key
    out = []
    i = j = 0
    for p, q in beads:
        out.append((i, p, list(range(j, j + q))))
        i += p; j += q
    return out, ar, a

if __name__ == '__main__':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    les, atoms, taklif, qol = load_all()
    byk = {'%d-%d' % (l.get('book', 1), l['num']): l for l in les}
    gaps = []
    nsent = ngroups = 0
    for k in byk:
        g, ar, a = groups_for(k, byk, atoms, taklif, qol)
        nsent += len(ar); ngroups += len(g)
        for (i, p, js) in g:
            if not js:
                gaps.append((k, i + 1, p))
    print('darslar:', len(byk), ' gaplar:', nsent, ' guruhlar:', ngroups, ' qo\'lda tuzatilgan:', len(qol))
    print('tarjimasiz guruhlar:', len(gaps), ' (gaplar: %d)' % sum(p for _, _, p in gaps))
    for k, i, p in gaps:
        print(k, i, p)
