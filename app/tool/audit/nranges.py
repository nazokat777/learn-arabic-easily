# -*- coding: utf-8 -*-
"""nranges.py -- which Nahv pages are transcribed (trans/n_pNNN.txt), as contiguous runs per book (book page ranges: 9-70, 77-159, 165-266, 273-408)."""
import os, re
SP = os.environ.get("AUDIT_SP", "tool/audit/work")
BOOKS = {1: (9, 70), 2: (77, 159), 3: (165, 266), 4: (273, 408)}
have = sorted(int(m.group(1)) for f in os.listdir(f"{SP}/trans") if (m := re.match(r'n_p(\d+)\.txt$', f)))
for b, (a, z) in BOOKS.items():
    pages = [p for p in have if a <= p <= z]
    runs = []; s = None; prev = None
    for p in pages:
        if s is None: s = prev = p
        elif p == prev + 1: prev = p
        else: runs.append((s, prev)); s = prev = p
    if s is not None: runs.append((s, prev))
    print(f"book {b} ({a}-{z}): {len(pages)}/{z-a+1} pages; runs: {', '.join(f'{x}-{y}' if x != y else str(x) for x, y in runs)}")
