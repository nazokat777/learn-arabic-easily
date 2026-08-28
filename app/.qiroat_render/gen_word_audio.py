# -*- coding: utf-8 -*-
"""Generate an MP3 for every individual word a learner can tap in a reading.

Third and last audio set, after gen_vocab_audio.py (lug'at) and
gen_sentence_audio.py (jumlalar). SentenceText makes every word in a passage
tappable, but only ~7% of those words happen to be vocabulary entries — the rest
fell back to device TTS, which is silent on a phone with no Arabic voice.

Words are tokenised the way the APP tokenises them (lib/arabic.dart tokenize):
a run of Arabic-range characters is one word, everything else is a separator.
The app looks a word up by its exact text, so the two must agree.

Already-covered words (vocab or single-word sentences) are skipped, so this
generates ~11 400 clips, ~42 MB at 32 kbps mono.

Resumable — existing files are skipped.
"""
import asyncio, json, re, subprocess, sys
from pathlib import Path

import edge_tts

from synth_word import synth as word_synth

sys.path.insert(0, str(Path(__file__).parent))
# Diqqat: bu import stdout'ni UTF-8 ga o'raydi. Shu yerda ikkinchi marta
# o'rasak, birinchisi yopilib «I/O operation on closed file» chiqadi.
from gen_sentence_audio import split_sentences, FFMPEG_TRIM, VOICE, RATE, RETRIES, WORKERS

LESSONS = Path("assets/content/qiroat_lessons.json")
OUT_DIR = Path("assets/audio/words")
MANIFEST = Path("assets/audio/word_manifest.json")
COVERED = [Path("assets/audio/vocab_manifest.json"),
           Path("assets/audio/sentence_manifest.json")]

# tokenize() dagi «so'z belgisi» diapazoni
ARABIC = r"[؀-ۿݐ-ݿ]"
SPLIT = re.compile(f"({ARABIC}+)")


def collect() -> list[str]:
    data = json.loads(LESSONS.read_text(encoding="utf-8"))
    covered = set()
    for p in COVERED:
        if p.exists():
            covered |= set(json.loads(p.read_text(encoding="utf-8")))
    seen = {}
    for lesson in data["lessons"]:
        for s in split_sentences(lesson["reading"]):
            for tok in SPLIT.findall(s):
                if tok not in covered:
                    seen.setdefault(tok, True)
    return list(seen)


def _letter_names() -> dict:
    p = Path("assets/content/letters.json")
    return {L["ar"]: L["name_ar"]
            for L in json.loads(p.read_text(encoding="utf-8"))["letters"]}


LETTER_NAME = _letter_names()


def spoken(text: str) -> str:
    """Sintezga beriladigan matn.

    Yolg'iz harfdan edge-tts jimlik chiqaradi, shuning uchun uning o'rniga
    harf NOMI o'qiladi — she'r muallifining bosh harflari («أ. ظ.») arabchada
    aynan shunday o'qiladi. Bu qoida shu yerda turishi kerak: avval bitta
    faylni qo'lda tuzatgandim va keyingi qayta yasashda tuzatish yo'qoldi.
    """
    return LETTER_NAME.get(text, text)


async def synth(text: str, dest: Path, attempt: int = 0) -> bool:
    """Yolg'iz so'z oxirgi harakati bilan o'qilsin - synth_word ga topshiramiz."""
    return await word_synth(spoken(text), dest, VOICE, RATE, FFMPEG_TRIM, RETRIES, attempt)


async def main() -> None:
    words = collect()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}

    todo = []
    for i, w in enumerate(words):
        name = manifest.get(w) or f"w{i:05d}.mp3"
        manifest[w] = name
        if not (OUT_DIR / name).exists():
            todo.append((w, OUT_DIR / name))

    print(f"words needing audio: {len(words)}   to generate: {len(todo)}", flush=True)
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
                if done[0] % 250 == 0:
                    print(f"  {done[0]}/{len(todo)}", flush=True)

    q = asyncio.Queue()
    for item in todo:
        q.put_nowait(item)
    await asyncio.gather(*[worker(q) for _ in range(WORKERS)])

    manifest = {w: n for w, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1048576:.1f} MB")


if __name__ == "__main__":
    asyncio.run(main())
