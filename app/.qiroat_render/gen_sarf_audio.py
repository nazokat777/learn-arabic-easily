# -*- coding: utf-8 -*-
"""Sarf darslarining arabcha matnlari uchun ovoz kliplari.

Sarf bo'limi keyin qo'shilgan, shuning uchun uning shakllari (وَثَبَ،
يَثِبُ، مَوْثُوبٌ…) hech qaysi to'plamda yo'q edi — ilova ularni brauzer
TTS'iga topshirardi, u esa harakatlarni ko'pincha yutib yuboradi. Sarfda
harakat farqi mazmunning o'zi (فَعِلَ / فَعُلَ), shuning uchun har bir
shakl alohida klip bo'lishi shart.

Alohida to'plam (`sarf/`, `sarf_manifest.json`): `extra` to'plami
ro'yxat tartibiga bog'liq nomlaydi (e000…), unga qo'shilsa eski
nomlar surilib ketardi.

Nimalar olinadi: «misol» bloklarining arabchasi (butun va so'zma-so'z),
matn ichidagi arabcha iboralar (ko'p so'zli ham — لَمْ يَثِبْ bitta
element), ro'yxat bandlari va jadval kataklaridagi arabcha. Yolg'iz so'z
`synth_word` orqali — oxirgi harakati tushib qolmasin.

Ishga tushirish (app/ dan):  python .qiroat_render/gen_sarf_audio.py
"""
import asyncio, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gen_sentence_audio import FFMPEG_TRIM, VOICE, RATE, RETRIES, WORKERS  # noqa: E402
from synth_word import synth as word_synth  # noqa: E402

OUT_DIR = Path("assets/audio/sarf")
MANIFEST = Path("assets/audio/sarf_manifest.json")
COVERED = ["vocab", "sentence", "word", "alifbo", "extra"]
LETTER = re.compile(r"[ء-يٱ-ۓ]")
# Arabcha ibora: harf/harakat va ular orasidagi bo'shliqlar. Tinish belgisi
# (،) chegara — paradigmadagi 14 shakl alohida-alohida olinadi.
# Faqat harf, harakat, tatvil — tinish belgilari (،؛؟) arab blokida bo'lsa
# ham ibora ichiga kirmaydi.
_H = "ء-يً-ْٰـٱ-ۓ"
PHRASE = re.compile(rf"[{_H}]+(?:[  ]+[{_H}]+)*")
WORD = re.compile(rf"[{_H}]+")
# Yolg'iz harakat belgisi yoki nuqtali doira (◌ِ) — so'z emas.
def _soz(t: str) -> bool:
    return bool(LETTER.search(t)) and "◌" not in t


def collect() -> list[str]:
    covered = set()
    for m in COVERED:
        p = Path(f"assets/audio/{m}_manifest.json")
        if p.exists():
            covered |= set(json.loads(p.read_text(encoding="utf-8")))
    out: dict[str, bool] = {}

    def want(t: str) -> None:
        t = t.strip().strip("«»()[]\"'.,:;!؟،")
        if t and t not in covered and _soz(t):
            out.setdefault(t, True)

    def matndan(uz: str) -> None:
        for ph in PHRASE.findall(uz):
            ph = ph.strip()
            if not _soz(ph):
                continue
            want(ph)
            if " " in ph:
                for w in WORD.findall(ph):
                    want(w)

    data = json.loads(Path("assets/content/sarf_lessons.json").read_text(encoding="utf-8"))
    for L in data["lessons"]:
        matndan(L.get("titleAr", ""))
        for b in L.get("blocks", []):
            matndan(b.get("ar", ""))
            matndan(b.get("uz", ""))
            matndan(b.get("intro", ""))
            for band in b.get("items", []):
                matndan(band)
            for q in b.get("qatorlar", []):
                for c in q.get("kataklar", []):
                    matndan(c)
    return list(out)


async def synth(text: str, dest: Path) -> bool:
    return await word_synth(text, dest, VOICE, RATE, FFMPEG_TRIM, RETRIES, 0)


async def main() -> None:
    texts = collect()
    if "--count" in sys.argv:
        print(f"sarf matnlari: {len(texts)}")
        for t in texts[:40]:
            print("  ", t)
        return
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # Nomlar matnning o'ziga bog'lanadi (mavjud manifestdan olinadi), shunda
    # keyingi ishga tushirishda eski kliplar qayta yasalmaydi.
    manifest: dict[str, str] = {}
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    band = {int(n[1:-4]) for n in manifest.values()} or {-1}
    keyingi = max(band) + 1
    for t in texts:
        if t not in manifest:
            manifest[t] = f"s{keyingi:04d}.mp3"
            keyingi += 1
    todo = [(t, OUT_DIR / n) for t, n in manifest.items()
            if t in set(texts) and not (OUT_DIR / n).exists()]
    print(f"sarf matnlari: {len(texts)}   yasaladi: {len(todo)}", flush=True)

    q: asyncio.Queue = asyncio.Queue()
    for item in todo:
        q.put_nowait(item)
    yasaldi = 0

    async def worker():
        nonlocal yasaldi
        while True:
            try:
                text, dest = q.get_nowait()
            except asyncio.QueueEmpty:
                return
            if await synth(text, dest):
                yasaldi += 1
                if yasaldi % 100 == 0:
                    print(f"  {yasaldi}/{len(todo)}", flush=True)

    await asyncio.gather(*[worker() for _ in range(WORKERS)])
    manifest = {t: n for t, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1024/1024:.1f} MB")


if __name__ == "__main__":
    asyncio.run(main())
