# Mabdaul qiroat — gapma-gap tarjima (qatlami)

Kitob tarjimasi (`translation`, 169 darsning hammasida bor) arabcha gaplarga bo'lingan:
dars JSON'iga `tarjimaSarlavha` va `tarjimaGaplar` qo'shilgan. Matn kitobdagining o'zi —
faqat qaysi arabcha gapga tegishli ekani aniqlangan (har dars qo'lda ko'rib chiqilgan).

Quvur (app/ papkasidan):

1. `satrlar.py`   — PDF'dan har darsning o'zbekcha SATRLARINI qayta oladi → `satrlar.json`
                    (PDF yo'llari skript ichida; `translation` bilan so'zma-so'z mosligi tekshiriladi).
2. `atomla.py`    — tarjimani «atom»larga bo'ladi (sarlavha + gap bo'laklari / she'r satrlari) → `atomlar.json`.
                    Qo'lda qo'shimchalar: `tuzat.json` (PDF nuqsonlari), `bolish.json` (atomni ikkiga bo'lish),
                    `sarlavha.json` (avtomatik topilmagan sarlavha).
3. `tekislash.py` — Gale–Church usulida arabcha gap ↔ atom «munchoqlari» taklifi → `taklif.json`
                    («p:q» = p ta arabcha gap ↔ q ta atom; q=0 — kitobda tarjimasi yo'q).
4. `goster.py`, `ikki.py` — ko'zdan kechirish uchun chiqarish (arabcha gap va atomlar yonma-yon).
5. `qol.py`       — qo'lda tuzatilgan munchoq qatorini `qol.json` ga yozadi (yig'indini tekshiradi).
                    `qol.json` `taklif.json` dan USTUN. 55 dars qo'lda tuzatilgan; qolganlari ko'rib tasdiqlangan.
6. `qoshimcha.json` — kitob tarjima qilmagan 28 gap uchun ilova qo'shgan tarjimalar (UI'da «ilova qo'shgan»
                    deb belgilanadi); `null` — she'r muallifining nomi (tarjimasiz).
7. `yoz.py`       — hammasini `assets/content/qiroat_lessons.json` ga yozadi va invariantlarni tekshiradi:
                    arabcha gaplar yig'indisi, kitob matni bilan bo'linish mosligi, tarjimasiz guruhlar ro'yxati.
                    So'ng `python .qiroat_render/stamp_version.py` (versiya izi).

`atomlar.json` yoki `tekislash.py` o'zgarsa `taklif.json` ni qayta yasang; `qol.json` dagi qatorlar atomlar
soni o'zgarsa `yoz.py` da to'xtaydi (yig'indi mos kelmaydi).
