# -*- coding: utf-8 -*-
"""Yolg'iz so'zni OXIRGI HARAKATI BILAN o'qitib, ovoz fayli yasaydi.

Muammo. TTS yolg'iz turgan arabcha so'zni «vaqf» shaklida o'qiydi - oxirgi
qisqa unlini tushiradi: «kataba» → «katab», «kitabun» → «kitab». Fe'l
oxiridagi harakatning tushib qolishi jiddiy xato, chunki o'quvchi so'zni
noto'g'ri yodlaydi. Jumla ichida esa o'sha so'z to'liq o'qiladi.

Yechim. So'zdan keyin «وَ» qo'shib yuboramiz - shunda so'z jumla oxirida
turmaydi va oxirgi harakati to'liq talaffuz qilinadi. Keyin «وَ» ni kesib
tashlaymiz.

Kesish nega bu safar xavfsiz. Avvalgi urinishlar JIMLIK bo'yicha kesardi va
har safar nutqning bir qismini yeb qo'yardi (damma eng jim tugagani uchun
birinchi bo'lib yo'qolardi). Bu yerda taxmin yo'q: edge-tts
`boundary="WordBoundary"` bilan har bir so'z qayerdan boshlanishini aniq
vaqt bilan aytadi. Biz «وَ» BOSHLANADIGAN nuqtadan kesamiz - so'zning o'zi,
oxirgi harakati va undan keyingi tabiiy tanaffus butunligicha qoladi.

Ko'p so'zli matn (jumla) uchun bu kerak emas: unda so'zlar allaqachon
o'zaro bog'lanib o'qiladi, oxirgi so'z esa tabiiy ravishda vaqfda tugaydi.
"""
import asyncio, re, subprocess
from pathlib import Path

import edge_tts

# So'zdan keyin qo'yiladigan bog'lovchi. «وَ» tanlandi: bir bo'g'inli,
# har qanday so'zdan keyin kelaveradi va so'zning oxirgi harakatiga
# ta'sir qilmaydi.
TAIL = "وَ"          # وَ

_SPACE = re.compile(r"\s")


def yolgiz_soz(text: str) -> bool:
    """Matn bitta so'zmi (ya'ni vaqf muammosi bormi)."""
    t = text.strip()
    return bool(t) and not _SPACE.search(t) and t[-1] not in ".؟!؛?:،,"


async def _stream(text: str, voice: str, rate: str, dest_raw: Path) -> float | None:
    """Ovozni yozadi; «وَ» boshlanadigan vaqtni qaytaradi (topilmasa None)."""
    comm = edge_tts.Communicate(f"{text} {TAIL}", voice, rate=rate,
                                boundary="WordBoundary")
    marks = []
    with open(dest_raw, "wb") as f:
        async for ch in comm.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])
            elif ch["type"] == "WordBoundary":
                marks.append(ch)
    # Oxirgi belgi «وَ» bo'lishi kerak. Bo'lmasa - kesmaymiz, chunki
    # noto'g'ri joydan kesish so'zni buzadi.
    if len(marks) >= 2 and marks[-1]["text"].strip() == TAIL:
        return marks[-1]["offset"] / 1e7
    return None


async def synth(text: str, dest: Path, voice: str, rate: str,
                trim_filter: str = "anull", retries: int = 4,
                attempt: int = 0) -> bool:
    """Bitta yozuvni ovozga aylantiradi.

    Yolg'iz so'z bo'lsa «وَ» qo'shib o'qitadi va o'sha joydan kesadi;
    aks holda matnni borligicha o'qitadi.
    """
    raw = dest.with_suffix(".raw.mp3")
    cut = None
    try:
        if yolgiz_soz(text):
            cut = await _stream(text, voice, rate, raw)
            if cut is None:
                # «وَ» ni ajratib bo'lmadi - qo'shimcha tovush qolib
                # ketmasin, so'zni yolg'iz holda qayta o'qitamiz.
                await edge_tts.Communicate(text, voice, rate=rate).save(str(raw))
        else:
            await edge_tts.Communicate(text, voice, rate=rate).save(str(raw))
    except Exception as e:
        if attempt < retries:
            await asyncio.sleep(1.5 * (attempt + 1))
            return await synth(text, dest, voice, rate, trim_filter, retries, attempt + 1)
        print(f"  !! {text[:40]}: {e}")
        return False

    cmd = ["ffmpeg", "-y", "-v", "error", "-i", str(raw)]
    af = trim_filter
    if cut:
        cmd += ["-t", f"{cut:.3f}"]
        # Kesilgan joyda «chirt» eshitilmasin: oxirgi 15 ms silliq so'nadi.
        # Bu nutqni olib tashlamaydi - kesuv allaqachon so'z tugagandan
        # keyingi tanaffusda turibdi.
        fade = max(0.0, cut - 0.015)
        af = f"afade=t=out:st={fade:.3f}:d=0.015" if af == "anull" else f"{af},afade=t=out:st={fade:.3f}:d=0.015"
    cmd += ["-af", af, "-ac", "1", "-ar", "24000", "-b:a", "32k", str(dest)]
    ok = subprocess.run(cmd, capture_output=True).returncode == 0
    raw.unlink(missing_ok=True)
    return ok
