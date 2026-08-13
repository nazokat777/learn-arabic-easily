# -*- coding: utf-8 -*-
"""Mabdaul qiroat BOOK 3, lesson 50 (PDF idx 102-103).
Read each band image, write it down immediately, re-compare before merging.
Vocab cells are re-checked at Matrix(10,10)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_b3_batch import merge, v

# ---------------- 50 : قَصِيدَةٌ حِكَمِيَّةٌ (poem) ----------------
# 2-column table: right cell = sadr, left cell = ajuz. One bayt per line.
L50_reading = "\n".join([
    "لَعَمْرُكَ لَيْسَ فَوْقَ الأَرْضِ باقٍ وَلا مِمَّا قَضاهُ اللهُ واقِ",
    "وَما لِلْمَرْءِ حَظٌّ غَيْرُ قُوتٍ وَلَوْ كانَتْ لَهُ أَرْضُ الْعِراقِ",
    "أَضَلُّ النَّاسِ فِي الدُّنْيا سَبِيلاً مُحِبٌّ باتَ مِنْها فِي وَثاقِ",
    "وَأَخْسَرُ ما يَضِيعُ الْعُمْرُ فِيهِ فُضُولُ الْمالِ تُجْمَعُ لِلرِّفاقِ",
    "وَأَفْضَلُ ما اشْتَغَلْتَ بِهِ كِتابٌ جَلِيلٌ نَفْعُهُ حُلْوُ الْمَذاقِ",
    "وَعِشْرَةُ حاذِقٍ فَطِنٍ لَبِيبٍ يُفِيدُكَ مِنْ مَعانِيهِ الدِّقاقِ",
    "مَضَى ذِكْرُ الْمُلوكِ بِكُلِّ عَصْرٍ وَذِكْرُ السُّوقَةِ الْعُلَماءِ باقِ",
    "وَكَمْ عِلْمٍ جَنَى مالاً وَجاهًا وَكَمْ مالٍ جَنَى حَرْبَ السِّباقِ",
    "وَما نَفْعُ الدَّراهِمِ مَعَ جَهُولٍ يُباعُ بِدِرْهَمٍ وَقْتَ النَّفاقِ",
    "إِذا حُمِلَ النِّضارُ عَلَى نِياقٍ فَأَيُّ الْفَخْرِ يُحْسَبُ لِلنِّياقِ",
])
L50_vocab = [
    v("لَعَمْرُكَ", "umringga qasam"),
    v("واقٍ", "saqlovchi"),
    v("حَظٌّ", "nasiba", "حُظُوظٌ"),
    v("وِثَاقٍ", "bog'lanib qoluvchi"),
    v("حُلْوُ الْمَذاقِ", "ta'mi totli"),
    v("السُّوقَةُ", "oddiy, sodda"),
    v("جَنَى، يَجْنِي، اِجْنِ، جَنْيٌ", "termoq"),
    v("جَاهٌ", "obro', mansab"),
    v("حَرْبُ السِّباقِ", "urush musobaqasi"),
    v("النَّفَاقُ", "rivojlanish"),
    v("النِّضارُ", "sof oltin"),
    v("نَاقَةٌ", "urg'ochi tuya", "نِيَاقٌ"),
]

new_lessons = [
    {"book": 3, "num": 50, "titleAr": "قَصِيدَةٌ حِكَمِيَّةٌ",
     "reading": L50_reading, "vocab": L50_vocab},
]

if __name__ == "__main__":
    merge(new_lessons)
