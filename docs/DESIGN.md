# "Arab tilini oson o'rganamiz" — Dizayn hujjati

**Sana:** 2026-08-06
**Platforma:** Flutter (Android + iOS + Web) — bitta kod bazasi
**Til:** Interfeys o'zbekcha, kontent arabcha + o'zbekcha tarjima

---

## 1. Vizyon
O'zbek tilida so'zlashuvchilar uchun arab tilining uch fanini — **Mabdaul qiroat → Sarf → Nahv** —
o'yinlashtirilgan, bosqichma-bosqich o'rgatuvchi ilova. Maqsad: yodlashni tushunishga aylantirish.

## 2. Asosiy tamoyil: "200% aniqlik dvigateli"
Kontent **AI tomonidan o'ylab topilmaydi**. Uch xil ishonchli manba ishlatiladi:

1. **Standart, o'zgarmas ma'lumot** (harflar, harakatlar, махраж) — arab alifbosi qat'iy, 100% aniq.
   - Harflarning 4 holati ZWJ (U+200D) orqali shrift bilan shakllantiriladi → xatosiz.
2. **Tekshirilgan darsliklar** (Мабдаун наҳв, Таркиб қоидалари, Мадина луғат) — bazaga
   struktura sifatida kiritiladi.
3. **AI (ixtiyoriy, keyingi bosqich)** — faqat tushuntirishni chiroyli yetkazish uchun,
   "tekshirilmagan" belgisi bilan. Grammatik javobni o'ylab topmaydi.

## 3. Modullar (3 bo'lim)

| Modul | Vazifa | MVP holati |
|---|---|---|
| **Mabdaul qiroat** | O'qishni o'rganish: harflar, harakat, tajvid, so'z, lug'at | ✅ MVP shu yerdan |
| **Sarf** | So'z tuzilishi (vazn, tasrif, fe'l boblari) | Keyingi bosqich |
| **Nahv** | Jumla tuzilishi (i'rob, amil-ma'mul) | Keyingi bosqich |

Mabdaul qiroatning ilg'or bosqichida har so'z uchun **sarfi + nahvi + tarjimasi** so'raladi.

## 4. Umumiy o'quv tsikli (har darsda bir xil)
```
DARS  →  TEST (dars oxirida)  →  QAYTA-QAYTA interaktiv test
                                        +
                    LUG'AT TESTI  +  SO'Z YASASH O'YINI
              (hammasi XP, olov/streak, gavhar bilan)
```

## 5. Texnik arxitektura
- **Kontent:** `assets/content/*.json` — telefonda mahalliy, offline ishlaydi.
- **Progress:** `shared_preferences` — XP, streak, tugatilgan darslar mahalliy saqlanadi.
- **UI:** RTL-aware, arabcha shrift (Amiri/Scheherazade), o'zbekcha interfeys.
- **Holat boshqaruvi:** oddiy (setState / ValueNotifier), keyin kerak bo'lsa kengaytiriladi.

## 6. MVP ko'lami (v0.1 — birinchi ishlaydigan versiya)
Mabdaul qiroat moduli:
1. **Harflar darsi** — 28 harf interaktiv grid, har harf: nomi, махраж, 4 holati, talaffuz.
2. **Harflarni tanish testi** — interaktiv, qayta-qayta.
3. **Harakatlar darsi** — fatha/kasra/zamma + sukun/shadda/tanvin.
4. **Lug'at testi** — Madina so'zlaridan (arabcha→o'zbekcha).
5. **So'z yasash o'yini** — harflardan so'z qurish.
6. **Gamifikatsiya** — XP + kunlik olov (streak).

## 7. Keyingi bosqichlar (yo'l xaritasi)
- v0.2: Tajvid darslari (izhor, iqlob, idg'om, ixfo...), audio talaffuz.
- v0.3: Sarf moduli (vazn laboratoriyasi, tasrif poygasi, fe'l boblari).
- v0.4: Nahv moduli (i'rob detektivi, amil-ma'mul).
- v0.5: Skaner kitoblardan OCR, AI-ustoz (grounded).
