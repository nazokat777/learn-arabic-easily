# -*- coding: utf-8 -*-
"""Mabdaul qiroat BOOK 3, lesson 51 (PDF idx 103-104).
Read each band image, write it down immediately, re-compare before merging.
Vocab cells are re-checked at Matrix(10,10)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_b3_batch import merge, v

# ---------------- 51 : قَصِيدَةٌ حِكَمِيَّةٌ (poem) ----------------
# 2-column table: right cell = sadr, left cell = ajuz. One bayt per line.
L51_reading = "\n".join([
    "وَأَقْبَحُ ما يَكُونُ غِنَى بَخِيلٍ يَغَصُّ وَماؤُهُ مِلْءُ الزِّقاقِ",
    "إِذا مَلَكَتْ يَداهُ الْفَلْسَ أَمْسَى رَقِيقًا لَيْسَ يَطْمَعُ فِي الْعِتاقِ",
    "أَلا يا جامِعَ الأَمْوالِ هَلاًّ جَمَعْتَ لَها زَمانًا لافْتِراقِ",
    "إِذا أَحْرَزْتَ مالَ الأَرْضِ طُرًّا فَمَا لَكَ فَوْقَ عَيْشِكَ مِنْ تَراقِ",
    "أَتَأْكُلُ كُلَّ يَوْمٍ أَلْفَ كَبْشٍ وَتَلْبَسُ أَلْفَ طاقٍ فَوْقَ طاقِ",
    "فُضُولُ الْمالِ ذاهِبَةٌ جُزافًا كَماءٍ صُبَّ فِي كَأْسٍ دِهاقِ",
    "مَضَتْ دُوَلُ الْعُلُومِ الزُّهْرِ قِدْمًا وَقامَتْ دَوْلَةُ الصُّفْرِ الرِّقاقِ",
    "وَأَبْرَزَتِ الْخَلاعَةُ مِعْصَمَيْها وَباتَ الجْهْلُ مَمْدُودَ الرِّواقِ",
    "فَأَصْبَحَ يَدَّعِي بِالسَّبْقِ جَهْلاً زَعانِفُ يَعْجَزُونَ عَنِ اللَّحاقِ",
    "إِذا هَلَكَتْ رِجالُ الحْيِّ أَضْحَى صَبِيُّ الْقَوْمِ يَحْلِفُ بِالطَّلاقِ",
    "أَسَرُّ النَّاسِ فِي الدُّنْيا جَهُولٌ يُفَكِّرُ فِي اصْطِباحٍ وَاغْتِباقِ",
    "وَأَتْعَبُهُمْ رَئِيسٌ كُلَّ يَوْمٍ يَكُونُ لِكُلِّ مَلْسُوعٍ كَراقِ",
    # the book closes the poem with its author's name on its own line
    "(الشّيخ ناصيف اليازجي)",
])
L51_vocab = [
    v("غَصَّ، يَغَصُّ، غُصَّ، غَصَصٌ", "tiqilmoq"),
    v("زِقٌّ", "mesh", "زِقَاقٌ"),
    v("فَلْسٌ", "pul", "فُلُوسٌ"),
    v("رَقِيقٌ", "qul"),
    v("الْعِتَاقُ", "ozod bo'lish"),
    v("أَحْرَزَ، يُحْرِزُ، أَحْرِزْ، إِحْرَازٌ", "egallamoq"),
    v("طُرًّا", "hammasini jamlagan holda"),
    v("تَرَاق", "yuksalish"),
    v("جُزافًا", "behuda"),
    v("دِهَاقٌ", "to'lgan, limmo-lim"),
    v("قِدْمٌ", "qadimdan, ko'pdan"),
    v("الصُّفْر", "sarg'aygan, hech vaqosi yo'q"),
    v("خَلاَعَةٌ", "buzuqlik, beboshlik"),
    v("مِعْصَمٌ", "bilak", "مَعَاصِمُ"),
    v("رِوَاقٌ", "yo'lak, karidor", "أَرْوِقَةٌ"),
    v("زِعْنِفَةٌ", "ta'yinsiz, qalang'i-qasang'i", "زَعَانِفُ"),
    v("لَحَاقٌ", "yetib, qo'shilish"),
    v("حَلَفَ، يَحْلِفُ، اِحْلِفْ، حَلْفٌ", "qasam ichmoq"),
    v("اِصْطِبَاحٌ", "ertalab ovqatlanuvchi"),
    v("اِغْتِبَاقٌ", "kechki payt suv ichish"),
    v("مَلْسُوعٌ", "chaqiluvchi"),
    v("راقٍ", "emlovchi"),
]

new_lessons = [
    {"book": 3, "num": 51, "titleAr": "قَصِيدَةٌ حِكَمِيَّةٌ",
     "reading": L51_reading, "vocab": L51_vocab},
]

if __name__ == "__main__":
    merge(new_lessons)
