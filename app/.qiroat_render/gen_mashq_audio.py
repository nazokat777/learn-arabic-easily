# -*- coding: utf-8 -*-
"""Mashq/kartochka/gap/tasnif rejimlari o'qib beradigan, lekin hech qaysi
to'plamda klipi yo'q matnlar uchun ovoz — «mashq/» to'plami.

Ro'yxatni ilova o'zi beradi: `flutter test test/ovoz_qamrov_test.dart`
`build/ovoz_yetishmaydi.txt` ga (manba<TAB>matn) yozadi — ya'ni aynan
MashqBank/tasnif/gap tuzish/harf nomi ishlatadigan satrlar, hech qanday
qo'lda qidirish yo'q. Bu skript o'sha matnlarni ar-SA-HamedNeural bilan
yasaydi. Nomlar matnga bog'lanadi (m0000…), qayta ishga tushirilsa faqat
yangilari yasaladi.

Nega alohida to'plam: `extra` ro'yxat tartibiga bog'liq nomlaydi, `sarf`
faqat Sarf darslaridan yig'adi; bu esa umumiy «ilova o'qiydigan hamma
narsa» uchun qoldiq to'plam.

Tartib (app/ dan):
  flutter test test/ovoz_qamrov_test.dart   # ro'yxat (yiqilsa — bo'sh emas)
  python .qiroat_render/gen_mashq_audio.py
  flutter test test/ovoz_qamrov_test.dart   # endi o'tishi kerak
  python .qiroat_render/audit_audio_silence.py
"""
import asyncio, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gen_sentence_audio import FFMPEG_TRIM, VOICE, RATE, RETRIES, WORKERS  # noqa: E402
from synth_word import synth as word_synth  # noqa: E402

OUT_DIR = Path("assets/audio/mashq")
MANIFEST = Path("assets/audio/mashq_manifest.json")
ROYXAT = Path("build/ovoz_yetishmaydi.txt")
COVERED = ["vocab", "sentence", "word", "alifbo", "extra", "sarf"]
LETTER = re.compile(r"[ء-يٱ-ۓ]")
LOTIN_QAVS = re.compile(r"\s*\([^)]*[A-Za-z][^)]*\)")


def collect() -> list[str]:
    covered = set()
    for m in COVERED:
        p = Path(f"assets/audio/{m}_manifest.json")
        if p.exists():
            covered |= set(json.loads(p.read_text(encoding="utf-8")))
    if not ROYXAT.exists():
        print("build/ovoz_yetishmaydi.txt yo'q — avval flutter test test/ovoz_qamrov_test.dart")
        return []
    out: dict[str, bool] = {}
    for line in ROYXAT.read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        t = line.split("\t", 1)[1].strip()
        # Ilova ham lotin qavsni o'qimaydi (Tts.speak) — klip ham shunday.
        t = LOTIN_QAVS.sub("", t).strip()
        t = re.sub(r"\s*=\s*", "، ", t)
        if t and t not in covered and LETTER.search(t):
            out.setdefault(t, True)
    return list(out)


async def synth(text: str, dest: Path) -> bool:
    return await word_synth(text, dest, VOICE, RATE, FFMPEG_TRIM, RETRIES, 0)


async def main() -> None:
    texts = collect()
    if "--count" in sys.argv:
        print(f"mashq matnlari: {len(texts)}")
        for t in texts[:60]:
            print("  ", t)
        return
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, str] = {}
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    band = {int(n[1:-4]) for n in manifest.values()} or {-1}
    keyingi = max(band) + 1
    for t in texts:
        if t not in manifest:
            manifest[t] = f"m{keyingi:04d}.mp3"
            keyingi += 1
    todo = [(t, OUT_DIR / n) for t, n in manifest.items()
            if not (OUT_DIR / n).exists()]
    print(f"mashq matnlari: {len(texts)}   yasaladi: {len(todo)}", flush=True)

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
                if yasaldi % 50 == 0:
                    print(f"  {yasaldi}/{len(todo)}", flush=True)

    await asyncio.gather(*[worker() for _ in range(WORKERS)])
    manifest = {t: n for t, n in manifest.items() if (OUT_DIR / n).exists()}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=0),
                        encoding="utf-8", newline="\n")
    total = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3"))
    print(f"\nfiles: {len(manifest)}   size: {total/1024/1024:.1f} MB")


if __name__ == "__main__":
    asyncio.run(main())
