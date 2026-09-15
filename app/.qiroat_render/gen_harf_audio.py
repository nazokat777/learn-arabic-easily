# -*- coding: utf-8 -*-
"""Harf NOMLARI — inson ovozi (Wikimedia Commons).

Manba: «File:Arabic alphabets.ogg» (Atef1975, CC BY-SA 4.0) — bitta
yozuvda 28 harf nomi tartib bilan (ألف … ياء), toza (clipping 0 %, shovqin
−48 dB), bir xil ovoz va ohang. Whisper (faster-whisper, small) bilan
tekshirildi: 28 so'z, tartib alifbo bilan aynan mos.

Nega bu: harf-harf alohida yozuvlar (Ruaa GHAREEB to'plami) telefon
mikrofonida va ko'pi qattiq kesilgan edi — «dabdala» eshitilardi.

Kesish: whisper so'z chegaralari — anchor; har oynada energiya bo'yicha
qat'iy chegara (−32 dB cho'qqiga nisbatan), 40 ms zaxira, fade, loudnorm,
0.3 s jimlik. Natija: assets/audio/harf/hNN.mp3 + harf_manifest.json
(matn = letters.json name_ar). VocabAudio ro'yxatida bu to'plam OXIRIDA.

Tartib:  python .qiroat_render/gen_harf_audio.py   (build/alfa/atef.ogg kerak —
         https://upload.wikimedia.org/wikipedia/commons/8/8f/Arabic_alphabets.ogg)
"""
import json, math, struct, subprocess, sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
SRC = Path("build/alfa/atef.ogg")
OUT = Path("assets/audio/harf")
MANIFEST = Path("assets/audio/harf_manifest.json")
NOMLAR = ['ألف','باء','تاء','ثاء','جيم','حاء','خاء','دال','ذال','راء','زاي','سين','شين','صاد',
          'ضاد','طاء','ظاء','عين','غين','فاء','قاف','كاف','لام','ميم','نون','هاء','واو','ياء']

letters = json.loads(Path("assets/content/letters.json").read_text(encoding="utf-8"))["letters"]
assert len(letters) == 28

# 1) Whisper anchorlari.
from faster_whisper import WhisperModel  # noqa: E402
model = WhisperModel("small", device="cpu", compute_type="int8")
segs, _ = model.transcribe(str(SRC), language="ar", beam_size=5, word_timestamps=True,
                           initial_prompt="أسماء الحروف: " + " ".join(NOMLAR))
words = [(w.start, w.end, w.word.strip()) for s in segs for w in (s.words or [])]
assert [w[2] for w in words] == NOMLAR, [w[2] for w in words]

# 2) Energiya konverti (10 ms).
pcm = subprocess.run(["ffmpeg", "-v", "error", "-i", str(SRC), "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                     capture_output=True).stdout
x = struct.unpack(f"<{len(pcm)//2}h", pcm)
N = 160
rms = [math.sqrt(sum(v*v for v in x[i:i+N]) / N) for i in range(0, len(x) - N, N)]
peak = max(rms)
thr = peak * 10 ** (-32 / 20)

# 3) Energiya bo'laklari (−35 dB, 120 ms gacha uzilishga chidamli).
on = [r > thr for r in rms]
esegs = []
i = 0
while i < len(on):
    if on[i]:
        j = i
        while j < len(on) and (on[j] or any(on[j:j + 12])):
            j += 1
        if (j - i) * 0.01 >= 0.08:
            esegs.append([i * 0.01, j * 0.01])
        i = j
    else:
        i += 1

# 4) Har whisper so'ziga eng ko'p ustma-ust tushgan bo'lak. Ikki so'z bitta
#    bo'lakni olsa — bo'lak ikki so'z chegarasidagi eng jim nuqtadan bo'linadi.
def ustma(a, b):
    return max(0.0, min(a[1], b[1]) - max(a[0], b[0]))

tayin = []
for w0, w1, _ in words:
    best = max(esegs, key=lambda e: ustma(e, (w0, w1)))
    tayin.append(best if ustma(best, (w0, w1)) > 0 else None)
assert all(t is not None for t in tayin)
for k in range(len(words) - 1):
    if tayin[k] is tayin[k + 1]:
        e = tayin[k]
        lo = int(max(e[0], words[k][0] + 0.15) * 100); hi = int(min(e[1], words[k + 1][1] - 0.15) * 100)
        cut = min(range(lo, hi), key=lambda q: rms[q]) * 0.01
        tayin[k] = [e[0], cut]; tayin[k + 1] = [cut, e[1]]
        print(f"  bo'lindi: {words[k][2]}|{words[k+1][2]} @ {cut:.2f}")
for k in range(len(tayin) - 1):
    assert tayin[k][1] <= tayin[k + 1][0] + 1e-6, (words[k][2], tayin[k], tayin[k + 1])

OUT.mkdir(parents=True, exist_ok=True)
manifest = {}
for i, (L, (w0, w1, nom)) in enumerate(zip(letters, words)):
    s, e = tayin[i]
    assert 0.2 <= e - s <= 1.3, (nom, s, e)
    s = max(0.0, s - 0.04); e = e + 0.06
    dest = OUT / f"h{i:02d}.mp3"
    kes = (f"atrim=start={s:.3f}:end={e:.3f},asetpts=PTS-STARTPTS,"
           f"afade=t=in:d=0.015,afade=t=out:st={max(0, e-s-0.05):.3f}:d=0.05")
    # Balandlik: qisqa klipda loudnorm cho'qqini 0 dB ga urib yuboradi —
    # o'lchab, o'zimiz kuchaytiramiz: RMS ≈ −19 dB, cho'qqi ≤ −1.5 dB.
    o = subprocess.run(["ffmpeg", "-v", "info", "-i", str(SRC), "-af", kes + ",volumedetect",
                        "-f", "null", "-"], capture_output=True, text=True).stderr
    import re
    mean = float(re.search(r"mean_volume: (\S+)", o).group(1))
    peak_db = float(re.search(r"max_volume: (\S+)", o).group(1))
    gain = min(-19.0 - mean, -1.5 - peak_db)
    af = f"{kes},volume={gain:.2f}dB,apad=pad_dur=0.3"
    r = subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(SRC), "-af", af,
                        "-ac", "1", "-ar", "24000", "-b:a", "48k", str(dest)], capture_output=True)
    if r.returncode != 0:
        print("XATO", L["ar"], r.stderr.decode(errors="ignore")[:200]); continue
    manifest[L["name_ar"]] = dest.name
    print(L["ar"], L["name_ar"], nom, f"{s:.2f}-{e:.2f} ({e-s:.2f}s)")
MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8", newline="\n")
(OUT / "ATTRIBUTION.txt").write_text(
    "Harf nomlari ovozi: «Arabic alphabets.ogg», Atef1975 — Wikimedia Commons, CC BY-SA 4.0\n"
    "(https://commons.wikimedia.org/wiki/File:Arabic_alphabets.ogg, "
    "https://creativecommons.org/licenses/by-sa/4.0/).\n"
    "Bitta yozuv 28 harfga bo'lingan, balandligi normalizatsiya qilingan.\n",
    encoding="utf-8")
print("files:", len(manifest))
