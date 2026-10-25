# -*- coding: utf-8 -*-
"""nrej.py "APP words" "BOOK words" [...]  -- remember diff_nahv flags that were judged FALSE (appends to $AUDIT_SP/nahv_rejects.txt)."""
import sys, os, re
SP = os.environ.get("AUDIT_SP", "tool/audit/work")
sys.argv_ = sys.argv
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ی': 'ي', 'ک': 'ك', 'ہ': 'ه'})
def nw(w): return re.sub(r'[^\u0621-\u064A]', '', DIAC.sub('', w).translate(TR)).replace('ءا', 'ا')
def words(t):
    t = re.sub(r'([«﴿])\s+', r'\1', t); t = re.sub(r'\s+([»﴾])', r'\1', t); t = re.sub('\u0640\s+', '\u0640', t)
    return [n for n in (nw(w.replace('[?]', '')) for w in re.split(r'\s+', t)) if n]
a = sys.argv[1:]
with open(f"{SP}/nahv_rejects.txt", "a", encoding="utf-8", newline="\n") as fh:
    for i in range(0, len(a), 2):
        s = ' '.join(words(a[i])) + '|' + ' '.join(words(a[i + 1])); fh.write(s + "\n"); print("rejected:", s)
