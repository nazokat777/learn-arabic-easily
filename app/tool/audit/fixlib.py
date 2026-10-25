# -*- coding: utf-8 -*-
"""Shared helpers for reading fixes (run from app/): load/save JSON, sentence helpers, validated replace/remove/split."""
import sys, json, re
APP = "assets/content/qiroat_lessons.json"
DIAC = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]')
TR = str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و'})
def nz(s): return re.sub(r'[\s.؟!؛?،,:\-–]+', ' ', DIAC.sub('', s).translate(TR)).strip()
TERM = ".؟!؛?"; RUN_ON = ".؟!؛"
def split_sentences(reading):
    out = []
    for line in reading.split("\n"):
        line = line.strip()
        if not line: continue
        buf = ""; i = 0
        while i < len(line):
            buf += line[i]
            if line[i] in TERM:
                while i + 1 < len(line) and line[i + 1] in RUN_ON:
                    i += 1; buf += line[i]
                t = buf.strip()
                if t: out.append(t)
                buf = ""
            i += 1
        t = buf.strip()
        if t: out.append(t)
    return out

class Fixer:
    def __init__(self):
        self.raw = open(APP, encoding="utf-8", newline="").read()
        self.d = json.loads(self.raw)
        self.idx = {}
        b = 1; prev = 0
        for l in self.d["lessons"]:
            if l["num"] < prev: b += 1
            prev = l["num"]
            self.idx[(b, l["num"])] = l
    def lesson(self, book, num): return self.idx[(book, num)]
    def find(self, book, num, expect_text):
        """index (1-based) of the sentence whose normalized text equals nz(expect_text)"""
        ss = split_sentences(self.lesson(book, num)["reading"])
        hits = [i + 1 for i, s in enumerate(ss) if nz(s) == nz(expect_text)]
        assert len(hits) == 1, ("find", book, num, hits, nz(expect_text))
        return hits[0]
    def replace_sentence(self, book, num, expect_text, fn, label):
        l = self.lesson(book, num)
        k = self.find(book, num, expect_text)
        old = split_sentences(l["reading"])[k - 1]
        new = fn(old)
        assert l["reading"].count(old) == 1, (label, "sentence not unique in reading")
        l["reading"] = l["reading"].replace(old, new)
        print(label, f"{book}-{num} #{k} |", old, "->", new)
    def remove_sentence(self, book, num, expect_text, label):
        l = self.lesson(book, num)
        k = self.find(book, num, expect_text)
        old = split_sentences(l["reading"])[k - 1]
        assert l["reading"].count(old) == 1, (label, "not unique")
        r = l["reading"]
        r = r.replace(" " + old, "", 1) if (" " + old) in r else r.replace(old + " ", "", 1)
        l["reading"] = r
        print(label, f"{book}-{num} #{k} | removed:", old)
    def replace_in_field(self, book, num, field, old, new, label):
        l = self.lesson(book, num)
        assert l[field].count(old) == 1, (label, field, l[field].count(old))
        l[field] = l[field].replace(old, new)
        print(label, f"{book}-{num} [{field}] |", old, "->", new)
    def save(self):
        out = json.dumps(self.d, ensure_ascii=False, indent=2)
        open(APP, "w", encoding="utf-8", newline="").write(out)
        print("WRITTEN")
