# -*- coding: utf-8 -*-
"""Nahv task files: mkbatches_n.py TARGET_IMAGES_PER_BATCH [pages comma list | START-END ...] -> tasks/n_batchK.txt"""
import sys, json, os
import os; SP = os.environ.get("AUDIT_SP", "tool/audit/work")
target = int(sys.argv[1])
meta = json.load(open(f"{SP}/chunks/n_meta.json", encoding='utf-8'))
pages = []
for tok in sys.argv[2:]:
    for part in tok.split(','):
        if '-' in part: a, b = part.split('-'); pages += list(range(int(a), int(b) + 1))
        elif part: pages.append(int(part))
if not pages: pages = sorted(int(k) for k in meta)
prefix = os.environ.get('NPREFIX', 'n')
batches = []; cur = []; cnt = 0
for p in pages:
    ent = meta.get(str(p))
    if not ent: continue
    out = f"{SP}/trans/n_p{p:03d}.txt"
    if os.path.exists(out) and not os.environ.get('NFORCE'): continue
    if cur and cnt + len(ent) > target: batches.append(cur); cur = []; cnt = 0
    cur.append((p, [e['file'] for e in ent], out)); cnt += len(ent)
if cur: batches.append(cur)
for bi, b in enumerate(batches, 1):
    lines = []
    for p, imgs, out in b:
        lines.append(f"Page {p}:")
        for i, im in enumerate(imgs, 1): lines.append(f"  strip {i}: {im}")
        lines.append(f"  OUTPUT FILE: {out}"); lines.append("")
    path = f"{SP}/tasks/{prefix}_batch{bi}.txt"; open(path, 'w', encoding='utf-8').write("\n".join(lines))
    print(path, "pages", b[0][0], "-", b[-1][0], "n=", len(b), "strips", sum(len(x[1]) for x in b))
