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
import asyncio, json, re, subprocess
from pathlib import Path

import edge_tts


def _letter_names() -> dict:
    """Harf -> uning arabcha nomi (أ -> أَلِف)."""
    p = Path("assets/content/letters.json")
    if not p.exists():
        return {}
    return {L["ar"]: L["name_ar"]
            for L in json.loads(p.read_text(encoding="utf-8"))["letters"]}


LETTER_NAME = _letter_names()
# Hamzali shakllar letters.json da alohida yozilmagan, lekin yolg'iz kelganda
# ular ham «أَلِف» deb o'qiladi.
for _alt in ("أ", "إ", "آ", "ء"):
    LETTER_NAME.setdefault(_alt, LETTER_NAME.get("ا", ""))
LETTER_NAME = {k: v for k, v in LETTER_NAME.items() if v}

# So'zdan keyin qo'yiladigan bog'lovchi. «وَ» tanlandi: bir bo'g'inli,
# har qanday so'zdan keyin kelaveradi va so'zning oxirgi harakatiga
# ta'sir qilmaydi.
TAIL = "وَ"          # وَ

_SPACE = re.compile(r"\s")

# Jumla oxiridagi tinish belgilari.
TERM = ".؟!؛?:،,…"


def tail_kerakmi(text: str) -> bool:
    """Bu matnning oxirgi so'zi vaqf shaklida o'qiladimi.

    Ha - deyarli har doim: yolg'iz so'z ham, butun jumla ham. Farqi shundaki,
    jumlada avval oxirgi tinish belgisini olib tashlaymiz, aks holda «وَ»
    nuqtadan keyin qoladi va oxirgi so'z baribir vaqfda o'qiladi.
    """
    return bool(matn_ozagi(text))


def matn_ozagi(text: str) -> str:
    """Sintezga beriladigan matn: oxiridagi tinish belgilarisiz.

    Yolg'iz harf («أ.» kabi bosh harflar) qolsa, uning o'rniga harf NOMI
    o'qiladi: edge-tts yalang'och harfdan jimlik chiqaradi, arabchada esa
    bunday bosh harf aynan nomi bilan o'qiladi.
    """
    t = text.strip().rstrip(TERM).strip()
    # Qavs kabi belgilar ham qolib ketmasin.
    core = t.strip("()[]«»\"'‘’ ")
    return LETTER_NAME.get(core, t)


async def _stream(text: str, voice: str, rate: str, dest_raw: Path) -> float | None:
    """Ovozni yozadi; qayerdan kesish kerakligini (soniya) qaytaradi.

    Kesuv nuqtasi ikki o'lchovning KATTAsi:
      * «وَ» boshlanadigan vaqt;
      * oxirgi haqiqiy so'zning tugash vaqti + 30 ms zaxira.
    Ikkinchisi kerak: ba'zan «وَ» ning boshlanishi so'zning oxirgi unlisi
    bilan ustma-ust tushadi va faqat birinchi o'lchov bo'yicha kessak,
    unli chala qolib ketadi.
    """
    comm = edge_tts.Communicate(f"{matn_ozagi(text)} {TAIL}", voice, rate=rate,
                                boundary="WordBoundary")
    marks = []
    with open(dest_raw, "wb") as f:
        async for ch in comm.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])
            elif ch["type"] == "WordBoundary":
                marks.append(ch)
    # Oxirgi belgi «وَ» bo'lishi kerak. Bo'lmasa - kesmaymiz, chunki
    # noto'g'ri joydan kesish nutqni buzadi.
    if len(marks) >= 2 and marks[-1]["text"].strip() == TAIL:
        wa_start = marks[-1]["offset"] / 1e7
        soz_oxiri = (marks[-2]["offset"] + marks[-2]["duration"]) / 1e7 + 0.03
        return max(wa_start, soz_oxiri)
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
        if tail_kerakmi(text):
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

    # Nega oxiriga 0.3 s jimlik qo'shiladi (apad): ba'zi telefon
    # pleerlari mp3 ning eng oxirgi kadrlarini yutib yuboradi - shunda
    # gapning oxirgi bo'g'ini "yeb qo'yilgandek" eshitiladi. Jimlik
    # qo'shilsa, yutilsa ham jimlik yutiladi, nutq emas.
    #
    # 48 kbps: 32 kbps da ba'zi harflar (ayniqsa sirg'aluvchilar) xira
    # chiqardi; 48 da manba sifati to'liq saqlanadi.
    if cut:
        fade = max(0.0, cut - 0.015)
        af = (f"atrim=end={cut:.3f},asetpts=PTS-STARTPTS,"
              f"afade=t=out:st={fade:.3f}:d=0.015,apad=pad_dur=0.3")
    else:
        af = f"{trim_filter},apad=pad_dur=0.3"
    cmd = ["ffmpeg", "-y", "-v", "error", "-i", str(raw),
           "-af", af, "-ac", "1", "-ar", "24000", "-b:a", "48k", str(dest)]
    ok = subprocess.run(cmd, capture_output=True).returncode == 0
    raw.unlink(missing_ok=True)
    return ok
