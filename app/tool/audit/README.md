# tool/audit — kitob rasmidan MUSTAQIL ko'chirib tekshirish quvuri

Ilovadagi arabcha matnni (Mabdaul qiroat: o'qish matni, kalitlar, lug'at, sarlavha, jadvallar; Nahv: «الدروس النحوية») manba PDF bilan solishtiradi.
2026-10-25 da Mabdaul qiroat uchun to'liq o'tkazildi (~101 tuzatish, kontent versiyasi 29).

## G'oya (ko'r-ko'rona ko'chirish)

1. **Qirqish** — `mkcrops*.py` PDF sahifalarini yuqori aniqlikdagi PNG bo'laklarga (chunk) kesadi: `work/chunks/<to'plam>/…png` + `*_meta.json`.
2. **Ko'chirish** — har bo'lak uchun alohida agent (Read + Write vositalari bilan) rasmga qarab matnni **ilovadagi matnni ko'rmasdan** ko'chiradi (`prompts/*.txt` — yo'riqnomalar). Natija `work/trans/…txt`.
3. **Solishtirish** — `diff_*.py` agent matnini ilova matni bilan harf darajasida solishtiradi (harakatlar olib tashlanadi; أإآٱ→ا, ى→ي, ئ→ي, ؤ→و; ة≠ه).
4. **Tekshirish** — har bir farq rasmda yaqinlashtirilib (`wc.py`, `wcall.py`, `vz.py`, `cropk.py`) qo'lda tasdiqlanadi. **Agent bayonotlarining ~50–60% i YOLG'ON** (avtotuzatish, sun-harf shaddasini «to'ldirish») — tekshirmasdan tuzatmang.
5. **Tuzatish** — `fixlib.Fixer` (`replace_in_field`, `replace_sentence`, `remove_sentence`, `save`): kutilgan matn aynan bir marta uchrashini tekshiradi, aks holda to'xtaydi.

## Siyosat

Harf, so'z, tartib, ortiqcha/yetishmayotgan gap tuzatiladi. Hamza o'rindig'i variantlari, bo'shliq, «***» bezak, qisqa unli farqi hisobga olinmaydi. Kitobning aniq bosma xatosi ilovada TO'G'RI shaklda qoladi.

## Muhit o'zgaruvchilari

| nom | ma'nosi | standart |
|---|---|---|
| `AUDIT_SP` | ish katalogi (chunks/, trans/, tasks/, notes) | `tool/audit/work` (git'ga kirmaydi) |
| `AUDIT_PDFS` | manba PDF'lar katalogi | `C:\Users\User\Downloads\Telegram Desktop` |
| `AUDIT_APP` | ilova ildizi (`whisper_new.py`) | `.` |

Skriptlarni `app` katalogidan ishga tushiring (`assets/content/…` yo'llari nisbiy).

## Skriptlar

| to'plam | qirqish | batch | solishtirish |
|---|---|---|---|
| Qiroat o'qish matni (1/2/3-kitob) | `mkcrops1.py`, `mkcrops23.py` | `mkbatches.py` | `diff_trans.py BOOK N…` |
| Kalitlar (mashq javoblari) | `mkcrops_key1.py`, `mkcrops_key2.py` | `mkbatches.py` | `diff_trans.py` |
| Lug'at jadvallari | `mkcrops_vocab.py` | `mkbatches_v.py` | `diff_vocab.py` |
| Sarlavhalar | `mkcrops_title.py` | — | `diff_titles.py` |
| Grammatik jadvallar | — | — | `diff_tables.py` |
| Nahv (4 kitob, 265 dars) | `mkcrops_nahv.py` | `mkbatches_n.py` | `diff_nahv.py BOOK P1 P2` |

Yaqinlashtirish: `wc.py BOOK L CHUNK QUERY`, `wcall.py BOOK L QUERY` (PDF matn qatlami so'z qutilaridan kesadi; 2/3-kitobda harflar asosan to'g'ri, ج ح خ م tushadi; 1-kitob qatlami yaroqsiz), `vz.py BOOK L CHUNK ROW COL` (lug'at katakchasi), `rechunk.py`, `locate.py`, `rg.py`.
`whisper_new.py` — yangi audio klip matnini whisper bilan tekshiradi.

## Tuzoqlar

- Nahv PDF skaner (matn qatlami yo'q); qirqish ~4.16 px/pt da, qora piksel profilidan kesiladi.
- Qiroat lug'at jadvali ko'zga teskari (ong juft avval); sahifa chegarasida bo'linib qolgan qator ikki yozuvga aylanishi mumkin.
- Gap soni o'zgarsa: `tool/tarjima/qol.json` (bead «p:q») + `python tool/tarjima/yoz.py`; lug'at o'zgarsa: `tool/ilgak/NNN.tsv` + `python tool/ilgak_yig.py`, `test/mnemonika_test.dart` sonlari.
- Yangi/tuzatilgan jumlaga ovoz: `gen_sentence_audio.py` (o'qish jumlalarini `ovoz_qamrov_test` tekshirmaydi).
- Kontent o'zgargach: `assets/content/version.json` +1, `.qiroat_render/stamp_version.py`, `flutter analyze`, `flutter test`.
