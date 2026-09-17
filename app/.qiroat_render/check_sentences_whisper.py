# -*- coding: utf-8 -*-
"""Jumla kliplarini whisper bilan «qayta o'qib», matnga solishtirish.

python .qiroat_render/check_sentences_whisper.py <dars raqami> [...]
Natija: build/whisper_dars<N>.txt — har jumla uchun o'xshashlik (0..1),
past bo'lganlari (< 0.6) shubhali: klip noto'g'ri/tiqilib o'qilgan bo'lishi mumkin.
Whisper harakatsiz yozadi, shuning uchun solishtirish harakatsiz, hamza/alif
normallashtirilib qilinadi.
"""
import json, re, sys, difflib
from pathlib import Path
from faster_whisper import WhisperModel

sys.path.insert(0, str(Path(__file__).parent))
ROOT = Path(__file__).resolve().parent.parent
HAR = re.compile(r'[ً-ْٰـ]')

def norm(s):
    s = HAR.sub('', s)
    s = re.sub(r'[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = re.sub(r'[^ء-ي\s]', ' ', s)
    return ' '.join(s.split())

def split_sentences(t):
    return [p.strip() for p in re.split(r'(?<=[\.\?؟!])\s+', t) if p.strip()]

def main():
    nums = [int(a) for a in sys.argv[1:]]
    q = json.load(open(ROOT / 'assets/content/qiroat_lessons.json', encoding='utf-8'))
    sm = json.load(open(ROOT / 'assets/audio/sentence_manifest.json', encoding='utf-8'))
    model = WhisperModel('small', device='cpu', compute_type='int8')
    for n in nums:
        l = [x for x in q['lessons'] if x['num'] == n][0]
        out = ROOT / 'build' / f'whisper_dars{n}.txt'
        rows = []
        for s in split_sentences(l['reading']):
            f = sm.get(s)
            if not f:
                rows.append((0.0, s, '(klip yo\'q)', '')); continue
            path = ROOT / 'assets/audio/sentences' / f
            segs, _ = model.transcribe(str(path), language='ar', beam_size=5)
            heard = ' '.join(x.text for x in segs).strip()
            r = difflib.SequenceMatcher(None, norm(s), norm(heard)).ratio()
            rows.append((r, s, heard, f))
        rows.sort()
        with open(out, 'w', encoding='utf-8') as fh:
            for r, s, heard, f in rows:
                fh.write(f'{r:.2f}\t{f}\t{s}\n\t\t{heard}\n')
        print(n, 'jumla', len(rows), 'shubhali(<0.6):', sum(1 for r in rows if r[0] < 0.6), '->', out.name)

if __name__ == '__main__':
    main()
