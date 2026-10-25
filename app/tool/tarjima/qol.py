# -*- coding: utf-8 -*-
"""Qo'l bilan tuzatilgan munchoq qatorlarini qol.json ga yozadi (yig'indini tekshirib).
Ishlatish:  python tool/tarjima/qol.py 1-14 "1:1 1:2 1:1*8 1:0 ..." [3-5 "..."] ...
Kalit bilan ikkinchi argument — munchoqlar qatori ("p:q" yoki "p:q*takror").
"""
import sys, io, json, os
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
from tekislash import parse_beads, beads_str

HERE = os.path.dirname(os.path.abspath(__file__))
QOL = os.path.join(HERE, 'qol.json')

def main(args):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    les = {'%d-%d' % (l.get('book', 1), l['num']): l for l in load()['lessons']}
    atoms = json.load(io.open(os.path.join(HERE, 'atomlar.json'), encoding='utf-8'))
    qol = json.load(io.open(QOL, encoding='utf-8')) if os.path.exists(QOL) else {}
    for k, s in zip(args[0::2], args[1::2]):
        beads = parse_beads(s)
        na = len(split_sentences(les[k]['reading']))
        nu = len(atoms[k]['atoms'])
        sp = sum(p for p, _ in beads); sq = sum(q for _, q in beads)
        if sp != na or sq != nu:
            print('XATO %s: arabcha %d (kerak %d), atom %d (kerak %d)' % (k, sp, na, sq, nu))
            continue
        qol[k] = beads_str(beads)
        print('OK', k, qol[k])
    io.open(QOL, 'w', encoding='utf-8', newline='\n').write(json.dumps(qol, ensure_ascii=False, indent=1, sort_keys=True) + '\n')

if __name__ == '__main__':
    main(sys.argv[1:])
