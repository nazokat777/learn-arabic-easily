# -*- coding: utf-8 -*-
"""Ilova ikonkasini manba rasmdan yasaydi (Android + web).

Manbadagi muammo: rasm RGB (shaffofliksiz) va tasvir atrofida QORA
hoshiya bor, ustiga plastinkaning burchaklari o'zi yumaloqlangan.
Shunday holda telefon ikonkani yana bir bor yumaloqlaydi va natijada
kichkina, qora ramkali ikonka chiqadi.

Yechim: qora hoshiya olib tashlanadi, yumaloq burchaklar plastinkaning
o'z yashili bilan to'ldiriladi va ikonka CHETGACHA to'la kvadrat bo'ladi.
Niqobni telefonning o'zi qo'yadi — dumaloq ham, kvadrat ham toza chiqadi.

Android 8+ uchun «adaptive» ikonka ham yasaladi: fon — bir tekis yashil,
old qatlam — tasvirning o'zi xavfsiz maydonga (66%) joylashtirilgan.
Shunda launcher animatsiya qilganda tasvir kesilib qolmaydi.

Ishga tushirish (app katalogidan):
    python .qiroat_render/make_icons.py <manba.png>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# Android launcher ikonkasi o'lchamlari
MIPMAP = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
# Adaptive ikonka: to'liq tuval 108dp, ko'rinadigan qismi 72dp.
ADAPTIVE = {k: int(v * 108 / 48) for k, v in MIPMAP.items()}

RES = Path("android/app/src/main/res")
WEB = Path("web")


def qora(c, chek=28):
    return c[0] < chek and c[1] < chek and c[2] < chek


def kesib_ol(im):
    """Qora hoshiyani olib tashlab, tasvirni kvadrat qilib qaytaradi."""
    px = im.load()
    w, h = im.size
    xs, ys = [], []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if not qora(px[x, y]):
                xs.append(x)
                ys.append(y)
    l, r, t, b = min(xs), max(xs), min(ys), max(ys)
    # Kvadratga tenglashtiramiz - cho'zilib ketmasin.
    kx, ky = (l + r) // 2, (t + b) // 2
    yon = max(r - l, b - t) // 2
    l, r, t, b = kx - yon, kx + yon, ky - yon, ky + yon
    l, t = max(0, l), max(0, t)
    r, b = min(w, r), min(h, b)
    return im.crop((l, t, r, b))


def plastinka_yashili(im):
    """Plastinkaning yashil rangi — chet bo'ylab halqadan o'rtacha."""
    px = im.load()
    w, h = im.size
    chet = int(w * 0.06)
    nam = []
    for y in range(chet, h - chet, 3):
        for x in (chet, w - chet):
            c = px[x, y]
            if qora(c):
                continue
            # yashilroq bo'lsin: g eng katta va juda yorug' bo'lmasin
            if c[1] >= c[0] and c[1] >= c[2] and sum(c) < 480:
                nam.append(c)
    if not nam:
        return (18, 79, 61)
    nam.sort(key=lambda c: c[1])
    return nam[len(nam) // 2]


def toliq_kvadrat(crop, yashil):
    """Yumaloq burchaklarni yashil bilan to'ldirib, to'la kvadrat qiladi.

    Burchakdagi qora piksellar niqob orqali yashilga almashtiriladi;
    chegara silliq bo'lishi uchun niqob biroz xiralashtiriladi.
    """
    crop = crop.convert("RGB")
    w, h = crop.size
    px = crop.load()
    niqob = Image.new("L", (w, h), 0)
    mp = niqob.load()
    for y in range(h):
        for x in range(w):
            mp[x, y] = 0 if qora(px[x, y]) else 255
    niqob = niqob.filter(ImageFilter.GaussianBlur(1.2))
    fon = Image.new("RGB", (w, h), yashil)
    return Image.composite(crop, fon, niqob)


def yumaloq(im, radius_nisbat=0.22):
    """Web/favicon uchun yumshoq yumaloq burchak (u yerda niqob yo'q)."""
    im = im.convert("RGBA")
    w, h = im.size
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        (0, 0, w - 1, h - 1), radius=int(w * radius_nisbat), fill=255
    )
    im.putalpha(m)
    return im


def main() -> int:
    if len(sys.argv) < 2:
        print("kerak: python .qiroat_render/make_icons.py <manba.png>")
        return 2
    manba = Path(sys.argv[1])
    if not manba.exists():
        print("manba topilmadi:", manba)
        return 2
    if not RES.exists():
        print("android/app/src/main/res topilmadi - app katalogidan ishga tushiring")
        return 2

    im = Image.open(manba).convert("RGB")
    crop = kesib_ol(im)
    yashil = plastinka_yashili(crop)
    tola = toliq_kvadrat(crop, yashil)
    print("manba:", im.size, "-> kesilgan:", crop.size)
    print("plastinka yashili:", yashil)

    # 1) Eski uslubdagi ikonka - chetgacha to'la kvadrat.
    for nom, olcham in MIPMAP.items():
        d = RES / ("mipmap-" + nom)
        d.mkdir(parents=True, exist_ok=True)
        tola.resize((olcham, olcham), Image.LANCZOS).save(d / "ic_launcher.png")

    # 2) Adaptive: fon bir tekis yashil, old qatlam xavfsiz maydonda.
    #    Tasvir 108dp tuvalning 72dp qismiga sig'ishi kerak, aks holda
    #    launcher uni kesib qo'yadi.
    for nom, olcham in ADAPTIVE.items():
        d = RES / ("mipmap-" + nom)
        d.mkdir(parents=True, exist_ok=True)
        old = Image.new("RGBA", (olcham, olcham), (0, 0, 0, 0))
        ich = int(olcham * 72 / 108)
        old.paste(
            tola.resize((ich, ich), Image.LANCZOS),
            ((olcham - ich) // 2, (olcham - ich) // 2),
        )
        old.save(d / "ic_launcher_foreground.png")

    (RES / "values").mkdir(parents=True, exist_ok=True)
    (RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n'
        "</resources>\n" % yashil,
        encoding="utf-8",
    )
    (RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    for nom in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (RES / "mipmap-anydpi-v26" / nom).write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            "</adaptive-icon>\n",
            encoding="utf-8",
        )

    # 3) Web: favicon va PWA ikonkalari.
    if WEB.exists():
        yumaloq(tola.resize((512, 512), Image.LANCZOS)).save(WEB / "favicon.png")
        ikon = WEB / "icons"
        ikon.mkdir(exist_ok=True)
        for olcham in (192, 512):
            tola.resize((olcham, olcham), Image.LANCZOS).convert("RGBA").save(
                ikon / ("Icon-%d.png" % olcham)
            )
            yumaloq(tola.resize((olcham, olcham), Image.LANCZOS), 0.0).save(
                ikon / ("Icon-maskable-%d.png" % olcham)
            )

    print("tayyor: mipmap x%d, adaptive, web" % len(MIPMAP))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
