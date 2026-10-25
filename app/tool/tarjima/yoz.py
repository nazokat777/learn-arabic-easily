# -*- coding: utf-8 -*-
"""Gapma-gap tarjimani assets/content/qiroat_lessons.json ga yozadi.

Har darsga qo'shiladi:
  tarjimaSarlavha : o'zbekcha sarlavha (bo'lsa)
  tarjimaGaplar   : [{"t": matn, "n": nechta arabcha gap (odatda 1), "q": 1 — ilova qo'shgan}, ...]
Invariantlar (buzilsa to'xtaydi):
  * sum(n) == arabcha gaplar soni (splitSentences)
  * sarlavha + (q bo'lmagan) matnlar == kitob tarjimasi (bo'shliqsiz solishtiriladi)
  * har bir tarjimasiz guruh qoshimcha.json da ko'rsatilgan (matn yoki null = muallif nomi)
translation maydoni tuzat.json dagi matn tuzatishlari bilan yangilanadi (PDF nuqsonlari).
Ishlatish (app/ papkasida):  python tool/tarjima/yoz.py
"""
import sys, io, json, os, re
sys.path.insert(0, os.path.dirname(__file__))
from umumiy import *
from yig import load_all, groups_for
HERE = os.path.dirname(os.path.abspath(__file__))

def norm(s):
    return re.sub(r'\s+', '', s)

def main():
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    raw = json.load(io.open(LESSONS, encoding='utf-8'))
    les, atoms, taklif, qol = load_all()
    byk = {'%d-%d' % (l.get('book', 1), l['num']): l for l in raw['lessons']}
    tuzat = json.load(io.open(os.path.join(HERE, 'tuzat.json'), encoding='utf-8'))
    qosh = json.load(io.open(os.path.join(HERE, 'qoshimcha.json'), encoding='utf-8'))
    used = set()
    nq = ngap = 0
    for k, l in byk.items():
        # 1) matn tuzatishlari (translation)
        tr = l['translation']
        assert tr == ' '.join(tr.split()), k
        for old, new in tuzat.get(k, []):
            if old in tr:
                tr = tr.replace(old, new, 1)
            else:
                assert not new or new in tr, (k, old)   # allaqachon qo'llangan (qayta ishga tushirish)
        tr = ' '.join(tr.split())
        l['translation'] = tr
        # 2) guruhlar
        g, ar, a = groups_for(k, byk, atoms, taklif, qol)
        title = atoms[k]['title']
        out = []
        book_parts = []
        for (i, p, js) in g:
            # she'rda bir bayt satrlari alohida qatorda ko'rsatiladi
            sep = '\n' if atoms[k]['kind'] == 'sher' else ' '
            text = sep.join(a[j] for j in js)
            e = {'t': text}
            if p != 1:
                e['n'] = p
            if not js:
                key = str(i + 1)
                assert k in qosh and key in qosh[k], 'tarjimasiz guruh qoshimcha.json da yo\'q: %s #%s' % (k, key)
                used.add((k, key))
                if qosh[k][key]:
                    assert p == 1, (k, key)
                    e['t'] = qosh[k][key]
                    e['q'] = 1
                    nq += 1
                ngap += 1
            else:
                book_parts.append(text)
            out.append(e)
        assert sum(e.get('n', 1) for e in out) == len(ar), k
        joined = ' '.join(([title] if title else []) + book_parts)   # bo'shliq/qator farqi inobatga olinmaydi
        assert norm(joined) == norm(tr), 'bo\'linish tarjimaga teng emas: %s' % k
        if title:
            l['tarjimaSarlavha'] = title
        l['tarjimaGaplar'] = out
    for k, v in qosh.items():
        for s in v:
            assert (k, s) in used, 'ishlatilmagan qoshimcha: %s %s' % (k, s)
    text = json.dumps(raw, ensure_ascii=False, indent=2)
    io.open(LESSONS, 'w', encoding='utf-8', newline='\n').write(text)
    print('OK: %d dars, ilova qo\'shgan tarjima: %d, tarjimasiz (muallif nomi) guruh: %d' % (len(byk), nq, ngap - nq))

if __name__ == '__main__':
    main()
