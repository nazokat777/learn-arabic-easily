# -*- coding: utf-8 -*-
"""Harf NOMLARI — inson ovozi (Wikimedia Commons, CC BY-SA 4.0).

Manba: Ruaa GHAREEB ning «Wiki Arabic for all» to'plami (Wikiversity
«Learn Arabic (Language Of Quran)/Alphabets»): har harf uchun ikki yozuv
(«…audio.wav» va «…p/pron.wav»). Yozuvlar telefon mikrofonida, ba'zilari
qattiq kesilgan (clipping) — har harf uchun kamroq kesilgan/tozaroq
varianti tanlanadi (build/commons_tanlov.json, harf_baho.py), so'ng:
  adeclip (kesilgan cho'qqilarni tiklash) → afftdn (shovqin) →
  highpass 80 Hz → nutq chegarasida kesish → loudnorm -16 LUFS → 0.3 s jimlik.

Natija: assets/audio/harf/hNN.mp3 + harf_manifest.json (matn = name_ar).
VocabAudio ro'yxatida bu to'plam OXIRIDA — TTS «alifbo» nomlarini bosib
o'tadi. Attribution: assets/audio/harf/ATTRIBUTION.txt va Alifbo ekranida.

Tartib: build/commons/*.wav bo'lishi kerak (yuklab olish skripti
commons_scan/harf_baho — scratchpad; API: commons.wikimedia.org).
"""
import json, subprocess, sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
SRC = Path("build/commons")
TANLOV = Path("build/commons_tanlov.json")
OUT = Path("assets/audio/harf")
MANIFEST = Path("assets/audio/harf_manifest.json")

letters = json.loads(Path("assets/content/letters.json").read_text(encoding="utf-8"))["letters"]
tanlov = json.loads(TANLOV.read_text(encoding="utf-8"))
OUT.mkdir(parents=True, exist_ok=True)
manifest = {}
for i, L in enumerate(letters):
    t = tanlov[L["ar"]]
    src = SRC / f"{t['fayl']}.wav"
    dest = OUT / f"h{i:02d}.mp3"
    start = max(0.0, t["start"] - 0.06)
    end = t["end"] + 0.18
    af = (f"adeclip,afftdn=nf=-32,highpass=f=80,"
          f"atrim=start={start:.3f}:end={end:.3f},asetpts=PTS-STARTPTS,"
          f"afade=t=in:d=0.02,afade=t=out:st={end-start-0.06:.3f}:d=0.06,"
          f"loudnorm=I=-16:TP=-1.5:LRA=7,apad=pad_dur=0.3")
    r = subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(src), "-af", af,
                        "-ac", "1", "-ar", "24000", "-b:a", "48k", str(dest)], capture_output=True)
    if r.returncode != 0:
        print("XATO", L["ar"], r.stderr.decode(errors="ignore")[:200]); continue
    manifest[L["name_ar"]] = dest.name
    print(L["ar"], L["name_ar"], t["fayl"], f"{start:.2f}-{end:.2f}")
MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0), encoding="utf-8", newline="\n")
(OUT / "ATTRIBUTION.txt").write_text(
    "Harf nomlari ovozi: Ruaa GHAREEB, «Wiki Arabic for all» (Wikiversity: Learn Arabic (Language Of Quran)/Alphabets).\n"
    "Manba: Wikimedia Commons, litsenziya CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).\n"
    "Fayllar qayta ishlangan (declip, shovqin tozalash, kesish, balandlik normalizatsiyasi).\n",
    encoding="utf-8")
print("files:", len(manifest))
