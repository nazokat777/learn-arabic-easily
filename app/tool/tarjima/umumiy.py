# -*- coding: utf-8 -*-
"""Mabdaul qiroat: o'qish matni (arabcha) va kitob tarjimasi (o'zbekcha) uchun umumiy yordamchilar.

splitSentences — lib/arabic.dart dagi Dart funksiyasining aynan nusxasi
(Dart tomonida test shuni tekshiradi)."""
import json, io, re, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LESSONS = os.path.join(ROOT, 'assets', 'content', 'qiroat_lessons.json')

def split_sentences(reading):
    out = []
    for line in reading.split('\n'):
        t = line.strip()
        if not t:
            continue
        buf = []
        i = 0
        while i < len(t):
            ch = t[i]
            buf.append(ch)
            if ch in '.؟!؛?':
                while i + 1 < len(t) and t[i + 1] in '.؟!؛':
                    i += 1
                    buf.append(t[i])
                s = ''.join(buf).strip()
                if s:
                    out.append(s)
                buf = []
            i += 1
        rest = ''.join(buf).strip()
        if rest:
            out.append(rest)
    return out

def load():
    return json.load(io.open(LESSONS, encoding='utf-8'))

D = re.compile('[\u064B-\u0652\u0653-\u0655\u0656-\u0670\u065F\u0640\u06D6-\u06ED\u08D3-\u08FF]')
def strip_d(s):
    return D.sub('', s).replace('\u200d', '')
