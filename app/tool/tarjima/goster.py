# -*- coding: utf-8 -*-
"""Ko'zdan kechirish uchun: tanlangan darslarni (taklif yoki qo'l bilan) munchoq-munchoq chiqaradi.
Ishlatish:  python tool/tarjima/goster.py 1-30 2-13 [--id]   (--id: 1:1 shaxsiyat tekislash)
"""
import sys, re, io, json, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
from tekislash import parse_beads, beads_str

HERE = os.path.dirname(os.path.abspath(__file__))

def uzatom(a):
    return a

def show(les, atoms, props, key, ident=False):
    l = next(x for x in les if '%d-%d' % (x.get('book', 1), x['num']) == key)
    a = atoms[key]
    ar = split_sentences(l['reading'])
    beads = [(1, 1)] * len(ar) if ident else parse_beads(props[key])
    print('=== %s [%s] ar=%d atoms=%d  %s' % (key, a['kind'], len(ar), len(a['atoms']), 'ID' if ident else beads_str(beads)))
    if a['title']:
        print('  T: %s' % a['title'])
    i = j = 0
    for p, q in beads:
        A = ' // '.join(strip_d(x) for x in ar[i:i + p])
        U = ' | '.join(a['atoms'][j:j + q])
        tag = '%d' % (i + 1) if p == 1 else '%d-%d' % (i + 1, i + p)
        print('%s%s) %s  ==>  %s' % (tag, '' if q == 1 else '[%d]' % q, A, U if q else "(YO'Q)"))
        i += p; j += q

if __name__ == '__main__':
    les = load()['lessons']
    atoms = json.load(io.open(os.path.join(HERE, 'atomlar.json'), encoding='utf-8'))
    props = json.load(io.open(os.path.join(HERE, 'taklif.json'), encoding='utf-8'))
    ident = '--id' in sys.argv
    for k in [x for x in sys.argv[1:] if not x.startswith('--')]:
        show(les, atoms, props, k, ident)
