# -*- coding: utf-8 -*-
"""«Harflarni ulash» darsining kontentini yasaydi.

Nega skript: so'zlarning arabchasi ham, o'zbekchasi ham QO'LDA yozilmaydi —
ilovaning allaqachon tekshirilgan lug'atidan (vocabulary.json va qiroat
darslari) harakati bilan birga olinadi. Shunda tarjima ham, harakat ham
yangi xato kirita olmaydi.

Bosqichlar arab yozuvini o'rgatishning klassik tartibida:
  1 — harflari chapga ULANMAYDIGAN so'zlar (shakl umuman o'zgarmaydi);
  2 — aralash, qisqa so'zlar (bir-ikki harf shaklini o'zgartiradi);
  3 — uch harfli, hammasi ulanadigan so'zlar;
  4 — to'rt harfli;
  5 — besh-olti harfli.
"""
import json, io, re
from pathlib import Path

HAR = re.compile(r'[\u064B-\u0652\u0670\u0640]')
def bare(s): return HAR.sub('', s).strip()

# Har bosqich uchun so'zlar HARAKATSIZ shakli bo'yicha tanlanadi;
# arabchasi va ma'nosi manbadan olinadi.
TANLOV = [
  (1, "Ulanmaydigan harflar", "الحُرُوفُ الَّتِي لَا تَتَّصِلُ",
   "Olti harf o'zidan keyingi harfga ULANMAYDI: ا د ذ ر ز و. "
   "Shuning uchun bu so'zlarda harflar shaklini umuman o'zgartirmaydi — "
   "shunchaki yonma-yon turadi. Eng oson bosqich.",
   ["دار","زر","ورد","زور","إذ","إذا","أراد","أدار","وارد"]),

  (2, "Aralash — qisqa so'zlar", "كَلِمَاتٌ قَصِيرَةٌ",
   "Endi ulanadigan harf ham qatnashadi. Ulanadigan harf o'zidan "
   "keyingisiga bog'lanib, shaklini o'zgartiradi; ulanmaydigani esa "
   "zanjirni uzadi. Masalan «باب»: birinchi ب ga ا ulanadi, lekin ا "
   "dan keyingi ب alohida turadi.",
   ["أب","أم","أخ","جد","يد","فم","سن","قط","باب","ماء","موز","ديك",
    "رأس","أرض","أنف","أذن","ريح","شاي","جدة","أخت","ابن","رجل"]),

  (3, "To'liq ulanadigan so'zlar", "كَلِمَاتٌ مُتَّصِلَةٌ",
   "Bu so'zlarda hamma harf bir-biriga ulanadi — so'z boshidan oxirigacha "
   "bitta zanjir bo'lib chiziladi. Harfning boshdagi, o'rtadagi va "
   "oxiridagi shakli aniq ko'rinadi.",
   ["بيت","قلم","شمس","قمر","كلب","سمك","لبن","عسل","عنب","خبز","جبل",
    "بحر","ثلج","حجر","جمل","بنت","عين","قلب","شعر","سكر","بطة","ستة"]),

  (4, "To'rt harfli so'zlar", "كَلِمَاتٌ رُبَاعِيَّةٌ",
   "So'z uzayadi, ammo qoida o'sha-o'sha. Endi bir so'z ichida ham "
   "ulanadigan, ham ulanmaydigan harflar aralash keladi.",
   ["بقرة","بيضة","تفاح","حصان","حمار","دفتر","دكان","زهرة","سرير",
    "سكين","سماء","خمسة","سبعة","تسعة","أبيض","أحمر","أخضر","أزرق",
    "أسود","أصفر","حمام","تاجر"]),

  (5, "Uzun so'zlar", "كَلِمَاتٌ طَوِيلَةٌ",
   "Oxirgi bosqich: besh-olti harfli so'zlar. Bularni ravon o'qiy "
   "olsangiz, arabcha matnni bo'g'inlab emas, so'z sifatida o'qiy "
   "boshlaysiz.",
   ["مفتاح","نافذة","حديقة","جامعة","سحابة","منديل","ثلاثة","أربعة",
    "اثنان","ثمانية","برتقال","إنسان","أسبوع","إبريق"]),
]

# --- manba lug'ati ---
cand = {}
def qosh(ar, uz, pri):
    ar = ar.split('،')[0].strip(); uz = uz.strip(); b = bare(ar)
    if not ar or not uz or not b: return
    if b in cand and cand[b][2] <= pri: return
    cand[b] = (ar, uz, pri)

for w in json.loads(Path('assets/content/vocabulary.json').read_text(encoding='utf-8'))['words']:
    qosh(w['ar'], w['uz'], 0)
for L in json.loads(Path('assets/content/qiroat_lessons.json').read_text(encoding='utf-8'))['lessons']:
    for w in L.get('vocab', []):
        qosh(w.get('ar',''), w.get('uz',''), L.get('book',1))

man = {}
for f, pre in (('vocab','vocab'),('sentence','sentences'),('word','words'),
               ('alifbo','alifbo'),('extra','extra')):
    for k, v in json.loads(Path('assets/audio/%s_manifest.json'%f).read_text(encoding='utf-8')).items():
        man[k.strip()] = pre + '/' + v

stages, yoq, ovozsiz = [], [], []
for num, title, titleAr, explain, keys in TANLOV:
    words = []
    for k in keys:
        if k not in cand:
            yoq.append((num, k)); continue
        ar, uz, _ = cand[k]
        if ar not in man: ovozsiz.append((num, k, ar))
        words.append({"ar": ar, "uz": uz})
    stages.append({"num": num, "title": title, "titleAr": titleAr,
                   "explain": explain, "words": words})

out = {
  "meta": {
    "title": "Harflarni ulash",
    "note": "So'zlar ilovaning o'z lug'atidan olingan (vocabulary.json va "
            "qiroat darslari) — arabchasi ham, tarjimasi ham qo'lda "
            "yozilmagan. Qayta yasash: .qiroat_render/build_ulash.py"
  },
  "stages": stages,
}
Path('assets/content/ulash.json').write_text(
    json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')

print("bosqichlar:", [(s['num'], len(s['words'])) for s in stages])
print("jami so'z:", sum(len(s['words']) for s in stages))
print("lug'atdan topilmadi:", yoq)
print("ovozi yo'q:", ovozsiz)
