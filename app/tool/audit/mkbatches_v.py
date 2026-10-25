# -*- coding: utf-8 -*-
"""Vocab task files: mkbatches_v.py TARGET_IMAGES_PER_BATCH  -> tasks/v_batchK.txt (all 3 books, lesson boundaries respected)"""
import sys, json, os
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
target = int(sys.argv[1])
items = []
for book in (1, 2, 3):
    meta = json.load(open(f"{SP}/chunks/v{book}_meta.json", encoding='utf-8'))
    for k in sorted(meta, key=int):
        n = int(k)
        outp = f"{SP}/trans/v{book}_l{n:02d}.txt"
        if os.path.exists(outp): continue
        items.append((book, n, [c['file'] for c in meta[k]], outp))
batches = []; cur = []; cnt = 0
for it in items:
    if cur and cnt + len(it[2]) > target:
        batches.append(cur); cur = []; cnt = 0
    cur.append(it); cnt += len(it[2])
if cur: batches.append(cur)
for bi, b in enumerate(batches, 1):
    lines = []
    for book, n, imgs, out in b:
        lines.append(f"Book {book} lesson {n}:")
        for i, im in enumerate(imgs, 1): lines.append(f"  image {i}: {im}")
        lines.append(f"  OUTPUT FILE: {out}")
        lines.append("")
    path = f"{SP}/tasks/v_batch{bi}.txt"
    open(path, 'w', encoding='utf-8').write("\n".join(lines))
    print(path, "items", len(b), f"({b[0][0]}-{b[0][1]} .. {b[-1][0]}-{b[-1][1]})", "images", sum(len(x[2]) for x in b))
