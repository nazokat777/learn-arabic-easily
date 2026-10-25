# -*- coding: utf-8 -*-
"""nzl.py LOC [LOC ...] [--out FILE] [--scale S] [--width PX] [--xrange X0 X1] [--tight]
LOC = 'page.strip:line/lines@word/words#x0-x1'  (as printed by diff_nahv.py; @word and #x-range optional).
Finds the text-line bands of the Nahv strip image from the ink profile (thin frame rules and the page header rule are
dropped), picks the band of that printed line, and crops a window around the word (RTL: word 1 is at the right).
All crops are stacked under small labels into ONE image -> prints its path. Needs AUDIT_SP (chunks/n/…png)."""
import sys, os, re
import numpy as np
from PIL import Image, ImageDraw

SP = os.environ.get("AUDIT_SP", "tool/audit/work")
args = sys.argv[1:]
out = f"{SP}/zoom/nzl_stack.png"; scale = 1.0; WIN = 0; GAP = 13
if '--out' in args: i = args.index('--out'); out = args[i + 1]; del args[i:i + 2]
if '--scale' in args: i = args.index('--scale'); scale = float(args[i + 1]); del args[i:i + 2]
TIGHT = '--tight' in args
if TIGHT: args.remove('--tight')   # one band only (no neighbouring bands when the band count differs from the transcribed line count)
XR = None
if '--xrange' in args: i = args.index('--xrange'); XR = (int(args[i + 1]), int(args[i + 2])); del args[i:i + 3]
if '--width' in args: i = args.index('--width'); WIN = int(args[i + 1]); del args[i:i + 2]


def bands_of(arr):
    H, W = arr.shape
    xa, xb = int(W * 0.08), int(W * 0.92)
    dark = (arr[:, xa:xb] < 140).sum(axis=1).astype(float)
    k = np.ones(5) / 5
    dark = np.convolve(dark, k, mode='same')
    ink = dark > 0.02 * (xb - xa)
    bands = []; s = None
    for y in range(H):
        if ink[y] and s is None: s = y
        if (not ink[y]) and s is not None: bands.append([s, y - 1]); s = None
    if s is not None: bands.append([s, H - 1])
    merged = []
    for b in bands:
        if merged and b[0] - merged[-1][1] < 7: merged[-1][1] = b[1]
        else: merged.append(b)
    return [b for b in merged if b[1] - b[0] >= 20]


tiles = []
for loc in args:
    xr = None
    if '#' in loc:
        loc, xs = loc.split('#'); xr = tuple(int(v) for v in xs.split('-'))
    m = re.match(r'(\d+)\.(\d+):(\d+)/(\d+)(?:@(\d+)/(\d+))?$', loc)
    page, strip, li, n = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
    wi, wn = (int(m.group(5)), int(m.group(6))) if m.group(5) else (None, None)
    im = Image.open(f"{SP}/chunks/n/p{page:03d}_c{strip}.png").convert('L')
    arr = np.asarray(im); H, W = arr.shape
    bands = bands_of(arr)
    if strip == 1 and bands and bands[0][1] < 110 and len(bands) > 1: bands = bands[1:]   # running header of the page
    M = len(bands)
    if M == 0: bands = [[0, H - 1]]; M = 1
    if M == n: idx = li - 1; ext = 0
    else: idx = min(M - 1, max(0, int(round((li - 0.5) * M / n - 0.5)))); ext = 0 if TIGHT else 1
    lo = max(0, idx - ext); hi = min(M - 1, idx + ext)
    y0 = max(0, bands[lo][0] - 14); y1 = min(H, bands[hi][1] + 14)
    # word blobs of the chosen band: ink columns separated by white gaps >= GAP px, listed right to left
    bsub = arr[bands[idx][0]:bands[idx][1] + 1, :] < 140
    colink = bsub.sum(axis=0)
    runs = []; s0 = None
    for x in range(W):
        if colink[x] > 0 and s0 is None: s0 = x
        if colink[x] == 0 and s0 is not None: runs.append([s0, x - 1]); s0 = None
    if s0 is not None: runs.append([s0, W - 1])
    blobs = []
    for r in runs:
        if blobs and r[0] - blobs[-1][1] < GAP: blobs[-1][1] = r[1]
        else: blobs.append(r)
    blobs = sorted([b for b in blobs if b[1] - b[0] >= 22], key=lambda b: -b[0])   # drop commas, frame edges
    cols = np.where(colink > 0)[0]
    xa, xb = (int(cols.min()), int(cols.max())) if len(cols) else (0, W - 1)
    nb = len(blobs)
    if WIN and wi is not None and nb:
        k = (wi - 1) if nb == wn else int(round((wi - 0.5) * nb / wn - 0.5))
        k = min(nb - 1, max(0, k))
        cx = (blobs[k][0] + blobs[k][1]) / 2
        cx0 = int(max(0, min(W - WIN, cx - WIN / 2))); cx1 = min(W, cx0 + WIN)
    else:
        cx0, cx1 = 0, W
    if XR: cx0, cx1 = max(0, XR[0]), min(W, XR[1])
    if xr: cx0, cx1 = max(0, xr[0]), min(W, xr[1])
    tile = im.crop((cx0, y0, cx1, y1))
    tile = tile.resize((int(tile.width * scale), int(tile.height * scale)), Image.LANCZOS)
    t = Image.new('L', (tile.width, tile.height + 22), 255)
    ImageDraw.Draw(t).text((6, 4), f"{loc}  bands {M}/{n} words {nb}/{wn}", fill=0)
    t.paste(tile, (0, 22)); tiles.append(t)
Wd = max(t.width for t in tiles); Ht = sum(t.height + 6 for t in tiles)
st = Image.new('L', (Wd, Ht), 255); y = 0
for t in tiles:
    st.paste(t, (0, y)); y += t.height + 6
os.makedirs(os.path.dirname(out), exist_ok=True)
st.save(out); print(out, st.size)
