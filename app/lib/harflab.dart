import 'content.dart';
import 'main.dart';

/// So'zni HARFLAB aytish uchun bo'lak: ko'rinadigan harf va uning aytiladigan
/// nomi (masalan «ب» → «بَاء»). Nom 28 harf uchun inson ovozidagi «harf»
/// to'plamidan chiqadi; qolgan belgilar (ة، ء، ى) uchun nom matn bilan
/// beriladi — ular kitobda ham shu nom bilan o'rgatiladi.
class HarfBolagi {
  /// Harfning o'zi (harakatsiz).
  final String harf;

  /// Nomi (aytiladigan).
  final String nom;

  /// Harf so'zdagi HARAKATI bilan (بَ، بِ، بُ، بْ، بَّ، بٌ …). Harflab
  /// yozishda aynan shu ko'rsatiladi va shu bilan solishtiriladi — o'quvchi
  /// harfni ham, harakatini ham eslasin (sukun, tashdid, tanvin ham).
  final String shakl;
  const HarfBolagi(this.harf, this.nom, [String? shakl])
    : shakl = shakl ?? harf;
}

/// Hamzali shakllar asl harfiga keltiriladi — nomi o'sha harf nomi bilan
/// aytiladi (أ → alif, ؤ → vov, ئ → yo). Boshlang'ich kitobda shunday.
const _asl = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي'};

const _maxsus = {
  'ة': 'تَاءٌ مَرْبُوطَةٌ',
  'ء': 'هَمْزَةٌ',
  'ى': 'أَلِفٌ مَقْصُورَةٌ',
};

/// Harakat belgilari (fatha, kasra, damma, sukun, shadda, tanvinlar, alif
/// xanjariya…) — harfga ergashadi.
final RegExp _harakat = RegExp('[ً-ْٰ]');

/// So'zni harflarga ajratadi, har harfga nomini va so'zdagi harakatli
/// shaklini biriktiradi. Bo'sh joy va tinish belgilari tashlab yuboriladi.
List<HarfBolagi> harflab(String soz) {
  final out = <HarfBolagi>[];
  final chars = soz.replaceAll('ـ', '').split('');
  for (var i = 0; i < chars.length; i++) {
    final ch = chars[i];
    if (ch.trim().isEmpty || _harakat.hasMatch(ch)) continue;
    final nom = harfNomi(ch);
    if (nom == null) continue; // tinish belgisi, raqam va h.k.
    var shakl = ch;
    var j = i + 1;
    while (j < chars.length && _harakat.hasMatch(chars[j])) {
      shakl += chars[j];
      j++;
    }
    out.add(HarfBolagi(ch, nom, shakl));
  }
  return out;
}

/// Chalg'ituvchi harf uchun tasodifiy harakat (ko'rinishi so'z harflariga
/// o'xshasin — harakatsiz chalg'ituvchi darrov bilinib qoladi).
const harakatlar = [
  '\u064E',
  '\u0650',
  '\u064F',
  '\u0652',
  '\u064B',
  '\u064C',
  '\u064D',
];

/// Bitta harfning aytiladigan nomi; harf bo'lmasa null.
String? harfNomi(String ch) {
  final m = _maxsus[ch];
  if (m != null) return m;
  final asl = _asl[ch] ?? ch;
  for (final Letter l in repo.letters) {
    if (l.ar == asl) return l.nameAr;
  }
  return null;
}
