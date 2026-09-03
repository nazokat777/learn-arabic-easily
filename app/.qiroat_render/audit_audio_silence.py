# -*- coding: utf-8 -*-
"""Find generated clips that are silent or nearly silent.

Why this exists: a clip's DURATION says nothing about whether it can be heard.
The lone letter «ظ» produced 1.78 s of near-silence — edge-tts simply refuses to
voice a bare Arabic letter — and a duration check called it fixed. Only peak
volume catches that class of failure, so measure loudness, not length.

Threshold: -30 dBFS peak. Real speech in this set peaks around -6 dB.
"""
import glob, json, os, re, subprocess, sys, io
from concurrent.futures import ThreadPoolExecutor

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Diqqat: nahv darslarining kliplari "extra" papkasida — u yerni tashlab
# ketsangiz, audit 0 jim klip deb yolg'on "toza" natija beradi.
SETS = (("vocab", "vocab"), ("sentences", "sentence"), ("words", "word"),
        ("extra", "extra"), ("alifbo", "alifbo"))
RX = re.compile(r"max_volume:\s*(-?[\d.]+) dB")
QUIET_DB = -30.0


def peak(path):
    # Diqqat: «-v error» qo'ymang — volumedetect xulosasi info darajasida
    # chiqadi, o'chirilsa har bir fayl 0 dB deb o'qilib, audit soxta «toza»
    # natija beradi.
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    m = RX.search(r.stderr)
    if not m:
        raise RuntimeError(f"volumedetect o'qilmadi: {path}")
    return path, float(m.group(1))


def main():
    text_of = {}
    files = []
    for folder, man in SETS:
        p = f"assets/audio/{man}_manifest.json"
        if not os.path.exists(p):
            continue
        for word, name in json.load(open(p, encoding="utf-8")).items():
            text_of[(folder, name)] = word
        files += glob.glob(f"assets/audio/{folder}/*.mp3")

    print(f"tekshirilmoqda: {len(files)} fayl", flush=True)
    quiet = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        for i, (path, db) in enumerate(ex.map(peak, files), 1):
            if db < QUIET_DB:
                folder = os.path.basename(os.path.dirname(path))
                quiet.append((path, db, text_of.get((folder, os.path.basename(path)))))
            if i % 4000 == 0:
                print(f"  {i}/{len(files)}", flush=True)

    print(f"\njim kliplar ({QUIET_DB} dB dan past): {len(quiet)}")
    for path, db, word in sorted(quiet, key=lambda x: x[1]):
        print(f"  {os.path.basename(path):14} {db:8.1f} dB  {word!r}")
    return 1 if quiet else 0


if __name__ == "__main__":
    sys.exit(main())
