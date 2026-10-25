# -*- coding: utf-8 -*-
"""Bitta darsning arabcha gaplari va o'zbekcha atomlarini alohida raqamlangan ro'yxat qilib chiqaradi."""
import sys, io, json, os
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
HERE = os.path.dirname(os.path.abspath(__file__))
if __name__ == '__main__':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    A = json.load(io.open(os.path.join(HERE, 'atomlar.json'), encoding='utf-8'))
    L = {'%d-%d' % (l.get('book', 1), l['num']): l for l in load()['lessons']}
    for k in sys.argv[1:]:
        print('=== %s title=%r' % (k, A[k]['title']))
        for i, s in enumerate(split_sentences(L[k]['reading']), 1):
            print('A%d: %s' % (i, strip_d(s)))
        for i, a in enumerate(A[k]['atoms'], 1):
            print('u%d: %s' % (i, a))
