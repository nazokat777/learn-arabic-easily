# -*- coding: utf-8 -*-
"""Generate audio for the Alifbo module: letter names, syllables, harakat.

The alphabet module teaches 28 letters and their махраж — and had no sound at
all, which is the one place a learner most needs to hear something.

Three kinds of clip:
  1. letter name      — أَلِف، بَاء …            (letters.json name_ar)
  2. syllable         — بَ  بِ  بُ                 (letter + fatha/kasra/damma)
  3. harakat name and its example — فَتْحَة، بَ    (harakat.json)

A BARE letter is never synthesised: edge-tts returns silence for it (that is how
the «ظ» clip in the reading text ended up inaudible). The name and the syllable
are what a teacher says anyway.

Small set (~130 clips, well under 1 MB), so it regenerates from scratch quickly.
"""
import asyncio, json, subprocess, sys
from pathlib import Path

import edge_tts

sys.path.insert(0, str(Path(__file__).parent))
# Bu import stdout'ni UTF-8 ga o'raydi — ikkinchi marta o'ramang.
from gen_sentence_audio import FFMPEG_TRIM, VOICE, RATE, RETRIES, WORKERS

OUT_DIR = Path("assets/audio/alifbo")
MANIFEST = Path("assets/audio/alifbo_manifest.json")
FATHA, DAMMA, KASRA = "َ", "ُ", "ِ"


def collect() -> list[str]:
    letters = json.loads(Path("assets/content/letters.json").read_text(encoding="utf-8"))["letters"]
    harakat = json.loads(Path("assets/content/harakat.json").read_text(encoding="utf-8"))["harakat"]
    texts = {}
    for L in letters:
        texts[L["name_ar"]] = True
        for sign in (FATHA, KASRA, DAMMA):
            texts[L["ar"] + sign] = True
    for h in harakat:
        texts[h["name_ar"]] = True
        texts[h["example_ar"]] = True
    return list(texts)


async def synth(text: str, dest: Path, attempt: int = 0) -> bool:
    raw = dest.with_suffix(".raw.mp3")
    try:
        await edge_tts.Communicate(text, VOICE, rate=RATE).save(str(raw))
    except Exception as e:
        if attempt < RETRIES:
            await asyncio.sleep(1.5 * (attempt + 1))
            return await synth(text, dest, attempt + 1)
        print(f"  !! {text}: {e}", flush=True)
        return False
    ok = subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", FFMPEG_TRIM,
         "-ac", "1", "-ar", "24000", "-b:a", "32k", str(dest)],
        capture_output=True,
    ).returncode == 0
    raw.unlink(missing_ok=True)
    return ok


async def main() -> None:
    texts = collect()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {t: f"a{i:03d}.mp3" for i, t in enumerate(texts)}

    todo = [(t, OUT_DIR / n) for t, n in manifest.items() if not (OUT_DIR / n).exists()]
    print(f"alifbo yozuvlari: {len(texts)}   yasaladi: {len(todo)}", flush=True)

    q = asyncio.Queue()
    for item in todo:
        q.put_nowait(item)

    async def worker():
        while True:
            try:
                text, dest = q.get_nowait()
            except asyncio.QueueEmpty:
                return
            await synth(text, dest)

    await asyncio.gather(*[worker() for _ in range(WORKERS)])

    manifest = {t: n for t, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1024:.0f} KB")


if __name__ == "__main__":
    asyncio.run(main())
