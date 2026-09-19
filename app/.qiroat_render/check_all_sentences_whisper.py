# -*- coding: utf-8 -*-
"""Bir to'plamning barcha kliplarini whisper bilan tekshirish.

python .qiroat_render/check_all_sentences_whisper.py [toplam=sentence]  (sentence|sarf|mashq|vocab|word|extra)
Natija: build/whisper_all.tsv  (o'xshashlik \t fayl \t matn \t eshitilgani),
past o'xshashlik (< 0.55) — shubhali, qayta yasash uchun build/whisper_shubhali.txt.
Davom etadigan: tekshirilgan fayllar tsv'da bo'lsa qayta tekshirilmaydi.
"""
import json, re, sys, difflib, io
from pathlib import Path
from faster_whisper import WhisperModel

if (sys.stdout.encoding or "").lower() not in ("utf-8", "utf8"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
HAR = re.compile(r'[ً-ْٰـ]')
CHEGARA = 0.55

def norm(s):
    s = HAR.sub('', s)
    s = re.sub(r'[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = re.sub(r'[^ء-ي\s]', ' ', s)
    return ' '.join(s.split())

TOPLAM = {'sentence': 'sentences', 'sarf': 'sarf', 'mashq': 'mashq', 'vocab': 'vocab', 'word': 'words', 'extra': 'extra'}

def main():
    nom = sys.argv[1] if len(sys.argv) > 1 else 'sentence'
    sm = json.load(open(ROOT / f'assets/audio/{nom}_manifest.json', encoding='utf-8'))
    out = ROOT / ('build/whisper_all.tsv' if nom == 'sentence' else f'build/whisper_{nom}.tsv')
    done = {}
    if out.exists():
        for line in open(out, encoding='utf-8'):
            p = line.rstrip('\n').split('\t')
            if len(p) >= 4: done[p[1]] = p
    model = WhisperModel('small', device='cpu', compute_type='int8')
    fh = open(out, 'a', encoding='utf-8')
    n = 0
    for text, f in sm.items():
        if f in done: continue
        path = ROOT / 'assets/audio' / TOPLAM[nom] / f
        if not path.exists():
            fh.write(f'0.00\t{f}\t{text}\t(fayl yo\'q)\n'); continue
        try:
            segs, _ = model.transcribe(str(path), language='ar', beam_size=5)
            heard = ' '.join(x.text for x in segs).strip()
        except Exception as e:
            heard = f'(xato: {e})'
        r = difflib.SequenceMatcher(None, norm(text), norm(heard)).ratio()
        fh.write(f'{r:.2f}\t{f}\t{text}\t{heard}\n'); fh.flush()
        n += 1
        if n % 100 == 0: print(n, 'tekshirildi', flush=True)
    fh.close()
    rows = []
    for line in open(out, encoding='utf-8'):
        p = line.rstrip('\n').split('\t')
        if len(p) >= 4: rows.append((float(p[0]), p[1], p[2], p[3]))
    rows.sort()
    with open(ROOT / ('build/whisper_shubhali.txt' if nom == 'sentence' else f'build/whisper_{nom}_shubhali.txt'), 'w', encoding='utf-8') as s:
        for r, f, t, h in rows:
            if r < CHEGARA: s.write(f'{r:.2f}\t{f}\t{t}\t{h}\n')
    print('jami', len(rows), 'shubhali', sum(1 for r in rows if r[0] < CHEGARA))

if __name__ == '__main__':
    main()
