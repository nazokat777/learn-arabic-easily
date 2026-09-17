import 'arabic.dart';
import 'content.dart';
import 'main.dart';

/// So'zni HARFLAB aytish uchun bo'lak: ko'rinadigan harf va uning aytiladigan
/// nomi (masalan «ب» → «بَاء»). Nom 28 harf uchun inson ovozidagi «harf»
/// to'plamidan chiqadi; qolgan belgilar (ة، ء، ى) uchun nom matn bilan
/// beriladi — ular kitobda ham shu nom bilan o'rgatiladi.
class HarfBolagi {
  final String harf;
  final String nom;
  const HarfBolagi(this.harf, this.nom);
}

/// Hamzali shakllar asl harfiga keltiriladi — nomi o'sha harf nomi bilan
/// aytiladi (أ → alif, ؤ → vov, ئ → yo). Boshlang'ich kitobda shunday.
const _asl = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي'};

const _maxsus = {
  'ة': 'تَاءٌ مَرْبُوطَةٌ',
  'ء': 'هَمْزَةٌ',
  'ى': 'أَلِفٌ مَقْصُورَةٌ',
};

/// So'zni harflarga ajratadi (harakatsiz), har harfga nomini biriktiradi.
/// Bo'sh joy va tinish belgilari tashlab yuboriladi.
List<HarfBolagi> harflab(String soz) {
  final out = <HarfBolagi>[];
  for (final ch in stripDiacritics(soz).split('')) {
    if (ch.trim().isEmpty) continue;
    final nom = harfNomi(ch);
    if (nom == null) continue; // tinish belgisi, raqam va h.k.
    out.add(HarfBolagi(ch, nom));
  }
  return out;
}

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
