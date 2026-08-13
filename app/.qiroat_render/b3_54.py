# -*- coding: utf-8 -*-
"""Mabdaul qiroat BOOK 3, lesson 54 (PDF idx 110-111).
Read each band image, write it down immediately, re-compare before merging.
Vocab cells are re-checked at Matrix(10,10)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_b3_batch import merge, v

# ---------------- 54 : قَصِيدَةٌ فِي الزُّهْرِ (poem) ----------------
# 2-column table: right cell = sadr, left cell = ajuz. One bayt per line.
L54_reading = "\n".join([
    "أَحْسَنَ اللهُ بِنا إِنَّ الْخَطايا لا تَفُوحُ",
    "فَإِذا الْمَسْتُورُ مِنَّا بَيْنَ ثَوْبَيْهِ فُضُوحُ",
    "كَمْ رَأَيْنا مِنْ عَزِيزٍ طُوِيَتْ عَنْهُ الْكُشُوحُ",
    "مَوْتَ بَعْضِ النَّاسِ فِي الأَرْضِ عَلَى الْبَعْضِ فُتوحُ",
    "سَيَصِيرُ الْمَرْءُ يَوْمًا جَسَدًا ما فِيهِ رُوحُ",
    "بَيْنَ عَيْنَيْ كَلِّ حَيٍّ عَلَمُ الْمَوْتِ يُلُوحُ",
    "كُلُّنا فِى غَفْلَةٍ وَالْمَوْتُ يَغْدُو وَيَرُوحُ",
    "كُلُّ نَطَّاحٍ مِنَ الدَّهْرِ لَهُ يَوْمٌ نَطوحُ",
    "نُحْ عَلَى نَفْسِكَ يا مِسْكِينُ إِنْ كُنْتَ تَنُوحُ",
    "لَسْتَ بِالْبَاقِي وَلَوْ عُمِّرْتَ ما عُمِّرَ نُوحُ",
    # the book closes the poem with its author's name on its own line
    "(أبو العتاهية)",
])
L54_vocab = [
    v("لا تَفُوحُ", "hid taratmaydi"),
    v("فُضُوحٌ", "fosh etilmoq, sharmanda bo'lmoq"),
    v("عَزِيزٌ", "kuchli, qudratli"),
    v("طُوِيَتْ عَنْهُ الكُشُوحُ", "(yorug'likdan keyin qorong'ulik keldi)"),
    v("كَشْحٌ", "yon, biqin", "كُشُوحٌ"),
    v("لاَحَ، يُلُوحُ، لُحْ، لَوْحٌ", "hilpiradi, zohir bo'ldi"),
    v("غَدَا، يَغْدُو، أُغْدُ، غُدُوٌّ", "tongda kelmoq"),
    v("رَاحَ، يَرُوحُ، رُحْ، رَوَاحٌ", "tunda kelmoq"),
    v("نَطَّاحٌ", "suzuvchi (zolim)"),
    v("نَاحَ، يَنُوحُ، نُحْ، نَوْحَةٌ", "baqirib yig'lamoq"),
]

new_lessons = [
    {"book": 3, "num": 54, "titleAr": "قَصِيدَةٌ فِي الزُّهْرِ",
     "reading": L54_reading, "vocab": L54_vocab},
]

if __name__ == "__main__":
    merge(new_lessons)
