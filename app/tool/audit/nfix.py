# -*- coding: utf-8 -*-
"""Validated edits of assets/content/nahv_lessons.json (run from app/).
The file is stored as json.dumps(indent=2, ensure_ascii=False) with CRLF line ends and no trailing newline;
NFixer asserts that this round-trip is byte-identical before touching anything, so a fix changes only its own text.

    f = NFixer()
    f.replace(1, 6, 'rule.ar', 'لِلْمُذَكَّرِ سُمِّيَ', 'لِمُذَكَّرٍ سُمِّيَ', 'N1')   # exactly one occurrence in that field
    f.save()

field selectors: 'titleAr', 'rule.ar', 'rule.uz', 'blocks[i].ar', 'blocks[i].items[j].ar', 'exercise[i].ar', 'exercise[i].uz',
or 'ANY' = every string in the lesson (the old text must then occur exactly once in the whole lesson)."""
import json, re
APP = "assets/content/nahv_lessons.json"


def _walk(o, path=""):
    if isinstance(o, str):
        yield path, o
    elif isinstance(o, dict):
        for k, v in o.items():
            yield from _walk(v, f"{path}.{k}" if path else k)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from _walk(v, f"{path}[{i}]")


def _get(o, path):
    cur = o
    for tok in re.findall(r'[^.\[\]]+|\[\d+\]', path):
        cur = cur[int(tok[1:-1])] if tok.startswith('[') else cur[tok]
    return cur


def _set(o, path, val):
    toks = re.findall(r'[^.\[\]]+|\[\d+\]', path)
    cur = o
    for tok in toks[:-1]:
        cur = cur[int(tok[1:-1])] if tok.startswith('[') else cur[tok]
    last = toks[-1]
    if last.startswith('['): cur[int(last[1:-1])] = val
    else: cur[last] = val


class NFixer:
    def __init__(self, path=APP):
        self.path = path
        self.raw = open(path, encoding="utf-8", newline="").read()
        self.d = json.loads(self.raw)
        assert self._dump() == self.raw, "nahv_lessons.json round-trip is not byte-identical - format changed?"
        self.idx = {(l["book"], l["num"]): l for l in self.d["lessons"]}
        self.log = []

    def _dump(self):
        return json.dumps(self.d, indent=2, ensure_ascii=False).replace("\n", "\r\n")

    def lesson(self, book, num):
        return self.idx[(book, num)]

    def replace(self, book, num, field, old, new, label=""):
        l = self.lesson(book, num)
        if field == "ANY":
            hits = [(p, s) for p, s in _walk(l) if old in s]
            n = sum(s.count(old) for _, s in hits)
            assert n == 1, (label, book, num, "expected exactly one occurrence in the lesson, found", n, [p for p, _ in hits])
            path, s = hits[0]
        else:
            path = field
            s = _get(l, path)
            assert s.count(old) == 1, (label, book, num, path, "occurrences:", s.count(old))
        _set(l, path, s.replace(old, new))
        self.log.append((label, book, num, path, old, new))
        print(label, f"{book}/{num} {path} | {old} -> {new}")

    def drop_intro(self, book, num, bi, expect_ar, label=""):
        """remove the invented connector intro («وَهِيَ:» …) of a list block"""
        b = self.lesson(book, num)["blocks"][bi]
        assert b["type"] == "list" and b.get("intro") and b["intro"]["ar"] == expect_ar, (label, book, num, bi, b.get("intro"))
        old = b["intro"]
        del b["intro"]
        self.log.append((label, book, num, f"blocks[{bi}].intro", old["ar"], ""))
        print(label, f"{book}/{num} blocks[{bi}].intro dropped |", old["ar"], "/", old.get("uz"))

    def find(self, book, num, text):
        """paths of the strings in the lesson that contain `text`"""
        return [p for p, s in _walk(self.lesson(book, num)) if text in s]

    def save(self):
        out = self._dump()
        with open(self.path, "w", encoding="utf-8", newline="") as fh:
            fh.write(out)
        print("saved", len(self.log), "fixes")
