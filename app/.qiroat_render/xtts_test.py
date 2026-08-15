# -*- coding: utf-8 -*-
"""XTTS-v2 arabcha i'robni (tanvinni) o'qiydimi - sinov.

NATIJA: YO'Q. Uzunlik o'zgaradi, lekin quloq bilan tekshirilganda «kitobun»
emas, «kitob» deb o'qiydi - edge-tts bilan bir xil. Sabab: modellar yakka
so'zni tabiiy vaqf (pauza) shaklida talaffuz qiladi.

Sinov usuli: bir xil so'zning tanvinli va tanvinsiz shakli. Agar model
tashkilni o'qisa, tanvinli variant sezilarli uzunroq bo'ladi (edge-tts da
farq aynan 0.00 s edi - u i'robni umuman aytmaydi).

Ovoz namunasi sifatida o'zimizdagi klip ishlatiladi (XTTS ovozni namunadan
klonlaydi), shunda ilovadagi ovoz o'zgarmaydi.
"""
import sys, io, wave, contextlib
from pathlib import Path
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import torch
from TTS.api import TTS

OUT = Path(".qiroat_render/_xtts"); OUT.mkdir(exist_ok=True)
SPEAKER = "assets/audio/vocab/0001.mp3"   # bizning hozirgi ovozimiz

def dur(p):
    with contextlib.closing(wave.open(str(p))) as w:
        return w.getnframes() / w.getframerate()

tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(
    "cuda" if torch.cuda.is_available() else "cpu")

pairs = [("كِتَاب", "كِتَابٌ"), ("قَلَم", "قَلَمٌ"), ("مِحْبَرَة", "مِحْبَرَةٌ")]
for i, (bare, full) in enumerate(pairs):
    for tag, text in (("bare", bare), ("full", full)):
        p = OUT / f"{i}_{tag}.wav"
        tts.tts_to_file(text=text, speaker_wav=SPEAKER, language="ar", file_path=str(p))
    print(f"{full}: tanvinsiz={dur(OUT/f'{i}_bare.wav'):.2f}s  "
          f"tanvinli={dur(OUT/f'{i}_full.wav'):.2f}s", flush=True)
