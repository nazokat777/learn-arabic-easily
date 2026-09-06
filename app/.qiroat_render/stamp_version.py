# -*- coding: utf-8 -*-
"""version.json ga kontentning BARMOQ IZINI (hash) bosadi.

Nega kerak: ilova yangi darslarni «version» raqami oshgandagina yuklab
olardi. Raqamni esa men qo'lda oshirardim — bir marta unutilsa, telefondagi
ilova eski darslarda abadiy qolib ketardi va buni hech kim sezmasdi.

Endi version.json ichida kontent fayllarining sha256 yig'indisi turadi.
Ilova raqamni ham, izni ham solishtiradi: iz o'zgargan bo'lsa yuklab oladi.
Ya'ni raqamni oshirish esdan chiqsa ham yangilanish ishlayveradi.

Bu skript CI'da (pages.yml) build'lardan OLDIN ishlaydi, shuning uchun
saytdagi va APK ichidagi iz bir xil bo'ladi — o'rnatishdan keyin ilova
o'zi bilgan kontentni qaytadan yuklab olmaydi.

Qo'lda ham ishga tushirsa bo'ladi:  python .qiroat_render/stamp_version.py
"""
import hashlib
import json
from pathlib import Path

CONTENT = Path("assets/content")
VERSION = CONTENT / "version.json"


def barmoq_izi() -> str:
    """Kontent fayllarining birlashgan sha256 izi.

    version.json ning o'zi hisobga KIRMAYDI — aks holda iz yozilishi
    izning o'zini o'zgartirib, hech qachon barqarorlashmasdi.
    """
    h = hashlib.sha256()
    for p in sorted(CONTENT.glob("*.json")):
        if p.name == VERSION.name:
            continue
        h.update(p.name.encode("utf-8"))
        h.update(p.read_bytes())
    return h.hexdigest()


def main() -> int:
    d = json.loads(VERSION.read_text(encoding="utf-8"))
    yangi = barmoq_izi()
    eski = d.get("hash")
    d["hash"] = yangi
    d.setdefault(
        "hashNote",
        "Kontent fayllarining sha256 izi. Ilova shu iz o'zgarganda yangi "
        "darslarni yuklab oladi — 'version' raqamini oshirish esdan chiqsa "
        "ham. Avtomatik yoziladi: .qiroat_render/stamp_version.py",
    )
    VERSION.write_text(
        json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    if eski == yangi:
        print("iz o'zgarmadi:", yangi[:16])
    else:
        print("iz yangilandi:", (eski or "yo'q")[:16], "->", yangi[:16])
    print("version:", d.get("version"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
