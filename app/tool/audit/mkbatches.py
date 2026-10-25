# -*- coding: utf-8 -*-
"""Write task files for subagent batches.
usage: mkbatches.py BOOK TARGET_IMAGES_PER_BATCH [skip lessons comma list]
Writes tasks/b<BOOK>_batch<K>.txt ; prints batch summaries."""
import sys, json, os
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
book = sys.argv[1]
target = int(sys.argv[2])
skip = set(int(x) for x in sys.argv[3].split(',')) if len(sys.argv) > 3 and sys.argv[3] else set()
iskey = book.startswith('k')
metafile = f"{SP}/chunks/{book if iskey else 'b' + book}_meta.json"
meta = json.load(open(metafile, encoding='utf-8'))
items = []
for k in sorted(meta, key=int):
    n = int(k)
    if n in skip: continue
    ent = meta[k]
    chunks = ent['chunks'] if isinstance(ent, dict) else ent
    prefix = f'{book}_k' if iskey else f'b{book}_l'
    items.append((n, [c['file'] for c in chunks], f"{SP}/trans/{prefix}{n:02d}.txt"))
batches = []; cur = []; cnt = 0
for it in items:
    if cur and cnt + len(it[1]) > target:
        batches.append(cur); cur = []; cnt = 0
    cur.append(it); cnt += len(it[1])
if cur: batches.append(cur)
for bi, b in enumerate(batches, 1):
    lines = []
    for n, imgs, out in b:
        lines.append(f"{'Key section' if iskey else 'Lesson'} {n}:")
        for i, im in enumerate(imgs, 1):
            lines.append(f"  image {i}: {im}")
        lines.append(f"  OUTPUT FILE: {out}")
        lines.append("")
    path = f"{SP}/tasks/{book if iskey else 'b' + book}_batch{bi}.txt"
    open(path, 'w', encoding='utf-8').write("\n".join(lines))
    print(path, "lessons", [x[0] for x in b][0], "-", [x[0] for x in b][-1], "n=", len(b), "images", sum(len(x[1]) for x in b))
