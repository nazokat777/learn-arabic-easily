# -*- coding: utf-8 -*-
"""Generate an MP3 for every sentence of every reading passage.

Companion to gen_vocab_audio.py. Same reason: the learner's phone has no Arabic
TTS voice, so anything that must be heard has to ship as a file.

Sentences are split the way the APP splits them (lib/arabic.dart splitSentences):
line by line first — so a poem's bayt stays whole — then on . ؟ ! ؛ within a line.
Keeping the two in step matters: the app looks a sentence up by its exact text, so
a different split would miss every file.

~3200 sentences, ~4.6 hours of speech, ~66 MB at 32 kbps mono. Flutter web fetches
one file per tap, so the download stays small for the learner.

Resumable — existing files are skipped.
"""
import asyncio, json, re, subprocess, sys, io
from pathlib import Path

# Faqat bir marta o'raymiz: ikkita modul ham o'rasa, birinchi o'rovchi
# yig'ishtirilganda buferni yopadi va keyingi print «I/O operation on
# closed file» bilan yiqiladi.
if (sys.stdout.encoding or "").lower() not in ("utf-8", "utf8"):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import edge_tts

LESSONS = Path("assets/content/qiroat_lessons.json")
OUT_DIR = Path("assets/audio/sentences")
MANIFEST = Path("assets/audio/sentence_manifest.json")
VOICE = "ar-SA-HamedNeural"
RATE = "-10%"
WORKERS = 5
RETRIES = 4
TERM = ".؟!؛?"      # splitSentences ASCII '?' ni ham ajratuvchi deb biladi
RUN_ON = ".؟!؛"     # ketma-ket ajratuvchilar bir jumlaga qo'shiladi ('?' dan tashqari)

# HECH NARSA KESILMAYDI.
#
# Uch marta urinib ko'rildi va har safar nutqning bir qismi yo'qoldi:
# avval so'z oxiridagi qisqa unli (damma «u» eng jim tugagani uchun eng
# ko'p zarar ko'rdi), keyin bosh tomondagi kesuv so'zning birinchi harfini
# yeb qo'ydi - «أَخَذَ» tanib bo'lmas holga kelgan edi. O'lchov: kesuv har
# bir so'zdan ~0.2 s olib tashlar edi.
#
# Endi ffmpeg faqat formatni o'zgartiradi (anull - o'tkazuvchi filtr).
# Klip boshida ~0.2 s, oxirida ~0.7 s jimlik qoladi; buning evaziga
# birorta harf ham, harakat ham yo'qolmaydi.
FFMPEG_TRIM = "anull"


def split_sentences(reading: str) -> list[str]:
    """Mirror of splitSentences() in lib/arabic.dart."""
    out = []
    for line in reading.split("\n"):
        line = line.strip()
        if not line:
            continue
        buf = ""
        i = 0
        while i < len(line):
            buf += line[i]
            if line[i] in TERM:
                while i + 1 < len(line) and line[i + 1] in RUN_ON:
                    i += 1
                    buf += line[i]
                s = buf.strip()
                if s:
                    out.append(s)
                buf = ""
            i += 1
        s = buf.strip()
        if s:
            out.append(s)
    return out


def collect() -> list[str]:
    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    seen = {}
    for lesson in data["lessons"]:
        for s in split_sentences(lesson["reading"]):
            seen.setdefault(s, True)
    return list(seen)


async def synth(text: str, dest: Path, attempt: int = 0) -> bool:
    raw = dest.with_suffix(".raw.mp3")
    try:
        await edge_tts.Communicate(text, VOICE, rate=RATE).save(str(raw))
    except Exception as e:
        if attempt < RETRIES:
            await asyncio.sleep(1.5 * (attempt + 1))
            return await synth(text, dest, attempt + 1)
        print(f"  !! {text[:40]}…: {e}")
        return False
    ok = subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", FFMPEG_TRIM,
         "-ac", "1", "-ar", "24000", "-b:a", "32k", str(dest)],
        capture_output=True,
    ).returncode == 0
    raw.unlink(missing_ok=True)
    return ok


async def main() -> None:
    sentences = collect()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}

    todo = []
    for i, s in enumerate(sentences):
        name = manifest.get(s) or f"s{i:04d}.mp3"
        manifest[s] = name
        if not (OUT_DIR / name).exists():
            todo.append((s, OUT_DIR / name))

    print(f"unique sentences: {len(sentences)}   to generate: {len(todo)}", flush=True)
    done = [0]
    lock = asyncio.Lock()

    async def worker(q):
        while True:
            try:
                text, dest = q.get_nowait()
            except asyncio.QueueEmpty:
                return
            await synth(text, dest)
            async with lock:
                done[0] += 1
                if done[0] % 100 == 0:
                    print(f"  {done[0]}/{len(todo)}", flush=True)

    q = asyncio.Queue()
    for item in todo:
        q.put_nowait(item)
    await asyncio.gather(*[worker(q) for _ in range(WORKERS)])

    manifest = {s: n for s, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1048576:.1f} MB")


if __name__ == "__main__":
    asyncio.run(main())
