# -*- coding: utf-8 -*-
"""XTTS bilan sinov namunalari - foydalanuvchi eshitib baho beradi."""
import sys, io, subprocess
from pathlib import Path
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import torch
from TTS.api import TTS

OUT = Path(".qiroat_render/_xtts_namuna"); OUT.mkdir(exist_ok=True)
SPEAKER = "assets/audio/vocab/0001.mp3"
WORDS = {"kitab":"كِتَابٌ","sabbura":"سَبُّورَةٌ","mihbara":"مِحْبَرَةٌ",
         "axaza":"أَخَذَ","hati":"هَاتِ","qalam":"قَلَمٌ"}
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(
    "cuda" if torch.cuda.is_available() else "cpu")
import time
t0 = time.time()
for name, w in WORDS.items():
    wav = OUT/f"{name}.wav"
    tts.tts_to_file(text=w, speaker_wav=SPEAKER, language="ar", file_path=str(wav))
    subprocess.run(["ffmpeg","-y","-v","error","-i",str(wav),"-ac","1","-ar","24000",
                    "-b:a","48k",str(OUT/f"{name}.mp3")], check=True)
    wav.unlink()
print(f"{len(WORDS)} ta klip, {time.time()-t0:.0f} soniya "
      f"({(time.time()-t0)/len(WORDS):.1f} s/klip)")
