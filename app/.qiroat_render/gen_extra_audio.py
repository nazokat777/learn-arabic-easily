# -*- coding: utf-8 -*-
"""Fill audio gaps for content outside the qiroat books.

Mashqlar (vocabulary.json, word_game) uses its own word list, so a handful of
its words never appeared in the qiroat books and had no clip. Those words are
generated here into the same alifbo/extra set so every exercise can speak.

Run after the other generators; it only makes what is still missing.
"""
import asyncio, json, re, subprocess, sys
from pathlib import Path

import edge_tts

sys.path.insert(0, str(Path(__file__).parent))
# Bu import stdout'ni UTF-8 ga o'raydi — ikkinchi marta o'ramang.
from gen_sentence_audio import FFMPEG_TRIM, VOICE, RATE, RETRIES, WORKERS

OUT_DIR = Path("assets/audio/extra")
MANIFEST = Path("assets/audio/extra_manifest.json")
COVERED = ["vocab", "sentence", "word", "alifbo"]
ARABIC = re.compile(r"[؀-ۿݐ-ݿ]")


def head(s: str) -> str:
    return re.split(r"[،,]", s)[0].strip()


def collect() -> list[str]:
    covered = set()
    for m in COVERED:
        p = Path(f"assets/audio/{m}_manifest.json")
        if p.exists():
            covered |= set(json.loads(p.read_text(encoding="utf-8")))
    out = {}

    def want(t: str) -> None:
        t = t.strip()
        if t and t not in covered and ARABIC.search(t):
            out.setdefault(t, True)

    for w in json.loads(Path("assets/content/vocabulary.json").read_text(encoding="utf-8"))["words"]:
        want(head(w["ar"]))

    # Grammatika jadvallarining arabcha kataklari - ular lug'atga kirmaydi,
    # shuning uchun boshqa hech qaysi to'plamda uchramaydi.
    for L in json.loads(Path("assets/content/qiroat_lessons.json").read_text(encoding="utf-8"))["lessons"]:
        for t in L.get("tables", []):
            for row in t["rows"]:
                for cell in row["cells"]:
                    want(cell)
    return list(out)


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
    manifest = {t: f"e{i:03d}.mp3" for i, t in enumerate(texts)}
    todo = [(t, OUT_DIR / n) for t, n in manifest.items() if not (OUT_DIR / n).exists()]
    print(f"qo'shimcha so'z: {len(texts)}   yasaladi: {len(todo)}", flush=True)

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
