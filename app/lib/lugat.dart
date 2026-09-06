import 'arabic.dart';
import 'content.dart';
import 'main.dart';

/// Butun ilova bo'ylab ishlaydigan arabcha so'z izlagich.
///
/// Nega kerak: matndagi so'zga bosilganda ma'nosi chiqishi kerak, lekin
/// nahv va sarf darslarida dars lug'ati YO'Q — o'sha kitoblar lug'at
/// bermaydi. Shu sababli nahv matnida so'zga bosilganda ilgari faqat ovoz
/// chiqardi. Endi so'z butun ilovadagi barcha lug'atlardan qidiriladi:
/// Mabdaul qiroat darslarining lug'ati, alifbo lug'ati va grammatika
/// so'zlari (grammatika.json).
///
/// MUHIM QOIDA: taxmin qilinmaydi. So'z topilmasa — hech qanday tarjima
/// ko'rsatilmaydi (faqat talaffuz qoladi). Noto'g'ri tarjima tarjimasiz
/// qolishdan yomonroq.
class LugatTopilma {
  final QiroatVocab soz;

  /// Bosilgan so'z lug'atdagi shakl bilan AYNAN mos keldimi.
  /// `false` bo'lsa — old qo'shimcha (ال، و، ب…) olib tashlab topilgan,
  /// ya'ni ekranda asl shaklni ham ko'rsatish kerak.
  final bool aynan;

  const LugatTopilma(this.soz, this.aynan);
}

class Lugat {
  Lugat._();
  static final Lugat instance = Lugat._();

  Map<String, QiroatVocab>? _indeks;

  /// Qidiruv uchun soddalashtirish: harakatlar, cho'ziq chiziq (tatweel) va
  /// hamza/alif ko'rinishlaridagi farqlar olib tashlanadi. Kitob matnida
  /// «كِتَابٌ», lug'atda «كتاب» bo'lishi mumkin — ikkisi bir xil so'z.
  static String kalit(String s) {
    var t = stripDiacritics(s).replaceAll('ـ', '');
    t = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    return t.trim();
  }

  void _qosh(Map<String, QiroatVocab> m, String ar, QiroatVocab v) {
    for (final shakl in ar.split(RegExp(r'[,،/]'))) {
      final k = kalit(shakl);
      if (k.length >= 2) m.putIfAbsent(k, () => v);
    }
  }

  Map<String, QiroatVocab> get _idx {
    final tayyor = _indeks;
    if (tayyor != null) return tayyor;
    final m = <String, QiroatVocab>{};
    // Grammatika so'zlari birinchi: nahv matnida ular eng ko'p uchraydi va
    // ma'nosi shu kontekstda aniqroq.
    for (final g in repo.grammatika) {
      _qosh(m, g.ar, g);
    }
    for (final l in repo.qiroatLessons) {
      for (final v in l.vocab) {
        _qosh(m, v.ar, v);
        if (v.pl.isNotEmpty) _qosh(m, v.pl, v);
      }
    }
    for (final w in repo.words) {
      _qosh(m, w.ar, QiroatVocab(ar: w.ar, pl: '', uz: w.uz));
    }
    _indeks = m;
    return m;
  }

  /// Kontent yangilanganda indeksni qaytadan yig'ish kerak.
  void tozala() => _indeks = null;

  /// Old qo'shimchalar — so'z boshiga yopishib keladigan yordamchi harflar.
  /// Uzunroqlari oldin sinaladi: «وال» ni «و» dan oldin.
  static const _oldQoshimchalar = [
    'وبال',
    'فبال',
    'وكال',
    'بال',
    'كال',
    'فال',
    'وال',
    'لل',
    'ال',
    'و',
    'ف',
    'ب',
    'ك',
    'ل',
    'س',
  ];

  /// So'zni qidiradi. Topilmasa `null`.
  LugatTopilma? qidir(String soz) {
    final k = kalit(soz);
    if (k.length < 2) return null;
    final aynan = _idx[k];
    if (aynan != null) return LugatTopilma(aynan, true);

    // Old qo'shimchani olib tashlab ko'ramiz. Qolgan qism kamida 3 harf
    // bo'lishi shart: aks holda «بل» dan «ل» qolib, tasodifiy so'zga
    // to'g'ri kelib qolardi.
    for (final p in _oldQoshimchalar) {
      if (!k.startsWith(p)) continue;
      final qolgan = k.substring(p.length);
      if (qolgan.length < 3) continue;
      final topildi = _idx[qolgan];
      if (topildi != null) return LugatTopilma(topildi, false);
    }
    return null;
  }
}
