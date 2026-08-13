# -*- coding: utf-8 -*-
"""Generate an MP3 for every vocabulary head-word, so the app can speak without
depending on a TTS voice being installed on the phone.

Why files at all: the user's phone has no Arabic TTS voice, and Android very
often ships without one. Device TTS stays as a fallback, but bundled audio makes
the vocabulary work everywhere.

Voice: ar-SA-HamedNeural (Microsoft neural, Saudi male) at -10% rate - clear and
appropriate for a Qur'an-reading primer.

Each clip is post-processed with ffmpeg: leading/trailing silence trimmed (edge-tts
pads ~1 s, which makes taps feel laggy) and re-encoded to 32 kbps mono 24 kHz.
That takes a word from ~12 KB / 1.9 s to ~3.7 KB / 0.8 s, so the whole set is
about 11 MB instead of 37 MB. Flutter web fetches assets on demand, so a learner
only downloads the words they actually play.

Only the HEAD form is spoken: vocab entries like «غَلِطَ، يَغْلَطُ، اِغْلَطْ، غَلَطٌ»
would otherwise read all four forms in one breath.

Resumable - already-generated files are skipped, so it can be re-run safely.
"""
import asyncio, json, re, subprocess, sys, io, os
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import edge_tts

LESSONS = Path("assets/content/qiroat_lessons.json")
OUT_DIR = Path("assets/audio/vocab")
MANIFEST = Path("assets/audio/vocab_manifest.json")
VOICE = "ar-SA-HamedNeural"
RATE = "-10%"
WORKERS = 5          # polite concurrency; the endpoint throttles above this
RETRIES = 4

FFMPEG_TRIM = (
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
    "areverse"
)


def head_of(ar: str) -> str:
    """First form only - verb entries list all four separated by ، or ,."""
    return re.split(r"[،,]", ar)[0].strip()


def collect_words() -> list[str]:
    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    seen = {}
    for lesson in data["lessons"]:
        for w in lesson["vocab"]:
            h = head_of(w["ar"])
            if h and h not in seen:
                seen[h] = True
    return list(seen)


async def synth(word: str, dest: Path, attempt: int = 0) -> bool:
    raw = dest.with_suffix(".raw.mp3")
    try:
        await edge_tts.Communicate(word, VOICE, rate=RATE).save(str(raw))
    except Exception as e:
        if attempt < RETRIES:
            await asyncio.sleep(1.5 * (attempt + 1))
            return await synth(word, dest, attempt + 1)
        print(f"  !! {word}: {e}")
        return False
    ok = subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", FFMPEG_TRIM,
         "-ac", "1", "-ar", "24000", "-b:a", "32k", str(dest)],
        capture_output=True,
    ).returncode == 0
    raw.unlink(missing_ok=True)
    if not ok:
        print(f"  !! ffmpeg failed: {word}")
    return ok


async def main() -> None:
    words = collect_words()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}

    todo = []
    for i, w in enumerate(words):
        name = manifest.get(w) or f"{i:04d}.mp3"
        manifest[w] = name
        if not (OUT_DIR / name).exists():
            todo.append((w, OUT_DIR / name))

    print(f"unique head-words: {len(words)}   to generate: {len(todo)}")
    done = [0]
    lock = asyncio.Lock()

    async def worker(queue):
        while True:
            try:
                word, dest = queue.get_nowait()
            except asyncio.QueueEmpty:
                return
            await synth(word, dest)
            async with lock:
                done[0] += 1
                if done[0] % 100 == 0:
                    print(f"  {done[0]}/{len(todo)}", flush=True)

    q = asyncio.Queue()
    for item in todo:
        q.put_nowait(item)
    await asyncio.gather(*[worker(q) for _ in range(WORKERS)])

    # keep only words that really have a file, so the app never asks for a 404
    manifest = {w: n for w, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1048576:.1f} MB")


if __name__ == "__main__":
    asyncio.run(main())
