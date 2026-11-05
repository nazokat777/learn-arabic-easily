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

/// Harf shaklidagi belgilarning o'zbekcha tavsifi (fatha, shadda …).
String harakatNomi(String shakl) {
  final q = <String>[];
  if (shakl.contains('ّ')) q.add('shadda (harf ikkilanadi)');
  const nomlar = {
    'َ': 'fatha («a»)',
    'ِ': 'kasra («i»)',
    'ُ': 'damma («u»)',
    'ْ': 'sukun (unlisiz)',
    'ً': 'tanvin («an»)',
    'ٍ': 'tanvin («in»)',
    'ٌ': 'tanvin («un»)',
  };
  nomlar.forEach((b, n) {
    if (shakl.contains(b)) q.add(n);
  });
  return q.isEmpty ? 'harakatsiz' : q.join(' + ');
}

/// Xato bosilganda tushuntirish: nima bosildi, nima kerak edi va shu joyning
/// yasalish qoidasi. [k] — so'zdagi (gapda: butun yozuvdagi) harf o'rni;
/// [soz] — shu harf turgan so'z harflari, [i] — so'z ichidagi o'rni.
String xatoIzohi(
  HarfBolagi bosilgan,
  HarfBolagi kerak,
  List<HarfBolagi> soz,
  int i,
) {
  final b = StringBuffer();
  if (bosilgan.harf == kerak.harf) {
    b.write(
      'Harf to\'g\'ri, harakati xato: siz ${bosilgan.shakl} — '
      '${harakatNomi(bosilgan.shakl)} bosdingiz. Bu yerda ${kerak.shakl} — '
      '${harakatNomi(kerak.shakl)} kerak.',
    );
  } else {
    b.write(
      'Siz ${bosilgan.shakl} (${bosilgan.nom}) bosdingiz. Bu yerda '
      '${kerak.shakl} (${kerak.nom}) — ${harakatNomi(kerak.shakl)} kerak.',
    );
  }
  final q = _yasalishQoidasi(kerak, soz, i);
  if (q != null) b.write('\n$q');
  return b.toString();
}

String? _yasalishQoidasi(HarfBolagi h, List<HarfBolagi> soz, int i) {
  final s = h.shakl;
  final alBilan = soz.length > 2 && soz[0].harf == 'ا' && soz[1].harf == 'ل';
  if (alBilan && i <= 1) {
    return "«ال» — aniqlik qo'shimchasi, so'z boshiga qo'shiladi.";
  }
  if (h.harf == 'ة') {
    return "«ة» (ta marbuta) so'z oxirida keladi, ko'pincha muannas belgisi.";
  }
  if (RegExp('[ً-ٍ]').hasMatch(s)) {
    return "Tanvin so'z oxirida keladi va otning noaniqligini bildiradi.";
  }
  if (s.contains('ّ')) {
    return 'Shadda: harf ikki marta aytiladi, lekin bir marta yoziladi.';
  }
  final oldingi = i > 0 ? soz[i - 1].shakl : '';
  if (h.harf == 'ا' && s == 'ا' && oldingi.contains('َ')) {
    return "Fathadan keyingi harakatsiz alif «a» tovushini cho'zadi.";
  }
  if (h.harf == 'و' && s == 'و' && oldingi.contains('ُ')) {
    return "Dammadan keyingi harakatsiz vov «u» tovushini cho'zadi.";
  }
  if (h.harf == 'ي' && s == 'ي' && oldingi.contains('ِ')) {
    return "Kasradan keyingi harakatsiz yo «i» tovushini cho'zadi.";
  }
  return null;
}
