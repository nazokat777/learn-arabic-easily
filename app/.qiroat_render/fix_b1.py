# -*- coding: utf-8 -*-
"""Audit fix: vocab entries missing from BOOK 1.

Found by audit_all.py (every Cyrillic source gloss matched against our JSON).
Only 4-column tables count as vocab - book 1 also carries 8-column pronoun/verb
conjugation paradigms, which are grammar reference and out of scope.

Every Arabic word below was re-read from the page image at Matrix(5,5) or more,
never from the garbled text layer.
"""
import json, sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

PATH = "assets/content/qiroat_lessons.json"


def v(ar, uz, pl=None):
    d = {"ar": ar}
    if pl:
        d["pl"] = pl
    d["uz"] = uz
    return d


# lesson -> entries to append, in the book's own reading order
ADD = {
    # p24 (idx 23): classroom vocabulary. The lesson already had the pronouns
    # and verb forms; the seven nouns below had been skipped.
    12: [
        v("مُصَلَّى", "ibodat o'rni, joynamoz", "مُصَلَّيَاتُ"),
        v("مِسْوَاكٌ", "misvok", "مَسَاوِيكُ"),
        v("مِسْطَرَةٌ", "chizg'ich", "مَسَاطِرُ"),
        v("قَلَمٌ", "qalam", "أَقْلَامٌ"),
        # SOURCE MISPRINT: the book prints the plural as (كَرَارِيسُ), which is the
        # plural of كُرَّاسَة "quire/notebook", not of كُرْسِيّ "chair". Verified by
        # zooming the cell to Matrix(10,10). Stored with the correct كَرَاسِيُّ so the
        # app does not teach a wrong plural.
        v("كُرْسِيٌّ", "kursi, stul", "كَرَاسِيُّ"),
        v("دَرْسٌ", "dars", "دُرُوسٌ"),
        v("بَابٌ", "eshik", "أَبْوَابٌ"),
    ],
    # p26-27 (idx 25-26): family + school nouns. The lesson had kept only the
    # grandparents, the pronouns and two verbs; the fifteen below were skipped.
    # (The demonstrative-pronoun paradigm tables further down idx 26 are grammar
    # reference, deliberately out of scope.)
    13: [
        v("أَبٌ", "ota", "آبَاءٌ"),
        v("أُمٌّ", "ona", "أُمَّهَاتٌ"),
        v("أَخٌ", "aka-uka", "إِخْوَةٌ"),
        v("أُخْتٌ", "opa-singil", "أَخَوَاتٌ"),
        v("اِبْنٌ", "o'g'il", "أَبْنَاءٌ"),
        v("بِنْتٌ", "qiz", "بَنَاتٌ"),
        v("وَلَدٌ", "bola", "أَوْلَادٌ"),
        v("وَرَقٌ", "varaq", "أَوْرَاقٌ"),
        v("مَدْرَسَةٌ", "maktab", "مَدَارِسُ"),
        v("فَصْلٌ", "sinf", "فُصُولٌ"),
        v("شُبَّاكٌ", "deraza", "شَبَابِيكُ"),
        v("هُمْ", "ular (m.z.)"),
        v("هَؤُلَاءِ", "bular"),
        v("أُولَئِكَ", "anavilar"),
        v("ـكُمْ", "sizlarning"),
    ],
    # p28 (idx 27): the lesson had kept only the adverb and the verbs.
    14: [
        v("فِنْجَانٌ", "piyola", "فَنَاجِينُ"),
        v("سِكِّينٌ", "pichoq", "سَكَاكِينُ"),
        v("فَرَسٌ", "ot", "أَفْرَاسٌ"),
        v("كَلْبٌ", "it", "كِلَابٌ"),
        v("مِلْعَقَةٌ", "qoshiq", "مَلَاعِقُ"),
    ],
    # p21 (idx 20)
    10: [
        v("رَكِبَ، يَرْكَبُ، اِرْكَبْ، رُكُوبٌ", "minmoq"),
        v("الْجُنَيْنَةُ", "bog'cha"),
        v("قُمْتُ", "turdim"),
    ],
    # p36 (idx 35): the possessive suffixes closing the lesson's table.
    18: [
        v("ـهُ", "uning"),
        v("ـكَ", "sening"),
        v("ـِي", "mening"),
    ],
    # p78 (idx 77): the table's closing example phrases.
    42: [
        v("يَمْدَحُنِي", "meni maqtaydi"),
        v("سَأَلْتُ فَرِيدًا كِتَابًا", "Fariddan kitobni so'radim"),
        v("سَأَلْتُ فَرِيدًا عَنْكَ", "sen haqingda Fariddan so'radim"),
    ],
    4: [v("يَا", "ey")],
    9: [v("قَامَ، يَقُومُ، قُمْ، قِيَامٌ", "turmoq (o'rnidan)")],
    24: [v("عِيدٌ", "hayit", "أَعْيَادٌ")],
    32: [v("اُكْتُبِي يَا عَائِشَةُ", "ey Oysha, yoz")],
    34: [v("أَعْطَى، يُعْطِي، أَعْطِ، إِعْطَاءٌ", "berdi")],
    37: [v("عِنْدَمَا أَذْهَبُ", "borgan vaqtda")],
    39: [v("أَ", "-mi?")],
    41: [v("يَجِبُ عَلَيْكَ أَنْ تَقْرَأَ دَرْسَكَ", "darsingni o'qish senga shart")],
    45: [v("أَظُنُّ فِي الفَصْلِ", "sinfda deb gumon qilaman")],
    47: [v("زَرَعَ، يَزْرَعُ، اِزْرَعْ، زَرْعٌ", "ekdi")],
}

