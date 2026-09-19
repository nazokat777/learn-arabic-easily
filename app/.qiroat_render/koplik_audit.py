# -*- coding: utf-8 -*-
"""Ko'plik auditi: kitob lug'at jadvallarida arabcha katak «،» bilan ikki
so'z (birlik ، ko'plik) bo'lsa-yu, ilova lug'atida `pl` bo'sh bo'lsa — nomzod.

Arabcha matn qatlami buzuq (ligaturalar aralash), lekin «،» (U+060C) va
qavslar buzilmaydi — ko'plik BORLIGINI shu bilan bilamiz; o'zbekcha ustun
(kirill) toza chiqadi — ilova yozuvi (lotin) bilan shu orqali juftlanadi.

python .qiroat_render/koplik_audit.py  -> build/koplik_nomzod.tsv
(kitob, pdf sahifa, o'zbekcha, ilova dars, ilova ar, buzuq arabcha)
"""
import json, re, sys, io
from pathlib import Path
import fitz

if (sys.stdout.encoding or "").lower() not in ("utf-8", "utf8"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
PDF = {
    1: r"C:/Users/User/Downloads/Telegram Desktop/mabdaul-qiroat-1.pdf",
    2: r"C:/Users/User/Downloads/Telegram Desktop/mabdaul-qiroat-2.pdf",
    3: r"C:/Users/User/Downloads/Telegram Desktop/Mabdaul qiroat 3 chi kitob.pdf",
}
CYR = {'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'j','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'x','ц':'ts','ч':'ch','ш':'sh','щ':'sh','ъ':'','ы':'i','ь':'','э':'e','ю':'yu','я':'ya','ў':'o','қ':'q','ғ':'g','ҳ':'h'}

def lat(s):
    return ''.join(CYR.get(c, c) for c in s.lower())

def key(s):
    s = lat(s)
    s = re.sub(r"[^a-z0-9]", "", s)
    return s

def app_vocab():
    q = json.load(open(ROOT / 'assets/content/qiroat_lessons.json', encoding='utf-8'))
    book, prev = 0, 0
    out = []
    for l in q['lessons']:
        if l['num'] <= prev: book += 1
        prev = l['num']
        for v in l['vocab']:
            out.append((book + 1, l['num'], v))
    return out

def main():
    vocab = app_vocab()
    by_book = {}
    for b, n, v in vocab:
        by_book.setdefault(b, []).append((n, v))
    nomzod = []
    jami_juft = 0
    for b, path in PDF.items():
        d = fitz.open(path)
        entries = by_book[b]
        idx = {}
        for n, v in entries:
            idx.setdefault(key(v['uz']), []).append((n, v))
        for pi in range(len(d)):
            page = d[pi]
            try:
                tabs = page.find_tables()
            except Exception:
                continue
            for t in tabs.tables:
                for row in t.extract():
                    cells = [(c or '').strip() for c in row]
                    # ustunlar juft-juft: (uz, ar) — arabcha katakda arab harfi bor
                    for i in range(len(cells) - 1):
                        uz, ar = cells[i], cells[i + 1]
                        if not re.search(r'[\u0400-\u04FF]', uz) or not re.search(r'[\u0600-\u06FF]', ar):
                            continue
                        uz1 = uz.split('\n')[0]
                        k = key(uz1)
                        if not k or k not in idx:
                            continue
                        jami_juft += 1
                        has_pl = ('،' in ar) or ('(' in ar) or (')' in ar)
                        if not has_pl:
                            continue
                        for n, v in idx[k]:
                            if not v.get('pl', '').strip():
                                nomzod.append((b, pi + 1, uz1, n, v['ar'], ar.replace('\n', ' ')))
    with open(ROOT / 'build/koplik_nomzod.tsv', 'w', encoding='utf-8') as f:
        for r in nomzod:
            f.write('\t'.join(str(x) for x in r) + '\n')
    print('juftlangan qatorlar', jami_juft, 'nomzod', len(nomzod))

if __name__ == '__main__':
    main()
