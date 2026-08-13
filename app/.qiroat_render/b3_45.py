# -*- coding: utf-8 -*-
"""Mabdaul qiroat BOOK 3, lesson 45 (PDF idx 91-92).
Read each band image, write it down immediately, re-compare before merging.
Vocab cells are re-checked at Matrix(10,10) - at 6x the final vowels are
unreadable and tanwin gets guessed wrong."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_b3_batch import merge, v

# ---------------- 45 : قَصِيدَةٌ حِكَمِيَّةٌ (poem) ----------------
# 2-column table: right cell = sadr, left cell = ajuz. One bayt per line.
L45_reading = "\n".join([
    "لا تَحْسَبَنَّ سُرورًا دائِمًا أَبَدًا مَنْ سَرَّهُ زَمَنٌ ساءَتْهُ أَزْمانُ",
    "يا أَيُّها الْعالِمُ الْمَرْضِيُّ سِيرَتُهُ أَبْشِرْ فَأَنْتَ بِغَيْرِ الْماءِ رَيَّانُ",
    "وَيا أَخا الجَهْلِ لَوْ أَصْبَحْتَ فِي لُجَجٍ فَأَنْتَ ما بَيْنَها لا شَكَّ ظَمْآنُ",
    "دَعِ التَّكاسُلَ فِي الخَيْرَاتِ تَطْلُبُها فَلَيْسَ يَسْعَدُ بِالخَيْرَاتِ كَسْلانُ",
    "لا تَحْسَبِ النَّاسَ طَبْعًا واحِدًا فَلَهُمْ غَرَائِزٌ لَسْتَ تُحْصِيهَا وَأَلْوانُ",
    "ما كُلُّ ماءٍ كَصَدَّاءٍ بِوَارِدِهِ نَعَمْ وَلا كُلُّ نَبْتٍ فَهو سَعْدانُ",
    "مَنِ اسْتَعانَ بِغَيْرِ اللهِ فِي طَلَبٍ فَإِنَّ ناصِرَهُ عَجْزٌ وَخِذْلانُ",
    "سَحْبانُ مِنْ غَيْرِ مالٍ باقِلٌ حَصِرٌ وَباقِلٌ فِي شِراءِ الْمالِ سَحْبانُ",
    "كُلُّ الذُّنُوبِ فَإِنَّ اللهَ يَغْفِرُها إِنْ شَيَّعَ الْمَرْءَ إِخْلاصٌ وَإِيْمانُ",
    "وَكُلُّ كَسْرٍ فَإِنَّ اللهَ يَجْبِرُهُ وَما لِكَسْرِ قَناةِ الدِّينَ جُبْرانُ",
    "أَحْسِنْ إِذا كانَ إِمْكانٌ وَمَقْدُرَةٌ فَلا يَدُومُ عَلَى الإِنْسَانِ إِمْكانُ",
    "فَالرَّوْضُ يَزْدانُ بِالأَنْوارِ فاغِمُهُ وَالْحُرُّ بِالْعَدْلِ وَالإِحْسَانِ يَزْدانُ",
    # the book closes the poem with its author's name on its own table row
    "(أبو الفتح البستي)",
])
L45_vocab = [
    v("الْمَرْضِيُّ", "rozi qilgan"),
    v("رَيَّانُ", "suvdan qongan"),
    v("أَخُو الجَهْلِ", "johil kimsa"),
    v("لُجَّةٌ", "qa'r, tubsizlik", "لُجَجٌ"),
    v("ظَمْآنُ", "chanqoq"),
    v("طَبْعٌ", "tabiat, fe'l-atvor", "طِبَاعٌ"),
    v("غَرِيزَةٌ", "instinkt, ichki sezgi", "غَرَائِزُ"),
    v("أَحْصَى، يُحْصِي، اِحْصِ، إِحْصَاءٌ", "sanamoq, hisoblamoq"),
    v("صَدَّاءٌ", "chashma, quduq"),
    v("وَارِدٌ", "suv ichadigan joy"),
    v("خِذْلانُ", "mag'lubiyat"),
    v("سَحْبانُ", "notiq, chechan Sahbon"),
    v("باقِلٌ", "noshud, Boqil"),
    v("حَصِرٌ", "duduq"),
    v("شَيَّعَ، يُشَيِّعُ، شَيِّعْ، مُشَايَعَةٌ", "kuzatmoq, jo'natmoq"),
    v("كَسْرٌ", "singan, nochor"),
    v("يَجْبِرُهُ", "tuzatmoq, yordam bermoq"),
    v("قَنَاةٌ", "umurtqa pog'ona, nayza"),
    v("يَزْدانُ", "ziyoda"),
    v("فاغِمُهُ", "hid taratuvchi"),
]

new_lessons = [
    {"book": 3, "num": 45, "titleAr": "قَصِيدَةٌ حِكَمِيَّةٌ",
     "reading": L45_reading, "vocab": L45_vocab},
]

if __name__ == "__main__":
    merge(new_lessons)