# Entries that exist but were stored INCOMPLETE - the book's gloss or plural had
# been cut short. Keyed by (lesson, arabic) -> fields to set.
UPDATE = {
    # p4-5 (idx 3-4): the gloss wraps across the page break, so only its first
    # half was taken and the plural cell was missed entirely.
    (1, "مَسْكَةٌ = مَاسِكَةٌ"): {"uz": "peroli ruchka, eshik ushlagichi",
                                  "pl": "مُسَكٌ"},
    (1, "نَشَّافَةُ الحِبْرِ"): {"uz": "siyoh shimdirgich, bosma"},
}


def main():
    data = json.load(open(PATH, encoding="utf-8"))
    for num, words in ADD.items():
        lesson = next(l for l in data["lessons"]
                      if l.get("book", 1) == 1 and l["num"] == num)
        have = {w["ar"] for w in lesson["vocab"]}
        added = 0
        for w in words:
            if w["ar"] not in have:
                lesson["vocab"].append(w)
                added += 1
        if added:
            print(f"book1 L{num}: +{added} -> {len(lesson['vocab'])} entries")

    for (num, ar), fields in UPDATE.items():
        lesson = next(l for l in data["lessons"]
                      if l.get("book", 1) == 1 and l["num"] == num)
        w = next(x for x in lesson["vocab"] if x["ar"] == ar)
        changed = {k: fv for k, fv in fields.items() if w.get(k) != fv}
        if changed:
            # keep key order ar, pl, uz so the file stays consistent
            new = {"ar": w["ar"]}
            pl = fields.get("pl", w.get("pl"))
            if pl:
                new["pl"] = pl
            new["uz"] = fields.get("uz", w["uz"])
            lesson["vocab"][lesson["vocab"].index(w)] = new
            print(f"book1 L{num}: updated {ar} -> {list(changed)}")

    # guard against the build-script accident that once cut book 2 to 5 lessons
    c = Counter(l.get("book", 1) for l in data["lessons"])
    assert c[1] == 52 and c[2] == 60, f"book counts wrong: {dict(c)}"

    json.dump(data, open(PATH, "w", encoding="utf-8", newline="\n"),
              ensure_ascii=False, indent=2)
    print("ok:", dict(sorted(c.items())))


if __name__ == "__main__":
    main()
